import 'package:equatable/equatable.dart';

enum AuthStatus {
  initial,     // 初始状态，检查中
  needsSetup,  // 首次使用，需要设置 PIN
  locked,      // 已设置，需要解锁
  unlocked,    // 已解锁
  error,       // 错误
}

class AuthState extends Equatable {
  final AuthStatus status;
  final int errorCount;
  final String? errorMessage;
  final DateTime? cooldownUntil;

  const AuthState({
    this.status = AuthStatus.initial,
    this.errorCount = 0,
    this.errorMessage,
    this.cooldownUntil,
  });

  /// 是否在冷却期
  bool get isInCooldown {
    if (cooldownUntil == null) return false;
    return DateTime.now().isBefore(cooldownUntil!);
  }

  AuthState copyWith({
    AuthStatus? status,
    int? errorCount,
    String? errorMessage,
    DateTime? cooldownUntil,
    bool clearCooldown = false,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorCount: errorCount ?? this.errorCount,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      cooldownUntil: clearCooldown ? null : (cooldownUntil ?? this.cooldownUntil),
    );
  }

  @override
  List<Object?> get props => [status, errorCount, errorMessage, cooldownUntil];
}
