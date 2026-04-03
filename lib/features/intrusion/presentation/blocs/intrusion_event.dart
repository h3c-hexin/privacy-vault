import 'package:equatable/equatable.dart';

abstract class IntrusionEvent extends Equatable {
  const IntrusionEvent();
  @override
  List<Object?> get props => [];
}

/// 加载入侵记录列表
class IntrusionLoadRecords extends IntrusionEvent {}

/// 删除入侵记录
class IntrusionDeleteRecord extends IntrusionEvent {
  final String recordId;
  const IntrusionDeleteRecord(this.recordId);
  @override
  List<Object?> get props => [recordId];
}

/// 清空所有记录
class IntrusionClearAll extends IntrusionEvent {}
