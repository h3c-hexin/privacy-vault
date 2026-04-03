import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_app.dart' as app;

/// 隐私保险箱 E2E 集成测试
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('首次启动流程', () {
    testWidgets('新手引导页正确显示并完成 PIN 设置', (tester) async {
      await app.testMain();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 步骤 1: 欢迎页
      expect(find.textContaining('欢迎'), findsOneWidget);
      expect(find.textContaining('开始设置'), findsOneWidget);

      await tester.tap(find.text('开始设置'));
      await tester.pumpAndSettle();

      // 步骤 2: PIN 设置
      expect(find.textContaining('设置密码'), findsOneWidget);

      // 输入 PIN: 1234
      for (final digit in ['1', '2', '3', '4']) {
        await tester.tap(find.text(digit).last);
        await tester.pump(const Duration(milliseconds: 150));
      }
      await tester.pumpAndSettle();

      // 确认 PIN
      expect(find.textContaining('再次输入'), findsOneWidget);

      for (final digit in ['1', '2', '3', '4']) {
        await tester.tap(find.text(digit).last);
        await tester.pump(const Duration(milliseconds: 150));
      }
      await tester.pumpAndSettle();

      // 步骤 3: 安全提示页
      expect(find.textContaining('安全提示'), findsOneWidget);

      await tester.tap(find.text('我已了解'));
      await tester.pumpAndSettle();

      // 步骤 4: 使用引导页
      expect(find.textContaining('如何进入'), findsOneWidget);

      await tester.tap(find.text('开始使用'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 应跳转到主页
      expect(find.textContaining('隐私保险箱'), findsOneWidget);
    });
  });
}
