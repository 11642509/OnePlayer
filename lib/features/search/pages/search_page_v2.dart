import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../shared/widgets/backgrounds/optimized_cosmic_background.dart';
import '../../../shared/widgets/common/glass_container.dart';
import '../../../app/theme/typography.dart';
import '../../../core/remote_control/focusable_glow.dart';
import '../../../app/routes/app_routes.dart';
import '../controllers/search_controller_v2.dart';

/// 重新设计的搜索页面
class SearchPageV2 extends GetView<SearchControllerV2> {
  const SearchPageV2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Focus(
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: OptimizedCosmicBackground(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _buildMainContent(),
              ),
            ],
          ),
        ),
      ),
    );
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
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
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
            onTap: () => Get.back(),
            onFocusChange: (hasFocus) {
              if (hasFocus) {
                // 当返回按钮获得焦点时，可以通过右键回到搜索框
              }
            },
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
          
          const SizedBox(width: 20),
          
          // 搜索框
          Expanded(
            child: _buildSearchInput(),
          ),
          
          const SizedBox(width: 20),
          
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
                    key: ValueKey('empty'),
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
    return Obx(() {
      final isFocused = controller.focusedArea.value == 'search';
      
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuint,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
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
          height: 56,
          borderRadius: 28,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isFocused 
                    ? Colors.white.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.1),
                width: isFocused ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // 搜索图标或进度条
                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 12),
                  child: controller.isSearching.value
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
                
                // 输入框
                Expanded(
                  child: TextField(
                    controller: controller.textController,
                    focusNode: controller.searchFocusNode,
                    style: AppTypography.bodyLarge.copyWith(
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: '搜索视频内容...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onSubmitted: (_) => controller.performSearch(),
                  ),
                ),
                
                const SizedBox(width: 20),
              ],
            ),
          ),
        ),
      );
    });
  }

  /// 构建主要内容
  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧源列表
          SizedBox(
            width: 300,
            child: _buildSourceList(),
          ),
          
          const SizedBox(width: 20),
          
          // 右侧结果区域
          Expanded(
            child: _buildResultArea(),
          ),
        ],
      ),
    );
  }

  /// 构建源列表
  Widget _buildSourceList() {
    return GlassContainer(
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              '搜索站点',
              style: AppTypography.titleLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // 源列表
          Expanded(
            child: Obx(() => ListView.builder(
              controller: controller.sourceScrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: controller.sources.length,
              itemBuilder: (context, index) {
                final source = controller.sources[index];
                return _buildSourceItem(source, index);
              },
            )),
          ),
        ],
      ),
    );
  }

  /// 构建源项目
  Widget _buildSourceItem(source, int index) {
    return Obx(() {
      final isSelected = controller.selectedSourceId.value == source.id;
      final isFocused = controller.focusedSourceIndex.value == index;
      final hasResults = controller.hasSourceResults(source.id);
      final isLoading = controller.isSourceLoading(source.id);
      final resultCount = controller.getSourceResultCount(source.id);

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: FocusableGlow(
          focusNode: controller.getSourceFocusNode(source.id),
          onTap: () {
            controller.selectSource(source.id);
            controller.focusedSourceIndex.value = index;
            controller.focusedArea.value = 'sources';
          },
          onFocusChange: (hasFocus) {
            if (hasFocus) {
              controller.focusedSourceIndex.value = index;
              controller.focusedArea.value = 'sources';
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: isFocused ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.4)
                    : isFocused
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // 源标识
                Container(
                  width: 4,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _parseColor(source.color),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // 源信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        source.name,
                        style: AppTypography.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      if (hasResults) ...[
                        const SizedBox(height: 4),
                        Text(
                          '$resultCount 个结果',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // 状态指示器
                if (isLoading) ...[
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ] else if (hasResults) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _parseColor(source.color).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$resultCount',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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
  Widget _buildResultArea() {
    return GlassContainer(
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Padding(
            padding: const EdgeInsets.all(20),
            child: Obx(() => Row(
              children: [
                Text(
                  '搜索结果',
                  style: AppTypography.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const Spacer(),
                
                if (controller.getCurrentResults().isNotEmpty) ...[
                  Text(
                    '${controller.getCurrentResults().length} 个结果',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            )),
          ),
          
          // 结果内容
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
      if (controller.keyword.value.isEmpty) {
        return _buildEmptyState(
          icon: Icons.search,
          title: '开始搜索',
          subtitle: '输入关键词搜索视频内容',
        );
      }

      if (controller.isSearching.value) {
        return _buildLoadingState();
      }

      if (controller.errorMessage.value.isNotEmpty) {
        return _buildErrorState();
      }

      final results = controller.getCurrentResults();
      if (results.isEmpty) {
        return _buildEmptyState(
          icon: Icons.search_off,
          title: '没有找到结果',
          subtitle: '试试其他关键词或选择其他站点',
        );
      }

      return _buildResultGrid(results);
    });
  }

  /// 构建结果网格
  Widget _buildResultGrid(List results) {
    return Obx(() {
      final isHorizontal = controller.isHorizontalLayout.value;
      
      return LayoutBuilder(
        builder: (context, constraints) {
          const int crossAxisCount = 4;
          const double crossAxisSpacing = 16;
          const double mainAxisSpacing = 16;
          const double padding = 20;
          const double titleHeight = 40;
          const double spacing = 8;
          
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
            padding: const EdgeInsets.all(padding),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: crossAxisSpacing,
              mainAxisSpacing: mainAxisSpacing,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              return _buildResultItem(result, index, isHorizontal, itemWidth, imageHeight);
            },
          );
        },
      );
    });
  }

  /// 构建结果项目
  Widget _buildResultItem(result, int index, bool isHorizontal, double itemWidth, double imageHeight) {
    return Obx(() {
      final isFocused = controller.focusedResultIndex.value == index;

      return FocusableGlow(
        focusNode: controller.getResultFocusNode(index),
        onTap: () {
          Get.toNamed(
            AppRoutes.videoDetail,
            parameters: {'videoId': result.vodId},
          );
        },
        onFocusChange: (hasFocus) {
          if (hasFocus) {
            controller.focusedResultIndex.value = index;
            controller.focusedArea.value = 'results';
          }
        },
        borderRadius: BorderRadius.circular(12),
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
                        color: Colors.white.withValues(alpha: isFocused ? 0.4 : 0.12),
                        width: isFocused ? 2 : 0.5,
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
                      color: Colors.white,
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
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: AppTypography.titleLarge.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 构建加载状态
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '搜索中...',
            style: AppTypography.titleMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          Obx(() => Text(
            '正在搜索「${controller.keyword.value}」',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.6),
            ),
          )),
        ],
      ),
    );
  }

  /// 构建错误状态
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 24),
          Text(
            '搜索失败',
            style: AppTypography.titleLarge.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Obx(() => Text(
            controller.errorMessage.value,
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          )),
          const SizedBox(height: 24),
          FocusableGlow(
            onTap: controller.performSearch,
            borderRadius: BorderRadius.circular(24),
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              borderRadius: 24,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '重试',
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
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