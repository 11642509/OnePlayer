import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// 背景工厂类 - 统一管理所有背景样式，避免重复代码
/// 遵循Claude.md规范的单一职责原则
class BackgroundFactory {
  // 私有构造函数，防止实例化
  BackgroundFactory._();

  // === 宇宙背景色彩渐变 ===
  static const Color _cosmicSolidColor = Color(0xFF0F0F23);

  // === 宇宙暗色系配色（参考现有宇宙背景） ===
  static const List<Color> _cosmicDarkGradientColors = [
    AppColors.cosmicSunEdge,      // 深褐色太阳边缘
    AppColors.cosmicWarmOrange,   // 温暖的深橙褐
    AppColors.cosmicDeepBlue,     // 宇宙深蓝黑
    AppColors.cosmicDeepBlack,    // 深邃宇宙黑
  ];

  static const List<double> _cosmicDarkGradientStops = [0.0, 0.15, 0.4, 1.0];

  // === 清新背景色彩渐变 ===
  static const List<Color> _freshGradientColors = [
    AppColors.freshSkyWhite,
    AppColors.freshMorningBlue,
    AppColors.freshAliceBlue,
  ];

  static const List<double> _freshGradientStops = [0.0, 0.6, 1.0];

  // === 金光效果配置 ===
  static const List<double> _mainLightStops = [0.0, 0.4, 0.7, 1.0];
  static const List<double> _focusLightStops = [0.0, 0.6, 1.0];

  /// 创建宇宙渐变背景（平衡模式 - 添加微光效果）
  static Widget createCosmicGradientBackground(Widget child) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _cosmicDarkGradientColors,
          stops: _cosmicDarkGradientStops,
        ),
      ),
      child: Stack(
        children: [
          // 微弱的金色微光照射效果（适合暗色背景）
          _buildCosmicGoldLight(intensity: 0.4),
          child,
        ],
      ),
    );
  }

  /// 创建宇宙纯色背景
  static Widget createCosmicSolidBackground(Widget child) {
    return Container(
      color: _cosmicSolidColor,
      child: child,
    );
  }

  /// 创建完整清新背景（高性能模式）
  static Widget createFullFreshBackground(Widget child) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _freshGradientColors,
          stops: _freshGradientStops,
        ),
      ),
      child: Stack(
        children: [
          // 主要的金色微光照射效果
          _buildMainGoldLight(intensity: 1.0),
          // 聚焦强光效果
          _buildFocusGoldLight(intensity: 1.0),
          child,
        ],
      ),
    );
  }

  /// 创建清新渐变背景（平衡模式）
  static Widget createFreshGradientBackground(Widget child) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _freshGradientColors,
          stops: _freshGradientStops,
        ),
      ),
      child: Stack(
        children: [
          // 微弱的金光照射效果
          _buildMainGoldLight(intensity: 0.6),
          child,
        ],
      ),
    );
  }

  /// 创建纯色清新背景（节能模式）
  static Widget createFreshSolidBackground(Widget child) {
    return Container(
      color: AppColors.freshSkyWhite,
      child: child,
    );
  }

  /// 构建主要金光效果
  static Widget _buildMainGoldLight({required double intensity}) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.0,
            colors: [
              AppColors.goldWithAlpha(0.25 * intensity),
              AppColors.goldWithAlpha(0.18 * intensity, baseColor: AppColors.goldOrange),
              AppColors.goldWithAlpha(0.12 * intensity, baseColor: AppColors.goldDeepOrange),
              Colors.transparent,
            ],
            stops: _mainLightStops,
          ),
        ),
      ),
    );
  }

  /// 构建聚焦金光效果
  static Widget _buildFocusGoldLight({required double intensity}) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 0.4,
            colors: [
              AppColors.goldWithAlpha(0.2 * intensity, baseColor: AppColors.goldBrightYellow),
              AppColors.goldWithAlpha(0.15 * intensity),
              Colors.transparent,
            ],
            stops: _focusLightStops,
          ),
        ),
      ),
    );
  }

  /// 构建宇宙暗色背景专用的金光效果（透明度更低，适合暗色调）
  static Widget _buildCosmicGoldLight({required double intensity}) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.2,
            colors: [
              AppColors.goldWithAlpha(0.08 * intensity), // 微弱金光，适合暗色背景
              AppColors.goldWithAlpha(0.06 * intensity, baseColor: AppColors.goldOrange), // 微弱橙光
              AppColors.goldWithAlpha(0.04 * intensity, baseColor: AppColors.goldDeepOrange), // 微弱深橙
              Colors.transparent,
            ],
            stops: const [0.0, 0.3, 0.6, 1.0],
          ),
        ),
      ),
    );
  }
}