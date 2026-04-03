import 'package:equatable/equatable.dart';
import 'package:privacy_vault/features/vault/data/file_import_service.dart';

enum ImportStatus {
  initial,
  picking,      // 文件选择中
  picked,       // 已选择文件
  importing,    // 导入中
  completed,    // 导入完成
  error,        // 出错
}

class ImportState extends Equatable {
  final ImportStatus status;
  final List<ImportFileInfo> selectedFiles;
  final int totalCount;
  final int completedCount;
  final int failedCount;
  final String? errorMessage;

  const ImportState({
    this.status = ImportStatus.initial,
    this.selectedFiles = const [],
    this.totalCount = 0,
    this.completedCount = 0,
    this.failedCount = 0,
    this.errorMessage,
  });

  double get progress =>
      totalCount > 0 ? completedCount / totalCount : 0.0;

  ImportState copyWith({
    ImportStatus? status,
    List<ImportFileInfo>? selectedFiles,
    int? totalCount,
    int? completedCount,
    int? failedCount,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ImportState(
      status: status ?? this.status,
      selectedFiles: selectedFiles ?? this.selectedFiles,
      totalCount: totalCount ?? this.totalCount,
      completedCount: completedCount ?? this.completedCount,
      failedCount: failedCount ?? this.failedCount,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status, selectedFiles, totalCount, completedCount, failedCount, errorMessage,
      ];
}
