import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 暴力破解防护服务
///
/// 统一管理错误计数、冷却期计算和 SecureStorage 持久化。
/// AuthBloc 和 CalculatorBloc 共享同一实例，确保状态同步。
class BruteForceGuard {
  final FlutterSecureStorage _secureStorage;

  static const int cooldown1Threshold = 5;
  static const int cooldown2Threshold = 10;
  static const Duration cooldown1Duration = Duration(seconds: 30);
  static const Duration cooldown2Duration = Duration(minutes: 5);

  static const String _errorCountKey = 'auth_error_count';
  static const String _cooldownUntilKey = 'auth_cooldown_until';

  BruteForceGuard({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// 读取持久化的错误计数
  Future<int> loadErrorCount() async {
    final str = await _secureStorage.read(key: _errorCountKey);
    return int.tryParse(str ?? '') ?? 0;
  }

  /// 读取持久化的冷却截止时间
  Future<DateTime?> loadCooldownUntil() async {
    final str = await _secureStorage.read(key: _cooldownUntilKey);
    if (str == null) return null;
    return DateTime.tryParse(str);
  }

  /// 检查当前是否处于冷却期
  Future<bool> isInCooldown() async {
    final cooldownUntil = await loadCooldownUntil();
    if (cooldownUntil == null) return false;
    return DateTime.now().isBefore(cooldownUntil);
  }

  /// 记录一次验证失败，返回更新后的错误计数和冷却截止时间
  Future<({int errorCount, DateTime? cooldownUntil})> recordFailure() async {
    final newErrorCount = (await loadErrorCount()) + 1;

    DateTime? cooldownUntil;
    if (newErrorCount >= cooldown2Threshold) {
      cooldownUntil = DateTime.now().add(cooldown2Duration);
    } else if (newErrorCount >= cooldown1Threshold) {
      cooldownUntil = DateTime.now().add(cooldown1Duration);
    }

    await _secureStorage.write(
      key: _errorCountKey,
      value: newErrorCount.toString(),
    );
    if (cooldownUntil != null) {
      await _secureStorage.write(
        key: _cooldownUntilKey,
        value: cooldownUntil.toIso8601String(),
      );
    }

    return (errorCount: newErrorCount, cooldownUntil: cooldownUntil);
  }

  /// 清除所有错误计数和冷却状态（解锁成功时调用）
  Future<void> reset() async {
    await Future.wait([
      _secureStorage.write(key: _errorCountKey, value: '0'),
      _secureStorage.delete(key: _cooldownUntilKey),
    ]);
  }
}
