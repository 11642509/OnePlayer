import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../shared/models/search_result.dart';
import '../../../shared/controllers/window_controller.dart';
import '../../../app/theme/typography.dart';
import '../../../core/remote_control/focusable_glow.dart';

/// 搜索结果网格组件
class SearchResultGrid extends StatelessWidget {
  final List<SearchResult> results;
  final Function(SearchResult) onResultSelected;
  final ScrollController scrollController;
  final int focusedIndex;
  final FocusNode Function(int) getFocusNode;

  const SearchResultGrid({
    super.key,
    required this.results,
    required this.onResultSelected,
    required this.scrollController,
    required this.focusedIndex,
    required this.getFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.white38,
            ),
            SizedBox(height: 16),
            Text(
              '没有找到结果',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Obx(() {
      final windowController = Get.find<WindowController>();
      final isPortrait = windowController.isPortrait.value;
      
      return GridView.builder(
        controller: scrollController,
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isPortrait ? 2 : 4,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: isPortrait ? 0.75 : 0.8,
        ),
        itemCount: results.length,
        itemBuilder: (context, index) {
          final result = results[index];
          final focusNode = getFocusNode(index);
          final isFocused = focusedIndex == index;
          
          return FocusableGlow(
            focusNode: focusNode,
            onTap: () => onResultSelected(result),
            onFocusChange: (hasFocus) {
              // 焦点变化时确保可见
              if (hasFocus) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (focusNode.context != null) {
                    Scrollable.ensureVisible(
                      focusNode.context!,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      alignment: 0.5,
                    );
                  }
                });
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              transform: Matrix4.identity()
                ..scale(isFocused ? 1.05 : 1.0),
              child: _buildResultCard(result, isFocused),
            ),
          );
        },
      );
    });
  }

  /// 构建结果卡片
  Widget _buildResultCard(SearchResult result, [bool isFocused = false]) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isFocused ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: isFocused ? 0.3 : 0.1),
          width: isFocused ? 1.5 : 1,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.1),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 视频封面
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 封面图片
                    Image.network(
                      result.vodPic,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[800],
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.white54,
                              size: 32,
                            ),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[800],
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    // 渐变遮罩
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.3),
                          ],
                        ),
                      ),
                    ),
                    
                    // 播放按钮
                    const Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // 视频信息
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 视频标题
                  Text(
                    result.vodName,
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const Spacer(),
                  
                  // 视频备注（时间、播放量等）
                  if (result.vodRemarks.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.white54,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            result.vodRemarks,
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white54,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}