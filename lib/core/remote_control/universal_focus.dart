import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../shared/controllers/window_controller.dart';

/// 通用焦点组件 - 根据屏幕方向自动调整焦点效果
/// 
/// 横屏模式：参考横屏搜索按钮的毛玻璃效果
/// 竖屏模式：蓝白色的焦点选中效果
class UniversalFocus extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final BorderRadius? borderRadius;
  final FocusNode? focusNode;
  final Function(bool)? onFocusChange;

  const UniversalFocus({
    super.key,
    required this.child,
    required this.onTap,
    this.borderRadius,
    this.focusNode,
    this.onFocusChange,
  });

  @override
  State<UniversalFocus> createState() => _UniversalFocusState();
}

class _UniversalFocusState extends State<UniversalFocus>
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
      duration: const Duration(milliseconds: 200),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
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
    widget.onFocusChange?.call(hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final windowController = Get.find<WindowController>();
      final isPortrait = windowController.isPortrait.value;
      final borderRadius = widget.borderRadius ?? BorderRadius.circular(8);
      
      return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final animValue = _animation.value;
          
          return Focus(
            focusNode: _focusNode,
            onKeyEvent: _handleKeyEvent,
            child: Stack(
              children: [
                // 子组件
                Material(
                  color: Colors.transparent,
                  borderRadius: borderRadius,
                  child: InkWell(
                    onTap: widget.onTap,
                    borderRadius: borderRadius,
                    splashColor: Colors.transparent, // 移除水波纹避免不协调
                    highlightColor: Colors.transparent, // 移除高亮避免不协调
                    hoverColor: Colors.transparent, // 移除悬停效果
                    child: widget.child,
                  ),
                ),
                // 焦点效果覆盖层
                if (animValue > 0)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: borderRadius,
                          border: _buildFocusBorder(isPortrait, animValue),
                          boxShadow: _buildFocusShadow(isPortrait, animValue),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    });
  }

  // 构建焦点边框
  Border _buildFocusBorder(bool isPortrait, double animValue) {
    if (isPortrait) {
      // 竖屏：蓝白色焦点边框
      return Border.all(
        color: const Color(0xFF0288D1).withValues(alpha: 0.8 * animValue), // 蓝色边框
        width: 1.5 * animValue,
      );
    } else {
      // 横屏：参考搜索按钮的毛玻璃边框
      return Border.all(
        color: Colors.white.withValues(alpha: 0.3 * animValue), // 白色毛玻璃边框
        width: 1.0 * animValue,
      );
    }
  }

  // 构建焦点阴影
  List<BoxShadow> _buildFocusShadow(bool isPortrait, double animValue) {
    if (isPortrait) {
      // 竖屏：蓝色焦点辉光
      return [
        BoxShadow(
          color: const Color(0xFF0288D1).withValues(alpha: 0.3 * animValue),
          blurRadius: 8 * animValue,
          spreadRadius: 1 * animValue,
        ),
      ];
    } else {
      // 横屏：白色毛玻璃辉光
      return [
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.15 * animValue),
          blurRadius: 6 * animValue,
          spreadRadius: 0.5 * animValue,
        ),
      ];
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.select || 
          event.logicalKey == LogicalKeyboardKey.enter) {
        widget.onTap();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }
}