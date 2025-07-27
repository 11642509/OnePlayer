import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../../../shared/controllers/window_controller.dart';
import '../controllers/vod_controller.dart';
import '../../../app/theme/typography.dart';
import '../../../core/remote_control/focus_aware_tab.dart';
import '../../../shared/widgets/video/video_grid_widget.dart';

class VideoOnDemandPage extends StatelessWidget {
  const VideoOnDemandPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用 Get.put 懒加载控制器，确保只创建一次
    final controller = Get.put(VodController(), permanent: true);
    final windowController = Get.find<WindowController>();
    
    // 分离AppBar构建，减少重建范围
    PreferredSizeWidget buildAppBar() {
      return PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Obx(() {
          final isPortrait = windowController.isPortrait.value;
          // AppBar背景也改为透明，与横屏一致
          const backgroundColor = Colors.transparent;
          
          return AppBar(
            backgroundColor: backgroundColor,
            elevation: 0,
            toolbarHeight: isPortrait ? 48 : null,
            title: SizedBox(
              height: isPortrait ? 36 : 40,
              width: double.infinity,
              child: controller.tabController != null ? _buildOptimizedTabBar(context, isPortrait) : const SizedBox(),
            ),
            // 统一使用左对齐，不再居中，以优化遥控器导航
            titleSpacing: 0,
            centerTitle: false,
          );
        }),
      );
    }
    
    // 主体内容构建，避免嵌套Obx
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
        // 影视页背景始终透明，与横屏一致
        const backgroundColor = Colors.transparent;
            
        // 如果数据正在加载中，显示加载指示器
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
  
  // 提取TabBar构建逻辑，避免重复计算，支持点击刷新
  Widget _buildOptimizedTabBar(BuildContext context, bool isPortrait) {
    final controller = Get.find<VodController>();
    
    return TabBar(
      controller: controller.tabController,
      isScrollable: true,
      // 禁用默认的焦点装饰，只使用我们自定义的FocusAwareTab效果
      splashFactory: NoSplash.splashFactory,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      onTap: (index) {
        // 检测是否点击了当前已选中的标签
        if (controller.tabController?.index == index) {
          // 如果是当前选中的标签，触发刷新
          controller.refreshCurrentCategory();
        }
        // 注意：不需要手动处理tab切换，TabBar会自动处理
      },
      tabs: controller.classList.map((item) {
        final tabContent = Text(
            item['type_name'] as String,
            style: TextStyle(
              fontFamily: AppTypography.systemFont, // 使用统一字体
              fontWeight: FontWeight.w600,
              // 统一使用16号字体，与主导航栏对齐
              fontSize: 16,
              letterSpacing: 0.1,
            ),
        );

        return Tab(
          height: isPortrait ? 36 : 40,
          // 竖屏使用与主导航一致的方形高亮，横屏使用药丸效果
          child: isPortrait 
              ? _PortraitFocusHighlight(child: tabContent)
              : FocusAwareTab(child: tabContent),
        );
      }).toList(),
      // 恢复为原来的颜色和指示器逻辑
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
      // 统一使用左侧内边距和起始对齐，优化遥控器导航
      padding: const EdgeInsets.only(left: 16),
      tabAlignment: TabAlignment.start,
      labelPadding: EdgeInsets.symmetric(
        horizontal: isPortrait ? 12 : 16,
      ),
    );
  }
  
}

// 独立的视频滚动页面组件，使用 AutomaticKeepAliveClientMixin 保持状态
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

/// 一个辅助组件，用于在竖屏模式下为Tab提供清晰的方形焦点高亮。
/// 与上方主导航保持一致的效果。
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