import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../utils/performance_manager.dart';
import '../../../app/theme/typography.dart';
import '../../../core/remote_control/focusable_item.dart';
import '../../../app/routes/app_routes.dart';

/// 公共视频网格组件 - 支持横竖屏响应式布局
class VideoGridWidget extends StatefulWidget {
  final List videoList;
  final ScrollController? scrollController;
  final bool isPortrait;
  final bool isHorizontalLayout; // 图片方向：true=横版(16:9), false=竖版(9:16)
  final VoidCallback? onLoadMore;
  final bool showLoadMore;
  final bool isLoadingMore;
  final bool hasMore;
  final EdgeInsetsGeometry? padding;
  final String? emptyMessage;
  final Widget? customLoadingWidget;
  final Function(dynamic video)? onVideoTap;
  
  const VideoGridWidget({
    super.key,
    required this.videoList,
    required this.isPortrait,
    this.scrollController,
    this.isHorizontalLayout = true,
    this.onLoadMore,
    this.showLoadMore = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.padding,
    this.emptyMessage,
    this.customLoadingWidget,
    this.onVideoTap,
  });

  @override
  State<VideoGridWidget> createState() => _VideoGridWidgetState();
}

class _VideoGridWidgetState extends State<VideoGridWidget> {
  // 为网格中的每个项目创建和管理FocusNode
  final Map<int, FocusNode> _focusNodes = {};
  
  @override
  void dispose() {
    // 销毁所有通过此状态管理的FocusNode
    for (final node in _focusNodes.values) {
      node.dispose();
    }
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
        _focusNodes[i] = FocusNode(debugLabel: 'VideoGrid_Item_$i');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videoList.isEmpty) {
      return Center(
        child: Text(
          widget.emptyMessage ?? '暂无内容',
          style: TextStyle(
            color: widget.isPortrait ? Colors.grey[600] : Colors.grey[400],
            fontSize: 16,
          ),
        ),
      );
    }

    // 根据图片方向选择布局
    if (widget.isHorizontalLayout) {
      return _buildHorizontalCardGrid();
    } else {
      return _buildVerticalCardGrid();
    }
  }

  /// 横向卡片网格布局 (适用于横向封面图)
  Widget _buildHorizontalCardGrid() {
    // 横向卡片：横屏4列，竖屏2列
    int crossAxisCount = widget.isPortrait ? 2 : 4;
    final double titleHeight = 40;
    final double spacing = 4;
    
    return Builder(builder: (context) {
      final double screenWidth = MediaQuery.of(context).size.width;
      final EdgeInsetsGeometry padding = widget.padding ?? 
          EdgeInsets.all(widget.isPortrait ? 16 : 24);
      
      // 计算实际内边距值
      final paddingValue = padding.resolve(TextDirection.ltr);
      final horizontalPadding = paddingValue.left + paddingValue.right;
      final spacingTotal = (crossAxisCount - 1) * (widget.isPortrait ? 16 : 20);
      
      // 精确计算项目宽度
      final double itemWidth = (screenWidth - horizontalPadding - spacingTotal) / crossAxisCount;
      
      // 横向卡片使用16:9比例
      final double imageHeight = itemWidth * 9 / 16;
      final double itemHeight = imageHeight + spacing + titleHeight;
      final double childAspectRatio = itemWidth / itemHeight;

      final int videoListLength = widget.videoList.length;
      _updateFocusNodes(videoListLength);

      return Focus(
        onKeyEvent: (node, event) => _handleKeyEvent(event, crossAxisCount, videoListLength),
        child: GridView.builder(
          controller: widget.scrollController,
          padding: padding,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: widget.isPortrait ? 16 : 20,
            mainAxisSpacing: widget.isPortrait ? 20 : 24,
          ),
          itemCount: widget.videoList.length + (widget.showLoadMore ? 1 : 0),
          cacheExtent: 99999,
          addAutomaticKeepAlives: true,
          addRepaintBoundaries: true,
          addSemanticIndexes: false,
          itemBuilder: (context, index) {
            if (index == widget.videoList.length && widget.showLoadMore) {
              return _buildLoadMoreIndicator();
            }
            
            final video = widget.videoList[index];
            return FocusableItem(
              autofocus: index == 0,
              focusNode: _focusNodes[index],
              onSelected: () => _onVideoSelected(video),
              child: VideoCardWidget(
                video: video,
                itemWidth: itemWidth,
                imageHeight: imageHeight,
                titleHeight: titleHeight,
                spacing: spacing,
                isPortrait: widget.isPortrait,
              ),
            );
          },
        ),
      );
    });
  }
  
  /// 纵向卡片网格布局 (适用于纵向封面图)
  Widget _buildVerticalCardGrid() {
    // 纵向卡片：横屏6列，竖屏3列
    int crossAxisCount = widget.isPortrait ? 3 : 6;
    final double titleHeight = 36;
    final double spacing = 4;
    
    return Builder(builder: (context) {
      final double screenWidth = MediaQuery.of(context).size.width;
      final EdgeInsetsGeometry padding = widget.padding ?? 
          EdgeInsets.all(widget.isPortrait ? 16 : 24);
      
      // 计算实际内边距值
      final paddingValue = padding.resolve(TextDirection.ltr);
      final horizontalPadding = paddingValue.left + paddingValue.right;
      final spacingTotal = (crossAxisCount - 1) * (widget.isPortrait ? 12 : 16);
      
      // 精确计算项目宽度
      final double itemWidth = (screenWidth - horizontalPadding - spacingTotal) / crossAxisCount;
      
      // 纵向卡片使用较小的纵向比例
      final double imageHeight = itemWidth * 1.4;
      final double itemHeight = imageHeight + spacing + titleHeight;
      final double childAspectRatio = itemWidth / itemHeight;

      final int videoListLength = widget.videoList.length;
      _updateFocusNodes(videoListLength);

      return Focus(
        onKeyEvent: (node, event) => _handleKeyEvent(event, crossAxisCount, videoListLength),
        child: GridView.builder(
          controller: widget.scrollController,
          padding: padding,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: widget.isPortrait ? 12 : 16,
            mainAxisSpacing: widget.isPortrait ? 16 : 20,
          ),
          itemCount: widget.videoList.length + (widget.showLoadMore ? 1 : 0),
          cacheExtent: 99999,
          addAutomaticKeepAlives: true,
          addRepaintBoundaries: true,
          addSemanticIndexes: false,
          itemBuilder: (context, index) {
            if (index == widget.videoList.length && widget.showLoadMore) {
              return _buildLoadMoreIndicator();
            }
            
            final video = widget.videoList[index];
            return FocusableItem(
              autofocus: index == 0,
              focusNode: _focusNodes[index],
              onSelected: () => _onVideoSelected(video),
              child: VideoCardWidget(
                video: video,
                itemWidth: itemWidth,
                imageHeight: imageHeight,
                titleHeight: titleHeight,
                spacing: spacing,
                isPortrait: widget.isPortrait,
              ),
            );
          },
        ),
      );
    });
  }

  /// 处理键盘事件
  KeyEventResult _handleKeyEvent(KeyEvent event, int crossAxisCount, int videoListLength) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

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
              alignment: 0.5,
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
  }

  /// 处理视频选择
  void _onVideoSelected(dynamic video) {
    if (widget.onVideoTap != null) {
      widget.onVideoTap!(video);
    } else {
      // 默认导航到视频详情页
      Get.toNamed(
        AppRoutes.videoDetail,
        parameters: {'videoId': video['vod_id'] ?? video['vodId']},
      );
    }
  }

  /// 构建加载更多指示器
  Widget _buildLoadMoreIndicator() {
    if (!widget.hasMore) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            '没有更多数据了',
            style: TextStyle(
              color: widget.isPortrait ? Colors.grey[600] : Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ),
      );
    }
    
    if (widget.isLoadingMore) {
      return widget.customLoadingWidget ?? Container(
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
  }
}

