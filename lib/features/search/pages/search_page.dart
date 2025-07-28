import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../../../shared/widgets/backgrounds/optimized_cosmic_background.dart';
import '../../../shared/widgets/backgrounds/fresh_cosmic_background.dart';
import '../../../shared/widgets/common/glass_container.dart';
import '../../../shared/widgets/video/video_grid_widget.dart';
import '../../../app/theme/typography.dart';
import '../../../app/data_source.dart';
import '../../../core/remote_control/focusable_glow.dart';
import '../../../core/remote_control/focus_aware_tab.dart';
import '../../../app/routes/app_routes.dart';
import '../../../shared/controllers/window_controller.dart';
import '../../../shared/services/back_button_handler.dart';
import '../controllers/search_controller.dart' as search_ctrl;

/// 搜索页面 - 保留搜索功能，解决阴影效果问题
class SearchPage extends GetView<search_ctrl.SearchController> {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final windowController = Get.find<WindowController>();
    final backButtonHandler = Get.find<BackButtonHandler>();
    
    return Obx(() {
      final isPortrait = windowController.isPortrait.value;
      
      // 1. 先构建基础内容（Scaffold）
      Widget content = Scaffold(
        backgroundColor: Colors.transparent,
        body: _buildResponsiveLayout(isPortrait),
      );
      
      // 2. 使用BackButtonHandler包装内容，完全参考视频详情页
      content = backButtonHandler.createPopScope(
        child: content,
      );
      
      // 3. 最后在外层套上背景
      if (isPortrait) {
        // 竖屏模式：使用默认主题
        return FreshCosmicBackground(child: content);
      } else {
        // 横屏模式：使用深色主题，与影视页完全一致，确保阴影效果相同
        return Theme(
          data: Theme.of(context).copyWith(
            brightness: Brightness.dark,
          ),
          child: OptimizedCosmicBackground(child: content),
        );
      }
    });
  }

  /// 构建响应式布局
  Widget _buildResponsiveLayout(bool isPortrait) {
    // 页面加载时自动将焦点设置到搜索框
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.searchFocusNode.canRequestFocus) {
        controller.searchFocusNode.requestFocus();
      }
    });

    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildSearchAppBar(isPortrait),
        body: _buildSearchBody(isPortrait),
      ),
    );
  }

  /// 构建搜索页AppBar（包含导航TabBar）
  PreferredSizeWidget? _buildSearchAppBar(bool isPortrait) {
    if (kDebugMode) {
      print('🔍 SearchPage: 构建AppBar, isPortrait=$isPortrait');
    }
    
    return PreferredSize(
      preferredSize: Size.fromHeight(kToolbarHeight + (isPortrait ? 16 : 20) * 2 + 48 + kToolbarHeight),
      child: Obx(() {
        final hasKeyword = controller.keyword.value.isNotEmpty;
        
        if (kDebugMode) {
          print('🔍 SearchPage: AppBar Obx更新, hasKeyword=$hasKeyword, isPortrait=$isPortrait');
        }
        
        return AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false, // 禁用自动返回按钮
          toolbarHeight: hasKeyword ? kToolbarHeight + (isPortrait ? 16 : 20) * 2 + kToolbarHeight : (isPortrait ? 16 : 20) * 2 + 48,
          title: Column(
            children: [
              // 搜索输入区域
              _buildHeaderContent(isPortrait),
              // 搜索站点TabBar（只有在有搜索关键词时显示）
              if (hasKeyword && controller.sites.isNotEmpty) ...[
                if (kDebugMode) ...[
                  Builder(builder: (context) {
                    print('🔍 SearchPage: 显示TabBar, 站点数量=${controller.sites.length}');
                    return const SizedBox.shrink();
                  }),
                ],
                SizedBox(
                  height: kToolbarHeight,
                  child: _buildSearchTabBar(isPortrait),
                ),
              ],
            ],
          ),
          titleSpacing: 0,
          centerTitle: false,
        );
      }),
    );
  }

  /// 构建头部内容（不包含响应式包装）
  Widget _buildHeaderContent(bool isPortrait) {
    return Container(
      padding: EdgeInsets.all(isPortrait ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isPortrait ? [
            Colors.white.withValues(alpha: 0.1),
            Colors.transparent,
          ] : [
            Colors.black.withValues(alpha: 0.2),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          // 返回按钮
          FocusableGlow(
            focusNode: controller.backButtonFocusNode,
            onTap: () => _handleBackNavigation(),
            borderRadius: BorderRadius.circular(12),
            child: GlassContainer(
              width: isPortrait ? 44 : 48,
              height: isPortrait ? 44 : 48,
              borderRadius: 12,
              isPortrait: isPortrait,
              child: Icon(
                Icons.arrow_back,
                color: isPortrait ? Colors.grey[800] : Colors.white,
                size: isPortrait ? 20 : 24,
              ),
            ),
          ),
          
          SizedBox(width: isPortrait ? 16 : 20),
          
          // 搜索框
          Expanded(
            child: _buildSearchInput(isPortrait),
          ),
          
          SizedBox(width: isPortrait ? 16 : 20),
          
          // 清除按钮
          Obx(() => AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: controller.keyword.value.isNotEmpty
                ? FocusableGlow(
                    key: const ValueKey('clear'),
                    focusNode: controller.clearButtonFocusNode,
                    onTap: controller.clearSearch,
                    borderRadius: BorderRadius.circular(12),
                    child: GlassContainer(
                      width: isPortrait ? 44 : 48,
                      height: isPortrait ? 44 : 48,
                      borderRadius: 12,
                      isPortrait: isPortrait,
                      child: Icon(
                        Icons.clear,
                        color: isPortrait ? Colors.grey[800] : Colors.white,
                        size: isPortrait ? 20 : 24,
                      ),
                    ),
                  )
                : SizedBox(
                    key: const ValueKey('empty'),
                    width: isPortrait ? 44 : 48,
                    height: isPortrait ? 44 : 48,
                  ),
          )),
        ],
      ),
    );
  }

  /// 构建搜索页主体内容
  Widget _buildSearchBody(bool isPortrait) {
    return Obx(() {
      // 如果没有搜索关键词，显示空状态
      if (controller.keyword.value.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search,
                size: 64,
                color: isPortrait ? Colors.grey[600] : Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                '输入关键词开始搜索',
                style: TextStyle(
                  color: isPortrait ? Colors.grey[600] : Colors.grey[400],
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }
      
      // 如果正在搜索，显示加载状态
      if (controller.isSearching.value) {
        return const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFF7BB0),
          ),
        );
      }
      
      // 如果有错误信息，显示错误
      if (controller.errorMessage.value.isNotEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: isPortrait ? Colors.grey[600] : Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                controller.errorMessage.value,
                style: TextStyle(
                  color: isPortrait ? Colors.grey[600] : Colors.grey[400],
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: controller.performSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7BB0),
                ),
                child: const Text('重试', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }
      
      // 显示搜索结果TabBarView
      if (controller.sites.isEmpty) {
        return Center(
          child: Text(
            '没有可用的搜索站点',
            style: TextStyle(
              color: isPortrait ? Colors.grey[600] : Colors.grey[400],
              fontSize: 16,
            ),
          ),
        );
      }
      
      return TabBarView(
        controller: controller.sourceTabController,
        physics: const NeverScrollableScrollPhysics(), // 禁用滑动切换，只允许点击导航
        children: controller.sites.map((site) {
          return SearchResultPage(
            key: ValueKey(site.id), // 稳定的key，避免重建
            controller: controller,
            siteId: site.id,
            siteName: site.name,
          );
        }).toList(),
      );
    });
  }

  /// 构建搜索TabBar - 参考影视页的TabBar构建逻辑
  Widget _buildSearchTabBar(bool isPortrait) {
    if (kDebugMode) {
      print('🔍 SearchPage: 构建TabBar, isPortrait=$isPortrait, sites数量=${controller.sites.length}');
      print('🔍 SearchPage: sites详情: ${controller.sites.map((s) => s.name).join(', ')}');
    }
    
    return TabBar(
      controller: controller.sourceTabController,
      isScrollable: true,
      // 禁用默认的焦点装饰，只使用我们自定义的FocusAwareTab效果
      splashFactory: NoSplash.splashFactory,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      tabs: controller.sites.asMap().entries.map((entry) {
        final index = entry.key;
        final site = entry.value;
        
        if (kDebugMode) {
          print('🔍 SearchPage: 创建Tab[$index] - ${site.name}, isPortrait=$isPortrait');
          if (index == 2) { // 第三个Tab (索引为2)
            print('🔍 SearchPage: ⚠️ 创建第三个Tab - ${site.name}');
          }
        }
        
        final tabContent = Text(
          site.name,
          style: TextStyle(
            fontFamily: AppTypography.systemFont,
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: 0.1,
          ),
        );

        if (kDebugMode) {
          print('🔍 SearchPage: Tab[$index] 开始构建子组件, isPortrait=$isPortrait');
        }

        return Tab(
          height: isPortrait ? 36 : 40,
          // 竖屏使用与主导航一致的方形高亮，横屏使用药丸效果
          child: isPortrait 
              ? Builder(
                  builder: (context) {
                    if (kDebugMode) {
                      print('🏗️ SearchPage: 构建Tab[$index](${site.name})的竖屏焦点组件');
                    }
                    return _PortraitFocusHighlightWithIndex(
                      index: index,
                      siteName: site.name,
                      child: tabContent,
                    );
                  },
                )
              : FocusAwareTab(child: tabContent),
        );
      }).toList(),
      // 根据屏幕方向调整颜色
      labelColor: isPortrait ? Colors.grey[800] : Colors.white,
      unselectedLabelColor: isPortrait ? Colors.grey[600] : Colors.white.withValues(alpha: 0.7),
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: Colors.transparent,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(
          color: isPortrait ? Colors.grey[800]! : Colors.white,
          width: 3,
        ),
        insets: const EdgeInsets.symmetric(horizontal: 16),
      ),
      padding: const EdgeInsets.only(left: 16),
      tabAlignment: TabAlignment.start,
      labelPadding: EdgeInsets.symmetric(
        horizontal: isPortrait ? 12 : 16,
      ),
    );
  }

  /// 处理键盘事件
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        if (controller.clearButtonFocusNode.hasFocus) {
          controller.searchFocusNode.requestFocus();
          return KeyEventResult.handled;
        }
        if (controller.searchFocusNode.hasFocus) {
          controller.backButtonFocusNode.requestFocus();
          return KeyEventResult.handled;
        }
        break;
      case LogicalKeyboardKey.arrowRight:
        if (controller.backButtonFocusNode.hasFocus) {
          controller.searchFocusNode.requestFocus();
          return KeyEventResult.handled;
        }
        if (controller.searchFocusNode.hasFocus && controller.keyword.value.isNotEmpty) {
          controller.clearButtonFocusNode.requestFocus();
          return KeyEventResult.handled;
        }
        break;
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.enter:
        if (controller.searchFocusNode.hasFocus) {
          controller.performSearch();
          return KeyEventResult.handled;
        } else if (controller.clearButtonFocusNode.hasFocus) {
          controller.clearSearch();
          return KeyEventResult.handled;
        } else if (controller.backButtonFocusNode.hasFocus) {
          _handleBackNavigation();
          return KeyEventResult.handled;
        }
        break;
      case LogicalKeyboardKey.escape:
      case LogicalKeyboardKey.goBack:
        // 不拦截返回键，让 BackButtonHandler 处理
        return KeyEventResult.ignored;
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.ignored;
  }

  /// 处理手动点击返回按钮的逻辑
  void _handleBackNavigation() {
    // 如果正在搜索，先取消搜索状态
    if (controller.isSearching.value) {
      return; // 搜索中不允许返回
    }
    
    // 手动点击返回按钮，直接返回
    Get.back();
  }

  /// 构建搜索输入框
  Widget _buildSearchInput(bool isPortrait) {
    return Obx(() {
      final isFocused = controller.focusedArea.value == 'search';
      
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuint,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isPortrait ? 24 : 28),
          boxShadow: isFocused
              ? [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.15),
                    blurRadius: 12,
                    spreadRadius: 0,
                    offset: const Offset(0, 0),
                  ),
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 0),
                  ),
                ]
              : [],
        ),
        child: GlassContainer(
          height: isPortrait ? 48 : 56,
          borderRadius: isPortrait ? 24 : 28,
          isPortrait: isPortrait,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isPortrait ? 24 : 28),
              border: Border.all(
                color: isFocused 
                    ? (isPortrait ? Colors.grey.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.4))
                    : (isPortrait ? Colors.grey.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.1)),
                width: isFocused ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // 搜索图标或进度条
                Padding(
                  padding: EdgeInsets.only(
                    left: isPortrait ? 16 : 20,
                    right: isPortrait ? 10 : 12,
                  ),
                  child: controller.isSearching.value
                      ? SizedBox(
                          width: isPortrait ? 16 : 20,
                          height: isPortrait ? 16 : 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isPortrait ? Colors.grey[700]! : Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        )
                      : Icon(
                          Icons.search,
                          color: isPortrait ? Colors.grey[600] : Colors.white.withValues(alpha: 0.7),
                          size: isPortrait ? 16 : 20,
                        ),
                ),
                
                // 输入框
                Expanded(
                  child: TextField(
                    controller: controller.textController,
                    focusNode: controller.searchFocusNode,
                    autofocus: true,
                    style: AppTypography.bodyLarge.copyWith(
                      color: isPortrait ? Colors.grey[800] : Colors.white,
                      fontSize: isPortrait ? 14 : 16,
                    ),
                    decoration: InputDecoration(
                      hintText: '搜索视频内容...',
                      hintStyle: TextStyle(
                        color: isPortrait ? Colors.grey[500] : Colors.white.withValues(alpha: 0.5),
                        fontSize: isPortrait ? 14 : 16,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: isPortrait ? 12 : 16,
                      ),
                    ),
                    onSubmitted: (_) => controller.performSearch(),
                  ),
                ),
                
                SizedBox(width: isPortrait ? 16 : 20),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// 带索引信息的竖屏焦点高亮组件
