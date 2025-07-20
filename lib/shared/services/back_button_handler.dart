import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../controllers/window_controller.dart';
import '../widgets/common/glass_container.dart';
import '../../core/remote_control/focusable_glow.dart';

/// 统一的返回键处理服务
/// 基于GetX架构，提供全局返回键管理和退出确认功能
class BackButtonHandler extends GetxService {
  // 页面回调栈
  final List<Future<bool> Function()> _backCallbacks = [];
  
  // 全局焦点节点，用于处理键盘事件
  late final FocusNode _globalFocusNode;
  
  // 对话框按钮焦点节点
  late final FocusNode _cancelButtonFocusNode;
  late final FocusNode _confirmButtonFocusNode;
  
  @override
  void onInit() {
    super.onInit();
    _globalFocusNode = FocusNode();
    _cancelButtonFocusNode = FocusNode();
    _confirmButtonFocusNode = FocusNode();
    _setupGlobalKeyboardListener();
  }
  
  @override
  void onClose() {
    _globalFocusNode.dispose();
    _cancelButtonFocusNode.dispose();
    _confirmButtonFocusNode.dispose();
    super.onClose();
  }
  
  /// 设置全局键盘监听器
  void _setupGlobalKeyboardListener() {
    ServicesBinding.instance.keyboard.addHandler(_handleGlobalKeyEvent);
  }
  
