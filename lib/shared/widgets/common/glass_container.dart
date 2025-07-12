import 'package:flutter/material.dart';

/// 通用毛玻璃容器 - 与导航栏完全一致的风格
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  
  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.width,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget container = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        // iOS 26 液态玻璃效果 - 与导航栏完全一致
        color: Colors.white.withValues(alpha: 0.08), // 极轻的白色透明度
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15), // 极细的玻璃边框
          width: 0.2,
        ),
        boxShadow: [
          // 极轻的玻璃投影
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            spreadRadius: -5,
            offset: const Offset(0, 8),
          ),
          // 玻璃的内部高光
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.15),
            blurRadius: 1,
            spreadRadius: 0,
            offset: const Offset(0, -0.3),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: Colors.white.withValues(alpha: 0.1),
          highlightColor: Colors.white.withValues(alpha: 0.05),
          child: container,
        ),
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
  
  const GlassOption({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isSelected = false,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      margin: margin ?? const EdgeInsets.only(bottom: 8),
      padding: padding ?? const EdgeInsets.all(16),
      onTap: onTap,
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
                  color: Colors.white.withValues(alpha: 0.6),
                  width: 2,
                ),
              ),
              child: isSelected 
                ? Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
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
    );
  }
}

/// 毛玻璃区域组件 - 用于设置分组
class GlassSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  
  const GlassSection({
    super.key,
    required this.title,
    required this.children,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
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
                color: Colors.white.withValues(alpha: 0.9),
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