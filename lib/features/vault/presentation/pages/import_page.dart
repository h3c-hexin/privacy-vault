import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_vault/core/theme/app_colors.dart';
import 'package:privacy_vault/core/theme/app_spacing.dart';
import 'package:privacy_vault/core/theme/app_typography.dart';
import 'package:privacy_vault/features/vault/presentation/blocs/import_bloc.dart';
import 'package:privacy_vault/features/vault/presentation/blocs/import_event.dart';
import 'package:privacy_vault/features/vault/presentation/blocs/import_state.dart';

/// 文件导入页
///
/// 提供文件来源选择、导入进度展示。
/// 从 FolderDetailPage 的 FAB 导航进入。
class ImportPage extends StatefulWidget {
  final String folderId;

  const ImportPage({super.key, required this.folderId});

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  bool _deleteSource = false;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ImportBloc, ImportState>(
      listener: (context, state) {
        if (state.status == ImportStatus.completed) {
          // 导入完成，返回上一页
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '导入完成：${state.completedCount} 成功'
                '${state.failedCount > 0 ? '，${state.failedCount} 失败' : ''}',
              ),
              backgroundColor:
                  state.failedCount > 0 ? AppColors.warningMain : AppColors.successMain,
            ),
          );
          context.pop(true); // 返回并通知刷新
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('导入文件'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: state.status == ImportStatus.importing
                  ? null
                  : () => context.pop(false),
            ),
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ImportState state) {
    switch (state.status) {
      case ImportStatus.initial:
      case ImportStatus.picking:
        return _buildSourceSelection(context, state);
      case ImportStatus.picked:
        return _buildFilePreview(context, state);
      case ImportStatus.importing:
        return _buildProgress(context, state);
      case ImportStatus.completed:
        return const Center(child: CircularProgressIndicator());
      case ImportStatus.error:
        return _buildError(context, state);
    }
  }

  /// 来源选择界面
  Widget _buildSourceSelection(BuildContext context, ImportState state) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '选择导入来源',
            style: AppTypography.h3.copyWith(color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SourceTile(
            icon: Icons.photo_library_outlined,
            title: '图片和视频',
            subtitle: '从设备中选择图片和视频文件',
            loading: state.status == ImportStatus.picking,
            onTap: () {
              context.read<ImportBloc>().add(
                const ImportPickFiles(fileType: 'all'),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _SourceTile(
            icon: Icons.image_outlined,
            title: '仅图片',
            subtitle: '从设备中选择图片',
            loading: state.status == ImportStatus.picking,
            onTap: () {
              context.read<ImportBloc>().add(
                const ImportPickFiles(fileType: 'image'),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _SourceTile(
            icon: Icons.videocam_outlined,
            title: '仅视频',
            subtitle: '从设备中选择视频',
            loading: state.status == ImportStatus.picking,
            onTap: () {
              context.read<ImportBloc>().add(
                const ImportPickFiles(fileType: 'video'),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 已选文件预览
  Widget _buildFilePreview(BuildContext context, ImportState state) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: state.selectedFiles.length,
            itemBuilder: (context, index) {
              final file = state.selectedFiles[index];
              final cs = Theme.of(context).colorScheme;
              return ListTile(
                leading: Icon(
                  file.fileType == 'video'
                      ? Icons.videocam_outlined
                      : Icons.image_outlined,
                  color: cs.primary,
                ),
                title: Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: cs.onSurface),
                ),
                subtitle: Text(
                  _formatBytes(file.size),
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              );
            },
          ),
        ),
        // 提示：导入完成后手动删除
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  '加密导入后，请自行前往相册删除原文件',
                  style: AppTypography.bodySm.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        // 底部操作栏
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      context.read<ImportBloc>().add(ImportReset());
                    },
                    child: const Text('重新选择'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () {
                      context.read<ImportBloc>().add(ImportStartImport(
                        files: state.selectedFiles,
                        folderId: widget.folderId,
                        deleteSource: false,
                      ));
                    },
                    child: Text('导入 ${state.selectedFiles.length} 个文件'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 导入进度
  Widget _buildProgress(BuildContext context, ImportState state) {
    return SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: state.progress,
                  strokeWidth: 6,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor:
                      AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
                ),
                Center(
                  child: Text(
                    '${(state.progress * 100).toInt()}%',
                    style: AppTypography.h2.copyWith(color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            '正在加密导入...',
            style: AppTypography.bodyLg.copyWith(color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${state.completedCount} / ${state.totalCount}',
            style: AppTypography.bodySm.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          if (state.failedCount > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${state.failedCount} 个文件导入失败',
              style: AppTypography.bodySm.copyWith(color: AppColors.errorMain),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          TextButton(
            onPressed: () {
              context.read<ImportBloc>().add(ImportCancel());
            },
            child: Text(
              '取消',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          ],
        ),
      ),
    );
  }

  /// 错误状态
  Widget _buildError(BuildContext context, ImportState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.errorMain),
            const SizedBox(height: AppSpacing.md),
            Text(
              state.errorMessage ?? '导入失败',
              style: AppTypography.bodyMd.copyWith(color: Theme.of(context).colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () {
                context.read<ImportBloc>().add(ImportReset());
              },
              child: const Text('重试'),
            ),
          ],
        ),
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

/// 来源选择卡片
class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool loading;
  final VoidCallback onTap;

  const _SourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.loading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: AppColors.gradientCardFor(Theme.of(context).brightness),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: cs.primary, size: 32),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyLg.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySm.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (loading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(Icons.chevron_right, color: cs.outline),
          ],
        ),
      ),
    );
  }
}
