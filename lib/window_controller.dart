import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:math' show sqrt;
import 'package:window_size/window_size.dart' as window_package;

/// 简单的窗口控制类，负责窗口尺寸调整和横竖屏切换
class WindowController {
  // 单例模式
  static final WindowController _instance = WindowController._internal();
  factory WindowController() => _instance;
  WindowController._internal();
  
  // 是否为竖屏状态
  final ValueNotifier<bool> isPortrait = ValueNotifier<bool>(true);
  
  // 方法通道，用于与原生代码通信
  static const MethodChannel _channel = MethodChannel('com.oneplayer.window/orientation');
  
  // 初始化窗口
  Future<void> initialize() async {
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      // 默认为横屏模式
      isPortrait.value = false;
      
      // 设置最小窗口尺寸
      await setMinWindowSize(const Size(640, 360));
      
      // 获取屏幕信息，设置初始窗口尺寸
      try {
        final screen = await getCurrentScreen();
        if (screen != null) {
          final screenWidth = screen.visibleFrame.width;
          final windowWidth = screenWidth * 0.7; // 屏幕宽度的70%
          final windowHeight = windowWidth * 9 / 16; // 16:9比例
          
          await setWindowSize(Size(windowWidth, windowHeight));
          debugPrint('窗口初始化 - 尺寸: ${windowWidth.toInt()} x ${windowHeight.toInt()} (16:9)');
        }
      } catch (e) {
        debugPrint('窗口初始化失败: $e');
      }
    } else {
      // 移动设备默认设置为横屏模式
      isPortrait.value = false;
      
      // 锁定为横屏，禁用自动旋转
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
      ]);
      
      // 应用系统UI设置
      _updateSystemUIOverlays(false);
    }
  }
  
  // 切换横竖屏
  Future<void> toggleOrientation() async {
    // 更新状态
    isPortrait.value = !isPortrait.value;
    
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      try {
        // 通知原生代码切换方向
        await _channel.invokeMethod('toggleOrientation', isPortrait.value);
        
        // 调整窗口尺寸
        final size = await getWindowSize();
        final area = size.width * size.height; // 保持面积不变
        
        Size newSize;
        if (isPortrait.value) {
          // 切换到竖屏: 9:16
          final height = sqrt(area * 16 / 9);
          final width = height * 9 / 16;
          newSize = Size(width, height);
        } else {
          // 切换到横屏: 16:9
          final width = sqrt(area * 16 / 9);
          final height = width * 9 / 16;
          newSize = Size(width, height);
        }
        
        // 更新最小尺寸
        if (isPortrait.value) {
          await setMinWindowSize(const Size(360, 640)); // 竖屏最小尺寸
        } else {
          await setMinWindowSize(const Size(640, 360)); // 横屏最小尺寸
        }
        
        // 应用新的窗口尺寸
        await setWindowSize(newSize);
        
        debugPrint('方向切换: ${isPortrait.value ? "竖屏 (9:16)" : "横屏 (16:9)"}, 新尺寸: ${newSize.width.toInt()} x ${newSize.height.toInt()}');
      } catch (e) {
        debugPrint('方向切换失败: $e');
      }
    } else {
      // 移动设备上手动设置方向
      try {
        // 根据当前状态设置方向
        if (isPortrait.value) {
          // 切换到竖屏模式
          await SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
          ]);
        } else {
          // 切换到横屏模式
          await SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeLeft,
          ]);
        }
        
        // 更新UI显示
        await _updateSystemUIOverlays(isPortrait.value);
        
        debugPrint('移动设备方向手动切换: ${isPortrait.value ? "竖屏" : "横屏"}');
      } catch (e) {
        debugPrint('移动设备方向切换失败: $e');
      }
    }
  }
  
  // 确保当前屏幕方向与设置一致（用于页面返回时）
  Future<void> ensureCorrectOrientation() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    
    try {
      // 根据当前设置的方向状态强制更新屏幕方向
      if (isPortrait.value) {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
      } else {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
        ]);
      }
      
      // 更新UI显示
      await _updateSystemUIOverlays(isPortrait.value);
      
      debugPrint('确保屏幕方向与设置一致: ${isPortrait.value ? "竖屏" : "横屏"}');
    } catch (e) {
      debugPrint('屏幕方向同步失败: $e');
    }
  }
  
  // 更新系统UI元素显示（状态栏、导航栏等）
  Future<void> _updateSystemUIOverlays(bool isPortrait) async {
    if (Platform.isAndroid) {
      // 横屏时隐藏状态栏，竖屏时显示
      if (isPortrait) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ));
      } else {
        // 横屏模式使用沉浸式体验
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      }
    }
  }
  
  // 设置窗口尺寸
  Future<void> setWindowSize(Size size) async {
    if (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) return;
    
    try {
      final screen = await getCurrentScreen();
      if (screen != null) {
        // 计算窗口位置，使其居中
        final screenCenterX = screen.visibleFrame.left + screen.visibleFrame.width / 2;
        final screenCenterY = screen.visibleFrame.top + screen.visibleFrame.height / 2;
        final left = screenCenterX - size.width / 2;
        final top = screenCenterY - size.height / 2;
        
        // 设置窗口位置和尺寸
        final frame = Rect.fromLTWH(left, top, size.width, size.height);
        window_package.setWindowFrame(frame);
      }
    } catch (e) {
      debugPrint('设置窗口尺寸失败: $e');
    }
  }
  
  // 获取窗口尺寸
  Future<Size> getWindowSize() async {
    if (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) {
      return const Size(1280, 720); // 默认尺寸
    }
    
    try {
      final window = await window_package.getWindowInfo();
      return Size(window.frame.width, window.frame.height);
    } catch (e) {
      debugPrint('获取窗口尺寸失败: $e');
      return const Size(1280, 720); // 默认尺寸
    }
  }
  
  // 设置最小窗口尺寸
  Future<void> setMinWindowSize(Size size) async {
    if (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) return;
    
    try {
      window_package.setWindowMinSize(size);
    } catch (e) {
      debugPrint('设置最小窗口尺寸失败: $e');
    }
  }
  
  // 获取当前屏幕
  Future<window_package.Screen?> getCurrentScreen() async {
    try {
      return await window_package.getCurrentScreen();
    } catch (e) {
      debugPrint('获取屏幕信息失败: $e');
      return null;
    }
  }
  
  // 获取屏幕比例
  double getAspectRatio() {
    return isPortrait.value ? 9/16 : 16/9; // 竖屏用9:16，横屏用16:9
  }
}

/*
// 方向变化监听器
class _OrientationObserver extends WidgetsBindingObserver {
  final WindowController controller;
  
  _OrientationObserver(this.controller);
  
  @override
  void didChangeMetrics() {
    // controller._updateOrientation();
  }
} 
*/ 