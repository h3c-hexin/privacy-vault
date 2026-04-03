import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:privacy_vault/core/database/app_database.dart';
import 'package:privacy_vault/core/storage/encrypted_file_storage.dart';
import 'trash_event.dart';
import 'trash_state.dart';

/// 回收站 BLoC
///
/// 管理已删除文件的列表、恢复、彻底删除和自动清理。
class TrashBloc extends Bloc<TrashEvent, TrashState> {
  final AppDatabase _db;
  final EncryptedFileStorage _fileStorage;

  TrashBloc({
    required AppDatabase database,
    required EncryptedFileStorage fileStorage,
  })  : _db = database,
        _fileStorage = fileStorage,
        super(const TrashState()) {
    on<TrashLoadFiles>(_onLoadFiles);
    on<TrashRestoreFile>(_onRestoreFile);
    on<TrashPermanentDelete>(_onPermanentDelete);
    on<TrashEmptyAll>(_onEmptyAll);
    on<TrashCleanExpired>(_onCleanExpired);
  }

  Future<void> _onLoadFiles(
    TrashLoadFiles event,
    Emitter<TrashState> emit,
  ) async {
    emit(state.copyWith(status: TrashStatus.loading));
    try {
      final files = await _db.getDeletedFiles();
      emit(state.copyWith(status: TrashStatus.loaded, files: files));
    } catch (e) {
      emit(state.copyWith(
        status: TrashStatus.error,
        errorMessage: '操作失败',
      ));
    }
  }

  Future<void> _onRestoreFile(
    TrashRestoreFile event,
    Emitter<TrashState> emit,
  ) async {
    try {
      await _db.restoreFile(event.fileId);
      add(TrashLoadFiles());
    } catch (e) {
      emit(state.copyWith(errorMessage: '恢复失败'));
    }
  }

  Future<void> _onPermanentDelete(
    TrashPermanentDelete event,
    Emitter<TrashState> emit,
  ) async {
    try {
      final file = await _db.getFileById(event.fileId);
      if (file != null) {
        // 删除加密文件和缩略图
        await _fileStorage.deleteEncryptedFile(
          file.encryptedPath,
          file.chunkCount,
        );
        await _fileStorage.deleteThumbnail(file.thumbnailPath);
        await _db.permanentDeleteFile(event.fileId);
      }
      add(TrashLoadFiles());
    } catch (e) {
      emit(state.copyWith(errorMessage: '删除失败'));
    }
  }

  Future<void> _onEmptyAll(
    TrashEmptyAll event,
    Emitter<TrashState> emit,
  ) async {
    try {
      final files = await _db.getDeletedFiles();
      for (final file in files) {
        await _fileStorage.deleteEncryptedFile(
          file.encryptedPath,
          file.chunkCount,
        );
        await _fileStorage.deleteThumbnail(file.thumbnailPath);
        await _db.permanentDeleteFile(file.id);
      }
      emit(state.copyWith(status: TrashStatus.loaded, files: const []));
    } catch (e) {
      emit(state.copyWith(errorMessage: '清空失败'));
    }
  }

  Future<void> _onCleanExpired(
    TrashCleanExpired event,
    Emitter<TrashState> emit,
  ) async {
    try {
      final expired = await _db.getExpiredDeletedFiles();
      for (final file in expired) {
        await _fileStorage.deleteEncryptedFile(
          file.encryptedPath,
          file.chunkCount,
        );
        await _fileStorage.deleteThumbnail(file.thumbnailPath);
        await _db.permanentDeleteFile(file.id);
      }
      add(TrashLoadFiles());
    } catch (e) {
      emit(state.copyWith(errorMessage: '清理失败'));
    }
  }
}
