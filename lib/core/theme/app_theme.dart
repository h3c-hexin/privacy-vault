import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_radius.dart';

/// 隐私保险箱主题配置
class AppTheme {
  AppTheme._();

  // ============================================================
  // 深色主题（默认）
  // ============================================================
  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    fontFamily: 'Roboto',

    // 色彩
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary500,
      onPrimary: AppColors.neutral0,
      primaryContainer: AppColors.primary800,
      onPrimaryContainer: AppColors.primary100,
      secondary: AppColors.primary300,
      onSecondary: AppColors.neutral900,
      surface: AppColors.neutral900,
      onSurface: AppColors.neutral200,
      onSurfaceVariant: AppColors.neutral400,
      surfaceContainerHighest: AppColors.neutral800,
      surfaceContainer: AppColors.neutral700,
      error: AppColors.errorMain,
      onError: AppColors.neutral0,
      outline: AppColors.neutral500,
      outlineVariant: AppColors.neutral600,
    ),

    // 脚手架
    scaffoldBackgroundColor: AppColors.neutral900,

    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.neutral900,
      foregroundColor: AppColors.neutral200,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTypography.h3.copyWith(color: AppColors.neutral200),
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),

    // 卡片
    cardTheme: CardThemeData(
      color: AppColors.neutral800,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
    ),

    // 按钮
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary500,
        foregroundColor: AppColors.neutral0,
        disabledBackgroundColor: AppColors.neutral700,
        disabledForegroundColor: AppColors.neutral500,
        textStyle: AppTypography.buttonLg,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        minimumSize: const Size(double.infinity, 52),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary400,
        side: const BorderSide(color: AppColors.primary700),
        textStyle: AppTypography.buttonMd,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary400,
        textStyle: AppTypography.buttonMd,
      ),
    ),

    // 输入框
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.neutral800,
      border: OutlineInputBorder(
        borderRadius: AppRadius.borderSm,
        borderSide: const BorderSide(color: AppColors.neutral700),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.borderSm,
        borderSide: const BorderSide(color: AppColors.neutral700),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.borderSm,
        borderSide: const BorderSide(color: AppColors.primary500, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.borderSm,
        borderSide: const BorderSide(color: AppColors.errorMain),
      ),
      hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.neutral500),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),

    // 对话框
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.neutral800,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
      titleTextStyle: AppTypography.h3.copyWith(color: AppColors.neutral200),
      contentTextStyle: AppTypography.bodyMd.copyWith(color: AppColors.neutral400),
    ),

    // BottomSheet
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.neutral800,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
    ),

    // 分割线
    dividerTheme: const DividerThemeData(
      color: AppColors.neutral700,
      thickness: 0.5,
    ),

    // Switch
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primary500;
        return AppColors.neutral400;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary500.withValues(alpha: 0.3);
        }
        return AppColors.neutral700;
      }),
    ),

    // Snackbar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.neutral700,
      contentTextStyle: AppTypography.bodyMd.copyWith(color: AppColors.neutral200),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
    ),

    // FloatingActionButton
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary500,
      foregroundColor: AppColors.neutral0,
      elevation: 4,
      shape: CircleBorder(),
    ),
  );

  // ============================================================
  // 浅色主题
  // ============================================================
  static ThemeData get light => ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    fontFamily: 'Roboto',

    colorScheme: const ColorScheme.light(
      primary: AppColors.primary500,
      onPrimary: AppColors.neutral0,
      primaryContainer: AppColors.primary50,
      onPrimaryContainer: AppColors.primary900,
      secondary: AppColors.primary300,
      onSecondary: AppColors.neutral0,
      surface: AppColors.neutral0,
      onSurface: AppColors.neutral700,
      onSurfaceVariant: AppColors.neutral500,
      surfaceContainerHighest: AppColors.neutral50,
      surfaceContainer: AppColors.neutral100,
      error: AppColors.errorMain,
      onError: AppColors.neutral0,
      outline: AppColors.neutral300,
      outlineVariant: AppColors.neutral200,
    ),

    scaffoldBackgroundColor: AppColors.neutral0,

    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.neutral0,
      foregroundColor: AppColors.neutral700,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTypography.h3.copyWith(color: AppColors.neutral700),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),

    cardTheme: CardThemeData(
      color: AppColors.neutral50,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary500,
        foregroundColor: AppColors.neutral0,
        disabledBackgroundColor: AppColors.neutral200,
        disabledForegroundColor: AppColors.neutral400,
        textStyle: AppTypography.buttonLg,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        minimumSize: const Size(double.infinity, 52),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary500,
        side: const BorderSide(color: AppColors.primary200),
        textStyle: AppTypography.buttonMd,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary500,
        textStyle: AppTypography.buttonMd,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.neutral50,
      border: OutlineInputBorder(
        borderRadius: AppRadius.borderSm,
        borderSide: const BorderSide(color: AppColors.neutral200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.borderSm,
        borderSide: const BorderSide(color: AppColors.neutral200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.borderSm,
        borderSide: const BorderSide(color: AppColors.primary500, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.borderSm,
        borderSide: const BorderSide(color: AppColors.errorMain),
      ),
      hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.neutral300),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.neutral0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
      titleTextStyle: AppTypography.h3.copyWith(color: AppColors.neutral700),
      contentTextStyle: AppTypography.bodyMd.copyWith(color: AppColors.neutral500),
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.neutral0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.neutral100,
      thickness: 0.5,
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primary500;
        return AppColors.neutral300;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary500.withValues(alpha: 0.3);
        }
        return AppColors.neutral200;
      }),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.neutral700,
      contentTextStyle: AppTypography.bodyMd.copyWith(color: AppColors.neutral0),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary500,
      foregroundColor: AppColors.neutral0,
      elevation: 4,
      shape: CircleBorder(),
    ),
  );
}
