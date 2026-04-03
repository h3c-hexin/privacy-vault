import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

/// 检查是否已完成首次设置
class AuthCheckSetup extends AuthEvent {}

/// 首次设置 PIN
class AuthSetupPin extends AuthEvent {
  final String pin;
  const AuthSetupPin(this.pin);
  @override
  List<Object?> get props => [pin];
}

/// PIN 解锁
class AuthUnlockWithPin extends AuthEvent {
  final String pin;
  const AuthUnlockWithPin(this.pin);
  @override
  List<Object?> get props => [pin];
}

/// 由计算器伪装入口触发的直接解锁（KeyManager 已在计算器中完成 PIN 验证和 KEK 解锁）
class AuthDirectUnlock extends AuthEvent {}

/// 手动锁定
class AuthLock extends AuthEvent {}
