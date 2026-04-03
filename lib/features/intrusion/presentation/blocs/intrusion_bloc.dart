import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:privacy_vault/core/database/app_database.dart';
import 'intrusion_event.dart';
import 'intrusion_state.dart';

/// 入侵记录 BLoC
class IntrusionBloc extends Bloc<IntrusionEvent, IntrusionState> {
  final AppDatabase _db;

  IntrusionBloc({required AppDatabase database})
      : _db = database,
        super(const IntrusionState()) {
    on<IntrusionLoadRecords>(_onLoadRecords);
    on<IntrusionDeleteRecord>(_onDeleteRecord);
    on<IntrusionClearAll>(_onClearAll);
  }

  Future<void> _onLoadRecords(
    IntrusionLoadRecords event,
    Emitter<IntrusionState> emit,
  ) async {
    emit(state.copyWith(status: IntrusionStatus.loading));
    try {
      final records = await _db.getAllIntrusionRecords();
      emit(state.copyWith(status: IntrusionStatus.loaded, records: records));
    } catch (e) {
      emit(state.copyWith(
        status: IntrusionStatus.error,
        errorMessage: '操作失败',
      ));
    }
  }

  Future<void> _onDeleteRecord(
    IntrusionDeleteRecord event,
    Emitter<IntrusionState> emit,
  ) async {
    try {
      await _db.deleteIntrusionRecord(event.recordId);
      add(IntrusionLoadRecords());
    } catch (e) {
      emit(state.copyWith(errorMessage: '删除失败'));
    }
  }

  Future<void> _onClearAll(
    IntrusionClearAll event,
    Emitter<IntrusionState> emit,
  ) async {
    try {
      final records = await _db.getAllIntrusionRecords();
      for (final record in records) {
        await _db.deleteIntrusionRecord(record.id);
      }
      emit(state.copyWith(status: IntrusionStatus.loaded, records: const []));
    } catch (e) {
      emit(state.copyWith(errorMessage: '清空失败'));
    }
  }
}
