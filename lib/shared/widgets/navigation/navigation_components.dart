import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:ui';
import '../../controllers/window_controller.dart';

// 横屏导航栏组件
class NavigationBar extends StatefulWidget {
  final String currentTab;
  final ValueChanged<String> onTabChanged;

  const NavigationBar({
    super.key,
    required this.currentTab,
    required this.onTabChanged,
  });

  @override
  State<NavigationBar> createState() => NavigationBarState();
}

class NavigationBarState extends State<NavigationBar> {
  // 导航标签列表
  final List<String> _tabs = ['测试', '影视', '番剧', '排行榜', '动态', '我的'];
  
  // 当前选中的标签索引
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _updateSelectedIndex();
  }

  @override
  void didUpdateWidget(NavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentTab != oldWidget.currentTab) {
      _updateSelectedIndex();
    }
  }

  void _updateSelectedIndex() {
    final index = _tabs.indexOf(widget.currentTab);
    if (index != -1) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final windowController = Get.find<WindowController>();
      final isPortrait = windowController.isPortrait.value;
      
      // 如果是竖屏模式，不显示这个导航栏
      if (isPortrait) {
        return const SizedBox.shrink();
      }
      
      final size = MediaQuery.of(context).size;
      // 将宽度调整为屏幕宽度的60%
      final navWidth = size.width * 0.6;
      // 根据导航栏宽度计算基础字体大小
      final baseFontSize = navWidth * 0.025; // 调小字体大小比例
      // 调整内边距使其更加紧凑
      const verticalPadding = 8.0; // 稍微增加垂直内边距
      const horizontalPadding = 12.0;

      return Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30), // 增加整个导航栏的圆角
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              width: navWidth,
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(77),
                borderRadius: BorderRadius.circular(30), // 增加整个导航栏的圆角
                border: Border.all(
                  color: Colors.white.withAlpha(51),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(51),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(
                vertical: verticalPadding,
                horizontal: horizontalPadding,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ..._tabs.asMap().entries.map((entry) {
                    final index = entry.key;
                    final title = entry.value;
                    return _buildNavItem(
                        title, baseFontSize, index == _selectedIndex);
                  }),
                  _buildSearchButton(baseFontSize),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildNavItem(String title, double baseFontSize, bool isSelected) {
    final isActive = widget.currentTab == title || isSelected;
    
    // 计算按钮高度，用于确定圆角大小
    final buttonHeight = baseFontSize * 2.2; // 估计的按钮高度

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: isActive ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 200),
      builder: (context, value, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(buttonHeight / 2), // 完全圆形的边角
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.white.withAlpha(26),
                      blurRadius: 12 * value,
                      spreadRadius: 2 * value,
                    ),
                  ]
                : null,
          ),
          child: TextButton(
            onPressed: () => widget.onTabChanged(title),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: baseFontSize * 0.9, // 增加水平内边距
                vertical: baseFontSize * 0.45, // 增加垂直内边距
              ),
              backgroundColor: Color.lerp(
                Colors.transparent,
                Colors.white.withAlpha(230),
                value,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(buttonHeight / 2), // 半圆形边角
              ),
            ).copyWith(
              overlayColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.hovered)) {
                  return Colors.white.withAlpha(77);
                }
                return Colors.transparent;
              }),
            ),
            child: Text(
              title,
              style: TextStyle(
                color: Color.lerp(
                  Colors.white.withAlpha(230),
                  Colors.black.withAlpha(217),
                  value,
                ),
                fontSize: baseFontSize + (2 * value),
                fontWeight: FontWeight.lerp(
                  FontWeight.w500,
                  FontWeight.w600,
                  value,
                ),
                letterSpacing: 0.2,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchButton(double baseFontSize) {
    // 计算按钮高度，用于确定圆角大小
    final buttonHeight = baseFontSize * 2.2; // 估计的按钮高度
    
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(26),
          borderRadius: BorderRadius.circular(buttonHeight / 2), // 半圆形边角
          border: Border.all(
            color: Colors.white.withAlpha(26),
            width: 0.5,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(buttonHeight / 2), // 半圆形边角
          onTap: () {},
          child: Padding(
            padding: EdgeInsets.all(baseFontSize * 0.55), // 增加内边距
            child: Icon(
              Icons.search_rounded,
              color: Colors.white.withAlpha(179),
              size: baseFontSize * 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

// 竖屏导航栏组件
class PortraitNavigationBar extends StatefulWidget {
  final ValueChanged<int> onTabChanged;
  final int currentIndex;

  const PortraitNavigationBar({
    super.key,
    required this.onTabChanged,
    required this.currentIndex,
  });

  @override
  State<PortraitNavigationBar> createState() => _PortraitNavigationBarState();
}

class _PortraitNavigationBarState extends State<PortraitNavigationBar> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['测试', '影视', '频道', '精选', '动态'];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length, 
      vsync: this,
      initialIndex: widget.currentIndex,
    );
    
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        widget.onTabChanged(_tabController.index);
      }
    });
    
    // 设置状态栏样式
    _updateStatusBarStyle();
  }
  
  @override
  void didUpdateWidget(PortraitNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      _tabController.animateTo(widget.currentIndex);
    }
    
    // 更新状态栏样式
    _updateStatusBarStyle();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 每次依赖变化时更新状态栏样式
    _updateStatusBarStyle();
  }
  
  // 更新状态栏样式
  void _updateStatusBarStyle() {
    // 竖屏模式下设置状态栏图标为深色
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light, // iOS
    ));
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // 确保状态栏样式正确
    _updateStatusBarStyle();
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white, // 确保标签栏为白色背景
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFEEEEEE), // 使用更浅的灰色作为分隔线
            width: 0.5, // 更细的线条
          ),
        ),
      ),
      child: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 6, 15, 8),
            child: Row(
              children: [
                // 头像
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.pink.withAlpha(60), width: 2),
                    image: const DecorationImage(
                      image: NetworkImage('https://wpimg.wallstcn.com/f778738c-e4f8-4870-b634-56703b4acafe.gif'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // 搜索框
                Expanded(
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(15),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        Icon(Icons.search, color: Colors.grey[400], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '搜索视频、番剧、UP主',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // 消息图标
                Icon(Icons.notifications_none, color: Colors.grey[500], size: 24),
                
                // 屏幕旋转按钮
                const SizedBox(width: 10),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.screen_lock_rotation, size: 24),
                  color: Colors.grey[500],
                  onPressed: Get.find<WindowController>().toggleOrientation,
                ),
              ],
            ),
          ),
          
          // 标签页
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: const Color(0xFFFF7BB0), // B站风格的粉色
            unselectedLabelColor: Colors.grey[600], 
            indicatorColor: const Color(0xFFFF7BB0),
            indicatorSize: TabBarIndicatorSize.label,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
            ),
            tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
          ),
        ],
      ),
    );
  }
}