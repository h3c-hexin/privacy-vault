import 'package:equatable/equatable.dart';
import 'package:privacy_vault/core/database/app_database.dart';

enum VaultStatus { initial, loading, loaded, error }

class VaultState extends Equatable {
  final VaultStatus status;
  final List<VaultFolder> folders;
  final Map<String, int> folderFileCounts; // folderId → fileCount
  final List<VaultFile> files;
  final String? currentFolderId;
  final String? errorMessage;

  const VaultState({
    this.status = VaultStatus.initial,
    this.folders = const [],
    this.folderFileCounts = const {},
    this.files = const [],
    this.currentFolderId,
    this.errorMessage,
  });

  VaultState copyWith({
    VaultStatus? status,
    List<VaultFolder>? folders,
    Map<String, int>? folderFileCounts,
    List<VaultFile>? files,
    String? currentFolderId,
    String? errorMessage,
    bool clearError = false,
  }) {
    return VaultState(
      status: status ?? this.status,
      folders: folders ?? this.folders,
      folderFileCounts: folderFileCounts ?? this.folderFileCounts,
      files: files ?? this.files,
      currentFolderId: currentFolderId ?? this.currentFolderId,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, folders, folderFileCounts, files, currentFolderId, errorMessage];
}
