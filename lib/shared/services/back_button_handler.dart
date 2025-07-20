import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../controllers/window_controller.dart';
import '../widgets/common/glass_container.dart';

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

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: GlassContainer(
          borderRadius: 25,
          child: Container(
            width: isPortrait ? 280 : 320,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '确认退出',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '确定要退出应用吗？',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Get.back(),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              '取消',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Get.back();
                          SystemNavigator.pop();
                        },
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B9D),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              '确认退出',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
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