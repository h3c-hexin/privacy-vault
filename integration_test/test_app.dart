import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:privacy_vault/core/di/injection.dart';
import 'package:privacy_vault/app.dart';

/// 集成测试专用入口
///
/// 不使用 runZonedGuarded（与 IntegrationTestWidgetsFlutterBinding 冲突），
/// 不启用 FLAG_SECURE（方便截图调试）。
Future<void> testMain() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // 重置 DI 容器，确保多次调用不会重复注册
  await GetIt.instance.reset();
  await configureDependencies();

  runApp(const PrivacyVaultApp());
}
