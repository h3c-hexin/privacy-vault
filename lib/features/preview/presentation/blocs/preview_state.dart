import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import 'package:privacy_vault/core/database/app_database.dart';

enum PreviewStatus { initial, loading, loaded, error }

class PreviewState extends Equatable {
  final PreviewStatus status;
  final VaultFile? currentFile;
  final Uint8List? decryptedBytes;
  final String? tempFilePath; // 视频临时文件路径
  final List<VaultFile> fileList; // 同文件夹的文件列表
  final int currentIndex;
  final String? errorMessage;
  final String? successMessage;

  const PreviewState({
    this.status = PreviewStatus.initial,
    this.currentFile,
    this.decryptedBytes,
    this.tempFilePath,
    this.fileList = const [],
    this.currentIndex = 0,
    this.errorMessage,
    this.successMessage,
  });

  PreviewState copyWith({
    PreviewStatus? status,
    VaultFile? currentFile,
    Uint8List? decryptedBytes,
    String? tempFilePath,
    List<VaultFile>? fileList,
    int? currentIndex,
    String? errorMessage,
    String? successMessage,
    bool clearBytes = false,
    bool clearTempPath = false,
    bool clearMessages = false,
  }) {
    return PreviewState(
      status: status ?? this.status,
      currentFile: currentFile ?? this.currentFile,
      decryptedBytes: clearBytes ? null : (decryptedBytes ?? this.decryptedBytes),
      tempFilePath: clearTempPath ? null : (tempFilePath ?? this.tempFilePath),
      fileList: fileList ?? this.fileList,
      currentIndex: currentIndex ?? this.currentIndex,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        status, currentFile, tempFilePath,
        fileList, currentIndex, errorMessage, successMessage,
        decryptedBytes?.length,
      ];
}
