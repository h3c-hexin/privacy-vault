import 'dart:collection';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:privacy_vault/core/database/app_database.dart';
import 'package:privacy_vault/core/storage/encrypted_file_storage.dart';
import 'package:privacy_vault/core/storage/temp_file_manager.dart';
import 'preview_event.dart';
import 'preview_state.dart';

/// 预览 BLoC
///
/// 管理文件解密预览、切换、导出、分享、删除。
/// 内置 LRU 图片缓存（最多 3 张），切换时预加载相邻图片。
class PreviewBloc extends Bloc<PreviewEvent, PreviewState> {
  final AppDatabase _db;
  final EncryptedFileStorage _fileStorage;
  final TempFileManager _tempManager;

  /// 已解密图片 LRU 缓存（fileId → bytes），最多保留 3 张
  final _imageCache = LinkedHashMap<String, Uint8List>();
  static const int _maxCachedImages = 3;

  PreviewBloc({
    required AppDatabase database,
    required EncryptedFileStorage fileStorage,
    required TempFileManager tempManager,
  })  : _db = database,
        _fileStorage = fileStorage,
        _tempManager = tempManager,
        super(const PreviewState()) {
    on<PreviewLoadFile>(_onLoadFile);
    on<PreviewGoToIndex>(_onGoToIndex);
    on<PreviewDeleteFile>(_onDeleteFile);
    on<PreviewExportFile>(_onExportFile);
    on<PreviewShareFile>(_onShareFile);
  }

