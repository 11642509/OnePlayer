import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'dart:ui' as ui;
import 'dart:async';
import '../../../shared/controllers/window_controller.dart';
import '../controllers/vod_controller.dart';
import 'video_detail_page.dart';

class VideoOnDemandPage extends StatelessWidget {
  const VideoOnDemandPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用 Get.put 懒加载控制器，确保只创建一次
    final controller = Get.put(VodController(), permanent: true);
    final windowController = Get.find<WindowController>();
    
    return Obx(() {
      // 根据窗口方向设置背景色：横屏透明，竖屏浅灰色(与PortraitHomeLayout一致)
      final backgroundColor = !windowController.isPortrait.value 
          ? Colors.transparent // 横屏透明，让主背景透过
          : const Color(0xFFF6F7F8); // 与PortraitHomeLayout一致的浅灰色背景
          
      // 如果数据正在加载中，显示加载指示器
      if (controller.isLoading.value && controller.homeData.isEmpty) {
        return Scaffold(
          backgroundColor: backgroundColor,
          body: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFF7BB0), // B站粉色
            ),
          ),
        );
      }
      
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          // 根据屏幕方向调整AppBar样式
          toolbarHeight: windowController.isPortrait.value ? 48 : null, // 竖屏模式下调整高度
          // 使用B站风格的顶部导航，但内容是我们自己的分类
          title: SizedBox(
            height: windowController.isPortrait.value ? 36 : 40, // 竖屏模式下高度稍小
            width: double.infinity, // 确保宽度占满
            child: controller.tabController != null ? TabBar(
              controller: controller.tabController,
              isScrollable: true,
              tabs: controller.classList.map((item) {
                return Tab(
                  height: windowController.isPortrait.value ? 36 : 40, // 竖屏模式下高度稍小
                  child: Text(
                    item['type_name'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: windowController.isPortrait.value ? 15 : 16, // 竖屏模式下字体稍小
                    ),
                  ),
                );
              }).toList(),
              labelColor: const Color(0xFFFF7BB0), // B站粉色
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFFFF7BB0), // B站粉色
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              indicator: UnderlineTabIndicator(
                borderSide: const BorderSide(
                  color: Color(0xFFFF7BB0),
                  width: 3,
                ),
                insets: EdgeInsets.symmetric(
                  horizontal: windowController.isPortrait.value ? 12 : 16, // 竖屏模式下指示器宽度稍小
                ),
              ),
              // 竖屏模式下靠左对齐
              padding: windowController.isPortrait.value 
                  ? const EdgeInsets.only(left: 16) 
                  : null,
              // 确保标签可以滚动
              tabAlignment: windowController.isPortrait.value 
                  ? TabAlignment.start  // 竖屏模式下靠左对齐
                  : TabAlignment.center, // 横屏模式下居中对齐
              // 调整标签间距
              labelPadding: EdgeInsets.symmetric(
                horizontal: windowController.isPortrait.value ? 12 : 16, // 竖屏模式下标签间距稍小
              ),
            ) : const SizedBox(),
          ),
          // 竖屏模式下让标题居左对齐
          titleSpacing: windowController.isPortrait.value ? 0 : null,
          centerTitle: !windowController.isPortrait.value, // 横屏居中，竖屏靠左
        ),
        body: controller.tabController != null ? TabBarView(
          controller: controller.tabController,
          children: controller.classList.map((category) {
            final typeId = category['type_id'] as String;
            final typeName = category['type_name'] as String;
            
            // 使用 VideoScrollPage 来包装每个分类页面，保持状态
            return VideoScrollPage(
              key: ValueKey(typeName), // 使用稳定的key
              controller: controller,
              typeName: typeName,
              typeId: typeId,
            );
          }).toList(),
        ) : const SizedBox(),
      );
    });
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
  
  /// 检测第一个视频封面图的方向，决定使用横向或纵向卡片布局
  Future<void> _checkFirstImageOrientation(List<dynamic> videoList) async {
    if (videoList.isEmpty) return;
    
    final firstVideo = videoList.first;
    final imageUrl = firstVideo['vod_pic'];
    if (imageUrl == null || imageUrl.isEmpty) return;
    
    try {
      // 获取图片信息
      final image = await _loadImageFromNetwork(imageUrl);
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
  
  /// 从网络加载图片并获取尺寸信息
  Future<ui.Image> _loadImageFromNetwork(String url) async {
    final completer = Completer<ui.Image>();
    final image = NetworkImage(url);
    
    image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(info.image);
      }, onError: (exception, stackTrace) {
        completer.completeError(exception);
      }),
    );
    
    return completer.future;
  }

  @override
  void dispose() {
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
      final double itemWidth = isPortrait 
          ? (screenWidth - 28) / 2 
          : (screenWidth - 58) / 4;
      
      // 横向卡片使用16:9比例
      final double imageHeight = itemWidth * 9 / 16;
      final double itemHeight = imageHeight + spacing + titleHeight;
      final double childAspectRatio = itemWidth / itemHeight;

      return GridView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(isPortrait ? 10 : 12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: isPortrait ? 8 : 10,
          mainAxisSpacing: isPortrait ? 12 : 16,
        ),
        itemCount: videoList.length + (widget.typeName != "主页" ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == videoList.length && widget.typeName != "主页") {
            return _buildLoadMoreIndicator();
          }
          
          final video = videoList[index];
          return _buildVideoCard(video, index, itemWidth, imageHeight, titleHeight, spacing, isPortrait);
        },
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
      final double itemWidth = isPortrait 
          ? (screenWidth - 28) / 2 
          : (screenWidth - 58) / 4;
      
      // 纵向卡片也使用16:9比例，但是是纵向的16:9
      final double imageHeight = itemWidth * 16 / 9; // 纵向16:9
      final double itemHeight = imageHeight + spacing + titleHeight;
      final double childAspectRatio = itemWidth / itemHeight;

      return GridView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(isPortrait ? 10 : 12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: isPortrait ? 8 : 10,
          mainAxisSpacing: isPortrait ? 12 : 16,
        ),
        itemCount: videoList.length + (widget.typeName != "主页" ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == videoList.length && widget.typeName != "主页") {
            return _buildLoadMoreIndicator();
          }
          
          final video = videoList[index];
          return _buildVideoCard(video, index, itemWidth, imageHeight, titleHeight, spacing, isPortrait);
        },
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
  
  Widget _buildVideoCard(dynamic video, int index, double itemWidth, double imageHeight, double titleHeight, double spacing, bool isPortrait) {
    final textColor = !isPortrait ? Colors.white : Colors.black;
    final cardBgColor = isPortrait ? Colors.white : Colors.black.withValues(alpha: 0.15);

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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 5,
                  offset: const Offset(0, 1),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, -0.5),
                ),
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.03),
                  blurRadius: 8,
                  spreadRadius: -2,
                  offset: const Offset(0, 0),
                ),
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.06),
                  blurRadius: 15,
                  spreadRadius: -3,
                  offset: const Offset(1, 1),
                ),
                BoxShadow(
                  color: Colors.yellow.withValues(alpha: 0.04),
                  blurRadius: 18,
                  spreadRadius: -5,
                  offset: const Offset(2, 2),
                ),
              ],
            ) : null,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(isPortrait ? 8 : 12),
                  child: Image.network(
                    video['vod_pic'],
                    width: itemWidth,
                    height: imageHeight,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => 
                      Container(
                        color: Colors.grey[800],
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[600],
                          size: 40,
                        ),
                      ),
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
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
                      Get.to(() => VideoDetailPage(videoId: video['vod_id']));
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
              style: TextStyle(
                fontSize: isPortrait ? 16 : 15, // 进一步增大字体，与大尺寸卡片更协调
                fontWeight: FontWeight.w500, // 统一使用中等粗细
                color: textColor,
                height: 1.3, // 减小行高以更好地适应两行文本
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.start, // 文本左对齐
            ),
          ),
        ),
      ],
    );
  }
}