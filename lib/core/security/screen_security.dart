import 'package:flutter/services.dart';

/// 屏幕安全服务
///
/// 通过 Android FLAG_SECURE 防止截屏和录屏，
/// 并在最近任务列表中隐藏内容。
class ScreenSecurity {
  static const _channel = MethodChannel('com.privacyvault/screen_security');

  /// 启用防截屏（设置 FLAG_SECURE）
  static Future<void> enable() async {
    try {
      await _channel.invokeMethod('enableSecureFlag');
    } on PlatformException {
      // 平台不支持时静默降级
    }
  }

  /// 禁用防截屏（清除 FLAG_SECURE）
  static Future<void> disable() async {
    try {
      await _channel.invokeMethod('disableSecureFlag');
    } on PlatformException {
      // 平台不支持时静默降级
    }
  }
}
