import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:privacy_vault/core/crypto/key_manager.dart';
import 'package:privacy_vault/core/database/app_database.dart';
import 'package:privacy_vault/features/intrusion/data/intrusion_capture_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final KeyManager _keyManager;
  final IntrusionCaptureService? _intrusionCapture;
  final AppDatabase? _db;
  final FlutterSecureStorage _secureStorage;

  // 冷却阈值
  static const int _cooldown1Threshold = 5;
  static const int _cooldown2Threshold = 10;
  static const Duration _cooldown1Duration = Duration(seconds: 30);
  static const Duration _cooldown2Duration = Duration(minutes: 5);

  // SecureStorage 键名——用于持久化暴力破解防护数据
  static const String _errorCountKey = 'auth_error_count';
  static const String _cooldownUntilKey = 'auth_cooldown_until';

  AuthBloc({
    required KeyManager keyManager,
    IntrusionCaptureService? intrusionCapture,
    AppDatabase? database,
    FlutterSecureStorage? secureStorage,
  })  : _keyManager = keyManager,
        _intrusionCapture = intrusionCapture,
        _db = database,
        _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        super(const AuthState()) {
    on<AuthCheckSetup>(_onCheckSetup);
    on<AuthSetupPin>(_onSetupPin);
    on<AuthUnlockWithPin>(_onUnlockWithPin);
    on<AuthDirectUnlock>(_onDirectUnlock);
    on<AuthLock>(_onLock);
  }

  /// 从 SecureStorage 恢复持久化的暴力破解防护状态
  ///
  /// 在首次解锁尝试前调用，确保 App 重启后冷却状态不丢失。
  Future<AuthState> _loadPersistedBruteForceState() async {
    final errorCountStr = await _secureStorage.read(key: _errorCountKey);
    final cooldownUntilStr = await _secureStorage.read(key: _cooldownUntilKey);

    final errorCount = int.tryParse(errorCountStr ?? '') ?? 0;
    DateTime? cooldownUntil;
    if (cooldownUntilStr != null) {
      cooldownUntil = DateTime.tryParse(cooldownUntilStr);
    }

    return state.copyWith(
      errorCount: errorCount,
      cooldownUntil: cooldownUntil,
    );
  }

  /// 将暴力破解防护状态持久化到 SecureStorage
  Future<void> _persistBruteForceState(int errorCount, DateTime? cooldownUntil) async {
    await _secureStorage.write(
      key: _errorCountKey,
      value: errorCount.toString(),
    );
    if (cooldownUntil != null) {
      await _secureStorage.write(
        key: _cooldownUntilKey,
        value: cooldownUntil.toIso8601String(),
      );
    } else {
      // 解锁成功后清除冷却记录
      await _secureStorage.delete(key: _cooldownUntilKey);
    }
  }

  Future<void> _onCheckSetup(
    AuthCheckSetup event,
    Emitter<AuthState> emit,
  ) async {
    final isSetup = await _keyManager.isSetupComplete();
    emit(state.copyWith(
      status: isSetup ? AuthStatus.locked : AuthStatus.needsSetup,
    ));
  }

  Future<void> _onSetupPin(
    AuthSetupPin event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _keyManager.setup(event.pin);
      emit(state.copyWith(status: AuthStatus.unlocked, clearError: true));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: '设置失败',
      ));
    }
  }

  Future<void> _onUnlockWithPin(
    AuthUnlockWithPin event,
    Emitter<AuthState> emit,
  ) async {
    // 首次解锁尝试前，从 SecureStorage 恢复持久化的冷却状态（应对 App 重启场景）
    final persistedState = await _loadPersistedBruteForceState();
    // 将恢复的状态合并到当前 state（仅当当前 errorCount 为 0 时才恢复，避免重复累加）
    AuthState currentState = state;
    if (state.errorCount == 0 && persistedState.errorCount > 0) {
      currentState = persistedState;
      emit(currentState);
    }

    // 检查冷却期（含从 SecureStorage 恢复的冷却时间）
    if (currentState.isInCooldown) {
      emit(currentState.copyWith(errorMessage: '请等待冷却期结束'));
      return;
    }

    final success = await _keyManager.unlockWithPin(event.pin);

    if (success) {
      // 解锁成功：清零错误计数，清除持久化冷却状态
      await _persistBruteForceState(0, null);
      emit(currentState.copyWith(
        status: AuthStatus.unlocked,
        errorCount: 0,
        clearError: true,
        clearCooldown: true,
      ));
    } else {
      final newErrorCount = currentState.errorCount + 1;
      DateTime? cooldownUntil;

      if (newErrorCount >= _cooldown2Threshold) {
        cooldownUntil = DateTime.now().add(_cooldown2Duration);
      } else if (newErrorCount >= _cooldown1Threshold) {
        cooldownUntil = DateTime.now().add(_cooldown1Duration);
      }

      // 持久化更新后的错误计数和冷却时间，防止 App 重启绕过限制
      await _persistBruteForceState(newErrorCount, cooldownUntil);

      emit(currentState.copyWith(
        errorCount: newErrorCount,
        errorMessage: '密码错误',
        cooldownUntil: cooldownUntil,
      ));

      // 达到阈值时触发入侵拍照（受设置开关控制）
      if (newErrorCount >= IntrusionCaptureService.captureThreshold) {
        final intrusionEnabled = await _db?.getSetting('intrusion_enabled');
        if (intrusionEnabled == 'true') {
          _intrusionCapture?.captureAndStore(newErrorCount);
        }
      }
    }
  }

  /// 计算器伪装入口已完成 PIN 验证和 KEK 解锁，直接切换到 unlocked 状态
  Future<void> _onDirectUnlock(AuthDirectUnlock event, Emitter<AuthState> emit) async {
    if (_keyManager.isUnlocked) {
      // 直接解锁成功也需清除持久化的暴力破解计数
      await _persistBruteForceState(0, null);
      emit(state.copyWith(
        status: AuthStatus.unlocked,
        errorCount: 0,
        clearError: true,
        clearCooldown: true,
      ));
    }
  }

  void _onLock(AuthLock event, Emitter<AuthState> emit) {
    _keyManager.lock();
    emit(state.copyWith(status: AuthStatus.locked, clearError: true));
  }
}
