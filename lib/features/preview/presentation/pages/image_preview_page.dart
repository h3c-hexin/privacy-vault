import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:privacy_vault/core/theme/app_colors.dart';
import 'package:privacy_vault/features/preview/presentation/blocs/preview_bloc.dart';
import 'package:privacy_vault/features/preview/presentation/blocs/preview_event.dart';
import 'package:privacy_vault/features/preview/presentation/blocs/preview_state.dart';
import 'package:privacy_vault/core/security/screen_security_observer.dart';
import 'package:privacy_vault/features/preview/presentation/widgets/preview_bottom_bar.dart';

/// 图片预览页
///
/// 全屏展示解密后的图片，支持双指缩放、双击放大、左右滑动切换、下滑关闭。
class ImagePreviewPage extends StatefulWidget {
  const ImagePreviewPage({super.key});

  @override
  State<ImagePreviewPage> createState() => _ImagePreviewPageState();
}

class _ImagePreviewPageState extends State<ImagePreviewPage> with ScreenSecureMixin {
  late PageController _pageController;
  bool _showUI = true;
  bool _initialJumpDone = false;

  @override
  void initState() {
    super.initState();
    // 初始 page=0，加载完成后通过 BlocListener 跳转到正确位置
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PreviewBloc, PreviewState>(
      listener: (context, state) {
        // 首次加载完成后，延迟到帧渲染完成再跳转
        if (state.status == PreviewStatus.loaded && !_initialJumpDone) {
          _initialJumpDone = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_pageController.hasClients &&
                _pageController.page?.round() != state.currentIndex) {
              _pageController.jumpToPage(state.currentIndex);
            }
          });
        }
        // 导出/分享成功提示
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.successMessage!)),
          );
        }
        // 错误提示
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.errorMain,
            ),
          );
        }
        // 删除后列表为空，关闭预览页
        if (state.status == PreviewStatus.initial && state.fileList.isEmpty) {
          Navigator.of(context).pop(true);
        }
      },
      builder: (context, state) {
        if (state.status == PreviewStatus.loading && state.decryptedBytes == null) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.status == PreviewStatus.error) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(backgroundColor: Colors.transparent),
            body: Center(
              child: Text(
                state.errorMessage ?? '加载失败',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.black,
          extendBodyBehindAppBar: true,
          extendBody: true,
          appBar: _showUI
              ? AppBar(
                  backgroundColor: Colors.black54,
                  foregroundColor: Colors.white,
                  title: Text(
                    state.currentFile?.originalName ?? '',
                    style: const TextStyle(fontSize: 14),
                  ),
                  actions: [
                    Text(
                      '${state.currentIndex + 1}/${state.fileList.length}',
                      style: const TextStyle(color: AppColors.neutral400),
                    ),
                    const SizedBox(width: 16),
                  ],
                )
              : null,
          body: Stack(
            children: [
              // 图片区域占满全屏，不受顶部/底部栏影响
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _showUI = !_showUI),
                  onVerticalDragEnd: (details) {
                    if (details.primaryVelocity != null &&
                        details.primaryVelocity! > 300) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: state.fileList.length,
                    onPageChanged: (index) {
                      final bloc = context.read<PreviewBloc>();
                      if (index != bloc.state.currentIndex) {
                        bloc.add(PreviewGoToIndex(index));
                      }
                    },
                    itemBuilder: (context, index) {
                      // 当前页显示 state 中的解密数据
                      if (index == state.currentIndex &&
                          state.decryptedBytes != null) {
                        return InteractiveViewer(
                          minScale: 0.5,
                          maxScale: 4.0,
                          child: Center(
                            child: Hero(
                              tag: 'preview_${state.currentFile?.id}',
                              child: Image.memory(
                                state.decryptedBytes!,
                                fit: BoxFit.contain,
                                cacheWidth:
                                    MediaQuery.of(context).size.width.toInt() * 2,
                              ),
                            ),
                          ),
                        );
                      }
                      // 相邻页尝试从 BLoC 内部缓存读取（预加载）
                      if (index < state.fileList.length) {
                        final file = state.fileList[index];
                        final bloc = context.read<PreviewBloc>();
                        final cached = bloc.getCachedImage(file.id);
                        if (cached != null) {
                          return InteractiveViewer(
                            minScale: 0.5,
                            maxScale: 4.0,
                            child: Center(
                              child: Hero(
                                tag: 'preview_${file.id}',
                                child: Image.memory(
                                  cached,
                                  fit: BoxFit.contain,
                                  cacheWidth:
                                      MediaQuery.of(context).size.width.toInt() * 2,
                                ),
                              ),
                            ),
                          );
                        }
                      }
                      return const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary500),
                      );
                    },
                  ),
                ),
              ),
              // 底部操作栏覆盖在图片之上，不影响图片布局
              if (_showUI)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: PreviewBottomBar(
                    onShare: () =>
                        context.read<PreviewBloc>().add(PreviewShareFile()),
                    onExport: () =>
                        context.read<PreviewBloc>().add(PreviewExportFile()),
                    onDelete: () => _confirmDelete(context),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除文件'),
        content: const Text('文件将移入回收站，30 天后自动清理。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<PreviewBloc>().add(PreviewDeleteFile());
            },
            child: Text('删除', style: TextStyle(color: AppColors.errorMain)),
          ),
        ],
      ),
    );
  }
}
