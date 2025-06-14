import 'package:flutter/material.dart';
import 'main.dart' show PlayerType;
import 'app/app.dart' show PortraitNavigationBar;
import 'page/home_test.dart';
import 'page/vod_page.dart'; // 导入VodPage

/// 竖屏主页布局
class PortraitHomeLayout extends StatefulWidget {
  final Function(BuildContext, PlayerType) onPlayerSelected;
  
  const PortraitHomeLayout({
    required this.onPlayerSelected,
    super.key,
  });

  @override
  State<PortraitHomeLayout> createState() => _PortraitHomeLayoutState();
}

class _PortraitHomeLayoutState extends State<PortraitHomeLayout> {
  int _currentTabIndex = 0;
  
  @override
  void initState() {
    super.initState();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }
  
  void _handleTabChanged(int index) {
    setState(() {
      _currentTabIndex = index;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 顶部导航栏 - 使用新的PortraitNavigationBar组件
        PortraitNavigationBar(
          currentIndex: _currentTabIndex,
          onTabChanged: _handleTabChanged,
        ),
        
        // 主内容区域 - 使用浅灰色背景
        Expanded(
          child: Container(
            color: const Color(0xFFF6F7F8), // B站内容区域的浅灰色背景
            child: _getContent(),
          ),
        ),
      ],
    );
  }
  
  // 根据当前标签索引获取对应的内容
  Widget _getContent() {
    switch (_currentTabIndex) {
      case 0: // 首页
        return PortraitHomeContent(
          tabIndex: _currentTabIndex,
          onPlayerSelected: widget.onPlayerSelected,
        );
      case 1: // 热门 - 显示VodPage
        return const VodPage();
      default: // 其他标签页显示占位内容
        return PortraitHomeContent(
          tabIndex: _currentTabIndex,
          onPlayerSelected: widget.onPlayerSelected,
        );
    }
  }
}