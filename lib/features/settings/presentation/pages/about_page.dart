import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_vault/core/theme/app_colors.dart';
import 'package:privacy_vault/core/theme/app_typography.dart';
import 'package:privacy_vault/core/theme/app_spacing.dart';

/// 关于页面
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('关于')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.gradientCardFor(Theme.of(context).brightness),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.calculate_outlined,
                size: 40,
                color: cs.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Text(
              '隐私保险箱',
              style: AppTypography.h2.copyWith(color: cs.onSurface),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: Text(
              'V1.0.0',
              style: AppTypography.bodySm.copyWith(color: cs.outline),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const _InfoCard(
            title: '安全特性',
            items: [
              'AES-256-GCM 军事级加密',
              'Android Keystore 硬件保护',
              '计算器伪装入口',
              '防截屏保护',
              '入侵检测拍照',
              '30 天回收站自动清理',
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const _InfoCard(
            title: '隐私声明',
            items: [
              '所有数据仅存储在本地设备',
              '不收集任何用户信息',
              '不联网，不上传任何数据',
              '加密密钥由用户 PIN 派生',
              '卸载 App 将永久删除所有数据',
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          ListTile(
            title: Text('隐私政策', style: TextStyle(color: cs.onSurface)),
            trailing: Icon(Icons.chevron_right, color: cs.outline),
            onTap: () => context.push('/settings/privacy-policy'),
          ),
          ListTile(
            title: Text('用户协议', style: TextStyle(color: cs.onSurface)),
            trailing: Icon(Icons.chevron_right, color: cs.outline),
            onTap: () => context.push('/settings/user-agreement'),
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Text(
              '© 2026 Privacy Vault',
              style: AppTypography.caption.copyWith(color: cs.outlineVariant),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<String> items;

  const _InfoCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.gradientCardFor(Theme.of(context).brightness),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.bodyLg.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 16, color: AppColors.successMain),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        item,
                        style: AppTypography.bodySm.copyWith(
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
