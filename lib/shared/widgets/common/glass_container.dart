import 'package:flutter/material.dart';
import '../../../core/remote_control/universal_focus.dart';

/// 通用毛玻璃容器 - 与导航栏完全一致的风格
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final bool? isPortrait; // 新增：用于判断屏幕方向
  
  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.width,
    this.height,
    this.onTap,
    this.isPortrait,
  });

  @override
  Widget build(BuildContext context) {
    // 检测屏幕方向，调整毛玻璃容器样式
    final orientation = isPortrait ?? (MediaQuery.of(context).orientation == Orientation.portrait);
    
    Widget container = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        // 根据屏幕方向调整容器颜色
        color: orientation 
            ? Colors.white.withValues(alpha: 0.85) // 竖屏：半透明白色，在亮背景上可见
            : Colors.white.withValues(alpha: 0.08), // 横屏：极轻透明度，保持原有效果
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: orientation
              ? Colors.grey.withValues(alpha: 0.25) // 竖屏：浅灰色边框
              : Colors.white.withValues(alpha: 0.15), // 横屏：白色边框
          width: 0.2,
        ),
        // 为竖屏添加轻微的玻璃效果，类似导航栏风格
        gradient: orientation ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.88), // 左上角稍亮
            Colors.white.withValues(alpha: 0.85), // 中间
            Colors.white.withValues(alpha: 0.82), // 右下角稍暗
          ],
          stops: const [0.0, 0.5, 1.0],
        ) : null,
        boxShadow: [
          // 调整投影颜色
          BoxShadow(
            color: orientation
                ? Colors.grey.withValues(alpha: 0.15) // 竖屏：灰色投影
                : Colors.black.withValues(alpha: 0.05), // 横屏：黑色投影
            blurRadius: 20,
            spreadRadius: -5,
            offset: const Offset(0, 8),
          ),
          // 调整内部高光 - 竖屏使用白色高光，类似导航栏
          BoxShadow(
            color: orientation
                ? Colors.white.withValues(alpha: 0.6) // 竖屏：白色高光，类似导航栏
                : Colors.white.withValues(alpha: 0.15), // 横屏：原有高光
            blurRadius: 1,
            spreadRadius: 0,
            offset: const Offset(0, -0.3), // 从上方照射，类似导航栏
          ),
        ],
      ),
      padding: padding,
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: container,
      );
    }

    return container;
  }
}

/// 毛玻璃选项组件 - 用于设置项
class GlassOption extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isSelected;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool? isPortrait; // 新增：用于判断屏幕方向
  
  const GlassOption({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isSelected = false,
    this.padding,
    this.margin,
    this.isPortrait,
  });

  @override
  Widget build(BuildContext context) {
    // 检测屏幕方向，调整文字颜色
    final orientation = isPortrait ?? (MediaQuery.of(context).orientation == Orientation.portrait);
    final textColor = orientation ? Colors.grey[800]! : Colors.white;
    final subtitleColor = orientation ? Colors.grey[600]! : Colors.white.withValues(alpha: 0.7);
    final indicatorColor = orientation ? Colors.grey[700]! : Colors.white.withValues(alpha: 0.6);
    final containerMargin = margin ?? const EdgeInsets.only(bottom: 8);
    final containerPadding = padding ?? const EdgeInsets.all(16);
    
    return Container(
      margin: containerMargin,
      child: UniversalFocus(
        onTap: onTap ?? () {}, // 提供默认的空回调
        borderRadius: BorderRadius.circular(16),
        child: GlassContainer(
          margin: EdgeInsets.zero, // 移除margin，让焦点边框完全贴合
          padding: containerPadding,
          onTap: onTap,
          isPortrait: orientation,
        child: Row(
          children: [
            // 选择指示器
            if (trailing == null) ...[
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: indicatorColor,
                    width: 2,
                  ),
                ),
                child: isSelected 
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: textColor,
                        ),
                      ),
                    )
                  : null,
              ),
              const SizedBox(width: 12),
            ],
            
            // 内容区域
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // 尾部组件
            if (trailing != null) trailing!,
          ],
        ),
      ),
    ),
    );
  }
}

/// 毛玻璃区域组件 - 用于设置分组
class GlassSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool? isPortrait; // 新增：用于判断屏幕方向
  
  const GlassSection({
    super.key,
    required this.title,
    required this.children,
    this.padding,
    this.margin,
    this.isPortrait,
  });

  @override
  Widget build(BuildContext context) {
    // 检测屏幕方向，调整文字颜色
    final orientation = isPortrait ?? (MediaQuery.of(context).orientation == Orientation.portrait);
    final titleColor = orientation ? Colors.grey[800]! : Colors.white.withValues(alpha: 0.9);
    
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 区域标题
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              title,
              style: TextStyle(
                color: titleColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          // 区域内容
          ...children,
        ],
      ),
    );
  }
}