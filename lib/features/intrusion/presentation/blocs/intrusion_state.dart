import 'package:equatable/equatable.dart';
import 'package:privacy_vault/core/database/app_database.dart';

enum IntrusionStatus { initial, loading, loaded, error }

class IntrusionState extends Equatable {
  final IntrusionStatus status;
  final List<IntrusionRecord> records;
  final String? errorMessage;

  const IntrusionState({
    this.status = IntrusionStatus.initial,
    this.records = const [],
    this.errorMessage,
  });

  IntrusionState copyWith({
    IntrusionStatus? status,
    List<IntrusionRecord>? records,
    String? errorMessage,
  }) {
    return IntrusionState(
      status: status ?? this.status,
      records: records ?? this.records,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, records, errorMessage];
}
