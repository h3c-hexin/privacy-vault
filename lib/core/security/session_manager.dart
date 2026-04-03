import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:privacy_vault/core/crypto/key_manager.dart';

/// 会话管理器
///
/// 管理认证状态和自动锁定。
/// 当 App 进入后台超过设定时间后自动锁定。
class SessionManager with WidgetsBindingObserver {
  final KeyManager _keyManager;

  Timer? _lockTimer;
  Duration _autoLockDelay = const Duration(seconds: 30);
  bool _isInForeground = true;

  /// 当前是否已认证
  bool get isAuthenticated => _keyManager.isUnlocked;

  /// 锁定回调
  VoidCallback? onLocked;

  SessionManager({required KeyManager keyManager}) : _keyManager = keyManager;

  /// 启动会话监听
  void start() {
    WidgetsBinding.instance.addObserver(this);
  }

  /// 停止会话监听
  void dispose() {
    _lockTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }

  /// 设置自动锁定延迟
  void setAutoLockDelay(Duration delay) {
    _autoLockDelay = delay;
  }

  /// 手动锁定
  ///
  /// 仅触发 onLocked 回调（通知 AuthBloc），
  /// 由 AuthBloc 统一调用 keyManager.lock() 清除密钥。
  void lock() {
    _lockTimer?.cancel();
    onLocked?.call();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _onBackground();
      case AppLifecycleState.inactive:
        // inactive 状态（来电、通知栏等）不启动锁定计时器
        break;
      case AppLifecycleState.resumed:
        _onForeground();
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _onBackground() {
    if (!_isInForeground) return;
    _isInForeground = false;

    if (!isAuthenticated) return;

    // 立即锁定（delay == 0）或启动计时器
    if (_autoLockDelay == Duration.zero) {
      lock();
    } else {
      _lockTimer?.cancel();
      _lockTimer = Timer(_autoLockDelay, lock);
    }
  }

  void _onForeground() {
    _isInForeground = true;
    // 回到前台时取消计时器（如果还没触发）
    _lockTimer?.cancel();
    _lockTimer = null;
  }
}
