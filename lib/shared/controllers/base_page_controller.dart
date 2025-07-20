import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/back_button_handler.dart';

/// 页面控制器基类
/// 提供统一的返回键处理和资源管理
abstract class BasePageController extends GetxController {
  final BackButtonHandler _backButtonHandler = Get.find<BackButtonHandler>();
  
  /// 页面返回回调，子类可重写实现自定义返回逻辑
  /// 返回true表示允许返回，false表示阻止返回
  Future<bool> onWillPop() async {
    return true; // 默认允许返回
  }
  
  @override
  void onInit() {
    super.onInit();
    // 注册返回键回调
    _backButtonHandler.registerCallback(onWillPop);
  }
  
  @override
  void onClose() {
    // 移除返回键回调
    _backButtonHandler.unregisterCallback(onWillPop);
    super.onClose();
  }
  
  /// 安全返回上一页
  /// 会触发资源清理逻辑
  void safeGoBack() {
    if (Navigator.canPop(Get.context!)) {
      Get.back();
    }
  }
  
  /// 带参数返回
  void goBackWithResult(dynamic result) {
    if (Navigator.canPop(Get.context!)) {
      Get.back(result: result);
    }
  }
}

/// 播放器页面控制器基类
/// 专门用于需要资源清理的播放器页面
abstract class BasePlayerController extends BasePageController {
  bool _isDisposing = false;
  
  /// 播放器资源清理，子类必须实现
  Future<void> disposePlayer();
  
  @override
  Future<bool> onWillPop() async {
    if (_isDisposing) {
      return false; // 正在清理中，阻止重复操作
    }
    
    _isDisposing = true;
    
    try {
      // 执行播放器资源清理
      await disposePlayer();
      return true; // 允许返回
    } catch (e) {
      // 清理失败，记录错误但仍允许返回
      if (kDebugMode) {
        print('播放器资源清理失败: $e');
      }
      return true;
    } finally {
      _isDisposing = false;
    }
  }
  
  @override
  void onClose() {
    if (!_isDisposing) {
      disposePlayer();
    }
    super.onClose();
  }
}