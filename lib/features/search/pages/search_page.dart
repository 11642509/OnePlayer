import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import '../../../shared/widgets/backgrounds/optimized_cosmic_background.dart';
import '../../../shared/widgets/common/glass_container.dart';
import '../../../shared/widgets/common/smart_text_field.dart';
import '../../../shared/controllers/window_controller.dart';
import '../../../app/theme/typography.dart';
import '../../../core/remote_control/focusable_glow.dart';
import '../controllers/search_controller.dart' as search_ctrl;
import '../widgets/search_source_list.dart';
import '../widgets/search_result_grid.dart';
import '../widgets/search_remote_navigation_handler.dart';
import '../../../shared/models/search_page_state.dart';

/// 搜索页面
class SearchPage extends GetView<search_ctrl.SearchController> {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 创建导航处理器
    final navigationHandler = SearchRemoteNavigationHandler(controller);
    
    return Scaffold(
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          // 优先让SmartTextField等子控件处理，未处理时分发到遥控器导航
          final result = navigationHandler.handleKeyEvent(event);
          if (result == KeyEventResult.handled) return result;
          // 兼容主页面遥控器体验
          if (event is KeyDownEvent) {
            switch (event.logicalKey) {
              case LogicalKeyboardKey.arrowUp:
                controller.moveFocusUp();
                return KeyEventResult.handled;
              case LogicalKeyboardKey.arrowDown:
                controller.moveFocusDown();
                return KeyEventResult.handled;
              case LogicalKeyboardKey.arrowLeft:
                controller.moveFocusLeft();
                return KeyEventResult.handled;
              case LogicalKeyboardKey.arrowRight:
                controller.moveFocusRight();
                return KeyEventResult.handled;
              default:
                break;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Obx(() {
          final windowController = Get.find<WindowController>();
          final isPortrait = windowController.isPortrait.value;
          
          return OptimizedCosmicBackground(
            child: isPortrait 
                ? _buildPortraitLayout() 
                : _buildLandscapeLayout(),
          );
        }),
      ),
    );
  }

