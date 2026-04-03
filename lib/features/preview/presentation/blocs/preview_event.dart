import 'package:equatable/equatable.dart';

abstract class PreviewEvent extends Equatable {
  const PreviewEvent();
  @override
  List<Object?> get props => [];
}

/// 加载预览文件
class PreviewLoadFile extends PreviewEvent {
  final String fileId;
  const PreviewLoadFile(this.fileId);
  @override
  List<Object?> get props => [fileId];
}

/// 切换到指定索引
class PreviewGoToIndex extends PreviewEvent {
  final int index;
  const PreviewGoToIndex(this.index);
  @override
  List<Object?> get props => [index];
}

/// 删除当前文件
class PreviewDeleteFile extends PreviewEvent {}

/// 导出当前文件
class PreviewExportFile extends PreviewEvent {}

/// 分享当前文件
class PreviewShareFile extends PreviewEvent {}