class _PortraitFocusHighlightWithIndex extends StatefulWidget {
  final Widget child;
  final int index;
  final String siteName;
  
  const _PortraitFocusHighlightWithIndex({
    required this.child,
    required this.index,
    required this.siteName,
  });

  @override
  State<_PortraitFocusHighlightWithIndex> createState() {
    if (kDebugMode) {
      print('🎯 PortraitFocusHighlightWithIndex: 创建状态 Tab[$index]($siteName)');
    }
    return _PortraitFocusHighlightWithIndexState();
  }
}

class _PortraitFocusHighlightWithIndexState extends State<_PortraitFocusHighlightWithIndex> {
  FocusNode? _focusNode;
  bool _isFocused = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final focusNode = Focus.of(context);
    if (_focusNode != focusNode) {
      if (kDebugMode) {
        print('🔥 Tab[${widget.index}](${widget.siteName}): FocusNode切换 ${_focusNode.hashCode} -> ${focusNode.hashCode}');
      }
      
      _focusNode?.removeListener(_onFocusChanged);
      _focusNode = focusNode;
      _focusNode?.addListener(_onFocusChanged);
      
      if (_focusNode != null && _isFocused != _focusNode!.hasFocus) {
        _isFocused = _focusNode!.hasFocus;
        
        if (kDebugMode) {
          print('🔥 Tab[${widget.index}](${widget.siteName}): 初始化状态 $_isFocused, FocusNode=${_focusNode.hashCode}');
        }
      }
    } else {
      if (kDebugMode) {
        print('🔥 Tab[${widget.index}](${widget.siteName}): FocusNode未变化 ${focusNode.hashCode}');
      }
    }
  }

  @override
  void dispose() {
    if (kDebugMode) {
      print('🔥 Tab[${widget.index}](${widget.siteName}): dispose');
    }
    _focusNode?.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted && _isFocused != _focusNode?.hasFocus) {
      final newFocus = _focusNode!.hasFocus;
      
      if (kDebugMode) {
        if (widget.index == 2) { // 特别关注第三个Tab
          print('🔥 ⚠️ Tab[${widget.index}](${widget.siteName}): 焦点变化 $_isFocused -> $newFocus');
        } else {
          print('🔥 Tab[${widget.index}](${widget.siteName}): 焦点变化 $_isFocused -> $newFocus');
        }
      }
      
      setState(() {
        _isFocused = newFocus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: _isFocused
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.black.withValues(alpha: 0.08),
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.3),
                width: 1,
              ),
            )
          : null,
      child: widget.child,
    );
  }
}

