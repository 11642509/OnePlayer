import 'package:flutter/material.dart';
import 'app/app.dart' as app; // 使用前缀导入以避免命名冲突
import 'main.dart' show PlayerType, windowController; // 引入PlayerType枚举和windowController实例
import 'page/home_test.dart'; // 导入HomeTest页面
import 'page/vod_page.dart'; // 导入VodPage页面

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
  final _navBarKey = GlobalKey<app.NavigationBarState>();

  void _handleTabChanged(String tab) {
    setState(() => _currentTab = tab);
  }

  // 根据当前标签获取对应的页面内容
  Widget _getContent() {
    switch (_currentTab) {
      case '测试':
        return HomeTest(
          onPlayerSelected: (context, type) {
            // 使用widget.onPlayerSelected回调
            widget.onPlayerSelected(context, type);
          },
        );
      case '影视':
        return const VodPage();
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
    // 计算导航栏的估计高度（根据app.dart中的设置）
    final navBarHeight = 46.0; // 标签栏估计高度
    final navBarOffset = navBarHeight / 3; // 下移标签栏高度的1/3
    final contentTopOffset = navBarOffset * 2; // 内容区域顶部偏移量为导航栏偏移量的2倍

    return Stack(
      children: [
        // 主内容区域
        Positioned(
          top: navBarHeight + contentTopOffset, // 使用新的偏移量
          left: 0,
          right: 0,
          bottom: 0,
          child: _getContent(),
        ),
        
        // 导航栏 - 从屏幕顶部下移1/3的导航栏高度
        Positioned(
          top: navBarOffset, // 下移1/3导航栏高度
          left: 0,
          right: 0,
          child: app.NavigationBar(
            key: _navBarKey,
            currentTab: _currentTab,
            onTabChanged: _handleTabChanged,
          ),
        ),
        
        // 横竖屏切换按钮 - 右上角，与导航栏对齐
        Positioned(
          top: navBarOffset + 5, // 下移1/3导航栏高度后再加5像素的偏移
          right: 10,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(100),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.screen_lock_portrait),
              tooltip: '切换为竖屏',
              onPressed: () => windowController.toggleOrientation(),
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
} 