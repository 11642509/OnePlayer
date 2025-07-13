import 'package:flutter/material.dart';

/// 一个能够感知自身是否被聚焦的Tab子组件。
///
/// 它通过监听父级`FocusNode`的状态，来在聚焦时改变自身的外观，
/// 从而在不干扰`TabBar`自身选择逻辑的情况下，提供清晰的焦点反馈。
class FocusAwareTab extends StatefulWidget {
  final Widget child;

  const FocusAwareTab({
    super.key,
    required this.child,
  });

  @override
  State<FocusAwareTab> createState() => _FocusAwareTabState();
}

class _FocusAwareTabState extends State<FocusAwareTab> {
  FocusNode? _focusNode;
  bool _isFocused = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 从上下文中获取由TabBar为每个Tab创建的FocusNode
    final focusNode = Focus.of(context);
    if (_focusNode != focusNode) {
      _focusNode?.removeListener(_onFocusChanged);
      _focusNode = focusNode;
      _focusNode?.addListener(_onFocusChanged);

      // 确保初始状态正确
      if (_focusNode != null && _isFocused != _focusNode!.hasFocus) {
        _isFocused = _focusNode!.hasFocus;
      }
    }
  }

  @override
  void dispose() {
    _focusNode?.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted && _isFocused != _focusNode?.hasFocus) {
      setState(() {
        _isFocused = _focusNode!.hasFocus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // 聚焦时显示药丸背景，否则不显示
    final BoxDecoration? decoration = _isFocused
        ? BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isDarkMode
                ? Colors.white.withOpacity(0.25)
                : Colors.grey[200],
          )
        : null;
    
    // 为了让药丸背景和文字之间有呼吸感，使用内边距
    return Container(
      decoration: decoration,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: widget.child,
    );
  }
} 