import 'package:flutter/material.dart';

/// 一个可重用的辉光焦点组件
///
/// 它为子组件添加一个与主题匹配的辉光效果，
/// 并且内置了完整的点击和按键（确认/回车）响应逻辑。
///
/// 新版本采用“轮廓光”+“氛围光”的设计，
/// 通过清晰的边框和柔和的光晕，实现既美观又清晰的焦点指示。
class FocusableGlow extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final BorderRadius borderRadius;

  const FocusableGlow({
    super.key,
    required this.child,
    required this.onTap,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  State<FocusableGlow> createState() => _FocusableGlowState();
}

class _FocusableGlowState extends State<FocusableGlow> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isFocused = _focusNode.hasFocus;
        });
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final glowColor = isDarkMode ? Colors.white : Theme.of(context).primaryColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        border: _isFocused
            ? Border.all(color: glowColor, width: 2.5)
            : Border.all(color: Colors.transparent, width: 2.5),
        boxShadow: _isFocused
            ? [
                // 柔和的氛围辉光
                BoxShadow(
                  color: glowColor.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: InkWell(
        focusNode: _focusNode,
        onTap: widget.onTap,
        borderRadius: widget.borderRadius,
        child: widget.child,
      ),
    );
  }
} 