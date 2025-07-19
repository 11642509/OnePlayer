import 'package:flutter/material.dart';
import '../../models/category_item.dart';
import '../navigation/category_tab_bar.dart';
import '../video/video_grid_widget.dart';

/// 通用的分类内容页面布局
/// 包含顶部TabBar和内容区域
class CategoryContentLayout extends StatelessWidget {
  final List<CategoryItem> categories;
  final TabController tabController;
  final bool isPortrait;
  final Widget Function(CategoryItem category, bool isPortrait) contentBuilder;
  final EdgeInsetsGeometry? tabBarPadding;
  final Color? backgroundColor;
  
  const CategoryContentLayout({
    super.key,
    required this.categories,
    required this.tabController,
    required this.isPortrait,
    required this.contentBuilder,
    this.tabBarPadding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const SizedBox();
    }
    
    return Column(
      children: [
        // TabBar区域
        Container(
          height: isPortrait ? 48 : 56,
          color: backgroundColor ?? Colors.transparent,
          child: CategoryTabBar(
            tabController: tabController,
            categories: categories,
            isPortrait: isPortrait,
            padding: tabBarPadding,
          ),
        ),
        
        // 内容区域
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: categories.map((category) {
              return contentBuilder(category, isPortrait);
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// 专门用于视频内容的分类页面布局
class VideoCategoryLayout extends StatelessWidget {
  final List<CategoryItem> categories;
  final TabController tabController;
  final bool isPortrait;
  final List Function(CategoryItem category) videoListBuilder;
  final ScrollController Function(CategoryItem category)? scrollControllerBuilder;
  final bool Function(CategoryItem category) isHorizontalLayoutBuilder;
  final VoidCallback Function(CategoryItem category)? onLoadMoreBuilder;
  final bool Function(CategoryItem category)? showLoadMoreBuilder;
  final bool Function(CategoryItem category)? isLoadingMoreBuilder;
  final bool Function(CategoryItem category)? hasMoreBuilder;
  final Function(dynamic video)? onVideoTap;
  final EdgeInsetsGeometry? padding;
  final String? emptyMessage;
  
  const VideoCategoryLayout({
    super.key,
    required this.categories,
    required this.tabController,
    required this.isPortrait,
    required this.videoListBuilder,
    required this.isHorizontalLayoutBuilder,
    this.scrollControllerBuilder,
    this.onLoadMoreBuilder,
    this.showLoadMoreBuilder,
    this.isLoadingMoreBuilder,
    this.hasMoreBuilder,
    this.onVideoTap,
    this.padding,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    return CategoryContentLayout(
      categories: categories,
      tabController: tabController,
      isPortrait: isPortrait,
      contentBuilder: (category, isPortrait) {
        final videoList = videoListBuilder(category);
        
        return VideoGridWidget(
          videoList: videoList,
          scrollController: scrollControllerBuilder?.call(category),
          isPortrait: isPortrait,
          isHorizontalLayout: isHorizontalLayoutBuilder(category),
          onLoadMore: onLoadMoreBuilder?.call(category),
          showLoadMore: showLoadMoreBuilder?.call(category) ?? false,
          isLoadingMore: isLoadingMoreBuilder?.call(category) ?? false,
          hasMore: hasMoreBuilder?.call(category) ?? true,
          onVideoTap: onVideoTap,
          padding: padding,
          emptyMessage: emptyMessage,
        );
      },
    );
  }
}