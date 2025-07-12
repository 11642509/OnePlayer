import 'package:flutter/material.dart';

/// 应用统一色彩常量
/// 遵循Claude.md规范，避免重复定义颜色值
class AppColors {
  // 私有构造函数，防止实例化
  AppColors._();

  // === 宇宙背景色彩系统 ===
  /// 深褐色太阳边缘
  static const Color cosmicSunEdge = Color(0xFF1A0F0A);
  /// 温暖的深橙褐
  static const Color cosmicWarmOrange = Color(0xFF2D1810);
  /// 宇宙深蓝黑
  static const Color cosmicDeepBlue = Color(0xFF0F1419);
  /// 深邃宇宙黑
  static const Color cosmicDeepBlack = Color(0xFF060A0F);
  /// 浩瀚宇宙深黑
  static const Color cosmicVastBlack = Color(0xFF020507);
  /// 无尽宇宙黑
  static const Color cosmicEndlessBlack = Color(0xFF000000);

  // === 金光色彩系统 ===
  /// 主要金光色
  static const Color goldPrimary = Color(0xFFFFE135);
  /// 橙金光色
  static const Color goldOrange = Color(0xFFFFB347);
  /// 深橙金光
  static const Color goldDeepOrange = Color(0xFFFF8C00);
  /// 扩散橙光
  static const Color goldSpreadOrange = Color(0xFFFFA500);
  /// 强烈黄光
  static const Color goldBrightYellow = Color(0xFFFFF700);

  // === 清新背景色彩系统 ===
  /// 清晨天空白
  static const Color freshSkyWhite = Color(0xFFF8FFFE);
  /// 晨曦浅蓝
  static const Color freshMorningBlue = Color(0xFFE8F4FD);
  /// 爱丽丝蓝（偏白）
  static const Color freshAliceBlue = Color(0xFFF0F8FF);

  // === 宇宙深空色彩 ===
  /// 深邃宇宙蓝
  static const Color spaceDeepBlue = Color(0xFF0B1426);
  /// 宇宙紫蓝
  static const Color spacePurpleBlue = Color(0xFF1A1A2E);
  /// 深空蓝
  static const Color spaceBlue = Color(0xFF16213E);
  /// 星云紫
  static const Color nebulaPurple = Color(0xFF4A0E4E);
  /// 深紫蓝
  static const Color deepPurpleBlue = Color(0xFF2E0C3A);

  // === 毛玻璃色彩系统 ===
  /// 白色毛玻璃 - 8% 透明度
  static Color get glassWhite08 => Colors.white.withValues(alpha: 0.08);
  /// 白色毛玻璃 - 15% 透明度
  static Color get glassWhite15 => Colors.white.withValues(alpha: 0.15);
  /// 黑色毛玻璃 - 15% 透明度
  static Color get glassBlack15 => Colors.black.withValues(alpha: 0.15);
  /// 黑色毛玻璃 - 30% 透明度
  static Color get glassBlack30 => Colors.black.withValues(alpha: 0.30);

  // === 主题色彩 ===
  /// 主题粉色
  static const Color themePink = Color(0xFFFF7BB0);
  /// 主题深粉色
  static const Color themeDeepPink = Color(0xFFFF4081);

  // === 透明度辅助方法 ===
  /// 金光透明度计算
  static Color goldWithAlpha(double alpha, {Color? baseColor}) {
    return (baseColor ?? goldPrimary).withValues(alpha: alpha);
  }

  /// 白色透明度计算
  static Color whiteWithAlpha(double alpha) {
    return Colors.white.withValues(alpha: alpha);
  }

  /// 黑色透明度计算
  static Color blackWithAlpha(double alpha) {
    return Colors.black.withValues(alpha: alpha);
  }
}