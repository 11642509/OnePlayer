import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:get/get.dart';
import '../../../shared/widgets/backgrounds/optimized_cosmic_background.dart';
import '../../../shared/widgets/backgrounds/fresh_cosmic_background.dart';
import '../../../shared/widgets/common/glass_container.dart';
import '../../../shared/widgets/video/video_grid_widget.dart';
import '../../../app/theme/typography.dart';
import '../../../core/remote_control/focusable_item.dart';
import '../../../core/remote_control/focus_aware_tab.dart';
import '../../../app/routes/app_routes.dart';
import '../../../shared/controllers/window_controller.dart';
import '../controllers/search_controller.dart' as search_ctrl;
// 添加影视页的控制器
import '../../video_on_demand/controllers/vod_controller.dart';

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
      // 如果没有搜索关键词，显示影视页内容
      if (controller.keyword.value.isEmpty) {
        return _buildMoviePageContent(isPortrait);
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
          child: isPortrait ? tabContent : FocusAwareTab(child: tabContent),
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

  /// 构建影视页完整内容 - 当没有搜索时显示
  Widget _buildMoviePageContent(bool isPortrait) {
    // 使用影视页的VodController
    final controller = Get.put(VodController(), permanent: true);
    
    // 分离AppBar构建，减少重建范围
    PreferredSizeWidget buildAppBar() {
      return PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Obx(() {
          final isPortrait = Get.find<WindowController>().isPortrait.value;
          const backgroundColor = Colors.transparent;
          
          return AppBar(
            backgroundColor: backgroundColor,
            elevation: 0,
            automaticallyImplyLeading: false,
            toolbarHeight: isPortrait ? 48 : null,
            title: SizedBox(
              height: isPortrait ? 36 : 40,
              width: double.infinity,
              child: controller.tabController != null ? _buildMovieTabBar(isPortrait, controller) : const SizedBox(),
            ),
            titleSpacing: 0,
            centerTitle: false,
          );
        }),
      );
    }
    
    // 主体内容构建
    Widget buildBody() {
      return controller.tabController != null ? TabBarView(
        controller: controller.tabController,
        children: controller.classList.map((category) {
          final typeId = category['type_id'] as String;
          final typeName = category['type_name'] as String;
          
          return VideoScrollPage(
            key: ValueKey(typeName),
            controller: controller,
            typeName: typeName,
            typeId: typeId,
          );
        }).toList(),
      ) : const SizedBox();
    }
    
    return Obx(() {
      const backgroundColor = Colors.transparent;
          
      if (controller.isLoading.value && controller.homeData.isEmpty) {
        return Scaffold(
          backgroundColor: backgroundColor,
          body: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFF7BB0),
            ),
          ),
        );
      }
      
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: buildAppBar(),
        body: buildBody(),
      );
    });
  }

  /// 构建影视页TabBar
  Widget _buildMovieTabBar(bool isPortrait, VodController vodController) {
    return TabBar(
      controller: vodController.tabController,
      isScrollable: true,
      tabs: vodController.classList.map((item) {
        final tabContent = Text(
          item['type_name'] as String,
          style: TextStyle(
            fontFamily: AppTypography.systemFont,
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: 0.1,
          ),
        );

        return Tab(
          height: isPortrait ? 36 : 40,
          child: isPortrait ? tabContent : FocusAwareTab(child: tabContent),
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
          Get.back();
          return KeyEventResult.handled;
        }
        break;
      case LogicalKeyboardKey.escape:
      case LogicalKeyboardKey.goBack:
        Get.back();
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.ignored;
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
          FocusableItem(
            focusNode: controller.backButtonFocusNode,
            onSelected: () => Get.back(),
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
                ? FocusableItem(
                    key: const ValueKey('clear'),
                    focusNode: controller.clearButtonFocusNode,
                    onSelected: controller.clearSearch,
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

// 独立的视频滚动页面组件，使用 AutomaticKeepAliveClientMixin 保持状态 - 完全复制影视页
class VideoScrollPage extends StatefulWidget {
  final VodController controller;
  final String typeName;
  final String typeId;
  
  const VideoScrollPage({
    super.key,
    required this.controller,
    required this.typeName,
    required this.typeId,
  });

  @override
  State<VideoScrollPage> createState() => _VideoScrollPageState();
}

class _VideoScrollPageState extends State<VideoScrollPage> with AutomaticKeepAliveClientMixin {
  late ScrollController _scrollController;
  bool _isHorizontalLayout = true; // 默认横向布局
  
  // 为网格中的每个项目创建和管理FocusNode
  final Map<int, FocusNode> _focusNodes = {};
  
  @override
  bool get wantKeepAlive => true; // 保持页面状态不被销毁

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller.getScrollController(widget.typeName);
    _setupScrollListener();
    
    // 监听数据变化，当数据更新时检测第一个视频的封面图
    ever(widget.controller.categoryData, (Map<String, List<dynamic>> data) {
      final videoList = data[widget.typeName] ?? [];
      _checkFirstImageOrientation(videoList);
    });
    
    // 初始检测
    final currentVideoList = widget.controller.categoryData[widget.typeName] ?? [];
    _checkFirstImageOrientation(currentVideoList);
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      // 滚动到接近底部时加载更多
      if (_scrollController.position.pixels / _scrollController.position.maxScrollExtent > 0.8) {
        // 非主页且有更多数据才加载
        if (widget.typeName != "主页") {
          widget.controller.loadMoreData(widget.typeName);
        }
      }
    });
  }
  
  /// 优化的图片方向检测机制，使用缓存避免重复检测
  Future<void> _checkFirstImageOrientation(List<dynamic> videoList) async {
    if (videoList.isEmpty) return;
    
    final firstVideo = videoList.first;
    final imageUrl = firstVideo['vod_pic'];
    if (imageUrl == null || imageUrl.isEmpty) return;
    
    // 使用controller的缓存获取图片信息，避免重复网络请求
    try {
      final image = await widget.controller.getCachedImageFuture(widget.typeName, imageUrl);
      final isHorizontal = image.width > image.height;
      
      if (mounted && _isHorizontalLayout != isHorizontal) {
        setState(() {
          _isHorizontalLayout = isHorizontal;
        });
      }
    } catch (e) {
      // 如果图片加载失败，保持默认布局
      if (kDebugMode) {
        print('检测图片方向失败: $e');
      }
    }
  }

  @override
  void dispose() {
    // 销毁所有通过此状态管理的FocusNode
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    // 不要在这里dispose _scrollController，因为它由VodController管理
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用 super.build
    
    return Obx(() {
      // 如果是主页，使用HomeData的数据
      if (widget.typeId == "0") {
        if (widget.controller.categoryData.containsKey("主页") && widget.controller.categoryData["主页"]!.isNotEmpty) {
          return _buildVideoScrollContent(widget.controller.categoryData["主页"]!);
        } else if (widget.controller.homeData.isNotEmpty && widget.controller.homeData.containsKey('list')) {
          // 缓存首页数据 - 使用调度器避免在build期间更新
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.controller.categoryData["主页"] = widget.controller.homeData['list'] as List;
          });
          return _buildVideoScrollContent(widget.controller.homeData['list'] as List);
        } else {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFF7BB0), // B站粉色
            ),
          );
        }
      } else {
        // 如果已有缓存数据，直接显示
        if (widget.controller.categoryData.containsKey(widget.typeName) && widget.controller.categoryData[widget.typeName]!.isNotEmpty) {
          return _buildVideoScrollContent(widget.controller.categoryData[widget.typeName]!);
        }
        
        // 否则显示加载状态，并触发数据加载
        widget.controller.ensureCategoryDataLoaded(widget.typeName);
        
        // 检查是否正在加载
        final isCurrentlyLoading = widget.controller.categoryLoadingStates[widget.typeName] ?? false;
        if (isCurrentlyLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFF7BB0), // B站粉色
            ),
          );
        }
        
        // 如果没有数据且没有在加载，显示错误或空状态
        return const Center(
          child: Text(
            '暂无数据',
            style: TextStyle(color: Colors.grey),
          ),
        );
      }
    });
  }
  
  Widget _buildVideoScrollContent(List videoList) {
    if (videoList.isEmpty) {
      return widget.controller.isLoading.value
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7BB0)))
          : Center(child: Text("此分类下暂无内容", style: TextStyle(color: Colors.grey[600])));
    }

    final windowController = Get.find<WindowController>();
    final isPortrait = windowController.isPortrait.value;
    
    return RefreshIndicator(
      color: const Color(0xFFFF7BB0),
      backgroundColor: Colors.grey[900],
      onRefresh: () async {
        await widget.controller.refreshData(widget.typeName);
      },
      child: VideoGridWidget(
        videoList: videoList,
        scrollController: _scrollController,
        isPortrait: isPortrait,
        isHorizontalLayout: _isHorizontalLayout,
        showLoadMore: widget.typeName != "主页",
        isLoadingMore: widget.controller.loadingMoreStates[widget.typeName] ?? false,
        hasMore: widget.controller.hasMoreStates[widget.typeName] ?? false,
        onLoadMore: () => widget.controller.loadMoreData(widget.typeName),
        emptyMessage: "此分类下暂无内容",
      ),
    );
  }
}