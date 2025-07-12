import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:get/get.dart';
import '../../utils/performance_manager.dart';

/// 竖屏清新亮色系宇宙背景 - 支持性能模式调节
class FreshCosmicBackground extends StatefulWidget {
  final Widget child;

  const FreshCosmicBackground({
    super.key,
    required this.child,
  });

  @override
  State<FreshCosmicBackground> createState() => _FreshCosmicBackgroundState();
}

class _FreshCosmicBackgroundState extends State<FreshCosmicBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _glowController;
  final List<Star> _stars = [];
  final List<GlowOrb> _glowOrbs = [];

  @override
  void initState() {
    super.initState();
    
    // 主动画控制器 - 更快更活跃的动画
    _controller = AnimationController(
      duration: const Duration(seconds: 8), // 比横屏更快
      vsync: this,
    )..repeat();

    // 光晕动画控制器
    _glowController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);

    // 移除所有光点和光线生成
    // _generateStars(); 
    // _generateGlowOrbs();
  }

  void _generateStars() {
    final random = math.Random();
    final performance = PerformanceManager.to;
    
    // 根据性能等级调整光晕数量
    int haloCount;
    switch (performance.visualQuality) {
      case 0: // 低性能
        haloCount = 8;
        break;
      case 1: // 中性能
        haloCount = 12;
        break;
      case 2: // 高性能
        haloCount = 20;
        break;
      case 3: // 自动模式
      default:
        haloCount = performance.isLowEndDevice ? 8 : 20;
        break;
    }

    for (int i = 0; i < haloCount; i++) {
      // 生成沿着左上到右下对角线的光晕位置
      final diagonalProgress = random.nextDouble();
      final scatter = (random.nextDouble() - 0.5) * 0.4; // 散射范围
      
      _stars.add(Star(
        x: (diagonalProgress + scatter * 0.5).clamp(0.0, 1.0),
        y: (diagonalProgress + scatter).clamp(0.0, 1.0),
        size: random.nextDouble() * 3.0 + 2.0, // 更大的光晕
        brightness: random.nextDouble() * 0.6 + 0.2,
        twinkleSpeed: random.nextDouble() * 1.0 + 0.5, // 更缓慢的闪烁
        color: _getRandomSunlightColor(random), // 阳光色调
      ));
    }
  }

  void _generateGlowOrbs() {
    final random = math.Random();
    final performance = PerformanceManager.to;
    
    // 光晕球数量
    int orbCount;
    switch (performance.visualQuality) {
      case 0:
        orbCount = 2;
        break;
      case 1:
        orbCount = 3;
        break;
      case 2:
        orbCount = 5;
        break;
      case 3:
      default:
        orbCount = performance.isLowEndDevice ? 2 : 5;
        break;
    }

    for (int i = 0; i < orbCount; i++) {
      _glowOrbs.add(GlowOrb(
        x: random.nextDouble(),
        y: random.nextDouble(),
        radius: random.nextDouble() * 80 + 40, // 较大的光晕
        color: _getRandomWarmColor(random), // 暖色调光晕
        intensity: random.nextDouble() * 0.4 + 0.1,
        driftSpeed: random.nextDouble() * 0.3 + 0.1,
      ));
    }
  }

  // 获取阳光色调颜色
  Color _getRandomSunlightColor(math.Random random) {
    final colors = [
      const Color(0xFFFFFBF0),     // 温暖白光
      const Color(0xFFFFF8DC),     // 玉米丝色（阳光色）
      const Color(0xFFFFE4B5),     // 鹿皮色（温暖米色）
      const Color(0xFFF0F8FF),     // 爱丽丝蓝（清晨天空）
      const Color(0xFFE6F7FF),     // 极浅蓝（天空光）
      const Color(0xFFFFFACD),     // 柠檬雪纺色（温和阳光）
    ];
    return colors[random.nextInt(colors.length)];
  }

  // 获取清晨暖色调颜色
  Color _getRandomWarmColor(math.Random random) {
    final colors = [
      const Color(0xFFFFF8DC), // 玉米丝色（清晨阳光）
      const Color(0xFFFFE4B5), // 鹿皮色（温暖米色）
      const Color(0xFFE0F6FF), // 浅蓝色（清晨天空）
      const Color(0xFFF0FFFF), // 天蓝色（清新）
      const Color(0xFFE6FFE6), // 蜜露色（清新绿）
    ];
    return colors[random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _controller.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final performance = PerformanceManager.to;
      
      // 使用与横屏一致的性能判断逻辑
      if (performance.enableBackgroundEffects) {
        // 高性能模式 - 完整微光效果
        return _buildFullEffectBackground();
      } else if (performance.enableGradientEffects) {
        // 平衡模式 - 渐变背景 + 微弱金光
        return _buildGradientBackground();
      } else {
        // 节能模式 - 纯色背景
        return _buildSolidBackground();
      }
    });
  }

  /// 节能模式 - 纯色背景
  Widget _buildSolidBackground() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FFFE), // 清晨天空白
      ),
      child: widget.child,
    );
  }

  /// 平衡模式 - 渐变背景
  Widget _buildGradientBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF8FFFE), // 清晨天空白
            Color(0xFFE8F4FD), // 晨曦浅蓝
            Color(0xFFF0F8FF), // 爱丽丝蓝（偏白）
          ],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // 添加明显的左上角微光照射效果
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft, // 光源位置
                  radius: 1.0,
                  colors: [
                    const Color(0xFFFFE135).withValues(alpha: 0.15), // 明显金光
                    const Color(0xFFFFB347).withValues(alpha: 0.12), // 橙光
                    const Color(0xFFFF8C00).withValues(alpha: 0.08), // 深橙
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 0.6, 1.0],
                ),
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }

  /// 高性能模式 - 完整微光效果（无光点光线）
  Widget _buildFullEffectBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF8FFFE), // 清晨天空白
            Color(0xFFE8F4FD), // 晨曦浅蓝
            Color(0xFFF0F8FF), // 爱丽丝蓝（偏白）
          ],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // 主要的金色微光照射效果
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft, // 光源位置
                  radius: 1.0,
                  colors: [
                    const Color(0xFFFFE135).withValues(alpha: 0.25), // 强烈金光
                    const Color(0xFFFFB347).withValues(alpha: 0.18), // 明显橙光
                    const Color(0xFFFF8C00).withValues(alpha: 0.12), // 深橙
                    const Color(0xFFFFA500).withValues(alpha: 0.06), // 扩散橙
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                ),
              ),
            ),
          ),
          
          // 增加聚焦的强光效果
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 0.4, // 更小半径，更聚焦
                  colors: [
                    const Color(0xFFFFF700).withValues(alpha: 0.2), // 强烈黄光
                    const Color(0xFFFFE135).withValues(alpha: 0.15), // 金光
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),
          
          // 内容层
          widget.child,
        ],
      ),
    );
  }

  Widget _buildGlowOrb(GlowOrb orb, int index) {
    final animationValue = _glowController.value;
    final driftOffset = (animationValue + index * 0.3) % 1.0;
    
    return Positioned(
      left: (orb.x + math.sin(driftOffset * 2 * math.pi) * 0.1) * 
             MediaQuery.of(context).size.width - orb.radius,
      top: (orb.y + math.cos(driftOffset * 2 * math.pi) * 0.05) * 
            MediaQuery.of(context).size.height - orb.radius,
      child: Container(
        width: orb.radius * 2,
        height: orb.radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              orb.color.withValues(alpha: orb.intensity),
              orb.color.withValues(alpha: orb.intensity * 0.5),
              orb.color.withValues(alpha: 0),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
      ),
    );
  }
}

