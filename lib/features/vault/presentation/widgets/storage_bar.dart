import 'package:flutter/material.dart';
import 'package:privacy_vault/core/theme/app_colors.dart';
import 'package:privacy_vault/core/theme/app_typography.dart';
import 'package:privacy_vault/core/theme/app_spacing.dart';
import 'package:privacy_vault/core/theme/app_radius.dart';

/// 存储用量条
class StorageBar extends StatelessWidget {
  final int usedBytes;
  final int totalBytes;

  const StorageBar({
    super.key,
    required this.usedBytes,
    required this.totalBytes,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ratio = totalBytes > 0 ? (usedBytes / totalBytes).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: AppRadius.borderFull,
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 4,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(cs.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '已用 ${_formatBytes(usedBytes)}',
                style: AppTypography.bodySm.copyWith(color: cs.onSurfaceVariant),
              ),
              Text(
                '共 ${_formatBytes(totalBytes)}',
                style: AppTypography.bodySm.copyWith(color: cs.outline),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
