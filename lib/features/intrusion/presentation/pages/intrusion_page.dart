import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:privacy_vault/core/theme/app_colors.dart';
import 'package:privacy_vault/core/theme/app_typography.dart';
import 'package:privacy_vault/core/theme/app_spacing.dart';
import 'package:privacy_vault/features/intrusion/presentation/blocs/intrusion_bloc.dart';
import 'package:privacy_vault/features/intrusion/presentation/blocs/intrusion_event.dart';
import 'package:privacy_vault/features/intrusion/presentation/blocs/intrusion_state.dart';
import 'package:privacy_vault/core/database/app_database.dart';
import 'package:privacy_vault/shared/widgets/empty_state.dart';
import 'package:intl/intl.dart';

/// 入侵记录页面
class IntrusionPage extends StatelessWidget {
  const IntrusionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IntrusionBloc, IntrusionState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('入侵记录'),
            actions: [
              if (state.records.isNotEmpty)
                TextButton(
                  onPressed: () => _confirmClearAll(context),
                  child: Text(
                    '清空',
                    style: TextStyle(color: AppColors.errorMain),
                  ),
                ),
            ],
          ),
          body: state.records.isEmpty
              ? const EmptyState(
                  icon: Icons.shield_outlined,
                  title: '暂无入侵记录',
                  subtitle: '密码输错时将自动拍照记录',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: state.records.length,
                  itemBuilder: (context, index) {
                    final record = state.records[index];
                    return _IntrusionRecordItem(
                      record: record,
                      onDelete: () {
                        context.read<IntrusionBloc>().add(
                          IntrusionDeleteRecord(record.id),
                        );
                      },
                    );
                  },
                ),
        );
      },
    );
  }

  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('清空所有记录'),
        content: const Text('此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<IntrusionBloc>().add(IntrusionClearAll());
            },
            child: Text('清空', style: TextStyle(color: AppColors.errorMain)),
          ),
        ],
      ),
    );
  }
}

/// 入侵记录项
class _IntrusionRecordItem extends StatelessWidget {
  final IntrusionRecord record;
  final VoidCallback onDelete;

  const _IntrusionRecordItem({
    required this.record,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final time = DateTime.fromMillisecondsSinceEpoch(record.timestamp);
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');

    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.person_outline,
            color: cs.onSurfaceVariant,
          ),
        ),
        title: Text(
          '尝试 ${record.attemptCount} 次',
          style: TextStyle(color: cs.onSurface),
        ),
        subtitle: Text(
          formatter.format(time),
          style: AppTypography.bodySm.copyWith(color: cs.outline),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: AppColors.errorMain),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