/// 公共视频卡片组件
class VideoCardWidget extends StatelessWidget {
  final dynamic video;
  final double itemWidth;
  final double imageHeight;
  final double titleHeight;
  final double spacing;
  final bool isPortrait;
  
  const VideoCardWidget({
    super.key,
    required this.video,
    required this.itemWidth,
    required this.imageHeight,
    required this.titleHeight,
    required this.spacing,
    required this.isPortrait,
  });

  @override
  Widget build(BuildContext context) {
    // 根据屏幕方向调整文字颜色：竖屏用深色，横屏用白色
    final textColor = isPortrait ? Colors.grey[800]! : Colors.white;
    // 卡片背景也根据模式调整
    final cardBgColor = isPortrait 
        ? Colors.white.withValues(alpha: 0.15) 
        : Colors.black.withValues(alpha: 0.15);
    final performance = PerformanceManager.to;

    final String? remarks = video['vod_remarks'] ?? video['vodRemarks'];
    final bool shouldShowRemarks = remarks != null && remarks.length <= 30;

    return RepaintBoundary(
      child: Column(
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
                boxShadow: performance.getOptimizedShadow(isCard: true),
              ) : null,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(isPortrait ? 8 : 12),
                    child: _buildOptimizedImage(),
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
                              Colors.black.withValues(alpha: 179/255.0),
                              Colors.black.withValues(alpha: 51/255.0),
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
                video['vod_name'] ?? video['vodName'] ?? '',
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
      ),
    );
  }

  /// 构建优化的图片组件
  Widget _buildOptimizedImage() {
    final imageUrl = video['vod_pic'] ?? video['vodPic'] ?? '';
    
    return Image.network(
      imageUrl,
      width: itemWidth,
      height: imageHeight,
      fit: BoxFit.cover,
      cacheWidth: (itemWidth * 2).round(),
      cacheHeight: (imageHeight * 2).round(),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: itemWidth,
          height: imageHeight,
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
        width: itemWidth,
        height: imageHeight,
        color: Colors.grey[800],
        child: Icon(
          Icons.image_not_supported,
          color: Colors.grey[600],
          size: 24,
        ),
      ),
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