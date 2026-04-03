import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_vault/core/theme/app_colors.dart';
import 'package:privacy_vault/core/di/injection.dart';
import 'package:privacy_vault/core/database/app_database.dart';
import 'package:privacy_vault/features/vault/presentation/blocs/vault_bloc.dart';
import 'package:privacy_vault/features/vault/presentation/blocs/vault_event.dart';
import 'package:privacy_vault/features/vault/presentation/blocs/vault_state.dart';
import 'package:privacy_vault/shared/widgets/empty_state.dart';
import 'package:privacy_vault/core/security/screen_security_observer.dart';
import 'package:privacy_vault/shared/widgets/encrypted_thumbnail.dart';

/// 文件夹详情页 - 缩略图网格
class FolderDetailPage extends StatefulWidget {
  final String folderId;

  const FolderDetailPage({super.key, required this.folderId});

  @override
  State<FolderDetailPage> createState() => _FolderDetailPageState();
}

class _FolderDetailPageState extends State<FolderDetailPage> with ScreenSecureMixin {
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VaultBloc(database: getIt<AppDatabase>())
        ..add(VaultLoadFiles(widget.folderId)),
      child: BlocBuilder<VaultBloc, VaultState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: Text(_isSelectionMode
                  ? '已选择 ${_selectedIds.length} 项'
                  : '文件夹'),
              actions: [
                if (_isSelectionMode) ...[
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: _selectedIds.isEmpty
                        ? null
                        : () {
                            context.read<VaultBloc>().add(
                              VaultBatchDelete(
                                _selectedIds.toList(),
                                widget.folderId,
                              ),
                            );
                            setState(() {
                              _isSelectionMode = false;
                              _selectedIds.clear();
                            });
                          },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() {
                      _isSelectionMode = false;
                      _selectedIds.clear();
                    }),
                  ),
                ],
              ],
            ),
            body: state.files.isEmpty
                ? const EmptyState(
                    icon: Icons.photo_library_outlined,
                    title: '文件夹是空的',
                    subtitle: '点击右下角按钮导入文件',
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
                      final isSelected = _selectedIds.contains(file.id);
                      return GestureDetector(
                        onTap: () {
                          if (_isSelectionMode) {
                            setState(() {
                              isSelected
                                  ? _selectedIds.remove(file.id)
                                  : _selectedIds.add(file.id);
                            });
                          } else {
                            final route = file.fileType == 'video'
                                ? '/preview/video/${file.id}'
                                : '/preview/image/${file.id}';
                            context.push(route);
                          }
                        },
                        onLongPress: () {
                          HapticFeedback.mediumImpact();
                          setState(() {
                            _isSelectionMode = true;
                            _selectedIds.add(file.id);
                          });
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // 加密缩略图（异步解密 + LRU 缓存 + Hero 动画）
                            Hero(
                              tag: 'preview_${file.id}',
                              child: EncryptedThumbnail(
                                thumbnailPath: file.thumbnailPath,
                                encryptedDek: file.encryptedDek,
                                fileType: file.fileType,
                              ),
                            ),
                            // 视频时长角标
                            if (file.durationMs != null)
                              Positioned(
                                right: 4,
                                bottom: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Text(
                                    _formatDuration(file.durationMs!),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                            // 选中标记
                            if (_isSelectionMode)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.white24,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
            floatingActionButton: _isSelectionMode
                ? null
                : FloatingActionButton(
                    onPressed: () async {
                      final result = await context.push<bool>(
                        '/import/${widget.folderId}',
                      );
                      if (result == true && context.mounted) {
                        context.read<VaultBloc>().add(
                          VaultLoadFiles(widget.folderId),
                        );
                      }
                    },
                    child: const Icon(Icons.add),
                  ),
          );
        },
      ),
    );
  }

  String _formatDuration(int ms) {
    final seconds = ms ~/ 1000;
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
