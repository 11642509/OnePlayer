import 'package:flutter/material.dart';

/// 应用颜色方案
class AppColorScheme {
  // 主色调
  static const Color primary = Color(0xFFFF7BB0); // B站风格粉色
  static const Color primaryVariant = Color(0xFFE91E63);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color secondaryVariant = Color(0xFF018786);
  
  // 表面颜色
  static const Color surface = Colors.white;
  static const Color surfaceDark = Color(0xFF121212);
  static const Color background = Color(0xFFF6F7F8); // 浅灰色背景
  static const Color backgroundDark = Colors.black;
  
  // 文本颜色
  static const Color onSurface = Color(0xFF212121);
  static const Color onSurfaceDark = Colors.white;
  static const Color onBackground = Color(0xFF212121);
  static const Color onBackgroundDark = Colors.white;
  
  // 边框和分割线
  static const Color border = Color(0xFFEEEEEE);
  static const Color borderDark = Color(0xFF333333);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color dividerDark = Color(0xFF333333);
  
  // 状态颜色
  static const Color error = Color(0xFFB00020);
  static const Color warning = Color(0xFFFF9800);
  static const Color success = Color(0xFF4CAF50);
  static const Color info = Color(0xFF2196F3);
  
  // 透明度变体
  static Color primaryWithAlpha(int alpha) => primary.withAlpha(alpha);
  static Color blackWithAlpha(int alpha) => Colors.black.withAlpha(alpha);
  static Color whiteWithAlpha(int alpha) => Colors.white.withAlpha(alpha);
  
  // 渐变色
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryVariant],
  );
  
  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2C2C2C), Color(0xFF1A1A1A)],
  );
}