import 'package:flutter/material.dart';

/// 性能优化的宇宙毛玻璃背景组件 V2
/// 保持原有视觉效果，但大幅降低资源消耗
class OptimizedCosmicBackgroundV2 extends StatelessWidget {
  final Widget child;
  final bool enableStars;
  final double intensity;
  
  const OptimizedCosmicBackgroundV2({
    super.key,
    required this.child,
    this.enableStars = true,
    this.intensity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        // 保持原有的震撼6色渐变背景
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A0F0A), // 深褐色太阳边缘
            Color(0xFF2D1810), // 温暖的深橙褐
            Color(0xFF0F1419), // 宇宙深蓝黑
            Color(0xFF060A0F), // 深邃宇宙黑
            Color(0xFF020507), // 浩瀚宇宙深黑
            Color(0xFF000000), // 无尽宇宙黑
          ],
          stops: [0.0, 0.15, 0.4, 0.6, 0.8, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // 优化1: 用渐变模拟毛玻璃效果，避免BackdropFilter
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft, // 光源位置
                  radius: 1.2,
                  colors: [
                    Color(0xFFFFE135).withValues(alpha: 0.12 * intensity), // 增强金光，模拟毛玻璃透射
                    Color(0xFFFFB347).withValues(alpha: 0.09 * intensity), // 增强橙光
                    Color(0xFFFF8C00).withValues(alpha: 0.06 * intensity), // 增强深橙
                    Color(0xFFFFA500).withValues(alpha: 0.03 * intensity), // 扩散光
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                ),
              ),
            ),
          ),
          
          // 优化2: 简化宇宙深空背景，减少渐变复杂度
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.bottomRight, // 宇宙深处
                  radius: 1.8,
                  colors: [
                    Color(0xFF0B1426).withValues(alpha: 0.8 * intensity), // 深邃宇宙蓝
                    Color(0xFF1A1A2E).withValues(alpha: 0.6 * intensity), // 宇宙紫蓝
                    Color(0xFF000000).withValues(alpha: 0.3 * intensity), // 直接到宇宙黑
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 0.7, 1.0], // 简化stops
                ),
              ),
            ),
          ),
          
          // 优化3: 单层轻量级散射光效，模拟原有的双层毛玻璃
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFE135).withValues(alpha: 0.08 * intensity), // 模拟毛玻璃金光透射
                    Color(0xFFFFB347).withValues(alpha: 0.06 * intensity), // 模拟橙光透射
                    Color(0xFF4A0E4E).withValues(alpha: 0.04 * intensity), // 模拟星云紫透射
                    Color(0xFF1A1A2E).withValues(alpha: 0.02 * intensity), // 模拟宇宙蓝透射
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                ),
              ),
            ),
          ),
          
          // 优化4: 条件性星点效果，使用静态位置避免动画开销
          if (enableStars) _buildOptimizedStars(),
          
          child,
        ],
      ),
    );
  }

  /// 优化的星点效果 - 静态位置，减少计算开销
  Widget _buildOptimizedStars() {
    return CustomPaint(
      painter: OptimizedStarPainter(intensity: intensity),
      size: Size.infinite,
    );
  }
}

/// 优化的星点绘制器 - 静态星点，无动画开销
class OptimizedStarPainter extends CustomPainter {
  final double intensity;
  
  OptimizedStarPainter({required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    // 预定义星点位置，避免随机计算
    final stars = [
      _StarData(0.15, 0.1, 2.0, 0.8),
      _StarData(0.25, 0.25, 1.5, 0.6),
      _StarData(0.4, 0.15, 2.5, 0.9),
      _StarData(0.65, 0.3, 1.8, 0.7),
      _StarData(0.8, 0.2, 2.2, 0.85),
      _StarData(0.2, 0.45, 1.2, 0.5),
      _StarData(0.35, 0.6, 1.8, 0.75),
      _StarData(0.55, 0.65, 2.0, 0.8),
      _StarData(0.75, 0.5, 1.5, 0.6),
      _StarData(0.9, 0.75, 2.3, 0.9),
      _StarData(0.1, 0.8, 1.6, 0.65),
      _StarData(0.45, 0.9, 1.9, 0.75),
    ];

    for (final star in stars) {
      // 金色星点，模拟原有效果
      final paint = Paint()
        ..color = Color(0xFFFFE135).withValues(alpha: star.alpha * intensity)
        ..style = PaintingStyle.fill;

      final center = Offset(
        star.x * size.width,
        star.y * size.height,
      );

      // 绘制星点本体
      canvas.drawCircle(center, star.size, paint);
      
      // 简化的十字星芒效果
      if (intensity > 0.5) {
        final crossPaint = Paint()
          ..color = Color(0xFFFFE135).withValues(alpha: star.alpha * intensity * 0.6)
          ..strokeWidth = 0.8
          ..strokeCap = StrokeCap.round;

        final crossSize = star.size * 1.5;
        // 只绘制两条线，降低绘制开销
        canvas.drawLine(
          center - Offset(crossSize, 0),
          center + Offset(crossSize, 0),
          crossPaint,
        );
        canvas.drawLine(
          center - Offset(0, crossSize),
          center + Offset(0, crossSize),
          crossPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false; // 静态绘制，无需重绘
}

/// 星点数据结构
class _StarData {
  final double x, y, size, alpha;
  _StarData(this.x, this.y, this.size, this.alpha);
}

/// 性能极致优化版本 - 仅渐变，无星点
class UltraOptimizedCosmicBackground extends StatelessWidget {
  final Widget child;
  final double intensity;
  
  const UltraOptimizedCosmicBackground({
    super.key,
    required this.child,
    this.intensity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        // 保持原有6色渐变
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A0F0A), // 深褐色太阳边缘
            Color(0xFF2D1810), // 温暖的深橙褐
            Color(0xFF0F1419), // 宇宙深蓝黑
            Color(0xFF060A0F), // 深邃宇宙黑
            Color(0xFF020507), // 浩瀚宇宙深黑
            Color(0xFF000000), // 无尽宇宙黑
          ],
          stops: [0.0, 0.15, 0.4, 0.6, 0.8, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // 单层优化的光效
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.0,
                  colors: [
                    Color(0xFFFFE135).withValues(alpha: 0.15 * intensity),
                    Color(0xFFFFB347).withValues(alpha: 0.12 * intensity),
                    Color(0xFFFF8C00).withValues(alpha: 0.08 * intensity),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 0.7, 1.0],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}