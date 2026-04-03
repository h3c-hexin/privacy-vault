import 'package:equatable/equatable.dart';

abstract class TrashEvent extends Equatable {
  const TrashEvent();
  @override
  List<Object?> get props => [];
}

/// 加载回收站文件列表
class TrashLoadFiles extends TrashEvent {}

/// 恢复文件
class TrashRestoreFile extends TrashEvent {
  final String fileId;
  const TrashRestoreFile(this.fileId);
  @override
  List<Object?> get props => [fileId];
}

/// 彻底删除文件
class TrashPermanentDelete extends TrashEvent {
  final String fileId;
  const TrashPermanentDelete(this.fileId);
  @override
  List<Object?> get props => [fileId];
}

/// 清空回收站
class TrashEmptyAll extends TrashEvent {}

/// 清理过期文件（30 天）
class TrashCleanExpired extends TrashEvent {}
