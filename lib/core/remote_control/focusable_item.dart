import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 一个可聚焦的通用组件，用于遥控器导航
///
/// 它包裹一个子组件，为其提供焦点管理、视觉反馈和按键响应。
/// 模仿Apple TV的视差和高光效果。
class FocusableItem extends StatefulWidget {
  /// 需要被包裹的子组件
  final Widget child;

  /// 当用户按下“确认”键时触发的回调
  final VoidCallback onSelected;

  /// 外部传入的焦点节点，用于更精细的控制
  final FocusNode? focusNode;

  /// 是否自动请求初始焦点
  final bool autofocus;

  const FocusableItem({
    super.key,
    required this.child,
    required this.onSelected,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  State<FocusableItem> createState() => _FocusableItemState();
}

class _FocusableItemState extends State<FocusableItem>
    with SingleTickerProviderStateMixin {
  late final FocusNode _focusNode;
  bool _isFocused = false;

  // 动画控制器，用于驱动视差和高光效果
  late final AnimationController _animationController;
  late final Animation<double> _shineAnimation;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);

    // 初始化动画控制器
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // 高光扫过的时间
    );

    // 创建一个从-1.0到2.0的动画，用于控制高光渐变的位置
    _shineAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.linear,
      ),
    );

    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          FocusScope.of(context).requestFocus(_focusNode);
        }
      });
    }
  }

  void _onFocusChange() {
    if (mounted && _isFocused != _focusNode.hasFocus) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
        if (_isFocused) {
          // 当获得焦点时，重复播放高光动画
          _animationController.repeat();
        } else {
          // 失去焦点时停止动画
          _animationController.stop();
        }
      });
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.select ||
          event.logicalKey == LogicalKeyboardKey.enter) {
        widget.onSelected();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      autofocus: widget.autofocus,
      child: TweenAnimationBuilder<double>(
        // 使用一个统一的动画驱动器
        tween: Tween(begin: 0.0, end: _isFocused ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          // 放大比例从 1.0 (value=0) 到 1.05 (value=1)
          final scale = 1.0 + (0.05 * value); 
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;
          
          // 3D倾斜效果
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001) // 透视
            ..rotateX(0.02 * value)
            ..rotateY(-0.02 * value);

          return Transform.scale(
            scale: scale,
            child: Transform(
              transform: transform,
              alignment: Alignment.center,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  // 阴影也使用动画值，实现平滑过渡
                  boxShadow: [
                    BoxShadow(
                      // 在深色模式下使用辉光，浅色模式下使用阴影
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.2 * value)
                          : Colors.black.withValues(alpha: 0.35 * value),
                      blurRadius: isDarkMode ? 25 * value : 20 * value,
                      spreadRadius: 3 * value,
                      // 辉光居中，阴影向下偏移
                      offset: isDarkMode ? Offset.zero : Offset(0, 10 * value),
                    )
                  ],
                ),
                child: child,
              ),
            ),
          );
        },
        child: GestureDetector(
          onTap: widget.onSelected,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                widget.child,
                // 镜面高光效果层
                if (_isFocused)
                  AnimatedBuilder(
                    animation: _shineAnimation,
                    builder: (context, child) {
                      return ShaderMask(
                        shaderCallback: (rect) {
                          return LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.0),
                              Colors.white.withValues(alpha: 0.2), // 降低高光亮度
                              Colors.white.withValues(alpha: 0.0),
                            ],
                            stops: const [0.4, 0.5, 0.6],
                            transform: GradientRotation(
                              _shineAnimation.value * math.pi / 2, // 减缓旋转速度
                            ),
                          ).createShader(rect);
                        },
                        blendMode: BlendMode.srcATop,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 