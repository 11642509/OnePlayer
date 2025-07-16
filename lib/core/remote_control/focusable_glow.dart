import 'package:flutter/material.dart';

/// 一个可重用的辉光焦点组件
///
/// 它为子组件添加一个与主题匹配的辉光效果，
/// 并且内置了完整的点击和按键（确认/回车）响应逻辑。
///
/// 精致版本采用"双层辉光"+"渐变边框"设计，
/// 通过清晰的边框和柔和的光晕，实现既美观又清晰的焦点指示。
/// 会根据当前主题（深色/浅色）和环境自动调整视觉效果。
class FocusableGlow extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final BorderRadius borderRadius;
  final Color? customGlowColor; // 允许自定义辉光颜色
  final FocusNode? focusNode; // 支持外部FocusNode
  final Function(bool)? onFocusChange; // 焦点变化回调

  const FocusableGlow({
    super.key,
    required this.child,
    required this.onTap,
    this.borderRadius = BorderRadius.zero,
    this.customGlowColor,
    this.focusNode,
    this.onFocusChange,
  });

  @override
  State<FocusableGlow> createState() => _FocusableGlowState();
}

class _FocusableGlowState extends State<FocusableGlow>
    with SingleTickerProviderStateMixin {
  late final FocusNode _focusNode;
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350), // 稍微延长动画时间，让过渡更加平滑
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuint, // 使用更加平滑的缓动曲线
    );
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    // 只在内部创建的FocusNode才需要释放
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChanged() {
    final hasFocus = _focusNode.hasFocus;
    if (hasFocus) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    // 调用外部回调
    widget.onFocusChange?.call(hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // 使用自定义颜色或根据主题选择默认颜色
    final Color primaryColor = widget.customGlowColor ?? (isDarkMode
        ? const Color(0xFF81D4FA) // 淡蓝色 - 更柔和
        : const Color(0xFF0288D1)); // 蓝色 - 更深沉
    
    // 创建渐变色 - 更加柔和的辅助颜色
    final Color secondaryColor = isDarkMode
        ? const Color(0xFFE1F5FE) // 非常浅的蓝色
        : const Color(0xFF4FC3F7); // 浅蓝色
    
    // 边框渐变色 - 更加精致的渐变
    final List<Color> borderGradient = isDarkMode
        ? [primaryColor, secondaryColor.withValues(alpha: 0.8), primaryColor.withValues(alpha: 0.9)]
        : [primaryColor.withValues(alpha: 0.8), secondaryColor, primaryColor.withValues(alpha: 0.7)];
    
    // 边框宽度 - 稍微减小，更加精致
    final double borderWidth = isDarkMode ? 1.8 : 1.2;
    
    // 双层辉光效果参数 - 更加柔和
    final double innerGlowOpacity = isDarkMode ? 0.6 : 0.35;
    final double outerGlowOpacity = isDarkMode ? 0.25 : 0.15;
    
    final double innerSpreadRadius = isDarkMode ? 1.5 : 0.8;
    final double outerSpreadRadius = isDarkMode ? 3.0 : 1.5;
    
    final double innerBlurRadius = isDarkMode ? 7.0 : 5.0;
    final double outerBlurRadius = isDarkMode ? 14.0 : 10.0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final animValue = _animation.value;
        
        return Container(
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            border: animValue > 0 ? _buildAnimatedBorder(
              borderGradient, 
              borderWidth * animValue, 
              widget.borderRadius,
            ) : null,
            boxShadow: animValue > 0
                ? [
                    // 内层辉光 - 更亮、更集中
                    BoxShadow(
                      color: primaryColor.withValues(alpha: innerGlowOpacity * animValue),
                      blurRadius: innerBlurRadius * animValue,
                      spreadRadius: innerSpreadRadius * animValue,
                    ),
                    // 外层辉光 - 更柔和、更扩散
                    BoxShadow(
                      color: secondaryColor.withValues(alpha: outerGlowOpacity * animValue),
                      blurRadius: outerBlurRadius * animValue,
                      spreadRadius: outerSpreadRadius * animValue,
                    ),
                  ]
                : null,
          ),
          child: child,
        );
      },
      child: InkWell(
        focusNode: _focusNode,
        onTap: widget.onTap,
        borderRadius: widget.borderRadius,
        splashColor: Colors.transparent, // 移除水波纹效果
        highlightColor: Colors.transparent, // 移除高亮效果
        hoverColor: Colors.transparent, // 移除悬停效果
        child: widget.child,
      ),
    );
  }
  
  // 创建渐变边框
  Border _buildAnimatedBorder(List<Color> colors, double width, BorderRadius borderRadius) {
    // 根据边框半径调整边框样式
    if (borderRadius == BorderRadius.zero) {
      return Border(
        top: _buildBorderSide(colors, width),
        right: _buildBorderSide(colors, width),
        bottom: _buildBorderSide(colors, width),
        left: _buildBorderSide(colors, width),
      );
    } else {
      return Border.all(
        color: Color.lerp(colors[0], colors[1], _animation.value) ?? colors[0],
        width: width,
      );
    }
  }
  
  // 创建渐变边框的边
  BorderSide _buildBorderSide(List<Color> colors, double width) {
    return BorderSide(
      color: Color.lerp(
        colors[0], 
        colors[1], 
        _animation.value
      ) ?? colors[0],
      width: width,
    );
  }
} 