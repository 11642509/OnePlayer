import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../../../app/config/config.dart';

/// 设置控制器
class SettingsController extends GetxController {
  // 播放器内核设置
  final Rx<PlayerKernel> _currentPlayerKernel = PlayerKernel.videoPlayer.obs;
  
  // 数据源设置
  final RxBool _useMockData = false.obs;
  
  // Getters
  Rx<PlayerKernel> get currentPlayerKernel => _currentPlayerKernel;
  RxBool get useMockData => _useMockData;
  
  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }
  
  /// 加载当前设置
  void _loadSettings() {
    // 从AppConfig加载当前设置
    _currentPlayerKernel.value = AppConfig.currentPlayerKernel;
    _useMockData.value = AppConfig.forceMockData;
    
    if (kDebugMode) {
      print('设置加载完成: 播放器=${_currentPlayerKernel.value}, 模拟数据=${_useMockData.value}');
    }
  }
  
  /// 设置播放器内核
  void setPlayerKernel(PlayerKernel kernel) {
    _currentPlayerKernel.value = kernel;
    AppConfig.currentPlayerKernel = kernel;
    
    if (kDebugMode) {
      print('播放器内核已切换: $kernel');
    }
  }
  
  /// 切换模拟数据开关
  void toggleMockData(bool useMock) {
    _useMockData.value = useMock;
    AppConfig.forceMockData = useMock;
    
    if (kDebugMode) {
      print('数据源已切换: ${useMock ? '模拟数据' : '在线数据'}');
    }
  }
  
  
  /// 重置所有设置为默认值
  void resetToDefaults() {
    setPlayerKernel(PlayerKernel.videoPlayer);
    toggleMockData(false);
  }
}