class FreshSunlightPainter extends CustomPainter {
  final List<Star> halos;
  final Animation<double> animation;
  final PerformanceManager performance;

  FreshSunlightPainter({
    required this.halos,
    required this.animation,
    required this.performance,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var halo in halos) {
      final animatedBrightness = halo.brightness * 
        (0.6 + 0.4 * math.sin(animation.value * 2 * math.pi * halo.twinkleSpeed));
      
      final center = Offset(
        halo.x * size.width,
        halo.y * size.height,
      );

      // 只绘制辐射光线效果，不绘制光点
      if (performance.visualQuality >= 1) {
        _drawSunlightRays(canvas, center, halo, animatedBrightness);
      }
    }
  }

  void _drawSunlightRays(Canvas canvas, Offset center, Star halo, double brightness) {
    final rayPaint = Paint()
      ..color = const Color(0xFFFFE135).withValues(alpha: brightness * 0.5) // 更明显的金色光线
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    // 绘制从左上到右下的辐射光线
    const rayCount = 8; // 增加光线数量
    const rayLength = 35.0; // 增加光线长度
    
    for (int i = 0; i < rayCount; i++) {
      // 主要方向是左上到右下（45度），加上一些随机偏移
      final baseAngle = math.pi / 4; // 45度
      final angleOffset = (i - rayCount / 2) * 0.25; // 分散角度
      final angle = baseAngle + angleOffset;
      
      final startOffset = Offset(
        center.dx - math.cos(angle) * rayLength * 0.3,
        center.dy - math.sin(angle) * rayLength * 0.3,
      );
      final endOffset = Offset(
        center.dx + math.cos(angle) * rayLength,
        center.dy + math.sin(angle) * rayLength,
      );
      
      // 绘制主光线
      canvas.drawLine(startOffset, endOffset, rayPaint);
      
      // 绘制更细的辅助光线增强效果
      final subRayPaint = Paint()
        ..color = const Color(0xFFFFF700).withValues(alpha: brightness * 0.3)
        ..strokeWidth = 0.6
        ..strokeCap = StrokeCap.round;
        
      canvas.drawLine(startOffset, endOffset, subRayPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Star {
  final double x;
  final double y;
  final double size;
  final double brightness;
  final double twinkleSpeed;
  final Color color;

  Star({
    required this.x,
    required this.y,
    required this.size,
    required this.brightness,
    required this.twinkleSpeed,
    required this.color,
  });
}

class GlowOrb {
  final double x;
  final double y;
  final double radius;
  final Color color;
  final double intensity;
  final double driftSpeed;

  GlowOrb({
    required this.x,
    required this.y,
    required this.radius,
    required this.color,
    required this.intensity,
    required this.driftSpeed,
  });
}