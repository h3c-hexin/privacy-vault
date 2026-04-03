import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:privacy_vault/core/crypto/key_manager.dart';
import 'package:privacy_vault/core/database/app_database.dart';
import 'package:privacy_vault/core/security/brute_force_guard.dart';
import 'package:privacy_vault/features/intrusion/data/intrusion_capture_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final KeyManager _keyManager;
  final IntrusionCaptureService? _intrusionCapture;
  final AppDatabase? _db;
  final BruteForceGuard _guard;

  AuthBloc({
    required KeyManager keyManager,
    IntrusionCaptureService? intrusionCapture,
    AppDatabase? database,
    required BruteForceGuard guard,
  })  : _keyManager = keyManager,
        _intrusionCapture = intrusionCapture,
        _db = database,
        _guard = guard,
        super(const AuthState()) {
    on<AuthCheckSetup>(_onCheckSetup);
    on<AuthSetupPin>(_onSetupPin);
    on<AuthUnlockWithPin>(_onUnlockWithPin);
    on<AuthDirectUnlock>(_onDirectUnlock);
    on<AuthLock>(_onLock);
  }

  /// 从 SecureStorage 恢复持久化的暴力破解防护状态
  Future<AuthState> _loadPersistedBruteForceState() async {
    final results = await Future.wait([
      _guard.loadErrorCount(),
      _guard.loadCooldownUntil(),
    ]);

    return state.copyWith(
      errorCount: results[0] as int,
      cooldownUntil: results[1] as DateTime?,
    );
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
    // 首次解锁尝试前，从 SecureStorage 恢复持久化的冷却状态
    final persistedState = await _loadPersistedBruteForceState();
    AuthState currentState = state;
    if (state.errorCount == 0 && persistedState.errorCount > 0) {
      currentState = persistedState;
      emit(currentState);
    }

    // 检查冷却期
    if (currentState.isInCooldown) {
      emit(currentState.copyWith(errorMessage: '请等待冷却期结束'));
      return;
    }

    final success = await _keyManager.unlockWithPin(event.pin);

    if (success) {
      await _guard.reset();
      emit(currentState.copyWith(
        status: AuthStatus.unlocked,
        errorCount: 0,
        clearError: true,
        clearCooldown: true,
      ));
    } else {
      final result = await _guard.recordFailure();

      emit(currentState.copyWith(
        errorCount: result.errorCount,
        errorMessage: '密码错误',
        cooldownUntil: result.cooldownUntil,
      ));

      // 达到阈值时触发入侵拍照
      if (result.errorCount >= IntrusionCaptureService.captureThreshold) {
        final intrusionEnabled = await _db?.getSetting('intrusion_enabled');
        if (intrusionEnabled == 'true') {
          _intrusionCapture?.captureAndStore(result.errorCount);
        }
      }
    }
  }

  /// 计算器伪装入口已完成 PIN 验证和 KEK 解锁，直接切换到 unlocked 状态
  Future<void> _onDirectUnlock(AuthDirectUnlock event, Emitter<AuthState> emit) async {
    if (_keyManager.isUnlocked) {
      await _guard.reset();
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
