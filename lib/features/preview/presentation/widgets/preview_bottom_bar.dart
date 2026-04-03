import 'package:flutter/material.dart';
import 'package:privacy_vault/core/theme/app_colors.dart';

/// 预览页底部操作栏
///
/// 提供分享、导出、删除操作按钮。
class PreviewBottomBar extends StatelessWidget {
  final VoidCallback onShare;
  final VoidCallback onExport;
  final VoidCallback onDelete;

  const PreviewBottomBar({
    super.key,
    required this.onShare,
    required this.onExport,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ActionButton(
              icon: Icons.share_outlined,
              label: '分享',
              onTap: onShare,
            ),
            _ActionButton(
              icon: Icons.download_outlined,
              label: '导出',
              onTap: onExport,
            ),
            _ActionButton(
              icon: Icons.delete_outline,
              label: '删除',
              onTap: onDelete,
              color: AppColors.errorMain,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
