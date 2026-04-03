import 'dart:async';
import 'dart:developer' as developer;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:privacy_vault/core/di/injection.dart';
import 'package:privacy_vault/core/storage/temp_file_manager.dart';
import 'package:privacy_vault/app.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 全局 Flutter 框架错误捕获
    FlutterError.onError = (details) {
      developer.log(
        'Flutter error: ${details.exceptionAsString()}',
        error: details.exception,
        stackTrace: details.stack,
        name: 'PrivacyVault',
      );
    };

    // 异步错误捕获
    PlatformDispatcher.instance.onError = (error, stack) {
      developer.log(
        'Platform error: $error',
        error: error,
        stackTrace: stack,
        name: 'PrivacyVault',
      );
      return true;
    };

    // Release 模式替换红屏（debug 模式保留默认行为便于排查）
    if (kReleaseMode) {
      ErrorWidget.builder = (details) => const SizedBox.shrink();
    }

    // 初始化 media_kit（视频播放）
    MediaKit.ensureInitialized();

    // 竖屏锁定
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // 防截屏：由 ScreenSecurityObserver 按路由动态控制，不再全局启用
    // （敏感页面启用，赞赏码/设置等页面允许截屏）

    // 依赖注入（异步，读取数据库密钥）
    await configureDependencies();

    // 清理上次残留的临时明文文件（App 崩溃/强杀后可能残留）
    getIt<TempFileManager>().cleanAll();

    runApp(const PrivacyVaultApp());
  }, (error, stack) {
    developer.log(
      'Uncaught error: $error',
      error: error,
      stackTrace: stack,
      name: 'PrivacyVault',
    );
  });
}
