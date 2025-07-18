import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:ui';
import '../../controllers/window_controller.dart';
import '../common/glass_container.dart';
import '../../../app/theme/typography.dart';
import '../../../core/remote_control/focusable_glow.dart';

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
  
  // 为每个导航项创建和管理FocusNode
  final Map<int, FocusNode> _focusNodes = {};
  final FocusNode _searchFocusNode = FocusNode();
  
  // 当前选中的标签索引
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < _tabs.length; i++) {
      _focusNodes[i] = FocusNode(debugLabel: 'Tab $i');
    }
    _updateSelectedIndex();
  }

  @override
  void dispose() {
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    _searchFocusNode.dispose();
    super.dispose();
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
      // final baseFontSize = navWidth * 0.025; // 调小字体大小比例
      // 调整内边距使其更加紧凑
      const verticalPadding = 8.0; // 稍微增加垂直内边距
      const horizontalPadding = 12.0;

      return Center(
        child: Container(
          width: navWidth,
          decoration: BoxDecoration(
            // iOS 26 液态玻璃效果 - 完全透明，仅有极轻的玻璃质感
            color: Colors.white.withValues(alpha: 0.08), // 极轻的白色透明度
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15), // 极细的玻璃边框
              width: 0.2,
            ),
            boxShadow: [
              // 极轻的玻璃投影
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                spreadRadius: -5,
                offset: const Offset(0, 8),
              ),
              // 玻璃的内部高光
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.15),
                blurRadius: 1,
                spreadRadius: 0,
                offset: const Offset(0, -0.3),
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
                  title,
                  index == _selectedIndex,
                  _focusNodes[index]!,
                );
              }),
              _buildSearchButton(_searchFocusNode),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildNavItem(
    String title,
    bool isSelected,
    FocusNode focusNode,
  ) {
    // 计算按钮高度，用于确定圆角大小
    const buttonHeight = 36.0; // 固定的按钮高度

    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, child) {
        final isFocused = focusNode.hasFocus;
        
        // 当获得焦点且未被选中时，显示药丸背景
        final showPill = isFocused && !isSelected;

    return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 200),
      builder: (context, value, child) {
            Color backgroundColor;
            if (isSelected) {
              backgroundColor = Colors.white.withValues(alpha: 0.85);
            } else if (showPill) {
              // 药丸效果只应该在深色模式下出现
              backgroundColor = Colors.white.withValues(alpha: 0.25);
            } else {
              backgroundColor = Colors.transparent;
            }

        return TextButton(
              focusNode: focusNode,
          onPressed: () => widget.onTabChanged(title),
          style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
            ),
                backgroundColor: backgroundColor,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(buttonHeight / 2),
            ),
          ).copyWith(
            overlayColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (states.contains(WidgetState.hovered) && !isSelected) {
                    return Colors.white.withValues(alpha: 0.1);
              }
              return Colors.transparent;
            }),
          ),
          child: Text(
            title,
            style: TextStyle(
                  // 仅在选中时（白色实底背景）使用深色文字
                  color: isSelected
                      ? Colors.black.withValues(alpha: 0.9)
                      : Colors.white.withValues(alpha: 0.9),
                  fontSize: 16 + (2 * value), // 未选中16，选中时动画到18
              fontWeight: FontWeight.lerp(
                FontWeight.w500,
                FontWeight.w600,
                value,
              ),
              letterSpacing: 0.2,
                  shadows: (isSelected || showPill)
                      ? null
                  : [
                      Shadow(
                            color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
          ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchButton(FocusNode focusNode) {
    // 计算按钮高度，用于确定圆角大小
    const buttonHeight = 36.0; // 固定的按钮高度
    
    return FocusableGlow(
      onTap: () { 
        Get.toNamed('/search'); 
      },
      borderRadius: BorderRadius.circular(buttonHeight / 2),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(buttonHeight / 2),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 0.2,
          ),
        ),
        child: const Icon(
              Icons.search_rounded,
          color: Colors.white,
          size: 18,
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

class _PortraitNavigationBarState extends State<PortraitNavigationBar>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['测试', '影视', '番剧', '排行榜', '动态', '我的']; // 与横屏导航完全一致
  
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
  
  // 更新状态栏样式 - 适配深色宇宙背景
  void _updateStatusBarStyle() {
    // 竖屏模式下设置状态栏图标为浅色（适配深色宇宙背景）
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, // 改为浅色图标
      statusBarBrightness: Brightness.dark, // iOS 适配深色背景
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
    
    return SafeArea(
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              // 使用与横屏导航相同的毛玻璃效果
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 0.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  spreadRadius: -5,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.15),
                  blurRadius: 1,
                  spreadRadius: 0,
                  offset: const Offset(0, -0.3),
                ),
              ],
            ),
            child: Column(
              children: [
                // 搜索栏
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 6, 15, 8),
                  child: Row(
                    children: [
                      // 头像 - 适配毛玻璃背景
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3), // 适配深色背景
                            width: 2
                          ),
                          image: const DecorationImage(
                            image: NetworkImage('https://wpimg.wallstcn.com/f778738c-e4f8-4870-b634-56703b4acafe.gif'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // 搜索框 - 毛玻璃风格
                      Expanded(
                        child: FocusableGlow(
                          onTap: () { 
                            Get.toNamed('/search'); 
                          },
                          borderRadius: BorderRadius.circular(18),
                        child: Container(
                          height: 36,
                          decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15), // 适配深色背景
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              Icon(Icons.search, 
                                color: Colors.white.withValues(alpha: 0.7), // 适配深色背景
                                size: 20
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '搜索视频、番剧、UP主',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7), // 适配深色背景
                                  fontSize: 13,
                                ),
                              ),
                            ],
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // 消息图标 - 适配深色背景
                      FocusableGlow(
                        onTap: () { /* TODO: 消息功能 */ },
                        borderRadius: BorderRadius.circular(18),
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: Icon(Icons.notifications_none, 
                        color: Colors.white.withValues(alpha: 0.8), 
                        size: 24
                          ),
                        ),
                      ),
                      
                      // 屏幕旋转按钮 - 使用GlassContainer
                      const SizedBox(width: 10),
                      FocusableGlow(
                        onTap: Get.find<WindowController>().toggleOrientation,
                        borderRadius: BorderRadius.circular(18),
                        child: GlassContainer(
                        width: 36,
                        height: 36,
                        borderRadius: 18,
                            child: Icon(
                              Icons.screen_rotation_rounded,
                              color: Colors.white.withValues(alpha: 0.8), // 适配深色背景
                              size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 标签页 - 适配毛玻璃背景并使用统一字体
                TabBar(
                  controller: _tabController,
                  isScrollable: true, // 恢复滚动，6个标签需要滚动
                  labelColor: Colors.white, // 浅色选中文字
                  unselectedLabelColor: Colors.white.withValues(alpha: 0.7), // 浅色未选中文字
                  indicatorColor: Colors.white, // 浅色指示器
                  indicatorSize: TabBarIndicatorSize.label,
                  indicatorWeight: 3,
                  dividerColor: Colors.transparent, // 移除底部横线
                  labelStyle: TextStyle(
                    fontFamily: AppTypography.systemFont, // 使用统一字体
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontFamily: AppTypography.systemFont, // 使用统一字体
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                  tabs: _tabs
                      .map((tab) => Tab(
                            child: _PortraitFocusHighlight(
                              child: Text(tab),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 一个辅助组件，用于在竖屏模式下为Tab提供清晰的方形焦点高亮。
class _PortraitFocusHighlight extends StatefulWidget {
  final Widget child;
  const _PortraitFocusHighlight({required this.child});

  @override
  State<_PortraitFocusHighlight> createState() =>
      _PortraitFocusHighlightState();
}

class _PortraitFocusHighlightState extends State<_PortraitFocusHighlight> {
  FocusNode? _focusNode;
  bool _isFocused = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final focusNode = Focus.of(context);
    if (_focusNode != focusNode) {
      _focusNode?.removeListener(_onFocusChanged);
      _focusNode = focusNode;
      _focusNode?.addListener(_onFocusChanged);
      if (_focusNode != null && _isFocused != _focusNode!.hasFocus) {
        _isFocused = _focusNode!.hasFocus;
      }
    }
  }

  @override
  void dispose() {
    _focusNode?.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted && _isFocused != _focusNode?.hasFocus) {
      setState(() {
        _isFocused = _focusNode!.hasFocus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 为了让高亮和文字之间有呼吸感，使用内边距
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: _isFocused
          ? BoxDecoration(
              // 模拟系统默认的方形高亮
              borderRadius: BorderRadius.circular(4),
              color: Colors.white.withValues(alpha: 0.2), // 适配深色背景
            )
          : null,
      child: widget.child,
    );
  }
}