import 'package:flutter/widgets.dart';
import 'package:privacy_vault/core/security/screen_security.dart';

/// 防截屏 Mixin
///
/// 在敏感页面的 State 中 mixin 此类，自动在进入时启用、离开时禁用 FLAG_SECURE。
/// 用法：class _MyPageState extends State<MyPage> with ScreenSecureMixin
mixin ScreenSecureMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    ScreenSecurity.enable();
  }

  @override
  void dispose() {
    ScreenSecurity.disable();
    super.dispose();
  }
}
