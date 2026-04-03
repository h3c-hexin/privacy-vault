import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_vault/core/database/app_database.dart';
import 'package:privacy_vault/core/di/injection.dart';
import 'package:privacy_vault/core/security/session_manager.dart';
import 'package:privacy_vault/core/theme/app_typography.dart';
import 'package:privacy_vault/core/theme/app_spacing.dart';
import 'package:privacy_vault/features/settings/presentation/blocs/settings_bloc.dart';
import 'package:privacy_vault/features/settings/presentation/blocs/settings_event.dart';
import 'package:privacy_vault/features/settings/presentation/blocs/settings_state.dart';

/// 设置页（入口）
///
/// 使用 BlocProvider 创建 SettingsBloc 并在页面销毁时自动关闭，
/// 所有数据操作均在 BLoC 中进行，页面本身只负责展示与派发事件。
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SettingsBloc(
        database: getIt<AppDatabase>(),
        sessionManager: getIt<SessionManager>(),
      )..add(SettingsLoad()),
      child: const _SettingsView(),
    );
  }
}

/// 设置页内容视图（纯展示层）
class _SettingsView extends StatelessWidget {
  const _SettingsView();

  /// 将秒数转为可读标签
  String _autoLockLabel(int seconds) {
    if (seconds == 0) return '立即锁定';
    if (seconds < 60) return '离开 $seconds 秒后';
    return '离开 ${seconds ~/ 60} 分钟后';
  }

  /// 字节数格式化显示
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// 弹出自动锁定时间选择对话框，选中后派发事件
  Future<void> _showAutoLockPicker(
    BuildContext context,
    int currentSeconds,
  ) async {
    const options = [
      (0, '立即锁定'),
      (30, '30 秒'),
      (60, '1 分钟'),
      (300, '5 分钟'),
      (600, '10 分钟'),
    ];

    final selected = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('自动锁定时间'),
        children: options.map((opt) {
          final (seconds, label) = opt;
          return RadioListTile<int>(
            title: Text(label),
            value: seconds,
            groupValue: currentSeconds,
            onChanged: (v) => Navigator.of(ctx).pop(v),
          );
        }).toList(),
      ),
    );

    if (selected != null && context.mounted) {
      context.read<SettingsBloc>().add(SettingsChangeAutoLock(selected));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          // 加载中显示进度条
          if (state.status == SettingsStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final storageSub = '已用 ${_formatBytes(state.usedBytes)}'
              '${state.availableBytes > 0 ? ' / 可用 ${_formatBytes(state.availableBytes)}' : ''}';

          return ListView(
            children: [
              const SizedBox(height: AppSpacing.md),
              _SectionHeader(title: '安全'),
              _SettingsTile(
                icon: Icons.lock_outline,
                title: '修改密码',
                onTap: () => context.push('/settings/password'),
              ),
              _SettingsTile(
                icon: Icons.timer_outlined,
                title: '自动锁定时间',
                subtitle: _autoLockLabel(state.autoLockSeconds),
                onTap: () => _showAutoLockPicker(
                  context,
                  state.autoLockSeconds,
                ),
              ),
              const Divider(height: 32),
              _SectionHeader(title: '存储'),
              _SettingsTile(
                icon: Icons.storage_outlined,
                title: '存储空间',
                subtitle: storageSub,
              ),
              _SettingsTile(
                icon: Icons.delete_sweep_outlined,
                title: '回收站',
                onTap: () => context.push('/trash'),
              ),
              const Divider(height: 32),
              _SectionHeader(title: '其他'),
              _SettingsTile(
                icon: Icons.favorite_outline,
                title: '支持开发者',
                onTap: () => context.push('/settings/donate'),
              ),
              _SettingsTile(
                icon: Icons.info_outline,
                title: '关于',
                onTap: () => context.push('/settings/about'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Text(
        title,
        style: AppTypography.bodySm.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: cs.onSurfaceVariant),
      title: Text(title, style: TextStyle(color: cs.onSurface)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: TextStyle(color: cs.outline))
          : null,
      trailing: trailing ??
          (onTap != null
              ? Icon(Icons.chevron_right, color: cs.outline)
              : null),
      onTap: onTap,
    );
  }
}
