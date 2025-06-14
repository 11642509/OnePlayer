import 'package:flutter/material.dart';
import 'dart:ui';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _currentTab = '热门'; // 默认选中热门页面
  final _navBarKey = GlobalKey<NavigationBarState>();

  void _handleTabChanged(String tab) {
    setState(() => _currentTab = tab);
  }

  Widget _getPage() {
    // 简单展示当前选中的页面
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 内容层
          Column(
            children: [
              // 导航栏
              Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                ),
                child: NavigationBar(
                  key: _navBarKey,
                  currentTab: _currentTab,
                  onTabChanged: _handleTabChanged,
                ),
              ),
              Expanded(
                child: _getPage(),
              ),
            ],
          ),
        ],
      ),
    );
  }  
}

// 导航栏组件
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
  final List<String> _tabs = ['热门', '哔哩哔哩', '番剧', '排行榜', '动态', '我的'];
  
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
