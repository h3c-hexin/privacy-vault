import 'package:flutter/material.dart';

/// 隐私保险箱 Design Token - 阴影
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get sm => [
    const BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get md => [
    const BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get lg => [
    const BoxShadow(
      color: Color(0x26000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];
}
