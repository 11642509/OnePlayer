import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/performance_manager.dart';

/// 性能优化的宇宙背景组件
/// 根据设备性能自动调整特效复杂度
class OptimizedCosmicBackground extends StatelessWidget {
  final Widget child;
  
  const OptimizedCosmicBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PerformanceManager>(
      init: PerformanceManager(),
      builder: (performance) {
        return performance.getOptimizedBackground(child: child);
      },
    );
  }
}

/// 简化版宇宙背景 - 高性能版本
class SimplifiedCosmicBackground extends StatelessWidget {
  final Widget child;
  
  const SimplifiedCosmicBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final performance = PerformanceManager.to;
    
    return Container(
      decoration: const BoxDecoration(
        // 简化的双色渐变背景
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A3E), // 宇宙蓝
            Color(0xFF0F0F23), // 深空黑
          ],
        ),
      ),
      child: Stack(
        children: [
          // 恢复微光照射效果 - 用户喜欢的背景特效
          if (performance.enableBackgroundEffects)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topLeft, // 光源位置
                    radius: 1.2,
                    colors: [
                      Color(0xFFFFE135).withValues(alpha: 0.08), // 毛玻璃透过的柔和金光
                      Color(0xFFFFB347).withValues(alpha: 0.06), // 柔和橙光
                      Color(0xFFFF8C00).withValues(alpha: 0.04), // 微弱深橙
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.4, 0.7, 1.0],
                  ),
                ),
              ),
            ),
          
          // 宇宙深空背景层
          if (performance.enableGradientEffects)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.bottomRight, // 宇宙深处
                    radius: 1.8,
                    colors: [
                      Color(0xFF0B1426).withValues(alpha: 0.3), // 深邃宇宙蓝
                      Color(0xFF1A1A2E).withValues(alpha: 0.2), // 宇宙紫蓝
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),
            ),
          
          // 微弱的星光效果（性能友好）
          if (performance.enableBackgroundEffects)
            Positioned.fill(
              child: CustomPaint(
                painter: OptimizedStarFieldPainter(),
              ),
            ),
          
          child,
        ],
      ),
    );
  }
}

/// 优化的星空绘制器 - 更少的星点，更好的性能
class OptimizedStarFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    // 只绘制12个星点，减少绘制负担
    const starPositions = [
      Offset(0.8, 0.2),
      Offset(0.9, 0.4),
      Offset(0.7, 0.6),
      Offset(0.85, 0.8),
      Offset(0.6, 0.3),
      Offset(0.95, 0.1),
      Offset(0.75, 0.9),
      Offset(0.65, 0.7),
      Offset(0.88, 0.5),
      Offset(0.72, 0.15),
      Offset(0.92, 0.7),
      Offset(0.68, 0.85),
    ];

    for (final position in starPositions) {
      canvas.drawCircle(
        Offset(position.dx * size.width, position.dy * size.height),
        1.0,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 纯渐变背景 - 最高性能版本
class GradientBackground extends StatelessWidget {
  final Widget child;
  
  const GradientBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1A3E),
            Color(0xFF0F0F23),
          ],
        ),
      ),
      child: child,
    );
  }
}

/// 纯色背景 - 极限性能版本
class SolidBackground extends StatelessWidget {
  final Widget child;
  
  const SolidBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F0F23),
      child: child,
    );
  }
}