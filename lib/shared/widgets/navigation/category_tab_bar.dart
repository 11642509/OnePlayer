import 'package:flutter/material.dart';
import '../../models/category_item.dart';
import '../../../app/theme/typography.dart';
import '../../../core/remote_control/focus_aware_tab.dart';

/// 通用分类TabBar组件
/// 可用于影视页分类导航和搜索页站点选择
class CategoryTabBar extends StatelessWidget {
  final TabController tabController;
  final List<CategoryItem> categories;
  final bool isPortrait;
  final bool isScrollable;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? labelPadding;
  final TabAlignment? tabAlignment;
  
  const CategoryTabBar({
    super.key,
    required this.tabController,
    required this.categories,
    required this.isPortrait,
    this.isScrollable = true,
    this.padding,
    this.labelPadding,
    this.tabAlignment,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const SizedBox();
    }
    
    return TabBar(
      controller: tabController,
      isScrollable: isScrollable,
      tabs: categories.map((category) {
        final tabContent = Text(
          category.name,
          style: TextStyle(
            fontFamily: AppTypography.systemFont,
            fontWeight: FontWeight.w600,
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
      // 根据屏幕方向调整颜色
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
      // 使用传入的参数或默认值
      padding: padding ?? const EdgeInsets.only(left: 16),
      tabAlignment: tabAlignment ?? TabAlignment.start,
      labelPadding: labelPadding ?? EdgeInsets.symmetric(
        horizontal: isPortrait ? 12 : 16,
      ),
    );
  }
}