  /// 处理全局键盘事件
  bool _handleGlobalKeyEvent(KeyEvent event) {
    // 只处理ESC键的按下事件
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      _handleEscapeKey();
      return true; // 表示事件已被处理
    }
    return false; // 让其他组件继续处理事件
  }
  
  /// 注册页面返回回调
  /// 当页面需要自定义返回逻辑时调用此方法
  void registerCallback(Future<bool> Function() callback) {
    _backCallbacks.add(callback);
  }
  
  /// 移除页面返回回调
  void unregisterCallback(Future<bool> Function() callback) {
    _backCallbacks.remove(callback);
  }
  
  /// 处理返回键逻辑
  /// 优先级：页面自定义回调 > GetX路由栈 > 退出确认
  Future<bool> handleBackButton() async {
    // 1. 执行页面自定义回调（如播放器资源清理）
    if (_backCallbacks.isNotEmpty) {
      final callback = _backCallbacks.last;
      final shouldContinue = await callback();
      if (!shouldContinue) {
        return false; // 页面阻止返回
      }
    }
    
    // 2. 检查GetX路由栈
    if (Get.isDialogOpen == true) {
      Get.back(); // 关闭对话框
      return false;
    }
    
    if (Get.isBottomSheetOpen == true) {
      Get.back(); // 关闭底部菜单
      return false;
    }
    
    // 3. 检查是否可以返回上一页
    if (Navigator.canPop(Get.context!)) {
      Get.back();
      return false;
    }
    
    // 4. 到达主页面，执行退出确认逻辑
    return await _handleAppExit();
  }
  
  /// 处理应用退出确认
  Future<bool> _handleAppExit() async {
    // 显示确认对话框
    _showExitHint();
    return false; // 不直接退出应用，通过对话框确认
  }
  
  /// 显示退出确认对话框
  void _showExitHint() {
    final windowController = Get.find<WindowController>();
    final isPortrait = windowController.isPortrait.value;

    // 对话框显示时，默认焦点在取消按钮
    Future.delayed(const Duration(milliseconds: 300), () {
      _cancelButtonFocusNode.requestFocus();
    });

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Focus(
          autofocus: true,
          onKeyEvent: _handleDialogKeyEvent,
          child: GlassContainer(
            width: isPortrait ? 280 : 320,
            padding: const EdgeInsets.all(24),
            borderRadius: 25,
            isPortrait: isPortrait,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '确认退出',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    // 根据横竖屏调整字体颜色，参考主导航栏
                    color: isPortrait ? Colors.grey[800] : Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '确定要退出应用吗？',
                  style: TextStyle(
                    fontSize: 14,
                    // 根据横竖屏调整字体颜色，参考主导航栏
                    color: isPortrait ? Colors.grey[600] : Colors.white.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    // 取消按钮 - 参考主导航栏未选中样式
                    Expanded(
                      child: _buildDialogButton(
                        text: '取消',
                        isPortrait: isPortrait,
                        isPrimary: false,
                        focusNode: _cancelButtonFocusNode,
                        onTap: () => Get.back(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 确认按钮 - 参考主导航栏选中样式
                    Expanded(
                      child: _buildDialogButton(
                        text: '确认退出',
                        isPortrait: isPortrait,
                        isPrimary: true,
                        focusNode: _confirmButtonFocusNode,
                        onTap: () {
                          Get.back();
                          SystemNavigator.pop();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  /// 处理对话框键盘事件，支持左右切换焦点
  KeyEventResult _handleDialogKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        if (_confirmButtonFocusNode.hasFocus) {
          _cancelButtonFocusNode.requestFocus();
          return KeyEventResult.handled;
        }
        break;
      case LogicalKeyboardKey.arrowRight:
        if (_cancelButtonFocusNode.hasFocus) {
          _confirmButtonFocusNode.requestFocus();
          return KeyEventResult.handled;
        }
        break;
      case LogicalKeyboardKey.escape:
      case LogicalKeyboardKey.goBack:
        Get.back(); // 按返回键或ESC键关闭对话框
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.ignored;
  }

  /// 构建对话框按钮，使用FocusableGlow支持遥控器操作
  Widget _buildDialogButton({
    required String text,
    required bool isPortrait,
    required bool isPrimary,
    required FocusNode focusNode,
    required VoidCallback onTap,
  }) {
    // 参考主导航栏的样式配置
    Color backgroundColor;
    Color textColor;
    Color? customGlowColor;
    
    if (isPrimary) {
      // 确认按钮使用选中状态的样式
      backgroundColor = isPortrait 
          ? Colors.grey.withValues(alpha: 0.85)  // 竖屏深色背景
          : Colors.white.withValues(alpha: 0.85); // 横屏白色背景
      textColor = isPortrait 
          ? Colors.white // 竖屏白色文字
          : Colors.black.withValues(alpha: 0.9); // 横屏深色文字
      // 确认按钮使用红色辉光效果
      customGlowColor = isPortrait 
          ? const Color(0xFFFF7BB0) // 竖屏粉红色辉光
          : const Color(0xFFFF5722); // 横屏橙红色辉光
    } else {
      // 取消按钮使用药丸效果样式
      backgroundColor = isPortrait
          ? Colors.grey.withValues(alpha: 0.15) // 竖屏轻微深色
          : Colors.white.withValues(alpha: 0.25); // 横屏轻微白色
      textColor = isPortrait 
          ? Colors.grey[700]! // 竖屏深色文字
          : Colors.white.withValues(alpha: 0.9); // 横屏白色文字
      // 取消按钮使用蓝色辉光效果
      customGlowColor = isPortrait
          ? const Color(0xFF64B5F6) // 竖屏天蓝色辉光
          : const Color(0xFF42A5F5); // 横屏浅蓝色辉光
    }

    return FocusableGlow(
      focusNode: focusNode,
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      customGlowColor: customGlowColor,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(22), // 药丸形状
          // 参考主导航栏的阴影效果
          boxShadow: isPrimary ? [
            BoxShadow(
              color: isPortrait 
                  ? Colors.grey.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: textColor,
              fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
              letterSpacing: 0.2,
              // 参考主导航栏的文字阴影
              shadows: (!isPrimary && !isPortrait) ? [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ] : null,
            ),
          ),
        ),
      ),
    );
  }
  
  /// 创建统一的PopScope Widget
  /// 所有页面都应该使用此方法包装根Widget
  Widget createPopScope({
    required Widget child,
    Future<bool> Function()? onWillPop,
    bool canPop = true,
  }) {
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        // 执行自定义回调
        if (onWillPop != null) {
          final shouldPop = await onWillPop();
          if (!shouldPop) return;
        }
        
        // 执行统一返回处理
        final shouldExit = await handleBackButton();
        if (shouldExit) {
          SystemNavigator.pop(); // 退出应用
        }
      },
      child: child,
    );
  }
  
  /// 处理ESC键按下事件
  void _handleEscapeKey() async {
    final shouldExit = await handleBackButton();
    if (shouldExit) {
      SystemNavigator.pop(); // 退出应用
    }
  }
}