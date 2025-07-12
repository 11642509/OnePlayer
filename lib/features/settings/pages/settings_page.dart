import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../shared/utils/performance_manager.dart';
import '../../../shared/widgets/common/glass_container.dart';
import '../../../app/config/config.dart';
import '../controllers/settings_controller.dart';

/// 设置页面 - 使用统一毛玻璃风格
class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final performance = Get.find<PerformanceManager>();
    
    return Obx(() {
      // 确保控制器已初始化
      if (!Get.isRegistered<SettingsController>()) {
        Get.put(SettingsController());
      }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 页面标题
              GlassContainer(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: const Text(
                  '⚙️ 设置',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 性能设置区域
              GlassSection(
                title: '性能设置',
                children: [
                  GlassOption(
                    title: '视觉质量',
                    subtitle: _getQualityDescription(performance.visualQuality),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                    onTap: () => _showPerformanceSettings(context),
                  ),
                ],
              ),
              
              // 播放设置区域
              GlassSection(
                title: '播放设置',
                children: [
                  Obx(() => GlassOption(
                    title: '播放内核',
                    subtitle: _getPlayerKernelDescription(controller.currentPlayerKernel.value),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          controller.currentPlayerKernel.value == PlayerKernel.vlc ? 'VLC' : 'VideoPlayer',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right, color: Colors.white54),
                      ],
                    ),
                    onTap: () => _showPlayerKernelDialog(context, controller),
                  )),
                ],
              ),
              
              // 数据设置区域
              GlassSection(
                title: '数据设置',
                children: [
                  Obx(() => GlassOption(
                    title: '数据源',
                    subtitle: controller.useMockData.value ? '使用模拟数据（离线模式）' : '使用在线数据',
                    trailing: Switch(
                      value: controller.useMockData.value,
                      onChanged: (value) {
                        controller.toggleMockData(value);
                        _showSettingToast(value ? '已切换到模拟数据' : '已切换到在线数据');
                      },
                      activeColor: Colors.white,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onTap: () {
                      final newValue = !controller.useMockData.value;
                      controller.toggleMockData(newValue);
                      _showSettingToast(newValue ? '已切换到模拟数据' : '已切换到在线数据');
                    },
                  )),
                  
                  GlassOption(
                    title: '数据源说明',
                    subtitle: '模拟数据：无需网络，用于测试\n在线数据：需要网络连接',
                  ),
                ],
              ),
              
              // 关于设置区域
              GlassSection(
                title: '关于',
                children: [
                  GlassOption(
                    title: '应用版本',
                    subtitle: '1.0.0',
                    trailing: const Text(
                      'Beta',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  
                  GlassOption(
                    title: '使用帮助',
                    subtitle: '查看使用说明和常见问题',
                    trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                    onTap: () => _showHelpDialog(context),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
  
  String _getQualityDescription(int quality) {
    switch (quality) {
      case 0: return '节能模式 - 最佳性能';
      case 1: return '平衡模式 - 渐变效果';
      case 2: return '高性能 - 完整微光效果';
      case 3: return '智能模式 - 自动调节';
      default: return '未知';
    }
  }
  
  String _getPlayerKernelDescription(PlayerKernel kernel) {
    switch (kernel) {
      case PlayerKernel.vlc:
        return 'VLC内核 - 兼容性强，支持更多格式';
      case PlayerKernel.videoPlayer:
        return 'VideoPlayer内核 - 性能优秀，系统集成度高';
    }
  }
  
  void _showPerformanceSettings(BuildContext context) {
    final performance = Get.find<PerformanceManager>();
    
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => Center(
        child: GlassContainer(
          width: 240,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '视觉质量',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 12),
              
              Column(
                children: [
                  _buildCompactOption('高性能', 2, performance, context),
                  _buildCompactOption('平衡', 1, performance, context),
                  _buildCompactOption('节能', 0, performance, context),
                  _buildCompactOption('智能', 3, performance, context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showPlayerKernelDialog(BuildContext context, SettingsController controller) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => Center(
        child: GlassContainer(
          width: 220,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '播放内核',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 12),
              
              Column(
                children: [
                  _buildCompactKernelOption('VLC', PlayerKernel.vlc, controller, context),
                  _buildCompactKernelOption('VideoPlayer', PlayerKernel.videoPlayer, controller, context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// 通用设置提示 - 毛玻璃风格
  void _showSettingToast(String message) {
    Get.snackbar(
      '',
      message,
      backgroundColor: Colors.white.withValues(alpha: 0.08), // 与导航栏一致的毛玻璃背景
      colorText: Colors.white,
      duration: const Duration(seconds: 1),
      margin: const EdgeInsets.all(16),
      borderRadius: 16, // 与GlassContainer一致的圆角
      borderColor: Colors.white.withValues(alpha: 0.15), // 极细的玻璃边框
      borderWidth: 0.2,
      boxShadows: [
        // 极轻的玻璃投影
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 20,
          spreadRadius: -5,
          offset: const Offset(0, 8),
        ),
        // 玻璃的内部高光
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.15),
          blurRadius: 1,
          spreadRadius: 0,
          offset: const Offset(0, -0.3),
        ),
      ],
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// 紧凑的性能选项 - 防止溢出
  Widget _buildCompactOption(String title, int value, PerformanceManager performance, BuildContext context) {
    final isSelected = performance.visualQuality == value;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            performance.setVisualQuality(value);
            Navigator.of(context).pop();
            _showSettingToast('已切换到$title模式');
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: isSelected 
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected 
                ? Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1)
                : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                  ),
                  child: isSelected 
                    ? Center(
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : null,
                ),
                const SizedBox(width: 10),
                Text(
                  title, 
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 紧凑的播放器内核选项
  Widget _buildCompactKernelOption(String title, PlayerKernel kernel, SettingsController controller, BuildContext context) {
    return Obx(() {
      final isSelected = controller.currentPlayerKernel.value == kernel;
      
      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              controller.setPlayerKernel(kernel);
              Navigator.of(context).pop();
              _showSettingToast('已切换到$title内核');
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: isSelected 
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: isSelected 
                  ? Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1)
                  : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                    child: isSelected 
                      ? Center(
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : null,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title, 
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          '使用帮助',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          '• 性能设置：根据设备性能调整特效质量\n'
          '• 播放内核：选择适合的视频播放引擎\n'
          '• 数据源：切换在线数据或离线模拟数据\n'
          '• 智能模式：根据设备规格自动调节',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}