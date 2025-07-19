import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../shared/widgets/backgrounds/optimized_cosmic_background.dart';
import '../../../shared/widgets/backgrounds/fresh_cosmic_background.dart';
import '../../../shared/widgets/common/glass_container.dart';
import '../../../app/theme/typography.dart';
import '../../../core/remote_control/focusable_item.dart';
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
    if (isPortrait) {
      return Column(
        children: [
          _buildHeader(isPortrait),
          _buildPortraitSourceSelector(),
          Expanded(
            child: _buildResultArea(isPortrait),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          _buildHeader(isPortrait),
          Expanded(
            child: _buildLandscapeMainContent(),
          ),
        ],
      );
    }
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
        controller.moveResultUp(); // 控制器内部已处理跳转到搜索框的逻辑
        return KeyEventResult.handled;
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
        controller.moveResultDown();
        return KeyEventResult.handled;
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
        if (controller.focusedResultIndex.value % 4 == 0) {
          // 在最左列，跳转到源列表
          controller.navigateToSources();
        } else {
          controller.moveResultLeft();
        }
        return KeyEventResult.handled;
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
        controller.moveResultRight();
        return KeyEventResult.handled;
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

  /// 构建横屏主要内容
  Widget _buildLandscapeMainContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧源列表
          SizedBox(
            width: 300,
            child: _buildSourceList(false),
          ),
          
          const SizedBox(width: 20),
          
          // 右侧结果区域
          Expanded(
            child: _buildResultArea(false),
          ),
        ],
      ),
    );
  }

  /// 构建竖屏源选择器（横向滚动）
  Widget _buildPortraitSourceSelector() {
    final windowController = Get.find<WindowController>();
    final isPortrait = windowController.isPortrait.value;
    
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              '搜索站点',
              style: AppTypography.titleMedium.copyWith(
                color: isPortrait ? Colors.grey[800] : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Obx(() => ListView.builder(
              controller: controller.sourceScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: controller.sources.length,
              itemBuilder: (context, index) {
                final source = controller.sources[index];
                return _buildPortraitSourceItem(source, index);
              },
            )),
          ),
        ],
      ),
    );
  }

  /// 构建竖屏源项目
  Widget _buildPortraitSourceItem(source, int index) {
    final windowController = Get.find<WindowController>();
    final isPortrait = windowController.isPortrait.value;
    
    return Obx(() {
      final isSelected = controller.selectedSourceId.value == source.id;
      final isFocused = controller.focusedSourceIndex.value == index;
      final hasResults = controller.hasSourceResults(source.id);
      final isLoading = controller.isSourceLoading(source.id);
      final resultCount = controller.getSourceResultCount(source.id);

      return Padding(
        padding: const EdgeInsets.only(right: 12),
        child: FocusableItem(
          focusNode: controller.getSourceFocusNode(source.id),
          onSelected: () {
            controller.selectSource(source.id);
            controller.focusedSourceIndex.value = index;
            controller.focusedArea.value = 'sources';
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 120,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isPortrait ? Colors.grey.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.2))
                  : (isPortrait ? Colors.grey.withValues(alpha: isFocused ? 0.2 : 0.12) : Colors.white.withValues(alpha: isFocused ? 0.15 : 0.08)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? (isPortrait ? Colors.grey.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.4))
                    : isFocused
                        ? (isPortrait ? Colors.grey.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.3))
                        : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    // 源标识
                    Container(
                      width: 3,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _parseColor(source.color),
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // 源名称
                    Expanded(
                      child: Text(
                        source.name,
                        style: AppTypography.bodySmall.copyWith(
                          color: isPortrait ? Colors.grey[800] : Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    // 状态指示器
                    if (isLoading)
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isPortrait ? Colors.grey[700]! : Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      )
                    else if (hasResults)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: _parseColor(source.color).withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$resultCount',
                          style: AppTypography.labelSmall.copyWith(
                            color: isPortrait ? Colors.grey[800] : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  /// 构建源列表
  Widget _buildSourceList(bool isPortrait) {
    return GlassContainer(
      borderRadius: 16,
      isPortrait: isPortrait,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Padding(
            padding: EdgeInsets.all(isPortrait ? 16 : 20),
            child: Text(
              '搜索站点',
              style: AppTypography.titleLarge.copyWith(
                color: isPortrait ? Colors.grey[800] : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isPortrait ? 16 : 18,
              ),
            ),
          ),
          
          // 源列表
          Expanded(
            child: Obx(() => ListView.builder(
              controller: controller.sourceScrollController,
              padding: EdgeInsets.symmetric(
                horizontal: isPortrait ? 16 : 20,
                vertical: 10,
              ),
              itemCount: controller.sources.length,
              itemBuilder: (context, index) {
                final source = controller.sources[index];
                return _buildSourceItem(source, index, isPortrait);
              },
            )),
          ),
        ],
      ),
    );
  }

  /// 构建源项目
  Widget _buildSourceItem(source, int index, bool isPortrait) {
    return Obx(() {
      final isSelected = controller.selectedSourceId.value == source.id;
      final isFocused = controller.focusedSourceIndex.value == index;
      final hasResults = controller.hasSourceResults(source.id);
      final isLoading = controller.isSourceLoading(source.id);
      final resultCount = controller.getSourceResultCount(source.id);

      return Padding(
        padding: EdgeInsets.only(bottom: isPortrait ? 10 : 12),
        child: FocusableItem(
          focusNode: controller.getSourceFocusNode(source.id),
          onSelected: () {
            controller.selectSource(source.id);
            controller.focusedSourceIndex.value = index;
            controller.focusedArea.value = 'sources';
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(isPortrait ? 12 : 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isPortrait ? Colors.grey.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.2))
                  : (isPortrait ? Colors.grey.withValues(alpha: isFocused ? 0.2 : 0.12) : Colors.white.withValues(alpha: isFocused ? 0.15 : 0.08)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? (isPortrait ? Colors.grey.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.4))
                    : isFocused
                        ? (isPortrait ? Colors.grey.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.3))
                        : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // 源标识
                Container(
                  width: 4,
                  height: isPortrait ? 28 : 32,
                  decoration: BoxDecoration(
                    color: _parseColor(source.color),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                SizedBox(width: isPortrait ? 12 : 16),
                
                // 源信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        source.name,
                        style: AppTypography.titleMedium.copyWith(
                          color: isPortrait ? Colors.grey[800] : Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: isPortrait ? 14 : 16,
                        ),
                      ),
                      if (hasResults) ...[
                        SizedBox(height: isPortrait ? 2 : 4),
                        Text(
                          '$resultCount 个结果',
                          style: AppTypography.bodySmall.copyWith(
                            color: isPortrait ? Colors.grey[600] : Colors.white.withValues(alpha: 0.7),
                            fontSize: isPortrait ? 11 : 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // 状态指示器
                if (isLoading) ...[
                  SizedBox(
                    width: isPortrait ? 16 : 20,
                    height: isPortrait ? 16 : 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isPortrait ? Colors.grey[700]! : Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ] else if (hasResults) ...[
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isPortrait ? 6 : 8,
                      vertical: isPortrait ? 3 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: _parseColor(source.color).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$resultCount',
                      style: AppTypography.labelSmall.copyWith(
                        color: isPortrait ? Colors.grey[800] : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isPortrait ? 10 : 11,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }

  /// 构建结果区域
  Widget _buildResultArea(bool isPortrait) {
    return GlassContainer(
      borderRadius: 16,
      isPortrait: isPortrait,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Padding(
            padding: EdgeInsets.all(isPortrait ? 16 : 20),
            child: Obx(() => Row(
              children: [
                Text(
                  '搜索结果',
                  style: AppTypography.titleLarge.copyWith(
                    color: isPortrait ? Colors.grey[800] : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isPortrait ? 16 : 18,
                  ),
                ),
                
                const Spacer(),
                
                if (controller.getCurrentResults().isNotEmpty) ...[
                  Text(
                    '${controller.getCurrentResults().length} 个结果',
                    style: AppTypography.bodyMedium.copyWith(
                      color: isPortrait ? Colors.grey[600] : Colors.white.withValues(alpha: 0.7),
                      fontSize: isPortrait ? 12 : 14,
                    ),
                  ),
                ],
              ],
            )),
          ),
          
          // 结果内容
          Expanded(
            child: _buildResultContent(isPortrait),
          ),
        ],
      ),
    );
  }

  /// 构建结果内容
  Widget _buildResultContent(bool isPortrait) {
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

  /// 构建结果网格
  Widget _buildResultGrid(List results, bool isPortrait) {
    return Obx(() {
      final isHorizontal = controller.isHorizontalLayout.value;
      
      return LayoutBuilder(
        builder: (context, constraints) {
          // 响应式布局参数
          final int crossAxisCount = isPortrait ? 2 : 4;  // 竖屏2列，横屏4列
          final double crossAxisSpacing = isPortrait ? 12 : 16;
          final double mainAxisSpacing = isPortrait ? 16 : 16;
          final double padding = isPortrait ? 16 : 20;
          final double titleHeight = 40;
          final double spacing = 8;
          
          // 计算每个项目的宽度
          final double itemWidth = (constraints.maxWidth - padding * 2 - crossAxisSpacing * (crossAxisCount - 1)) / crossAxisCount;
          
          // 根据图片方向计算高度
          final double imageHeight = isHorizontal 
              ? itemWidth * 9 / 16  // 横版图片：16:9
              : itemWidth * 16 / 9; // 竖版图片：9:16
          
          final double itemHeight = imageHeight + spacing + titleHeight;
          final double childAspectRatio = itemWidth / itemHeight;
          
          return GridView.builder(
            controller: controller.resultScrollController,
            padding: EdgeInsets.all(padding),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: crossAxisSpacing,
              mainAxisSpacing: mainAxisSpacing,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              return _buildResultItem(result, index, isHorizontal, itemWidth, imageHeight, isPortrait);
            },
          );
        },
      );
    });
  }

  /// 构建结果项目
  Widget _buildResultItem(result, int index, bool isHorizontal, double itemWidth, double imageHeight, bool isPortrait) {
    return Obx(() {
      final isFocused = controller.focusedResultIndex.value == index;

      return FocusableItem(
        focusNode: controller.getResultFocusNode(index),
        onSelected: () {
          Get.toNamed(
            AppRoutes.videoDetail,
            parameters: {'videoId': result.vodId},
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..scale(isFocused ? 1.02 : 1.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 封面卡片
              SizedBox(
                height: imageHeight,
                child: Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: Colors.black.withValues(alpha: 0.15),
                  child: Container(
                    width: double.infinity,
                    height: imageHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isPortrait 
                            ? Colors.grey.withValues(alpha: isFocused ? 0.4 : 0.12)
                            : Colors.white.withValues(alpha: isFocused ? 0.4 : 0.12),
                        width: isFocused ? 2 : 0.5,
                      ),
                      boxShadow: isFocused
                          ? [
                              BoxShadow(
                                color: isPortrait 
                                    ? Colors.grey.withValues(alpha: 0.2)
                                    : Colors.white.withValues(alpha: 0.1),
                                blurRadius: 8,
                                spreadRadius: 0,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            result.vodPic,
                            fit: BoxFit.cover,
                            width: itemWidth,
                            height: imageHeight,
                            cacheWidth: (itemWidth * 2).round(),
                            cacheHeight: (imageHeight * 2).round(),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[850],
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                ),
                              );
                            },
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
                          ),
                        ),
                        
                        // 备注信息覆盖层
                        if (result.vodRemarks.isNotEmpty && result.vodRemarks.length <= 30) ...[
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.7),
                                    Colors.black.withValues(alpha: 0.2),
                                  ],
                                ),
                              ),
                              child: Text(
                                result.vodRemarks,
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
                        
                        // 播放按钮（仅在焦点时显示）
                        if (isFocused) ...[
                          Center(
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              
              // 标题
              const SizedBox(height: 8),
              SizedBox(
                height: 36, // 固定高度避免溢出
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    result.vodName,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isPortrait ? Colors.grey[800] : Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
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
        ),
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