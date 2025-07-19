import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// 搜索页面
class SearchPage extends GetView<search_ctrl.SearchController> {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final windowController = Get.find<WindowController>();
    
    return Obx(() {
      final isPortrait = windowController.isPortrait.value;
      
      return Scaffold(
        body: Focus(
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: isPortrait 
              ? FreshCosmicBackground(
                  child: _buildResponsiveLayout(isPortrait),
                )
              : OptimizedCosmicBackground(
                  child: _buildResponsiveLayout(isPortrait),
                ),
        ),
      );
    });
  }

  /// 构建响应式布局
  Widget _buildResponsiveLayout(bool isPortrait) {
    return Column(
      children: [
        _buildHeader(isPortrait),
        Expanded(
          child: _buildMainContent(isPortrait),
        ),
      ],
    );
  }

  /// 构建主要内容 - 参考影视页设计
  Widget _buildMainContent(bool isPortrait) {
    return Column(
      children: [
        // 分类导航（源站点选择）
        _buildSourceTabBar(isPortrait),
        
        // 搜索结果区域
        Expanded(
          child: _buildSearchResults(isPortrait),
        ),
      ],
    );
  }

  /// 构建源站点选择的TabBar - 参考影视页的分类导航
  Widget _buildSourceTabBar(bool isPortrait) {
    return Container(
      height: isPortrait ? 48 : 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isPortrait ? [
            Colors.white.withValues(alpha: 0.05),
            Colors.transparent,
          ] : [
            Colors.black.withValues(alpha: 0.1),
            Colors.transparent,
          ],
        ),
      ),
      child: Obx(() {
        if (controller.sources.isEmpty) {
          return const SizedBox();
        }
        
        return TabBar(
          controller: controller.sourceTabController,
          isScrollable: true,
          tabs: controller.sources.map((source) {
            final tabContent = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 源标识点
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: _parseColor(source.color),
                    shape: BoxShape.circle,
                  ),
                ),
                // 源名称
                Text(
                  source.name,
                  style: TextStyle(
                    fontFamily: AppTypography.systemFont,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.1,
                  ),
                ),
                // 结果数量徽标
                if (controller.hasSourceResults(source.id)) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _parseColor(source.color).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${controller.getSourceResultCount(source.id)}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isPortrait ? Colors.grey[800] : Colors.white,
                      ),
                    ),
                  ),
                ],
                // 加载指示器
                if (controller.isSourceLoading(source.id)) ...[
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isPortrait ? Colors.grey[700]! : Colors.white.withValues(alpha: 0.8),
                      ),
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
        );
      }),
    );
  }

  /// 构建搜索结果 - 参考影视页的视频网格
  Widget _buildSearchResults(bool isPortrait) {
    return Obx(() {
      if (controller.keyword.value.isEmpty) {
        return _buildEmptyState(
          icon: Icons.search,
          title: '开始搜索',
          subtitle: '输入关键词搜索视频内容',
          isPortrait: isPortrait,
        );
      }

      if (controller.isSearching.value) {
        return _buildLoadingState(isPortrait);
      }

      if (controller.errorMessage.value.isNotEmpty) {
        return _buildErrorState(isPortrait);
      }

      final results = controller.getCurrentResults();
      if (results.isEmpty) {
        return _buildEmptyState(
          icon: Icons.search_off,
          title: '没有找到结果',
          subtitle: '试试其他关键词或选择其他站点',
          isPortrait: isPortrait,
        );
      }

      return _buildResultGrid(results, isPortrait);
    });
  }

  /// 处理键盘事件
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        return _handleArrowUp();
      case LogicalKeyboardKey.arrowDown:
        return _handleArrowDown();
      case LogicalKeyboardKey.arrowLeft:
        return _handleArrowLeft();
      case LogicalKeyboardKey.arrowRight:
        return _handleArrowRight();
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.enter:
        return _handleConfirm();
      case LogicalKeyboardKey.escape:
      case LogicalKeyboardKey.goBack:
        return _handleBack();
      default:
        return KeyEventResult.ignored;
    }
  }

  KeyEventResult _handleArrowUp() {
    switch (controller.focusedArea.value) {
      case 'sources':
        if (controller.focusedSourceIndex.value > 0) {
          controller.moveSourceUp();
        } else {
          // 如果在源列表第一项，跳转到搜索框
          controller.navigateToSearch();
        }
        return KeyEventResult.handled;
      case 'results':
        // 由于使用了VideoGridWidget，交由其内部处理焦点导航
        // 如果需要跳转到搜索框，可以监听边界情况
        return KeyEventResult.ignored; // 让VideoGridWidget处理
      default:
        return KeyEventResult.ignored;
    }
  }

  KeyEventResult _handleArrowDown() {
    switch (controller.focusedArea.value) {
      case 'search':
        controller.navigateToSources();
        return KeyEventResult.handled;
      case 'sources':
        controller.moveSourceDown();
        return KeyEventResult.handled;
      case 'results':
        // 由于使用了VideoGridWidget，交由其内部处理焦点导航
        return KeyEventResult.ignored; // 让VideoGridWidget处理
      default:
        return KeyEventResult.ignored;
    }
  }

  KeyEventResult _handleArrowLeft() {
    // 检查当前焦点是否在清除按钮上
    if (controller.clearButtonFocusNode.hasFocus) {
      controller.navigateToSearch();
      return KeyEventResult.handled;
    }
    
    switch (controller.focusedArea.value) {
      case 'search':
        // 从搜索框左键跳转到返回按钮
        controller.backButtonFocusNode.requestFocus();
        return KeyEventResult.handled;
      case 'results':
        // 由于使用了VideoGridWidget，交由其内部处理焦点导航
        // 如果在最左列，可能需要跳转到源列表，但这需要VideoGridWidget支持
        return KeyEventResult.ignored; // 让VideoGridWidget处理
      default:
        return KeyEventResult.ignored;
    }
  }

  KeyEventResult _handleArrowRight() {
    // 检查当前焦点是否在返回按钮上
    if (controller.backButtonFocusNode.hasFocus) {
      controller.navigateToSearch();
      return KeyEventResult.handled;
    }
    
    // 检查当前焦点是否在清除按钮上
    if (controller.clearButtonFocusNode.hasFocus) {
      // 从清除按钮无法再向右，保持在清除按钮
      return KeyEventResult.handled;
    }
    
    switch (controller.focusedArea.value) {
      case 'search':
        // 从搜索框右键跳转到清除按钮（如果有内容）
        if (controller.keyword.value.isNotEmpty) {
          controller.clearButtonFocusNode.requestFocus();
        }
        return KeyEventResult.handled;
      case 'sources':
        controller.navigateToResults();
        return KeyEventResult.handled;
      case 'results':
        // 由于使用了VideoGridWidget，交由其内部处理焦点导航
        return KeyEventResult.ignored; // 让VideoGridWidget处理
      default:
        return KeyEventResult.ignored;
    }
  }

  KeyEventResult _handleConfirm() {
    controller.confirmSelection();
    return KeyEventResult.handled;
  }

  KeyEventResult _handleBack() {
    switch (controller.focusedArea.value) {
      case 'sources':
        controller.navigateToSearch();
        return KeyEventResult.handled;
      case 'results':
        controller.navigateToSources();
        return KeyEventResult.handled;
      default:
        Get.back();
        return KeyEventResult.handled;
    }
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

  /// 构建结果网格 - 使用共享的VideoGridWidget
  Widget _buildResultGrid(List results, bool isPortrait) {
    return Obx(() {
      final isHorizontal = controller.isHorizontalLayout.value;
      
      // 将搜索结果转换为video格式
      final List<Map<String, dynamic>> videoList = results.map((result) => {
        'vod_id': result.vodId,
        'vod_name': result.vodName,
        'vod_pic': result.vodPic,
        'vod_remarks': result.vodRemarks,
        // 为兼容性添加备用字段名
        'vodId': result.vodId,
        'vodName': result.vodName,
        'vodPic': result.vodPic,
        'vodRemarks': result.vodRemarks,
      }).toList();
      
      return VideoGridWidget(
        videoList: videoList,
        scrollController: controller.resultScrollController,
        isPortrait: isPortrait,
        isHorizontalLayout: isHorizontal,
        showLoadMore: false,
        isLoadingMore: false,
        hasMore: false,
        padding: EdgeInsets.all(isPortrait ? 16 : 20),
        emptyMessage: "没有找到相关视频",
        onVideoTap: (video) {
          Get.toNamed(
            AppRoutes.videoDetail,
            parameters: {'videoId': video['vod_id'] ?? video['vodId']},
          );
        },
      );
    });
  }

  /// 构建空状态
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isPortrait,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: isPortrait ? 60 : 80,
            color: isPortrait ? Colors.grey[400] : Colors.white.withValues(alpha: 0.3),
          ),
          SizedBox(height: isPortrait ? 16 : 24),
          Text(
            title,
            style: AppTypography.titleLarge.copyWith(
              color: isPortrait ? Colors.grey[700] : Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
              fontSize: isPortrait ? 18 : 20,
            ),
          ),
          SizedBox(height: isPortrait ? 8 : 12),
          Text(
            subtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: isPortrait ? Colors.grey[600] : Colors.white.withValues(alpha: 0.6),
              fontSize: isPortrait ? 13 : 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 构建加载状态
  Widget _buildLoadingState(bool isPortrait) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: isPortrait ? 50 : 60,
            height: isPortrait ? 50 : 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(isPortrait ? Colors.grey[700]! : Colors.white),
            ),
          ),
          SizedBox(height: isPortrait ? 16 : 24),
          Text(
            '搜索中...',
            style: AppTypography.titleMedium.copyWith(
              color: isPortrait ? Colors.grey[700] : Colors.white.withValues(alpha: 0.9),
              fontSize: isPortrait ? 16 : 18,
            ),
          ),
          SizedBox(height: isPortrait ? 6 : 8),
          Obx(() => Text(
            '正在搜索「${controller.keyword.value}」',
            style: AppTypography.bodyMedium.copyWith(
              color: isPortrait ? Colors.grey[600] : Colors.white.withValues(alpha: 0.6),
              fontSize: isPortrait ? 12 : 14,
            ),
          )),
        ],
      ),
    );
  }

  /// 构建错误状态
  Widget _buildErrorState(bool isPortrait) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: isPortrait ? 60 : 80,
            color: isPortrait ? Colors.red[400] : Colors.red.withValues(alpha: 0.8),
          ),
          SizedBox(height: isPortrait ? 16 : 24),
          Text(
            '搜索失败',
            style: AppTypography.titleLarge.copyWith(
              color: isPortrait ? Colors.grey[700] : Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
              fontSize: isPortrait ? 18 : 20,
            ),
          ),
          SizedBox(height: isPortrait ? 8 : 12),
          Obx(() => Text(
            controller.errorMessage.value,
            style: AppTypography.bodyMedium.copyWith(
              color: isPortrait ? Colors.grey[600] : Colors.white.withValues(alpha: 0.7),
              fontSize: isPortrait ? 13 : 14,
            ),
            textAlign: TextAlign.center,
          )),
          SizedBox(height: isPortrait ? 16 : 24),
          FocusableItem(
            onSelected: controller.performSearch,
            child: GlassContainer(
              padding: EdgeInsets.symmetric(
                horizontal: isPortrait ? 20 : 24,
                vertical: isPortrait ? 10 : 12,
              ),
              borderRadius: 24,
              isPortrait: isPortrait,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.refresh,
                    color: isPortrait ? Colors.grey[800] : Colors.white,
                    size: isPortrait ? 16 : 18,
                  ),
                  SizedBox(width: isPortrait ? 6 : 8),
                  Text(
                    '重试',
                    style: AppTypography.labelLarge.copyWith(
                      color: isPortrait ? Colors.grey[800] : Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: isPortrait ? 13 : 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 解析颜色
  Color _parseColor(String colorString) {
    try {
      final hexColor = colorString.replaceAll('#', '');
      return Color(int.parse('FF$hexColor', radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }
}