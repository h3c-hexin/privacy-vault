import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:privacy_vault/core/security/screen_security_observer.dart';
import 'package:privacy_vault/core/theme/app_colors.dart';
import 'package:privacy_vault/core/theme/app_typography.dart';
import 'package:privacy_vault/core/theme/app_spacing.dart';
import 'package:privacy_vault/features/trash/presentation/blocs/trash_bloc.dart';
import 'package:privacy_vault/features/trash/presentation/blocs/trash_event.dart';
import 'package:privacy_vault/features/trash/presentation/blocs/trash_state.dart';
import 'package:privacy_vault/core/database/app_database.dart';
import 'package:privacy_vault/shared/widgets/empty_state.dart';
import 'package:privacy_vault/shared/widgets/encrypted_thumbnail.dart';

/// 回收站页面
///
/// 缩略图网格布局，点击弹出操作面板（恢复/删除）。
class TrashPage extends StatefulWidget {
  const TrashPage({super.key});

  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage> with ScreenSecureMixin {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TrashBloc, TrashState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text('回收站 (${state.files.length})'),
            actions: [
              if (state.files.isNotEmpty)
                TextButton(
                  onPressed: () => _confirmEmptyAll(context),
                  child: Text(
                    '清空',
                    style: TextStyle(color: AppColors.errorMain),
                  ),
                ),
            ],
          ),
          body: state.files.isEmpty
              ? const EmptyState(
                  icon: Icons.delete_outline,
                  title: '回收站是空的',
                  subtitle: '删除的文件将在此保留 30 天',
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(2),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                  ),
                  itemCount: state.files.length,
                  itemBuilder: (context, index) {
                    final file = state.files[index];
                    return _TrashGridItem(
                      file: file,
                      onTap: () => _showActions(context, file),
                    );
                  },
                ),
        );
      },
    );
  }

  void _showActions(BuildContext context, VaultFile file) {
    final cs = Theme.of(context).colorScheme;
    final daysLeft = _daysUntilExpiry(file.deletedAt);
    final daysText = daysLeft > 0 ? '$daysLeft 天后自动删除' : '即将自动删除';

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 文件信息头
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  // 小缩略图
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: EncryptedThumbnail(
                        thumbnailPath: file.thumbnailPath,
                        encryptedDek: file.encryptedDek,
                        fileType: file.fileType,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.originalName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          daysText,
                          style: AppTypography.bodySm
                              .copyWith(color: cs.outline),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.restore, color: cs.primary),
              title: const Text('恢复文件'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                context.read<TrashBloc>().add(TrashRestoreFile(file.id));
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(
                    const SnackBar(content: Text('文件已恢复')),
                  );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_forever, color: AppColors.errorMain),
              title: Text('彻底删除',
                  style: TextStyle(color: AppColors.errorMain)),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _confirmDelete(context, file);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, VaultFile file) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('彻底删除'),
        content: const Text('此操作不可撤销，文件将被永久删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<TrashBloc>().add(TrashPermanentDelete(file.id));
            },
            child: Text('删除', style: TextStyle(color: AppColors.errorMain)),
          ),
        ],
      ),
    );
  }

  void _confirmEmptyAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('清空回收站'),
        content: const Text('所有文件将被永久删除，此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<TrashBloc>().add(TrashEmptyAll());
            },
            child: Text('清空', style: TextStyle(color: AppColors.errorMain)),
          ),
        ],
      ),
    );
  }

  int _daysUntilExpiry(int? deletedAtMs) {
    if (deletedAtMs == null) return 30;
    final deletedAt = DateTime.fromMillisecondsSinceEpoch(deletedAtMs);
    final expiryDate = deletedAt.add(const Duration(days: 30));
    return expiryDate.difference(DateTime.now()).inDays;
  }
}

/// 回收站缩略图网格项
class _TrashGridItem extends StatelessWidget {
  final VaultFile file;
  final VoidCallback onTap;

  const _TrashGridItem({required this.file, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final daysLeft = _daysUntilExpiry(file.deletedAt);

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 缩略图
          EncryptedThumbnail(
            thumbnailPath: file.thumbnailPath,
            encryptedDek: file.encryptedDek,
            fileType: file.fileType,
          ),
          // 剩余天数角标（左下角）
          Positioned(
            left: 4,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                daysLeft > 0 ? '${daysLeft}天' : '即将删除',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
          // 视频标识（右下角）
          if (file.fileType == 'video')
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.videocam,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  int _daysUntilExpiry(int? deletedAtMs) {
    if (deletedAtMs == null) return 30;
    final deletedAt = DateTime.fromMillisecondsSinceEpoch(deletedAtMs);
    final expiryDate = deletedAt.add(const Duration(days: 30));
    return expiryDate.difference(DateTime.now()).inDays;
  }
}
