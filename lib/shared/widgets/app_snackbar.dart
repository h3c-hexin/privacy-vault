import 'package:flutter/material.dart';
import 'package:privacy_vault/core/theme/app_colors.dart';

/// 带撤销操作的 SnackBar
///
/// 用于删除操作后提供撤销机会。
void showUndoSnackBar(
  BuildContext context, {
  required String message,
  required VoidCallback onUndo,
  Duration duration = const Duration(seconds: 5),
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration,
      action: SnackBarAction(
        label: '撤销',
        textColor: Theme.of(context).colorScheme.primary,
        onPressed: onUndo,
      ),
    ),
  );
}

/// 成功提示 SnackBar
void showSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppColors.successMain,
    ),
  );
}

/// 错误提示 SnackBar
void showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppColors.errorMain,
    ),
  );
}
