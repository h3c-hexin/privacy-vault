import 'dart:developer' as developer;
import 'package:drift/drift.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:privacy_vault/core/database/app_database.dart';
import 'package:privacy_vault/core/storage/encrypted_file_storage.dart';
import 'package:privacy_vault/features/vault/data/file_import_service.dart';
import 'package:privacy_vault/features/vault/data/thumbnail_service.dart';
import 'import_event.dart';
import 'import_state.dart';

/// 文件导入 BLoC
///
/// 管理文件选择、加密导入、进度追踪的完整流程。
class ImportBloc extends Bloc<ImportEvent, ImportState> {
  final FileImportService _importService;
  final EncryptedFileStorage _fileStorage;
  final ThumbnailService _thumbnailService;
  final AppDatabase _db;
  static const _uuid = Uuid();

  bool _cancelled = false;

  ImportBloc({
    required FileImportService importService,
    required EncryptedFileStorage fileStorage,
    required ThumbnailService thumbnailService,
    required AppDatabase database,
  })  : _importService = importService,
        _fileStorage = fileStorage,
        _thumbnailService = thumbnailService,
        _db = database,
        super(const ImportState()) {
    on<ImportPickFiles>(_onPickFiles);
    on<ImportStartImport>(_onStartImport);
    on<ImportCancel>(_onCancel);
    on<ImportReset>(_onReset);
  }

  Future<void> _onPickFiles(
    ImportPickFiles event,
    Emitter<ImportState> emit,
  ) async {
    emit(state.copyWith(status: ImportStatus.picking));
    try {
      final List<ImportFileInfo> files;
      switch (event.fileType) {
        case 'image':
          files = await _importService.pickImages();
        case 'video':
          files = await _importService.pickVideos();
        default:
          files = await _importService.pickFiles();
      }

      if (files.isEmpty) {
        emit(state.copyWith(status: ImportStatus.initial));
      } else {
        emit(state.copyWith(
          status: ImportStatus.picked,
          selectedFiles: files,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: ImportStatus.error,
        errorMessage: '选择文件失败',
      ));
    }
  }

  Future<void> _onStartImport(
    ImportStartImport event,
    Emitter<ImportState> emit,
  ) async {
    _cancelled = false;
    final files = event.files;

    emit(state.copyWith(
      status: ImportStatus.importing,
      totalCount: files.length,
      completedCount: 0,
      failedCount: 0,
    ));

    int completed = 0;
    int failed = 0;

    for (final file in files) {
      if (_cancelled) break;

      try {
        await _importSingleFile(file, event.folderId, event.deleteSource);
        completed++;
      } catch (e, stack) {
        failed++;
        developer.log(
          '文件导入失败: ${file.name}',
          error: e,
          stackTrace: stack,
          name: 'ImportBloc',
        );
      }

      // 每个文件处理后再次检查取消标志
      if (_cancelled) break;

      emit(state.copyWith(
        completedCount: completed,
        failedCount: failed,
      ));
    }

    // 清理 file_picker 缓存
    await _importService.cleanPickerCache();

    emit(state.copyWith(
      status: _cancelled ? ImportStatus.initial : ImportStatus.completed,
    ));
  }

  /// 导入单个文件：加密存储 → 缩略图 → 清零 DEK → 写入 DB
  Future<void> _importSingleFile(
    ImportFileInfo file,
    String folderId,
    bool deleteSource,
  ) async {
    final fileId = _uuid.v4();
    final result = await _fileStorage.encryptAndStore(file.path, fileId);

    try {
      // 生成缩略图（仅图片）
      String? thumbnailPath;
      int? width;
      int? height;

      if (file.fileType == 'image') {
        final thumbResult =
            await _thumbnailService.generateThumbnailAndGetDimensions(
          file.path,
          fileId,
          result.plainDek,
        );
        thumbnailPath = thumbResult.thumbnailPath;
        width = thumbResult.width;
        height = thumbResult.height;
      }

      // 写入数据库
      final now = DateTime.now().millisecondsSinceEpoch;
      await _db.insertFile(VaultFilesCompanion(
        id: Value(fileId),
        folderId: Value(folderId),
        originalName: Value(file.name),
        fileType: Value(file.fileType),
        mimeType: Value(file.mimeType),
        encryptedPath: Value(result.encryptedPath),
        thumbnailPath: Value(thumbnailPath),
        fileSize: Value(result.originalSize),
        encryptedSize: Value(result.encryptedSize),
        width: Value(width),
        height: Value(height),
        encryptedDek: Value(result.encryptedDek),
        dekIv: const Value(''),
        fileIv: const Value(''),
        chunkCount: Value(result.chunkCount),
        checksum: Value(result.checksum),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));

      if (deleteSource) {
        await _importService.deleteSourceFile(file.path);
      }
    } finally {
      // 确保 plainDek 无论成功失败都被清零
      for (var i = 0; i < result.plainDek.length; i++) {
        result.plainDek[i] = 0;
      }
    }
  }

  void _onCancel(ImportCancel event, Emitter<ImportState> emit) {
    _cancelled = true;
  }

  void _onReset(ImportReset event, Emitter<ImportState> emit) {
    _cancelled = false;
    emit(const ImportState());
  }
}
