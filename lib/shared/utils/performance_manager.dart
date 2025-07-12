import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'dart:io';
import '../widgets/backgrounds/cosmic_background.dart';

/// 性能管理器 - 根据设备性能动态调整特效质量
class PerformanceManager extends GetxController {
  static PerformanceManager get to => Get.find();
  
  // 视觉质量等级 - 默认自动模式，适合电视盒子
  final RxInt _visualQuality = 3.obs; // 0: 低, 1: 中, 2: 高, 3: 自动
  
  // 性能指标
  final RxDouble _currentFPS = 60.0.obs;
  final RxBool _isLowEndDevice = false.obs;
  
  // Getters
  int get visualQuality => _visualQuality.value;
  double get currentFPS => _currentFPS.value;
  bool get isLowEndDevice => _isLowEndDevice.value;
  
  // 特效开关 - 修复：用户手动设置应该优先于设备检测
  bool get enableBackgroundEffects {
    if (visualQuality == 3) {
      // 智能模式：根据设备性能自动调整
      return visualQuality >= 2 && !isLowEndDevice;
    } else {
      // 手动模式：尊重用户选择
      return visualQuality >= 2;
    }
  }
  bool get enableShadowEffects => visualQuality >= 1;
  bool get enableAnimations => visualQuality >= 1;
  bool get enableBlurEffects {
    if (visualQuality == 3) {
      return visualQuality >= 2 && currentFPS > 45;
    } else {
      return visualQuality >= 2;
    }
  }
  bool get enableGradientEffects => visualQuality >= 1;
  
  @override
  void onInit() {
    super.onInit();
    _detectDevicePerformance();
    _startPerformanceMonitoring();
  }
  
  /// 检测设备性能 - 简单有效的智能判断
  void _detectDevicePerformance() {
    // 基于设备信息的智能判断
    _isLowEndDevice.value = _isLowEndDeviceBySpecs();
    
    // Debug模式可强制设置
    if (kDebugMode) {
      final forceMode = const String.fromEnvironment('DEVICE_MODE');
      if (forceMode == 'high') {
        _isLowEndDevice.value = false;
      } else if (forceMode == 'low') {
        _isLowEndDevice.value = true;
      }
    }
    
    // 自动模式下，根据设备判断设置初始质量
    if (_visualQuality.value == 3) {
      if (_isLowEndDevice.value) {
        _visualQuality.value = 0; // 低端设备：节能模式
      } else {
        _visualQuality.value = 2; // 高端设备：完整效果
      }
    }
    
    if (kDebugMode) {
      print('智能模式检测: 设备=${_isLowEndDevice.value ? "低端" : "高端"}, 初始质量=${_visualQuality.value}');
    }
  }
  
