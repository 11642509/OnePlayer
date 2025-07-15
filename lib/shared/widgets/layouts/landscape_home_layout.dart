import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../navigation/navigation_components.dart' as nav; // 使用前缀导入以避免命名冲突
import '../../../main.dart' show PlayerType; // 引入PlayerType枚举
import '../../controllers/window_controller.dart';
import '../../../features/home/pages/home_selection_page.dart'; // 导入HomeTest页面
import '../../../features/video_on_demand/pages/video_on_demand_page.dart'; // 导入VodPage页面
import '../../../features/settings/pages/settings_page.dart'; // 导入设置页面
import '../backgrounds/optimized_cosmic_background.dart'; // 导入优化背景组件
import '../common/glass_container.dart'; // 导入通用毛玻璃组件
import '../../../core/remote_control/focusable_glow.dart';

/// 横屏主页布局
class LandscapeHomeLayout extends StatefulWidget {
  final Function(BuildContext, PlayerType) onPlayerSelected;
  
  const LandscapeHomeLayout({
    super.key, 
    required this.onPlayerSelected
  });

  @override
  State<LandscapeHomeLayout> createState() => _LandscapeHomeLayoutState();
}

class _LandscapeHomeLayoutState extends State<LandscapeHomeLayout> {
  String _currentTab = '测试'; // 默认选中测试页面
  final _navBarKey = GlobalKey<nav.NavigationBarState>();

  void _handleTabChanged(String tab) {
    setState(() => _currentTab = tab);
  }

  // 根据当前标签获取对应的页面内容
  Widget _getContent() {
    switch (_currentTab) {
      case '测试':
        return HomeSelection(
          onPlayerSelected: (context, type) {
            // 使用widget.onPlayerSelected回调
            widget.onPlayerSelected(context, type);
          },
        );
      case '影视':
        return const VideoOnDemandPage();
      case '我的':
        return const SettingsPage();
      default:
        return Center(
          child: Text(
            '$_currentTab 页面',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final windowController = Get.find<WindowController>();
      final isPortrait = windowController.isPortrait.value;
      
      // 如果是竖屏模式，不显示这个布局
      if (isPortrait) {
        return const SizedBox.shrink();
      }
      
      // 计算导航栏的估计高度（根据app.dart中的设置）
      final navBarHeight = 46.0; // 标签栏估计高度
      final navBarOffset = navBarHeight / 3; // 下移标签栏高度的1/3
      final contentTopOffset = navBarOffset * 2; // 内容区域顶部偏移量为导航栏偏移量的2倍

      return OptimizedCosmicBackground(
        child: Stack(
          children: [
            
            // 主内容区域
            Positioned(
              top: navBarHeight + contentTopOffset,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  // 苹果风格内容区域毛玻璃
                  color: Colors.black.withValues(alpha: 0.05), // 极轻透明度
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16), // 苹果风格圆角
                    topRight: Radius.circular(16),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), // 苹果风格模糊
                    child: _getContent(),
                  ),
                ),
              ),
            ),
            
            // 导航栏 - 从屏幕顶部下移1/3的导航栏高度
            Positioned(
              top: navBarOffset,
              left: 0,
              right: 0,
              child: nav.NavigationBar(
                key: _navBarKey,
                currentTab: _currentTab,
                onTabChanged: _handleTabChanged,
              ),
            ),
            
            // 横竖屏切换按钮 - 使用统一毛玻璃效果
            Positioned(
              top: navBarOffset + 8,
              right: 15,
              child: FocusableGlow(
                onTap: () => windowController.toggleOrientation(),
                borderRadius: BorderRadius.circular(18),
              child: GlassContainer(
                width: 36,
                height: 36,
                borderRadius: 18,
                    child: Center(
                      child: CustomPaint(
                        size: const Size(20, 20),
                        painter: RotationIconPainter(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

// 自定义绘制的旋转图标
class RotationIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;

    // 画手机轮廓 (竖屏状态)
    final phoneRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.4,
        height: size.height * 0.7,
      ),
      const Radius.circular(2),
    );
    canvas.drawRRect(phoneRect, paint);

    // 画旋转箭头
    final arrowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    // 圆弧箭头
    final arcRect = Rect.fromCenter(
      center: center,
      width: size.width * 0.8,
      height: size.height * 0.8,
    );
    
    // 画圆弧
    canvas.drawArc(
      arcRect,
      -math.pi / 2, // 从顶部开始
      math.pi * 1.2, // 画3/4圆
      false,
      arrowPaint,
    );

    // 画箭头头部
    final arrowSize = size.width * 0.08;
    final arrowEnd = Offset(
      center.dx + radius * math.cos(math.pi * 0.7),
      center.dy + radius * math.sin(math.pi * 0.7),
    );
    
    final arrowHead1 = Offset(
      arrowEnd.dx - arrowSize * math.cos(math.pi * 0.7 - 0.3),
      arrowEnd.dy - arrowSize * math.sin(math.pi * 0.7 - 0.3),
    );
    
    final arrowHead2 = Offset(
      arrowEnd.dx - arrowSize * math.cos(math.pi * 0.7 + 0.3),
      arrowEnd.dy - arrowSize * math.sin(math.pi * 0.7 + 0.3),
    );

    // 画箭头头部
    canvas.drawLine(arrowEnd, arrowHead1, arrowPaint);
    canvas.drawLine(arrowEnd, arrowHead2, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}