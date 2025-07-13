import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../../../shared/controllers/window_controller.dart';
import '../controllers/vod_controller.dart';
import '../../../app/routes/app_routes.dart';
import '../../../shared/utils/performance_manager.dart';
import '../../../app/theme/typography.dart';
import '../../../core/remote_control/focusable_item.dart';
import '../../../core/remote_control/focus_aware_tab.dart';

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
  
  // 提取TabBar构建逻辑，避免重复计算
  Widget _buildOptimizedTabBar(BuildContext context, bool isPortrait) {
    final controller = Get.find<VodController>();
    
    return TabBar(
      controller: controller.tabController,
      isScrollable: true,
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
          // 仅在横屏模式下应用自定义的焦点效果
          child: isPortrait ? tabContent : FocusAwareTab(child: tabContent),
        );
      }).toList(),
      // 恢复为原来的颜色和指示器逻辑
      labelColor: isPortrait ? Colors.grey[800] : Colors.white,
      unselectedLabelColor: isPortrait ? Colors.grey[600] : Colors.white.withOpacity(0.7),
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
  bool get wantKeepAlive => true; // 保持页面状态不被销销

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

  /// 根据视频列表的大小，更新和管理FocusNode池
  void _updateFocusNodes(int listSize) {
    // 移除不再需要的节点的FocusNode
    final toRemove = _focusNodes.keys.where((i) => i >= listSize).toList();
    for (final i in toRemove) {
      _focusNodes.remove(i)?.dispose();
    }

    // 为新节点添加FocusNode
    for (var i = 0; i < listSize; i++) {
      if (!_focusNodes.containsKey(i)) {
        _focusNodes[i] = FocusNode(debugLabel: 'Item $i');
      }
    }
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

    // 直接使用我们的布局选择逻辑，不再需要FutureBuilder
    return _buildScrollableGrid(videoList, _isHorizontalLayout);
  }
  
  Widget _buildScrollableGrid(List videoList, bool isLandscapeLayout) {
    final windowController = Get.find<WindowController>();
    final isPortrait = windowController.isPortrait.value;
    
    return RefreshIndicator(
      color: const Color(0xFFFF7BB0),
      backgroundColor: Colors.grey[900],
      onRefresh: () async {
        await widget.controller.refreshData(widget.typeName);
      },
      child: _buildScrollableVideoGrid(videoList, isLandscapeLayout, isPortrait),
    );
  }
  
  Widget _buildScrollableVideoGrid(List videoList, bool isLandscapeLayout, bool isPortrait) {
    // 根据检测到的图片方向决定布局参数
    return Builder(builder: (context) {
      if (_isHorizontalLayout) {
        return _buildHorizontalCardGrid(videoList, isPortrait);
      } else {
        return _buildVerticalCardGrid(videoList, isPortrait);
      }
    });
  }
  
  /// 横向卡片网格布局 (适用于横向封面图)
  Widget _buildHorizontalCardGrid(List videoList, bool isPortrait) {
    // 横向卡片：横屏4列，竖屏2列
    int crossAxisCount = isPortrait ? 2 : 4;
    final double titleHeight = 40; // 增加标题高度以确保两行文字完整显示
    final double spacing = 4;
    
    return Builder(builder: (context) {
      final double screenWidth = MediaQuery.of(context).size.width;
      // 精确计算项目宽度，减去所有水平内边距和间距
      final double itemWidth = isPortrait 
          ? (screenWidth - 16 * 2 - 16) / 2 // (总宽 - 左右内边距 - 间距) / 列数
          : (screenWidth - 24 * 2 - 20 * 3) / 4; // (总宽 - 左右内边距 - 间距) / 列数
      
      // 横向卡片使用16:9比例
      final double imageHeight = itemWidth * 9 / 16;
      final double itemHeight = imageHeight + spacing + titleHeight;
      final double childAspectRatio = itemWidth / itemHeight;

      final int videoListLength = videoList.length;
      _updateFocusNodes(videoListLength);

      return Focus(
        onKey: (node, event) {
          if (event is! RawKeyDownEvent) return KeyEventResult.ignored;

          final currentIndex = _focusNodes.entries
              .firstWhere((entry) => entry.value.hasFocus, orElse: () => MapEntry(-1, FocusNode()))
              .key;

          if (currentIndex == -1) {
            return KeyEventResult.ignored;
          }

          int targetIndex = -1;
          
          switch (event.logicalKey) {
            case LogicalKeyboardKey.arrowUp:
              targetIndex = currentIndex - crossAxisCount;
              break;
            case LogicalKeyboardKey.arrowDown:
              targetIndex = currentIndex + crossAxisCount;
              break;
            case LogicalKeyboardKey.arrowLeft:
              if (currentIndex % crossAxisCount != 0) {
                targetIndex = currentIndex - 1;
              }
              break;
            case LogicalKeyboardKey.arrowRight:
              if ((currentIndex + 1) % crossAxisCount != 0 && currentIndex + 1 < videoListLength) {
                targetIndex = currentIndex + 1;
              }
              break;
            default:
              return KeyEventResult.ignored;
          }

          if (targetIndex >= 0 && targetIndex < videoListLength) {
            final targetNode = _focusNodes[targetIndex];
            if (targetNode != null) {
              targetNode.requestFocus();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (targetNode.context != null) {
                  Scrollable.ensureVisible(
                    targetNode.context!,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    alignment: 0.5, // 尽量将项目滚动到视口中间
                  );
                }
              });
            }
            return KeyEventResult.handled;
          }
          
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            return KeyEventResult.ignored; 
          }

          return KeyEventResult.handled;
        },
        child: GridView.builder(
        controller: _scrollController,
          padding: EdgeInsets.all(isPortrait ? 16 : 24), // 增加内边距
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
            crossAxisSpacing: isPortrait ? 16 : 20, // 增加水平间距
            mainAxisSpacing: isPortrait ? 20 : 24, // 增加垂直间距
        ),
        itemCount: videoList.length + (widget.typeName != "主页" ? 1 : 0),
        // 性能优化：大幅增加缓存，确保遥控器快速导航时项目不被回收
        cacheExtent: 99999,
        addAutomaticKeepAlives: true,
        addRepaintBoundaries: true,
        addSemanticIndexes: false, // 在不需要语义索引的情况下禁用
        itemBuilder: (context, index) {
          if (index == videoList.length && widget.typeName != "主页") {
            return _buildLoadMoreIndicator();
          }
          
          final video = videoList[index];
          // 使用稳定的key来优化widget复用
            return FocusableItem(
              autofocus: index == 0,
              focusNode: _focusNodes[index],
              onSelected: () {
                Get.toNamed(
                  AppRoutes.videoDetail,
                  parameters: {'videoId': video['vod_id']},
                );
              },
              child: _buildOptimizedVideoCard(
            video, 
            index, 
            itemWidth, 
            imageHeight, 
            titleHeight, 
            spacing, 
            isPortrait,
              ),
          );
        },
        ),
      );
    });
  }
  
  /// 纵向卡片网格布局 (适用于纵向封面图)
  Widget _buildVerticalCardGrid(List videoList, bool isPortrait) {
    // 纵向卡片：横屏4列，竖屏2列
    int crossAxisCount = isPortrait ? 2 : 4;
    final double titleHeight = 40; // 增加标题高度以确保两行文字完整显示
    final double spacing = 4;
    
    return Builder(builder: (context) {
      final double screenWidth = MediaQuery.of(context).size.width;
      // 精确计算项目宽度，减去所有水平内边距和间距
      final double itemWidth = isPortrait 
          ? (screenWidth - 16 * 2 - 16) / 2 // (总宽 - 左右内边距 - 间距) / 列数
          : (screenWidth - 24 * 2 - 20 * 3) / 4; // (总宽 - 左右内边距 - 间距) / 列数
      
      // 纵向卡片也使用16:9比例，但是是纵向的16:9
      final double imageHeight = itemWidth * 16 / 9; // 纵向16:9
      final double itemHeight = imageHeight + spacing + titleHeight;
      final double childAspectRatio = itemWidth / itemHeight;

      final int videoListLength = videoList.length;
      _updateFocusNodes(videoListLength);

      return Focus(
        onKey: (node, event) {
          if (event is! RawKeyDownEvent) return KeyEventResult.ignored;

          final currentIndex = _focusNodes.entries
              .firstWhere((entry) => entry.value.hasFocus, orElse: () => MapEntry(-1, FocusNode()))
              .key;

          if (currentIndex == -1) {
            return KeyEventResult.ignored;
          }

          int targetIndex = -1;
          
          switch (event.logicalKey) {
            case LogicalKeyboardKey.arrowUp:
              targetIndex = currentIndex - crossAxisCount;
              break;
            case LogicalKeyboardKey.arrowDown:
              targetIndex = currentIndex + crossAxisCount;
              break;
            case LogicalKeyboardKey.arrowLeft:
              if (currentIndex % crossAxisCount != 0) {
                targetIndex = currentIndex - 1;
              }
              break;
            case LogicalKeyboardKey.arrowRight:
              if ((currentIndex + 1) % crossAxisCount != 0 && currentIndex + 1 < videoListLength) {
                targetIndex = currentIndex + 1;
              }
              break;
            default:
              return KeyEventResult.ignored;
          }

          if (targetIndex >= 0 && targetIndex < videoListLength) {
            final targetNode = _focusNodes[targetIndex];
            if (targetNode != null) {
              targetNode.requestFocus();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (targetNode.context != null) {
                  Scrollable.ensureVisible(
                    targetNode.context!,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    alignment: 0.5, // 尽量将项目滚动到视口中间
                  );
                }
              });
            }
            return KeyEventResult.handled;
          }
          
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            return KeyEventResult.ignored; 
          }

          return KeyEventResult.handled;
        },
        child: GridView.builder(
        controller: _scrollController,
          padding: EdgeInsets.all(isPortrait ? 16 : 24), // 增加内边距
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
            crossAxisSpacing: isPortrait ? 16 : 20, // 增加水平间距
            mainAxisSpacing: isPortrait ? 20 : 24, // 增加垂直间距
        ),
        itemCount: videoList.length + (widget.typeName != "主页" ? 1 : 0),
        // 性能优化：大幅增加缓存，确保遥控器快速导航时项目不被回收
        cacheExtent: 99999,
        addAutomaticKeepAlives: true,
        addRepaintBoundaries: true,
        addSemanticIndexes: false, // 在不需要语义索引的情况下禁用
        itemBuilder: (context, index) {
          if (index == videoList.length && widget.typeName != "主页") {
            return _buildLoadMoreIndicator();
          }
          
          final video = videoList[index];
          // 使用稳定的key来优化widget复用
            return FocusableItem(
              autofocus: index == 0,
              focusNode: _focusNodes[index],
              onSelected: () {
                Get.toNamed(
                  AppRoutes.videoDetail,
                  parameters: {'videoId': video['vod_id']},
                );
              },
              child: _buildOptimizedVideoCard(
            video, 
            index, 
            itemWidth, 
            imageHeight, 
            titleHeight, 
            spacing, 
            isPortrait,
              ),
          );
        },
        ),
      );
    });
  }
  
  Widget _buildLoadMoreIndicator() {
    return Obx(() {
      final isLoadingMore = widget.controller.loadingMoreStates[widget.typeName] ?? false;
      final hasMore = widget.controller.hasMoreStates[widget.typeName] ?? false;
      
      if (!hasMore) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: const Center(
            child: Text(
              '没有更多数据了',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
        );
      }
      
      if (isLoadingMore) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Color(0xFFFF7BB0),
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  '加载中...',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      
      return const SizedBox.shrink();
    });
  }
  
  // 优化的VideoCard构建方法，减少不必要的重建
  Widget _buildOptimizedVideoCard(dynamic video, int index, double itemWidth, double imageHeight, double titleHeight, double spacing, bool isPortrait) {
    // 使用稳定的key提高复用性能
    final videoId = video['vod_id']?.toString() ?? index.toString();
    
    return RepaintBoundary(
      key: ValueKey(videoId),
      child: _buildVideoCard(video, index, itemWidth, imageHeight, titleHeight, spacing, isPortrait),
    );
  }
  
  Widget _buildVideoCard(dynamic video, int index, double itemWidth, double imageHeight, double titleHeight, double spacing, bool isPortrait) {
    final windowController = Get.find<WindowController>();
    final isPortraitMode = windowController.isPortrait.value;
    
    // 根据屏幕方向调整文字颜色：竖屏用深色，横屏用白色
    final textColor = isPortraitMode ? Colors.grey[800]! : Colors.white;
    // 卡片背景也根据模式调整
    final cardBgColor = isPortraitMode 
        ? Colors.white.withValues(alpha: 0.15) 
        : Colors.black.withValues(alpha: 0.15);
    final performance = PerformanceManager.to;

    final String? remarks = video['vod_remarks'];
    final bool shouldShowRemarks = remarks != null && remarks.length <= 30;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Card(
          elevation: isPortrait ? 2 : 0,
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isPortrait ? 8 : 12),
          ),
          color: cardBgColor,
          child: Container(
            width: itemWidth,
            height: imageHeight,
            decoration: !isPortrait ? BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 0.3,
              ),
              // 使用性能管理器优化阴影
              boxShadow: performance.getOptimizedShadow(isCard: true),
            ) : null,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(isPortrait ? 8 : 12),
                  child: _buildOptimizedImage(
                    video['vod_pic'],
                    itemWidth,
                    imageHeight,
                    isPortrait,
                  ),
                ),
                if (shouldShowRemarks)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withAlpha(179),
                            Colors.black.withAlpha(51),
                          ],
                        ),
                      ),
                      child: Text(
                        remarks,
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Get.toNamed(
                        AppRoutes.videoDetail,
                        parameters: {'videoId': video['vod_id']},
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: spacing),
        SizedBox(
          height: titleHeight,
          width: itemWidth,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isPortrait ? 4 : 6),
            child: Text(
              video['vod_name'],
              style: AppTypography.videoTitle.copyWith(
                fontSize: isPortrait ? 13 : 14,
                color: textColor,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.start,
            ),
          ),
        ),
      ],
    );
  }
  
  // 构建优化的图片组件，减少重复加载
  Widget _buildOptimizedImage(String imageUrl, double width, double height, bool isPortrait) {
    // 使用Image.network的原生缓存机制，并优化加载参数
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      // 启用缓存，减少网络请求
      cacheWidth: (width * 2).round(), // 2倍像素密度
      cacheHeight: (height * 2).round(),
      // 优化加载性能
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width,
          height: height,
          color: Colors.grey[850],
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF7BB0)),
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        width: width,
        height: height,
        color: Colors.grey[800],
        child: Icon(
          Icons.image_not_supported,
          color: Colors.grey[600],
          size: 24, // 减小图标尺寸
        ),
      ),
      // 设置内存缓存限制，避免内存过载
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 200),
          child: child,
        );
      },
    );
  }
}