  /// 基于设备规格判断是否为低端设备
  bool _isLowEndDeviceBySpecs() {
    try {
      // 桌面平台一律高性能
      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        if (kDebugMode) {
          print('桌面平台检测: ${Platform.operatingSystem} - 判定为高端设备');
        }
        return false;
      }
      
      // 获取设备信息
      final view = WidgetsBinding.instance.platformDispatcher.views.first;
      final devicePixelRatio = view.devicePixelRatio;
      final screenSize = view.physicalSize;
      final totalPixels = screenSize.width * screenSize.height;
      final logicalSize = view.physicalSize / devicePixelRatio;
      
      if (kDebugMode) {
        print('设备规格详情:');
        print('  物理分辨率: ${screenSize.width.toInt()}x${screenSize.height.toInt()}');
        print('  逻辑分辨率: ${logicalSize.width.toInt()}x${logicalSize.height.toInt()}');
        print('  像素密度: $devicePixelRatio');
        print('  总像素: ${totalPixels.toInt()}');
      }
      
      // 移动设备和TV盒子判断逻辑
      if (Platform.isAndroid) {
        // 关键：通过像素密度区分手机和TV盒子
        if (devicePixelRatio < 1.5) {
          // 低像素密度通常是TV盒子（接大屏幕但密度低）
          if (kDebugMode) print('Android TV盒子检测: 低像素密度 ($devicePixelRatio) - 判定为低端设备');
          return true;
        } else if (totalPixels > 8000000 && devicePixelRatio > 2.5) {
          // 高分辨率+高密度 = 旗舰手机
          if (kDebugMode) print('Android旗舰设备: 高分辨率+高密度');
          return false;
        } else if (totalPixels < 3000000) {
          // 低分辨率设备
          if (kDebugMode) print('Android低端设备: 低分辨率');
          return true;
        } else {
          // 中等规格手机，默认为标准设备
          if (kDebugMode) print('Android中端设备: 默认为高端');
          return false;
        }
      } else if (Platform.isIOS) {
        // iOS设备通常性能较好，只有很老的设备才算低端
        final isLowEnd = totalPixels < 2000000; // 更严格的标准
        if (kDebugMode) {
          print('iOS设备: ${isLowEnd ? "低端" : "高端"}设备 (总像素: ${totalPixels.toInt()})');
        }
        return isLowEnd;
      } else {
        // 其他平台默认低端
        if (kDebugMode) print('其他平台: 默认低端设备');
        return true;
      }
    } catch (e) {
      // 检测失败，保守估计为低端
      if (kDebugMode) {
        print('设备检测失败: $e，默认为低端设备');
      }
      return true;
    }
  }
  
  /// 性能监控（简化版 - 基于设备规格的一次性判断）
  void _startPerformanceMonitoring() {
    // 不再需要复杂的FPS监控，基于设备规格的判断已经足够准确
    if (kDebugMode) {
      print('性能监控已简化：基于设备规格一次性判断，无需实时FPS监控');
    }
  }
  
  /// 手动设置视觉质量
  void setVisualQuality(int quality) {
    _visualQuality.value = quality.clamp(0, 3);
    
    // 调试信息
    if (kDebugMode) {
      print('手动设置视觉质量: $quality, enableBackgroundEffects: $enableBackgroundEffects, isLowEndDevice: $isLowEndDevice');
    }
    
    // 通知使用GetBuilder的组件更新
    update();
  }
  
  /// 更新FPS数据
  void updateFPS(double fps) {
    _currentFPS.value = fps;
  }
  
  /// 获取推荐的背景组件
  Widget getOptimizedBackground({required Widget child}) {
    if (kDebugMode) {
      print('getOptimizedBackground: visualQuality=$visualQuality, enableBackgroundEffects=$enableBackgroundEffects, enableGradientEffects=$enableGradientEffects');
    }
    
    if (enableBackgroundEffects) {
      // 高质量：使用与视频详情页完全相同的原始宇宙背景
      if (kDebugMode) {
        print('使用原始宇宙背景（与视频详情页相同的微光效果）');
      }
      return CosmicBackground(intensity: 0.8, child: child); // 轻微降低强度以优化性能
    } else if (enableGradientEffects) {
      // 中质量：简单渐变背景
      if (kDebugMode) {
        print('使用渐变背景');
      }
      return _buildGradientBackground(child);
    } else {
      // 低质量：纯色背景
      if (kDebugMode) {
        print('使用纯色背景');
      }
      return _buildSolidBackground(child);
    }
  }
  
  
  /// 渐变背景
  Widget _buildGradientBackground(Widget child) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1A3E),
            Color(0xFF0F0F23),
          ],
        ),
      ),
      child: child,
    );
  }
  
  /// 纯色背景
  Widget _buildSolidBackground(Widget child) {
    return Container(
      color: const Color(0xFF0F0F23),
      child: child,
    );
  }
  
  /// 获取优化的阴影效果
  List<BoxShadow> getOptimizedShadow({bool isCard = false}) {
    if (!enableShadowEffects) return [];
    
    if (isCard && visualQuality >= 2) {
      // 高质量卡片阴影
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];
    } else {
      // 简化阴影
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.15),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];
    }
  }
  
  /// 获取优化的动画时长
  Duration getOptimizedAnimationDuration({Duration? normal}) {
    normal ??= const Duration(milliseconds: 300);
    
    if (!enableAnimations) {
      return Duration.zero; // 禁用动画
    } else if (visualQuality <= 1) {
      return Duration(milliseconds: (normal.inMilliseconds * 0.7).round());
    } else {
      return normal;
    }
  }
}