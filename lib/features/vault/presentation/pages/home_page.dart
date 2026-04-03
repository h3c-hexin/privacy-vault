import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_vault/core/theme/app_colors.dart';
import 'package:privacy_vault/core/theme/app_spacing.dart';
import 'package:privacy_vault/core/di/injection.dart';
import 'package:privacy_vault/core/database/app_database.dart';
import 'package:privacy_vault/features/vault/presentation/blocs/vault_bloc.dart';
import 'package:privacy_vault/features/vault/presentation/blocs/vault_event.dart';
import 'package:privacy_vault/features/vault/presentation/blocs/vault_state.dart';
import 'package:privacy_vault/features/vault/presentation/widgets/folder_card.dart';
import 'package:privacy_vault/shared/widgets/empty_state.dart';

/// 主页 - 文件夹总览
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VaultBloc(database: getIt<AppDatabase>())
        ..add(VaultLoadFolders()),
      child: const _HomePageBody(),
    );
  }
}

class _HomePageBody extends StatelessWidget {
  const _HomePageBody();

  @override
  Widget build(BuildContext context) {
    return BlocListener<VaultBloc, VaultState>(
      listenWhen: (prev, curr) => curr.errorMessage != null && curr.errorMessage != prev.errorMessage,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.errorMessage!),
            backgroundColor: AppColors.errorMain,
          ),
        );
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('隐私保险箱'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await context.push('/trash');
              if (context.mounted) {
                context.read<VaultBloc>().add(VaultLoadFolders());
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: BlocBuilder<VaultBloc, VaultState>(
        builder: (context, state) {
          if (state.status == VaultStatus.loading && state.folders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.folders.isEmpty) {
            return const EmptyState(
              icon: Icons.folder_outlined,
              title: '还没有文件夹',
              subtitle: '点击右下角按钮创建一个文件夹开始保护你的文件',
            );
          }

          return Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: state.folders.length,
                    itemBuilder: (context, index) {
                      final folder = state.folders[index];
                      return FolderCard(
                        folder: folder,
                        fileCount: state.folderFileCounts[folder.id] ?? 0,
                        onTap: () async {
                          await context.push('/folder/${folder.id}');
                          // 从文件夹详情返回后刷新计数
                          if (context.mounted) {
                            context.read<VaultBloc>().add(VaultLoadFolders());
                          }
                        },
                        onLongPress: () => _showFolderOptions(context, folder),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateFolderDialog(context),
        child: const Icon(Icons.add),
      ),
    ),
    );
  }

  void _showCreateFolderDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('新建文件夹'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '文件夹名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                context.read<VaultBloc>().add(VaultCreateFolder(name));
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _showFolderOptions(BuildContext context, VaultFolder folder) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('重命名'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _showRenameFolderDialog(context, folder);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.errorMain),
              title: Text('删除', style: TextStyle(color: AppColors.errorMain)),
              onTap: () {
                Navigator.of(sheetContext).pop();
                context.read<VaultBloc>().add(VaultDeleteFolder(folder.id));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameFolderDialog(BuildContext context, VaultFolder folder) {
    final controller = TextEditingController(text: folder.name);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('重命名文件夹'),
        content: TextField(
          controller: controller,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                context.read<VaultBloc>().add(VaultRenameFolder(folder.id, name));
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }
}