/// 竖屏焦点高亮组件（备用，保持兼容性）
class _PortraitFocusHighlight extends StatefulWidget {
  final Widget child;
  
  const _PortraitFocusHighlight({
    required this.child,
  });

  @override
  State<_PortraitFocusHighlight> createState() => _PortraitFocusHighlightState();
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: _isFocused
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.black.withValues(alpha: 0.08),
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.3),
                width: 1,
              ),
            )
          : null,
      child: widget.child,
    );
  }
}


/// 搜索结果页面 - 参考影视页的VideoScrollPage架构
class SearchResultPage extends StatefulWidget {
  final search_ctrl.SearchController controller;
  final String siteId;
  final String siteName;
  
  const SearchResultPage({
    super.key,
    required this.controller,
    required this.siteId,
    required this.siteName,
  });

  @override
  State<SearchResultPage> createState() => _SearchResultPageState();
}

class _SearchResultPageState extends State<SearchResultPage> with AutomaticKeepAliveClientMixin {
  late ScrollController _scrollController;
  bool _isHorizontalLayout = true; // 默认横向布局，会根据图片检测动态调整
  
  // 为网格中的每个项目创建和管理FocusNode - 参考影视页
  final Map<int, FocusNode> _focusNodes = {};
  
  @override
  bool get wantKeepAlive => true; // 保持页面状态不被销毁
  
  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller.getScrollController(widget.siteId);
    
