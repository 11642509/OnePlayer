import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../shared/widgets/backgrounds/optimized_cosmic_background.dart';
import '../../../shared/widgets/backgrounds/fresh_cosmic_background.dart';
import '../../../shared/widgets/common/glass_container.dart';
import '../../../shared/widgets/video/video_grid_widget.dart';
import '../../../app/theme/typography.dart';
import '../../../core/remote_control/focusable_glow.dart';
import '../../../core/remote_control/focus_aware_tab.dart';
import '../../../app/routes/app_routes.dart';
import '../../../shared/controllers/window_controller.dart';
import '../controllers/search_controller.dart' as search_ctrl;

/// 搜索页面 - 保留搜索功能，解决阴影效果问题
class SearchPage extends GetView<search_ctrl.SearchController> {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final windowController = Get.find<WindowController>();
    
    return Obx(() {
      final isPortrait = windowController.isPortrait.value;
      
      Widget buildContent() {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: isPortrait 
              ? FreshCosmicBackground(
                  child: _buildResponsiveLayout(isPortrait),
                )
              : OptimizedCosmicBackground(
                  child: _buildResponsiveLayout(isPortrait),
                ),
        );
      }
      
      if (isPortrait) {
        // 竖屏模式：使用默认主题
        return buildContent();
      } else {
        // 横屏模式：使用深色主题，与影视页完全一致，确保阴影效果相同
        return Theme(
          data: Theme.of(context).copyWith(
            brightness: Brightness.dark,
          ),
          child: buildContent(),
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
      child: Column(
        children: [
          _buildHeader(isPortrait),
          Expanded(
            child: _buildSearchContent(isPortrait),
          ),
        ],
      ),
    );
  }

  /// 构建搜索内容 - 根据搜索状态显示不同内容
  Widget _buildSearchContent(bool isPortrait) {
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
      
      // 显示搜索结果
      return _buildSearchResults(isPortrait);
    });
  }

  /// 构建搜索结果
  Widget _buildSearchResults(bool isPortrait) {
    return Obx(() {
      if (controller.sources.isEmpty) {
        return Center(
          child: Text(
            '没有可用的搜索源',
            style: TextStyle(
              color: isPortrait ? Colors.grey[600] : Colors.grey[400],
              fontSize: 16,
            ),
          ),
        );
      }

      return DefaultTabController(
        length: controller.sources.length,
        child: Column(
          children: [
            // 搜索源TabBar
            SizedBox(
              height: kToolbarHeight,
              child: _buildSearchTabBar(isPortrait),
            ),
            // 搜索结果TabBarView
            Expanded(
              child: _buildSearchTabBarView(isPortrait),
            ),
          ],
        ),
      );
    });
  }

  /// 构建搜索TabBar
  Widget _buildSearchTabBar(bool isPortrait) {
    return TabBar(
      controller: controller.sourceTabController,
      isScrollable: true,
      // 禁用默认的焦点装饰，只使用我们自定义的FocusAwareTab效果
      splashFactory: NoSplash.splashFactory,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      tabs: controller.sources.map((source) {
        final resultCount = controller.getSourceResultCount(source.id);
        final isLoading = controller.isSourceLoading(source.id);
        
        final tabContent = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              source.name,
              style: TextStyle(
                fontFamily: AppTypography.systemFont,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                letterSpacing: 0.1,
              ),
            ),
            if (isLoading) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isPortrait ? Colors.grey[700]! : Colors.white,
                  ),
                ),
              ),
            ] else if (resultCount > 0) ...[
              const SizedBox(width: 4),
              Text(
                '($resultCount)',
                style: TextStyle(
                  fontSize: 12,
                  color: isPortrait ? Colors.grey[600] : Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        );

        return Tab(
          height: isPortrait ? 36 : 40,
          child: isPortrait 
              ? _PortraitFocusHighlight(child: tabContent)
              : FocusAwareTab(child: tabContent),
        );
      }).toList(),
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
      onTap: (index) {
        if (index < controller.sources.length) {
          final source = controller.sources[index];
          controller.selectSource(source.id);
        }
      },
    );
  }

  /// 构建搜索TabBarView
  Widget _buildSearchTabBarView(bool isPortrait) {
    return TabBarView(
      controller: controller.sourceTabController,
      children: controller.sources.map((source) {
        return _buildSourceResultPage(source.id, isPortrait);
      }).toList(),
    );
  }

  /// 构建单个搜索源的结果页面
  Widget _buildSourceResultPage(String sourceId, bool isPortrait) {
    return Obx(() {
      final results = controller.sourceResults[sourceId] ?? [];
      final isLoading = controller.isSourceLoading(sourceId);
      
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
                '此源暂无搜索结果',
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
          await controller.performSearch();
        },
        child: VideoGridWidget(
          videoList: videoList,
          scrollController: controller.getScrollController(sourceId),
          isPortrait: isPortrait,
          isHorizontalLayout: controller.isHorizontalLayout.value,
          showLoadMore: false, // 搜索结果通常不需要加载更多
          isLoadingMore: false,
          hasMore: false,
          emptyMessage: "此源暂无搜索结果",
          onVideoTap: (video) {
            Get.toNamed(
              AppRoutes.videoDetail,
              parameters: {'videoId': video['vod_id'] ?? ''},
            );
          },
        ),
      );
    });
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
        _handleBackNavigation();
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.ignored;
  }

  /// 统一处理返回导航逻辑，防止重复调用
  void _handleBackNavigation() {
    // 如果正在搜索，先取消搜索状态
    if (controller.isSearching.value) {
      return; // 搜索中不允许返回
    }
    
    // 确保只调用一次返回
    if (Get.isDialogOpen == true) {
      return; // 如果有对话框打开，不执行返回
    }
    
    Get.back();
  }

  /// 构建头部
  Widget _buildHeader(bool isPortrait) {
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

/// 一个辅助组件，用于在竖屏模式下为Tab提供清晰的方形焦点高亮。
/// 与影视页竖屏分类导航保持一致的效果。
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
              // 轻微的焦点高亮效果，类似测试页风格
              borderRadius: BorderRadius.circular(4),
              color: Colors.black.withValues(alpha: 0.08), // 轻微的深色高亮
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.3), // 轻微的边框
                width: 1,
              ),
            )
          : null,
      child: widget.child,
    );
  }
}

