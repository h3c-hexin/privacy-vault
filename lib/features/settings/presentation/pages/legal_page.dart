import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:privacy_vault/core/theme/app_spacing.dart';

/// 法律文档展示页（隐私政策 / 用户协议）
///
/// 从 assets 加载 Markdown 文本并以纯文本方式展示。
/// 不引入 Markdown 渲染库，保持轻量。
class LegalPage extends StatelessWidget {
  final String title;
  final String assetPath;

  const LegalPage({
    super.key,
    required this.title,
    required this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<String>(
        future: rootBundle.loadString(assetPath),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                '加载失败',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              _stripMarkdown(snapshot.data ?? ''),
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          );
        },
      ),
    );
  }

  /// 去除 Markdown 标记，转为纯文本展示
  String _stripMarkdown(String md) {
    // 表格行转为可读文本：去掉 | 分隔符，移除对齐行（---）
    final noTableSep = md.replaceAll(
      RegExp(r'^\|[-:\s|]+\|$', multiLine: true), // 表格分隔行
      '',
    );
    final tableToText = noTableSep.replaceAllMapped(
      RegExp(r'^\|(.+)\|$', multiLine: true),
      (m) => m[1]!.split('|').map((c) => c.trim()).where((c) => c.isNotEmpty).join('  ·  '),
    );
    return tableToText
        .replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '') // 标题
        .replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => m[1]!) // 加粗
        .replaceAllMapped(RegExp(r'\*(.+?)\*'), (m) => m[1]!) // 斜体
        .replaceAll(RegExp(r'^-\s+', multiLine: true), '• ') // 列表
        .replaceAll(RegExp(r'^>\s+', multiLine: true), '  ') // 引用
        .replaceAll(RegExp(r'---+'), '') // 分隔线
        .replaceAll(RegExp(r'\n{3,}'), '\n\n') // 多余空行
        .trim();
  }
}
