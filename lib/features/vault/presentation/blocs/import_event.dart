import 'package:equatable/equatable.dart';
import 'package:privacy_vault/features/vault/data/file_import_service.dart';

abstract class ImportEvent extends Equatable {
  const ImportEvent();
  @override
  List<Object?> get props => [];
}

/// 选择文件（打开文件选择器）
class ImportPickFiles extends ImportEvent {
  final String fileType; // 'all', 'image', 'video'
  const ImportPickFiles({this.fileType = 'all'});
  @override
  List<Object?> get props => [fileType];
}

/// 开始导入已选择的文件到指定文件夹
class ImportStartImport extends ImportEvent {
  final List<ImportFileInfo> files;
  final String folderId;
  final bool deleteSource;

  const ImportStartImport({
    required this.files,
    required this.folderId,
    this.deleteSource = false,
  });

  @override
  List<Object?> get props => [files, folderId, deleteSource];
}

/// 取消导入
class ImportCancel extends ImportEvent {}

/// 重置状态
class ImportReset extends ImportEvent {}
