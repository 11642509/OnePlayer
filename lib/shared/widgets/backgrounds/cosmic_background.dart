import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;

/// 宇宙毛玻璃背景组件
/// 创建太阳照在宇宙中的毛玻璃高斯模糊效果
class CosmicBackground extends StatelessWidget {
  final Widget child;
  final bool enableStars;
  final double intensity;
  
  const CosmicBackground({
    super.key,
    required this.child,
    this.enableStars = true,
    this.intensity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        // 太阳照在宇宙的震撼背景
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
          // 毛玻璃效果的柔和光源
          Positioned.fill(
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 45 * intensity, sigmaY: 45 * intensity), // 强高斯模糊
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topLeft, // 光源位置
                      radius: 1.2,
                      colors: [
                        Color(0xFFFFE135).withValues(alpha: 0.08 * intensity), // 毛玻璃透过的柔和金光
                        Color(0xFFFFB347).withValues(alpha: 0.06 * intensity), // 柔和橙光
                        Color(0xFFFF8C00).withValues(alpha: 0.04 * intensity), // 微弱深橙
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.4, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // 宇宙深空背景
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.bottomRight, // 宇宙深处
                  radius: 1.8,
                  colors: [
                    Color(0xFF0B1426).withValues(alpha: 0.9 * intensity), // 深邃宇宙蓝
                    Color(0xFF1A1A2E).withValues(alpha: 0.7 * intensity), // 宇宙紫蓝
                    Color(0xFF16213E).withValues(alpha: 0.5 * intensity), // 深空蓝
                    Color(0xFF000000).withValues(alpha: 0.3 * intensity), // 宇宙黑
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 0.6, 0.8, 1.0],
                ),
              ),
            ),
          ),
          
          // 毛玻璃散射光效
          Positioned.fill(
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25 * intensity, sigmaY: 25 * intensity), // 中等模糊
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFE135).withValues(alpha: 0.04 * intensity), // 极轻的金光透射
                        Color(0xFFFFB347).withValues(alpha: 0.03 * intensity), // 极轻的橙光透射
                        Color(0xFF4A0E4E).withValues(alpha: 0.02 * intensity), // 星云紫透射
                        Color(0xFF1A1A2E).withValues(alpha: 0.01 * intensity), // 宇宙蓝透射
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.3, 0.6, 0.8, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // 毛玻璃光束效果
          Positioned(
            top: -200,
            left: -200,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 35 * intensity, sigmaY: 35 * intensity), // 毛玻璃模糊
                child: Container(
                  width: 1000,
                  height: 800,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topLeft,
                      radius: 0.8,
                      colors: [
                        Color(0xFFFFE135).withValues(alpha: 0.06 * intensity), // 毛玻璃透过的柔和光
                        Color(0xFFFFB347).withValues(alpha: 0.04 * intensity), // 柔和橙光
                        Color(0xFFFF8C00).withValues(alpha: 0.02 * intensity), // 微弱深橙
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.4, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // 宇宙星云毛玻璃效果
          Positioned(
            top: -200,
            right: -200,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30 * intensity, sigmaY: 30 * intensity), // 星云模糊
                child: Container(
                  width: 800,
                  height: 1000,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topRight,
                      radius: 1.2,
                      colors: [
                        Color(0xFF4A0E4E).withValues(alpha: 0.08 * intensity), // 柔和星云紫
                        Color(0xFF2E0C3A).withValues(alpha: 0.06 * intensity), // 柔和深紫蓝
                        Color(0xFF1A1A2E).withValues(alpha: 0.04 * intensity), // 柔和宇宙蓝
                        Color(0xFF0F0F23).withValues(alpha: 0.02 * intensity), // 柔和深空蓝
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.3, 0.6, 0.8, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // 毛玻璃光散射效果
          Positioned.fill(
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15 * intensity, sigmaY: 15 * intensity), // 轻微毛玻璃模糊
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topLeft,
                      radius: 2.0,
                      colors: [
                        Color(0xFFFFE135).withValues(alpha: 0.03 * intensity), // 极轻的毛玻璃金光
                        Color(0xFFFFB347).withValues(alpha: 0.02 * intensity), // 极轻的毛玻璃橙光
                        Color(0xFF4A0E4E).withValues(alpha: 0.015 * intensity), // 极轻的星云紫
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.4, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // 微弱的星光点点效果
          if (enableStars)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                child: CustomPaint(
                  painter: StarFieldPainter(intensity: intensity),
                ),
              ),
            ),
          
          // 子组件
          child,
        ],
      ),
    );
  }
}

// 星空绘制器 - 创建微弱的星光点点效果
class StarFieldPainter extends CustomPainter {
  final double intensity;
  
  const StarFieldPainter({this.intensity = 1.0});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05 * intensity)
      ..style = PaintingStyle.fill;

    // 创建随机星点
    final random = math.Random(42); // 固定种子确保星点位置一致
    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.5 + 0.5;
      
      // 只在右侧宇宙区域绘制星点
      if (x > size.width * 0.4) {
        canvas.drawCircle(
          Offset(x, y),
          radius,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}