import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:privacy_vault/core/theme/app_colors.dart';
import 'package:privacy_vault/features/preview/presentation/blocs/preview_bloc.dart';
import 'package:privacy_vault/features/preview/presentation/blocs/preview_event.dart';
import 'package:privacy_vault/features/preview/presentation/blocs/preview_state.dart';
import 'package:privacy_vault/core/security/screen_security_observer.dart';
import 'package:privacy_vault/features/preview/presentation/widgets/preview_bottom_bar.dart';

/// 视频播放页
///
/// 使用 media_kit 播放解密到临时目录的视频文件。
class VideoPlayerPage extends StatefulWidget {
  const VideoPlayerPage({super.key});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> with ScreenSecureMixin {
  late final Player _player;
  late final VideoController _videoController;
  bool _showUI = true;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _videoController = VideoController(_player);

    // 加载视频
    final bloc = context.read<PreviewBloc>();
    if (bloc.state.tempFilePath != null) {
      _player.open(Media(bloc.state.tempFilePath!));
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PreviewBloc, PreviewState>(
      listenWhen: (prev, curr) => prev.tempFilePath != curr.tempFilePath,
      listener: (context, state) {
        if (state.tempFilePath != null) {
          _player.open(Media(state.tempFilePath!));
        }
      },
      builder: (context, state) {
        if (state.status == PreviewStatus.loading) {
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
          appBar: _showUI
              ? AppBar(
                  backgroundColor: Colors.black54,
                  foregroundColor: Colors.white,
                  title: Text(
                    state.currentFile?.originalName ?? '',
                    style: const TextStyle(fontSize: 14),
                  ),
                )
              : null,
          body: GestureDetector(
            onTap: () => setState(() => _showUI = !_showUI),
            child: Center(
              child: Video(
                controller: _videoController,
                controls: MaterialVideoControls,
              ),
            ),
          ),
          bottomNavigationBar: _showUI
              ? PreviewBottomBar(
                  onShare: () =>
                      context.read<PreviewBloc>().add(PreviewShareFile()),
                  onExport: () =>
                      context.read<PreviewBloc>().add(PreviewExportFile()),
                  onDelete: () => _confirmDelete(context),
                )
              : null,
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
              _player.stop();
              context.read<PreviewBloc>().add(PreviewDeleteFile());
              if (context.read<PreviewBloc>().state.fileList.length <= 1) {
                Navigator.of(context).pop(true);
              }
            },
            child: Text('删除', style: TextStyle(color: AppColors.errorMain)),
          ),
        ],
      ),
    );
  }
}