    // 监听搜索结果变化，当数据更新时检测第一个视频的封面图 - 参考影视页
    ever(widget.controller.sourceResults, (Map<String, List> data) {
      final videoList = data[widget.siteId] ?? [];
      _checkFirstImageOrientation(videoList);
    });
    
    // 初始检测
    final currentVideoList = widget.controller.sourceResults[widget.siteId] ?? [];
    _checkFirstImageOrientation(currentVideoList);
  }
  
  /// 优化的图片方向检测机制 - 完全参考影视页实现
  Future<void> _checkFirstImageOrientation(List videoList) async {
    if (videoList.isEmpty) return;
    
    final firstVideo = videoList.first;
    final imageUrl = firstVideo.vodPic; // SearchResult对象的属性
    if (imageUrl == null || imageUrl.isEmpty) return;
    
    // 搜索页目前没有图片缓存机制，直接检测
    try {
      // 简化版本的图片检测，如果需要缓存可以后续添加
      final image = await _loadImageInfo(imageUrl);
      if (image != null) {
        final isHorizontal = image.image.width > image.image.height;
        
        if (mounted && _isHorizontalLayout != isHorizontal) {
          if (kDebugMode) {
            print('🖼️ SearchResultPage[${widget.siteId}]: 图片方向检测 $_isHorizontalLayout -> $isHorizontal');
          }
          setState(() {
            _isHorizontalLayout = isHorizontal;
          });
        }
      }
    } catch (e) {
      // 如果图片加载失败，保持默认布局
      if (kDebugMode) {
        print('🖼️ SearchResultPage[${widget.siteId}]: 检测图片方向失败: $e');
      }
    }
  }
  
  /// 简化的图片信息加载
  Future<ImageInfo?> _loadImageInfo(String imageUrl) async {
    try {
      final imageProvider = NetworkImage(imageUrl);
      final completer = Completer<ImageInfo?>();
      final imageStream = imageProvider.resolve(const ImageConfiguration());
      
      late ImageStreamListener listener;
      listener = ImageStreamListener(
        (ImageInfo info, bool synchronousCall) {
          if (!completer.isCompleted) {
            completer.complete(info);
          }
          imageStream.removeListener(listener);
        },
        onError: (exception, stackTrace) {
          if (!completer.isCompleted) {
            completer.complete(null);
          }
          imageStream.removeListener(listener);
        },
      );
      
      imageStream.addListener(listener);
      
      // 设置超时
      Future.delayed(const Duration(seconds: 5), () {
        if (!completer.isCompleted) {
          completer.complete(null);
          imageStream.removeListener(listener);
        }
      });
      
      return await completer.future;
    } catch (e) {
      return null;
    }
  }
  
  @override
  void dispose() {
    // 销毁所有通过此状态管理的FocusNode
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    // 不要在这里dispose _scrollController，因为它由SearchController管理
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用 super.build
    
    final windowController = Get.find<WindowController>();
    final isPortrait = windowController.isPortrait.value;
    
    return Obx(() {
      final results = widget.controller.sourceResults[widget.siteId] ?? [];
      final isLoading = widget.controller.isSiteLoading(widget.siteId);
      
      if (isLoading && results.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFF7BB0),
          ),
        );
      }
      
      if (results.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: isPortrait ? Colors.grey[600] : Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                '此站点暂无搜索结果',
                style: TextStyle(
                  color: isPortrait ? Colors.grey[600] : Colors.grey[400],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      }
      
      // 将SearchResult转换为VideoGridWidget需要的格式
      final videoList = results.map((result) => {
        'vod_id': result.vodId,
        'vod_name': result.vodName,
        'vod_pic': result.vodPic,
        'vod_remarks': result.vodRemarks,
      }).toList();
      
      return RefreshIndicator(
        color: const Color(0xFFFF7BB0),
        backgroundColor: Colors.grey[900],
        onRefresh: () async {
          await widget.controller.performSearch();
        },
        child: VideoGridWidget(
          videoList: videoList,
          scrollController: _scrollController,
          isPortrait: isPortrait,
          isHorizontalLayout: _isHorizontalLayout,
          showLoadMore: false, // 搜索结果通常不需要加载更多
          isLoadingMore: false,
          hasMore: false,
          emptyMessage: "此站点暂无搜索结果",
          onVideoTap: (video) {
            // 获取当前选中的搜索站点并切换DataSource
            final currentSite = widget.controller.selectedSiteId.value;
            DataSource(siteId: currentSite); // 切换到对应站点
            
            Get.toNamed(
              AppRoutes.videoDetail,
              parameters: {'videoId': video['vod_id'] ?? ''},
            );
          },
        ),
      );
    });
  }
}

