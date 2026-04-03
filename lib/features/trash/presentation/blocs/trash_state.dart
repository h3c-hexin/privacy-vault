import 'package:equatable/equatable.dart';
import 'package:privacy_vault/core/database/app_database.dart';

enum TrashStatus { initial, loading, loaded, error }

class TrashState extends Equatable {
  final TrashStatus status;
  final List<VaultFile> files;
  final String? errorMessage;

  const TrashState({
    this.status = TrashStatus.initial,
    this.files = const [],
    this.errorMessage,
  });

  TrashState copyWith({
    TrashStatus? status,
    List<VaultFile>? files,
    String? errorMessage,
  }) {
    return TrashState(
      status: status ?? this.status,
      files: files ?? this.files,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, files, errorMessage];
}
