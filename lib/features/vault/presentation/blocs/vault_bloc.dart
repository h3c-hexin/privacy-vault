import 'dart:developer' as developer;
import 'package:drift/drift.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:privacy_vault/core/database/app_database.dart';
import 'vault_event.dart';
import 'vault_state.dart';

class VaultBloc extends Bloc<VaultEvent, VaultState> {
  final AppDatabase _db;
  static const _uuid = Uuid();

  VaultBloc({required AppDatabase database})
      : _db = database,
        super(const VaultState()) {
    on<VaultLoadFolders>(_onLoadFolders);
    on<VaultCreateFolder>(_onCreateFolder);
    on<VaultRenameFolder>(_onRenameFolder);
    on<VaultDeleteFolder>(_onDeleteFolder);
    on<VaultLoadFiles>(_onLoadFiles);
    on<VaultDeleteFile>(_onDeleteFile);
    on<VaultBatchDelete>(_onBatchDelete);
  }

  Future<void> _onLoadFolders(
    VaultLoadFolders event,
    Emitter<VaultState> emit,
  ) async {
    emit(state.copyWith(status: VaultStatus.loading));
    try {
      final folders = await _db.getAllFolders();

      // 并行查询每个文件夹的文件数
      final countFutures = folders.map((f) => _db.getFileCountInFolder(f.id));
      final counts = await Future.wait(countFutures);
      final countMap = <String, int>{};
      for (var i = 0; i < folders.length; i++) {
        countMap[folders[i].id] = counts[i];
      }

      developer.log('加载文件夹: ${folders.length} 个', name: 'VaultBloc');
      emit(state.copyWith(
        status: VaultStatus.loaded,
        folders: folders,
        folderFileCounts: countMap,
      ));
    } catch (e, stackTrace) {
      developer.log('加载文件夹失败', error: e, stackTrace: stackTrace, name: 'VaultBloc');
      emit(state.copyWith(status: VaultStatus.error, errorMessage: '加载失败'));
    }
  }

  Future<void> _onCreateFolder(
    VaultCreateFolder event,
    Emitter<VaultState> emit,
  ) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      await _db.insertFolder(VaultFoldersCompanion(
        id: Value(_uuid.v4()),
        name: Value(event.name),
        sortOrder: Value(state.folders.length),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));
      add(VaultLoadFolders());
    } catch (e, stackTrace) {
      developer.log(
        '创建文件夹失败',
        error: e,
        stackTrace: stackTrace,
        name: 'VaultBloc',
      );
      emit(state.copyWith(errorMessage: '创建文件夹失败'));
    }
  }

  Future<void> _onRenameFolder(
    VaultRenameFolder event,
    Emitter<VaultState> emit,
  ) async {
    try {
      await _db.updateFolder(VaultFoldersCompanion(
        id: Value(event.folderId),
        name: Value(event.newName),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ));
      add(VaultLoadFolders());
    } catch (e) {
      emit(state.copyWith(errorMessage: '重命名失败'));
    }
  }

  Future<void> _onDeleteFolder(
    VaultDeleteFolder event,
    Emitter<VaultState> emit,
  ) async {
    try {
      // 事务保护：文件移入回收站 + 删除文件夹原子执行
      await _db.transaction(() async {
        final files = await _db.getFilesByFolder(event.folderId);
        for (final file in files) {
          await _db.softDeleteFile(file.id, event.folderId);
        }
        await _db.deleteFolder(event.folderId);
      });
      add(VaultLoadFolders());
    } catch (e) {
      emit(state.copyWith(errorMessage: '删除文件夹失败'));
    }
  }

  Future<void> _onLoadFiles(
    VaultLoadFiles event,
    Emitter<VaultState> emit,
  ) async {
    emit(state.copyWith(status: VaultStatus.loading, currentFolderId: event.folderId));
    try {
      final files = await _db.getFilesByFolder(event.folderId);
      emit(state.copyWith(status: VaultStatus.loaded, files: files));
    } catch (e) {
      emit(state.copyWith(status: VaultStatus.error, errorMessage: '加载失败'));
    }
  }

  Future<void> _onDeleteFile(
    VaultDeleteFile event,
    Emitter<VaultState> emit,
  ) async {
    try {
      await _db.softDeleteFile(event.fileId, event.folderId);
      add(VaultLoadFiles(event.folderId));
    } catch (e) {
      emit(state.copyWith(errorMessage: '删除失败'));
    }
  }

  Future<void> _onBatchDelete(
    VaultBatchDelete event,
    Emitter<VaultState> emit,
  ) async {
    try {
      for (final fileId in event.fileIds) {
        await _db.softDeleteFile(fileId, event.folderId);
      }
      add(VaultLoadFiles(event.folderId));
    } catch (e) {
      emit(state.copyWith(errorMessage: '批量删除失败'));
    }
  }
}
