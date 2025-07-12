import 'package:flutter/material.dart';
import '../../../main.dart' show PlayerType;
import '../navigation/navigation_components.dart' show PortraitNavigationBar;
import '../../../features/home/pages/home_selection_page.dart';
import '../../../features/video_on_demand/pages/video_on_demand_page.dart';
import '../../../features/settings/pages/settings_page.dart';
import '../backgrounds/fresh_cosmic_background.dart';
import '../../../app/theme/typography.dart';

/// 竖屏主页布局 - 保持原有布局，使用毛玻璃材质
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
  
  void _handleTabChanged(int index) {
    setState(() {
      _currentTabIndex = index;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return FreshCosmicBackground(
      child: Column(
        children: [
          // 顶部导航栏 - 使用毛玻璃材质的PortraitNavigationBar组件
          PortraitNavigationBar(
            currentIndex: _currentTabIndex,
            onTabChanged: _handleTabChanged,
          ),
          
          // 主内容区域
          Expanded(
            child: _getContent(),
          ),
        ],
      ),
    );
  }
  
  // 根据当前标签索引获取对应的内容
  Widget _getContent() {
    switch (_currentTabIndex) {
      case 0: // 测试
        return HomeSelection(
          onPlayerSelected: widget.onPlayerSelected,
        );
      case 1: // 影视
        return const VideoOnDemandPage();
      case 2: // 番剧
        return Center(
          child: Text(
            '番剧页面\n敬请期待',
            textAlign: TextAlign.center,
            style: AppTypography.titleMedium.copyWith(
              fontSize: 18,
              color: Colors.grey[700], // 适配亮色背景
            ),
          ),
        );
      case 3: // 排行榜
        return Center(
          child: Text(
            '排行榜页面\n敬请期待',
            textAlign: TextAlign.center,
            style: AppTypography.titleMedium.copyWith(
              fontSize: 18,
              color: Colors.grey[700], // 适配亮色背景
            ),
          ),
        );
      case 4: // 动态
        return Center(
          child: Text(
            '动态页面\n敬请期待',
            textAlign: TextAlign.center,
            style: AppTypography.titleMedium.copyWith(
              fontSize: 18,
              color: Colors.grey[700], // 适配亮色背景
            ),
          ),
        );
      case 5: // 我的
        return const SettingsPage();
      default: // 其他标签页显示占位内容
        return HomeSelection(
          onPlayerSelected: widget.onPlayerSelected,
        );
    }
  }
}