  Future<void> _onLoadFile(
    PreviewLoadFile event,
    Emitter<PreviewState> emit,
  ) async {
    emit(state.copyWith(status: PreviewStatus.loading));
    try {
      final file = await _db.getFileById(event.fileId);
      if (file == null) {
        emit(state.copyWith(
          status: PreviewStatus.error,
          errorMessage: '文件不存在',
        ));
        return;
      }

      // 加载同文件夹的文件列表（首次加载或列表为空时）
      final fileList = state.fileList.isEmpty
          ? await _db.getFilesByFolder(file.folderId)
          : state.fileList;
      final index = fileList.indexWhere((f) => f.id == file.id);

      if (file.fileType == 'image') {
        // 优先从缓存读取（并更新 LRU 顺序）
        final cached = _touchCachedImage(file.id);
        final bytes = cached ?? await _fileStorage.decryptToMemory(
          file.encryptedPath,
          file.encryptedDek,
          file.chunkCount,
        );
        // 存入缓存
        _putCachedImage(file.id, bytes);

        emit(state.copyWith(
          status: PreviewStatus.loaded,
          currentFile: file,
          decryptedBytes: bytes,
          fileList: fileList,
          currentIndex: index >= 0 ? index : 0,
          clearTempPath: true,
        ));

        // 预加载相邻图片（不阻塞当前页渲染）
        _prefetchAdjacent(fileList, index >= 0 ? index : 0);
      } else if (file.fileType == 'video') {
        // 视频解密到临时文件
        final tempPath = await _fileStorage.decryptToTemp(
          file.encryptedPath,
          file.encryptedDek,
          file.chunkCount,
          file.originalName,
        );
        emit(state.copyWith(
          status: PreviewStatus.loaded,
          currentFile: file,
          tempFilePath: tempPath,
          fileList: fileList,
          currentIndex: index >= 0 ? index : 0,
          clearBytes: true,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: PreviewStatus.error,
        errorMessage: '解密失败',
      ));
    }
  }

  Future<void> _onGoToIndex(
    PreviewGoToIndex event,
    Emitter<PreviewState> emit,
  ) async {
    if (event.index < 0 || event.index >= state.fileList.length) return;

    // 清理之前的临时文件
    if (state.tempFilePath != null) {
      await _tempManager.cleanFile(state.tempFilePath!);
    }

    final file = state.fileList[event.index];
    add(PreviewLoadFile(file.id));
  }

  Future<void> _onDeleteFile(
    PreviewDeleteFile event,
    Emitter<PreviewState> emit,
  ) async {
    final file = state.currentFile;
    if (file == null) return;

    try {
      await _db.softDeleteFile(file.id, file.folderId);

      // 清理临时文件
      if (state.tempFilePath != null) {
        await _tempManager.cleanFile(state.tempFilePath!);
      }

      // 更新文件列表
      final newList = state.fileList.where((f) => f.id != file.id).toList();
      if (newList.isEmpty) {
        emit(const PreviewState(status: PreviewStatus.initial));
        return;
      }

      final newIndex = state.currentIndex.clamp(0, newList.length - 1);
      emit(state.copyWith(
        fileList: newList,
        currentIndex: newIndex,
        clearBytes: true,
        clearTempPath: true,
      ));
      add(PreviewLoadFile(newList[newIndex].id));
    } catch (e) {
      emit(state.copyWith(errorMessage: '删除失败'));
    }
  }

  Future<void> _onExportFile(
    PreviewExportFile event,
    Emitter<PreviewState> emit,
  ) async {
    final file = state.currentFile;
    if (file == null) return;

    // 先清除旧消息，确保新消息能触发 Equatable 变更
    emit(state.copyWith(clearMessages: true));

    try {
      // 检查并请求相册写入权限
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        final granted = await Gal.requestAccess(toAlbum: true);
        if (!granted) {
          emit(state.copyWith(errorMessage: '需要相册写入权限才能导出'));
          return;
        }
      }

      // 解密到临时目录
      final tempPath = await _fileStorage.decryptToTemp(
        file.encryptedPath,
        file.encryptedDek,
        file.chunkCount,
        file.originalName,
      );

      try {
        // 保存到系统相册（通过 MediaStore API，兼容 Android 10+）
        if (file.fileType == 'video') {
          await Gal.putVideo(tempPath, album: '隐私保险箱');
        } else {
          await Gal.putImage(tempPath, album: '隐私保险箱');
        }
        emit(state.copyWith(successMessage: '已保存到相册'));
      } finally {
        // 无论成功失败都清理临时明文文件
        await _tempManager.cleanFile(tempPath);
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: '保存失败'));
    }
  }

  Future<void> _onShareFile(
    PreviewShareFile event,
    Emitter<PreviewState> emit,
  ) async {
    final file = state.currentFile;
    if (file == null) return;

    String? tempPath;
    try {
      // 解密到临时目录，路径记录以便 BLoC close 时兜底清理
      tempPath = await _fileStorage.decryptToTemp(
        file.encryptedPath,
        file.encryptedDek,
        file.chunkCount,
        file.originalName,
      );
      emit(state.copyWith(tempFilePath: tempPath));

      // 调用系统分享
      await Share.shareXFiles([XFile(tempPath)]);
    } catch (e) {
      emit(state.copyWith(errorMessage: '分享失败'));
    } finally {
      // 清理临时文件（分享完成或失败）
      if (tempPath != null) {
        await _tempManager.cleanFile(tempPath);
        emit(state.copyWith(clearTempPath: true));
      }
    }
  }

  /// 只读查询缓存（不修改 LRU 顺序，安全用于 build）
  Uint8List? getCachedImage(String fileId) => _imageCache[fileId];

  /// 获取并更新 LRU 顺序（仅在确认切换到该页时调用）
  Uint8List? _touchCachedImage(String fileId) {
    final value = _imageCache.remove(fileId);
    if (value != null) {
      _imageCache[fileId] = value; // 移到末尾
    }
    return value;
  }

  /// 存入 LRU 缓存
  void _putCachedImage(String fileId, Uint8List bytes) {
    _imageCache.remove(fileId);
    while (_imageCache.length >= _maxCachedImages) {
      _imageCache.remove(_imageCache.keys.first);
    }
    _imageCache[fileId] = bytes;
  }

  /// 预加载当前索引前后各一张图片（后台静默执行）
  void _prefetchAdjacent(List<VaultFile> fileList, int currentIndex) {
    for (final offset in [-1, 1]) {
      final i = currentIndex + offset;
      if (i < 0 || i >= fileList.length) continue;
      final f = fileList[i];
      if (f.fileType != 'image') continue;
      if (_imageCache.containsKey(f.id)) continue;

      // 后台解密，不 emit 状态
      _fileStorage.decryptToMemory(
        f.encryptedPath,
        f.encryptedDek,
        f.chunkCount,
      ).then((bytes) {
        if (!isClosed) _putCachedImage(f.id, bytes);
      }).catchError((_) {
        // 预加载失败静默忽略
      });
    }
  }

  @override
  Future<void> close() async {
    _imageCache.clear();
    // 清理临时文件
    if (state.tempFilePath != null) {
      await _tempManager.cleanFile(state.tempFilePath!);
    }
    return super.close();
  }
}
