import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 智能文本框组件 - 支持遥控器键盘响应
class SmartTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final TextStyle? style;
  final InputDecoration? decoration;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  
  // 遥控器导航相关
  final VoidCallback? onNavigateLeft;
  final VoidCallback? onNavigateRight;
  final VoidCallback? onNavigateUp;
  final VoidCallback? onNavigateDown;
  
  const SmartTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.style,
    this.decoration,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.onNavigateLeft,
    this.onNavigateRight,
    this.onNavigateUp,
    this.onNavigateDown,
  });

  @override
  State<SmartTextField> createState() => _SmartTextFieldState();
}

class _SmartTextFieldState extends State<SmartTextField> {
  late FocusNode _focusNode;
  bool _ownsNode = false;
  
  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
      _ownsNode = false;
    } else {
      _focusNode = FocusNode();
      _ownsNode = true;
    }
  }
  
  @override
  void dispose() {
    if (_ownsNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }
  
  /// 处理键盘事件
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    
    // 获取当前光标位置
    final selection = widget.controller.selection;
    final text = widget.controller.text;
    
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        // 如果光标在文本开头，且有左导航回调，则触发左导航
        if (selection.start == 0 && widget.onNavigateLeft != null) {
          widget.onNavigateLeft!();
          return KeyEventResult.handled;
        }
        break;
        
      case LogicalKeyboardKey.arrowRight:
        // 如果光标在文本末尾，且有右导航回调，则触发右导航
        if (selection.end == text.length && widget.onNavigateRight != null) {
          widget.onNavigateRight!();
          return KeyEventResult.handled;
        }
        break;
        
      case LogicalKeyboardKey.arrowUp:
        // 如果是单行文本框，且有上导航回调，则触发上导航
        if (widget.maxLines == 1 && widget.onNavigateUp != null) {
          widget.onNavigateUp!();
          return KeyEventResult.handled;
        }
        break;
        
      case LogicalKeyboardKey.arrowDown:
        // 如果是单行文本框，且有下导航回调，则触发下导航
        if (widget.maxLines == 1 && widget.onNavigateDown != null) {
          widget.onNavigateDown!();
          return KeyEventResult.handled;
        }
        break;
        
      case LogicalKeyboardKey.enter:
        // 如果设置了onSubmitted回调，则触发提交
        if (widget.onSubmitted != null) {
          widget.onSubmitted!(widget.controller.text);
          return KeyEventResult.handled;
        }
        break;
    }
    
    return KeyEventResult.ignored;
  }
  
  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: _handleKeyEvent,
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        style: widget.style,
        decoration: widget.decoration ?? InputDecoration(
          hintText: widget.hintText,
          border: InputBorder.none,
          prefixIcon: widget.prefixIcon,
          suffixIcon: widget.suffixIcon,
        ),
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        maxLines: widget.maxLines,
        enabled: widget.enabled,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        enableInteractiveSelection: true,
        autofocus: false,
      ),
    );
  }
}