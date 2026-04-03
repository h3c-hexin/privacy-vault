import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:privacy_vault/core/theme/app_colors.dart';
import 'package:privacy_vault/core/theme/app_typography.dart';
import 'package:privacy_vault/core/theme/app_spacing.dart';

/// 支持开发者页面
class DonatePage extends StatelessWidget {
  const DonatePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('支持开发者')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.favorite,
                color: AppColors.errorMain,
                size: 64,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '感谢你的支持！',
                style: AppTypography.h2.copyWith(color: cs.onSurface),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '如果这个 App 对你有帮助，\n可以请开发者喝杯咖啡',
                style: AppTypography.bodyMd.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/zanshangma.png',
                  width: 240,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: () => _saveToGallery(context),
                icon: const Icon(Icons.save_alt),
                label: const Text('保存赞赏码到相册'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveToGallery(BuildContext context) async {
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('需要相册权限才能保存')),
            );
          }
          return;
        }
      }

      // 从 assets 复制到临时文件，再保存到相册
      final bytes = await rootBundle.load('assets/images/zanshangma.png');
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(p.join(tempDir.path, 'zanshangma.png'));
      await tempFile.writeAsBytes(bytes.buffer.asUint8List());
      await Gal.putImage(tempFile.path);
      await tempFile.delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('已保存到相册'),
            backgroundColor: AppColors.successMain,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存失败')),
        );
      }
    }
  }
}
