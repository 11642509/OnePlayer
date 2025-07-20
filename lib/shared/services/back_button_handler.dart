import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'dart:ui';
import '../controllers/window_controller.dart';

/// 统一的返回键处理服务
/// 基于GetX架构，提供全局返回键管理和退出确认功能
class BackButtonHandler extends GetxService {
  // 页面回调栈
  final List<Future<bool> Function()> _backCallbacks = [];
  
  // 全局焦点节点，用于处理键盘事件
  late final FocusNode _globalFocusNode;
  
  @override
  void onInit() {
    super.onInit();
    _globalFocusNode = FocusNode();
    _setupGlobalKeyboardListener();
  }
  
  @override
  void onClose() {
    _globalFocusNode.dispose();
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
  /// 优先级：页面自定义回调 > GetX路由栈 > 标签页返回 > 退出确认
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
    
    // 4. 检查是否在标签页中，如果是，返回到主标签页
    if (_isInTabPage()) {
      _returnToMainTab();
      return false;
    }
    
    // 5. 到达主页面，执行退出确认逻辑
    return await _handleAppExit();
  }
  
  /// 检查当前是否在标签页中（非主标签页）
  bool _isInTabPage() {
    // 由于已移除影视页和设置页的BackButtonHandler包装，
    // 这个方法现在只在主页面被调用，直接返回false
    return false;
  }
  
  /// 返回到主标签页
  void _returnToMainTab() {
    // 由于影视页和设置页是主页面内的标签内容，不需要特殊处理
    // 直接执行退出确认逻辑
    _showExitHint();
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

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: isPortrait ? 280 : 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            // 降低透明度，使弹窗更不透明
            color: isPortrait 
                ? Colors.white.withValues(alpha: 0.92) // 竖屏：白色背景，更不透明
                : Colors.white.withValues(alpha: 0.15), // 横屏：白色毛玻璃，稍微提高不透明度
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isPortrait 
                  ? Colors.grey.withValues(alpha: 0.3) // 竖屏：灰色边框
                  : Colors.white.withValues(alpha: 0.2), // 横屏：白色边框
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isPortrait 
                    ? Colors.grey.withValues(alpha: 0.25) // 竖屏：灰色投影
                    : Colors.black.withValues(alpha: 0.15), // 横屏：深色投影
                blurRadius: 20,
                spreadRadius: -2,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: isPortrait 
                    ? Colors.white.withValues(alpha: 0.9) // 竖屏：明显白色高光
                    : Colors.white.withValues(alpha: 0.25), // 横屏：白色高光
                blurRadius: 1,
                spreadRadius: 0,
                offset: const Offset(0, -0.5),
              ),
            ],
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // 添加背景模糊效果
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
              ),
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
      ),
      barrierDismissible: true,
    );
  }

  /// 构建对话框按钮，参考主导航栏样式
  Widget _buildDialogButton({
    required String text,
    required bool isPortrait,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    // 参考主导航栏的样式配置
    Color backgroundColor;
    Color textColor;
    
    if (isPrimary) {
      // 确认按钮使用选中状态的样式
      backgroundColor = isPortrait 
          ? Colors.grey.withValues(alpha: 0.85)  // 竖屏深色背景
          : Colors.white.withValues(alpha: 0.85); // 横屏白色背景
      textColor = isPortrait 
          ? Colors.white // 竖屏白色文字
          : Colors.black.withValues(alpha: 0.9); // 横屏深色文字
    } else {
      // 取消按钮使用药丸效果样式
      backgroundColor = isPortrait
          ? Colors.grey.withValues(alpha: 0.15) // 竖屏轻微深色
          : Colors.white.withValues(alpha: 0.25); // 横屏轻微白色
      textColor = isPortrait 
          ? Colors.grey[700]! // 竖屏深色文字
          : Colors.white.withValues(alpha: 0.9); // 横屏白色文字
    }

    return GestureDetector(
      onTap: onTap,
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