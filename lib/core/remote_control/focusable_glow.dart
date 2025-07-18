import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    // 强制使用深色主题的焦点效果，因为我们有宇宙背景
    // 这样确保在深色背景上焦点效果始终可见
    
    // 使用自定义颜色或增强的默认颜色
    final Color primaryColor = widget.customGlowColor ?? const Color(0xFF81D4FA); // 淡蓝色 - 在深色背景上更明显
    
    // 创建渐变色 - 更加醒目的辅助颜色
    final Color secondaryColor = const Color(0xFFE1F5FE); // 非常浅的蓝色
    
    // 边框渐变色 - 更加明显的渐变
    final List<Color> borderGradient = [
      primaryColor, 
      secondaryColor.withValues(alpha: 0.9), 
      primaryColor.withValues(alpha: 0.95)
    ];
    
    // 边框宽度 - 增加宽度使其更明显
    final double borderWidth = 2.5; // 增加边框宽度
    
    // 双层辉光效果参数 - 增强可见性
    final double innerGlowOpacity = 0.8; // 增强内层辉光
    final double outerGlowOpacity = 0.4; // 增强外层辉光
    
    final double innerSpreadRadius = 2.0; // 增加内层扩散
    final double outerSpreadRadius = 4.0; // 增加外层扩散
    
    final double innerBlurRadius = 8.0; // 增加内层模糊
    final double outerBlurRadius = 16.0; // 增加外层模糊

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
      child: Focus(
        focusNode: _focusNode,
        onKeyEvent: _handleKeyEvent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: widget.borderRadius,
          splashColor: Colors.transparent, // 移除水波纹效果
          highlightColor: Colors.transparent, // 移除高亮效果
          hoverColor: Colors.transparent, // 移除悬停效果
          child: widget.child,
        ),
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
  
  /// 处理键盘事件
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.select || 
          event.logicalKey == LogicalKeyboardKey.enter) {
        // 触发点击事件
        widget.onTap();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }
} 