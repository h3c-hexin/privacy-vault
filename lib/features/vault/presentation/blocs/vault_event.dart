import 'package:equatable/equatable.dart';

abstract class VaultEvent extends Equatable {
  const VaultEvent();
  @override
  List<Object?> get props => [];
}

class VaultLoadFolders extends VaultEvent {}

class VaultCreateFolder extends VaultEvent {
  final String name;
  const VaultCreateFolder(this.name);
  @override
  List<Object?> get props => [name];
}

class VaultRenameFolder extends VaultEvent {
  final String folderId;
  final String newName;
  const VaultRenameFolder(this.folderId, this.newName);
  @override
  List<Object?> get props => [folderId, newName];
}

class VaultDeleteFolder extends VaultEvent {
  final String folderId;
  const VaultDeleteFolder(this.folderId);
  @override
  List<Object?> get props => [folderId];
}

class VaultLoadFiles extends VaultEvent {
  final String folderId;
  const VaultLoadFiles(this.folderId);
  @override
  List<Object?> get props => [folderId];
}

class VaultDeleteFile extends VaultEvent {
  final String fileId;
  final String folderId;
  const VaultDeleteFile(this.fileId, this.folderId);
  @override
  List<Object?> get props => [fileId, folderId];
}

class VaultBatchDelete extends VaultEvent {
  final List<String> fileIds;
  final String folderId;
  const VaultBatchDelete(this.fileIds, this.folderId);
  @override
  List<Object?> get props => [fileIds, folderId];
}
