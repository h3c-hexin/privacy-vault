import 'package:flutter/material.dart';
import 'package:privacy_vault/core/theme/app_colors.dart';
import 'package:privacy_vault/core/theme/app_radius.dart';

/// 骨架屏加载占位
class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: _animation.value),
            borderRadius: widget.borderRadius ?? AppRadius.borderSm,
          ),
        );
      },
    );
  }
}

/// 文件夹卡片骨架屏
class FolderCardSkeleton extends StatelessWidget {
  const FolderCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonBox(
          width: double.infinity,
          height: 100,
          borderRadius: AppRadius.borderMd,
        ),
        const SizedBox(height: 8),
        const SkeletonBox(width: 80, height: 14),
        const SizedBox(height: 4),
        const SkeletonBox(width: 50, height: 12),
      ],
    );
  }
}

/// 缩略图网格骨架屏
class ThumbnailGridSkeleton extends StatelessWidget {
  final int count;

  const ThumbnailGridSkeleton({super.key, this.count = 9});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: count,
      itemBuilder: (context, index) => SkeletonBox(
        width: double.infinity,
        height: double.infinity,
        borderRadius: BorderRadius.circular(0),
      ),
    );
  }
}
