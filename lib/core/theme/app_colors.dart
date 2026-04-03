import 'package:flutter/material.dart';

/// 隐私保险箱 Design Token - 色彩系统
class AppColors {
  AppColors._();

  // ============================================================
  // Primary - 低饱和深蓝色系
  // ============================================================
  static const Color primary50 = Color(0xFFE8EDF5);
  static const Color primary100 = Color(0xFFC5D1E8);
  static const Color primary200 = Color(0xFF9FB3D8);
  static const Color primary300 = Color(0xFF7A96C8);
  static const Color primary400 = Color(0xFF5A7DB8);
  static const Color primary500 = Color(0xFF3D64A8); // 主色
  static const Color primary600 = Color(0xFF2F5091); // 按下态
  static const Color primary700 = Color(0xFF233D7A);
  static const Color primary800 = Color(0xFF1A2E5C);
  static const Color primary900 = Color(0xFF111D3D);

  // ============================================================
  // Neutral - 中性色
  // ============================================================
  static const Color neutral0 = Color(0xFFFFFFFF);
  static const Color neutral50 = Color(0xFFF7F8FA);
  static const Color neutral100 = Color(0xFFEEF0F4);
  static const Color neutral200 = Color(0xFFD8DCE4);
  static const Color neutral300 = Color(0xFFB8BEC8);
  static const Color neutral400 = Color(0xFF8E96A4);
  static const Color neutral500 = Color(0xFF6B7280);
  static const Color neutral600 = Color(0xFF4B5563);
  static const Color neutral700 = Color(0xFF374151);
  static const Color neutral800 = Color(0xFF1F2937);
  static const Color neutral900 = Color(0xFF111827);
  static const Color neutral950 = Color(0xFF0A0E17);

  // ============================================================
  // Semantic - 语义色
  // ============================================================
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color successMain = Color(0xFF16A34A);
  static const Color successDark = Color(0xFF15803D);

  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningMain = Color(0xFFD97706);
  static const Color warningDark = Color(0xFFB45309);

  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorMain = Color(0xFFDC2626);
  static const Color errorDark = Color(0xFFB91C1C);

  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color infoMain = Color(0xFF2563EB);
  static const Color infoDark = Color(0xFF1D4ED8);

  // ============================================================
  // Gradient - 渐变色
  // ============================================================
  static const LinearGradient gradientPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary500, primary600],
  );

  static const LinearGradient gradientDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [neutral900, neutral950],
  );

  static const LinearGradient gradientCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [neutral800, primary800],
  );

  /// 根据亮/暗模式返回适配的卡片渐变
  static LinearGradient gradientCardFor(Brightness brightness) {
    return brightness == Brightness.dark
        ? gradientCard
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [neutral100, primary50],
          );
  }
}
