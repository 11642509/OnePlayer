import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/performance_manager.dart';

/// 性能优化的清新背景组件 - 竖屏版本
/// 根据设备性能自动调整特效复杂度
class OptimizedFreshBackground extends StatelessWidget {
  final Widget child;
  
  const OptimizedFreshBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PerformanceManager>(
      init: PerformanceManager(),
      builder: (performance) {
        return performance.getOptimizedFreshBackground(child: child);
      },
    );
  }
}

/// 简化版清新背景 - 高性能版本
class SimplifiedFreshBackground extends StatelessWidget {
  final Widget child;
  
  const SimplifiedFreshBackground({
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
            Color(0xFFF8FFFE), // 清晨天空白
            Color(0xFFF0F8FF), // 爱丽丝蓝（偏白）
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
                      const Color(0xFFFFE135).withValues(alpha: 0.12), // 柔和金光
                      const Color(0xFFFFB347).withValues(alpha: 0.08), // 柔和橙光
                      const Color(0xFFFF8C00).withValues(alpha: 0.04), // 微弱深橙
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.4, 0.7, 1.0],
                  ),
                ),
              ),
            ),
          
          // 清新背景层
          if (performance.enableGradientEffects)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.bottomRight, // 清新深处
                    radius: 1.8,
                    colors: [
                      const Color(0xFFE8F4FD).withValues(alpha: 0.3), // 深邃清新蓝
                      const Color(0xFFF0F8FF).withValues(alpha: 0.2), // 清新蓝白
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.6, 1.0],
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

/// 纯渐变背景 - 最高性能版本
class FreshGradientBackground extends StatelessWidget {
  final Widget child;
  
  const FreshGradientBackground({
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
            Color(0xFFF8FFFE), // 清晨天空白
            Color(0xFFF0F8FF), // 爱丽丝蓝（偏白）
          ],
        ),
      ),
      child: child,
    );
  }
}

/// 纯色背景 - 极限性能版本
class FreshSolidBackground extends StatelessWidget {
  final Widget child;
  
  const FreshSolidBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FFFE), // 清晨天空白
      child: child,
    );
  }
}