  /// 构建横屏布局
  Widget _buildLandscapeLayout() {
    return Column(
      children: [
        // 顶部搜索栏
        _buildSearchHeader(),
        
        // 主要内容区域
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // 左侧站点列表
                SizedBox(
                  width: 280,
                  child: _buildSourceSection(),
                ),
                
                const SizedBox(width: 16),
                
                // 右侧搜索结果
                Expanded(
                  child: _buildResultSection(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 构建竖屏布局
  Widget _buildPortraitLayout() {
    return Column(
      children: [
        // 顶部搜索栏
        _buildSearchHeader(),
        
        // 主要内容区域
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // 站点选择器（横向滚动）
                SizedBox(
                  height: 80,
                  child: _buildSourceSectionHorizontal(),
                ),
                
                const SizedBox(height: 16),
                
                // 搜索结果
                Expanded(
                  child: _buildResultSection(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 构建搜索头部
  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.1),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          // 返回按钮
          FocusableGlow(
            onTap: () => Get.back(),
            borderRadius: BorderRadius.circular(12),
            child: GlassContainer(
              width: 48,
              height: 48,
              borderRadius: 12,
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // 搜索输入框
          Expanded(
            child: _buildSearchInput(),
          ),
          
          const SizedBox(width: 16),
          
          // 清除按钮
          Obx(() => AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) {
              return ScaleTransition(
                scale: animation,
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            child: controller.currentKeyword.isNotEmpty
                ? FocusableGlow(
                    key: const ValueKey('clear_button'),
                    focusNode: controller.getClearButtonFocusNode,
                    onTap: controller.clearSearch,
                    borderRadius: BorderRadius.circular(12),
                    child: GlassContainer(
                      width: 48,
                      height: 48,
                      borderRadius: 12,
                      child: const Icon(
                        Icons.clear,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  )
                : const SizedBox(
                    key: ValueKey('empty_space'),
                    width: 48,
                    height: 48,
                  ),
          )),
        ],
      ),
    );
  }

  /// 构建搜索输入框
  Widget _buildSearchInput() {
    return Stack(
      children: [
        Obx(() => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuint,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: controller.searchFocused
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
            height: 48,
            borderRadius: 24,
            child: Row(
              children: [
                // 搜索图标或进度条
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  child: Obx(() =>
                    controller.isSearching && controller.currentKeyword.isNotEmpty
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        )
                      : Icon(
                          Icons.search,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 20,
                        ),
                  ),
                ),
                // 输入框
                Expanded(
                  child: SmartTextField(
                    controller: controller.textController,
                    focusNode: controller.searchFocusNode,
                    hintText: '搜索视频内容...',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white,
                      height: 1.2,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: Colors.white54,
                        fontSize: 15,
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    onSubmitted: (value) => controller.performSearch(value),
                    // 智能导航 - 从搜索框向下移动到源列表或结果区
                    onNavigateDown: () {
                      if (controller.availableSources.isNotEmpty) {
                        controller.navigateFromSearchToSources();
                      } else if (controller.currentResults.isNotEmpty) {
                        controller.navigateFromSourcesToResults();
                      }
                    },
                    // 支持Escape返回
                    onNavigateUp: () {
                      Get.back();
                    },
                    // 左右方向键可切换到清除按钮
                    onNavigateLeft: () {
                      // 聚焦到清除按钮
                      controller.getClearButtonFocusNode.requestFocus();
                    },
                    onNavigateRight: () {
                      controller.getClearButtonFocusNode.requestFocus();
                    },
                  ),
                ),
                // 语音搜索图标（装饰性）
                Padding(
                  padding: const EdgeInsets.only(right: 16, left: 8),
                  child: Icon(
                    Icons.mic_none,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        )),
        
        // 移除搜索建议相关UI
        // 删除Obx(() => AnimatedSwitcher(...SearchSuggestions...))
      ],
    );
  }

  /// 构建站点区域（竖屏）
  Widget _buildSourceSection() {
    return GlassContainer(
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '搜索站点',
              style: AppTypography.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          // 站点列表
          Expanded(
            child: SearchSourceList(
              sources: controller.availableSources,
              selectedSourceId: controller.selectedSourceId,
              searchResults: controller.searchResults,
              loadingStates: controller.pageState.loadingStates,
              onSourceSelected: controller.selectSource,
              scrollController: controller.sourceScrollController,
              focusedIndex: controller.focusedSourceIndexValue,
              isSearching: controller.isSearching,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建站点区域（横屏）
  Widget _buildSourceSectionHorizontal() {
    return GlassContainer(
      borderRadius: 16,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: controller.availableSources.length,
          itemBuilder: (context, index) {
            final source = controller.availableSources[index];
            final isSelected = controller.selectedSourceId == source.id;
            final hasResults = controller.hasSourceResults(source.id);
            final isLoading = controller.isSourceLoading(source.id);
            final resultCount = controller.getSourceResultCount(source.id);
            final isFocused = controller.focusedSourceIndexValue == index;
            
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FocusableGlow(
                focusNode: controller.getSourceFocusNode(index),
                onTap: () {
                  controller.selectSource(source.id);
                  controller.focusedSourceIndex.value = index;
                },
                onFocusChange: (hasFocus) {
                  if (hasFocus) {
                    controller.focusedSourceIndex.value = index;
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  width: 120,
                  transform: Matrix4.identity()
                    ..scale(isFocused ? 1.05 : 1.0),
                  decoration: BoxDecoration(
                    gradient: isSelected 
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.25),
                              Colors.white.withValues(alpha: 0.15),
                            ],
                          )
                        : null,
                    color: !isSelected 
                        ? Colors.white.withValues(alpha: isFocused ? 0.15 : 0.08)
                        : null,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected 
                          ? Colors.white.withValues(alpha: 0.4)
                          : isFocused
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.transparent,
                      width: 1.5,
                    ),
                    boxShadow: isSelected || isFocused
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
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 站点名称
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: AppTypography.labelMedium.copyWith(
                            color: Colors.white.withValues(
                              alpha: isSelected ? 1.0 : 0.85,
                            ),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            fontSize: isSelected ? 13 : 12,
                          ),
                          child: Text(
                            source.name,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        const SizedBox(height: 6),
                        
                        // 状态指示器
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: _buildSourceStatusIndicator(
                            isLoading: isLoading,
                            hasResults: hasResults,
                            resultCount: resultCount,
                            isSelected: isSelected,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 站点卡片状态指示器部分
  Widget _buildSourceStatusIndicator({
    required bool isLoading,
    required bool hasResults,
    required int resultCount,
    required bool isSelected,
  }) {
    // 只在搜索中状态才显示进度圈
    final loading = controller.pageState.status == SearchPageStatus.loading && isLoading;
    if (loading) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            Colors.white.withValues(alpha: 0.8),
          ),
        ),
      );
    } else if (hasResults) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.green.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Text(
          '$resultCount',
          style: AppTypography.labelSmall.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else {
      return Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.3),
        ),
      );
    }
  }

  /// 构建结果区域
  Widget _buildResultSection() {
    return GlassContainer(
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 结果标题
          Padding(
            padding: const EdgeInsets.all(16),
            child: Obx(() => Row(
              children: [
                Text(
                  '搜索结果',
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                if (controller.selectedSourceId != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      controller.availableSources
                          .where((s) => s.id == controller.selectedSourceId)
                          .firstOrNull?.name ?? '',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
                
                const Spacer(),
                
                // 结果统计
                if (controller.hasResults) ...[
                  Text(
                    '${controller.currentResults.length} 个结果',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ],
            )),
          ),
          
          // 结果列表
          Expanded(
            child: _buildResultContent(),
          ),
        ],
      ),
    );
  }

  /// 构建结果内容
  Widget _buildResultContent() {
    return Obx(() {
      final pageState = controller.pageState;
      
      switch (pageState.status) {
        case SearchPageStatus.idle:
          return _buildEmptyState(
            icon: Icons.search,
            title: '开始搜索',
            subtitle: '输入关键词搜索视频内容',
          );
          
        case SearchPageStatus.loading:
          return _buildLoadingState();
          
        case SearchPageStatus.empty:
          return _buildEmptyState(
            icon: Icons.search_off,
            title: '没有找到结果',
            subtitle: '试试其他关键词或检查网络连接',
          );
          
        case SearchPageStatus.error:
          return _buildErrorState(pageState.errorMessage ?? '搜索失败');
          
        case SearchPageStatus.success:
          return SearchResultGrid(
            results: controller.currentResults,
            onResultSelected: (result) {
              // 处理结果选择
              Get.toNamed('/video-detail', arguments: result);
            },
            scrollController: controller.resultScrollController,
            focusedIndex: controller.focusedResultIndexValue,
            getFocusNode: (index) => controller.getResultFocusNode(index),
          );
      }
    });
  }

  /// 构建空状态
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: TweenAnimationBuilder(
        duration: const Duration(milliseconds: 600),
        tween: Tween<double>(begin: 0, end: 1),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Opacity(
              opacity: value.clamp(0.0, 1.0), // 修复：限制opacity在0~1
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 动画图标
                  TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 2000),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, iconValue, _) {
                      return Transform.rotate(
                        angle: iconValue * 0.1 * 3.14159,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.05),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            icon,
                            size: 40,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Container(
                    constraints: const BoxConstraints(maxWidth: 280),
                    child: Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建加载状态
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 简单有效的加载动画
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 搜索提示文字
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: AppTypography.titleMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
            child: const Text('搜索中'),
          ),
          
          const SizedBox(height: 8),
          
          Obx(() => AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.6),
            ),
            child: Text(
              '正在搜索「${controller.currentKeyword}」...',
              textAlign: TextAlign.center,
            ),
          )),
        ],
      ),
    );
  }

  /// 构建错误状态
  Widget _buildErrorState(String message) {
    return Center(
      child: TweenAnimationBuilder(
        duration: const Duration(milliseconds: 500),
        tween: Tween<double>(begin: 0, end: 1),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 错误图标动画
                  TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 800),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, iconValue, _) {
                      return Transform.scale(
                        scale: 0.8 + (0.2 * iconValue),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red.withValues(alpha: 0.1),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            Icons.error_outline,
                            size: 40,
                            color: Colors.red.withValues(alpha: 0.8),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    '搜索失败',
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Text(
                      message,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  FocusableGlow(
                    onTap: controller.refreshSearch,
                    borderRadius: BorderRadius.circular(24),
                    child: GlassContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      borderRadius: 24,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh,
                            color: Colors.white.withValues(alpha: 0.9),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '重试',
                            style: AppTypography.labelMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}