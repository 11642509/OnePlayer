import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../shared/utils/performance_manager.dart';
import '../../../shared/widgets/common/glass_container.dart';
import '../../../app/config/config.dart';
import '../controllers/settings_controller.dart';
import '../../../core/remote_control/universal_focus.dart';
import '../../../shared/controllers/window_controller.dart';
import '../../../features/video_on_demand/controllers/vod_controller.dart';
import '../widgets/cms_site_manager.dart';

/// 设置页面 - 使用统一毛玻璃风格
class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final performance = Get.find<PerformanceManager>();
    final windowController = Get.find<WindowController>();
    
    return Obx(() {
        // 确保控制器已初始化
        if (!Get.isRegistered<SettingsController>()) {
          Get.put(SettingsController());
        }
        
        // 使用WindowController统一判断横竖屏，与其他页面保持一致
        final isPortrait = windowController.isPortrait.value;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 页面标题
              GlassContainer(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                isPortrait: isPortrait,
                child: Text(
                  '⚙️ 设置',
                  style: TextStyle(
                    color: isPortrait ? Colors.grey[800] : Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 性能设置区域
              GlassSection(
                title: '性能设置',
                isPortrait: isPortrait,
                children: [
                  GlassOption(
                    title: '视觉质量',
                    subtitle: _getQualityDescription(performance.visualQuality),
                    trailing: Icon(Icons.chevron_right, color: isPortrait ? Colors.grey[600] : Colors.white54),
                    onTap: () => _showPerformanceSettings(context),
                    isPortrait: isPortrait,
                  ),
                ],
              ),
              
              // 播放设置区域
              GlassSection(
                title: '播放设置',
                isPortrait: isPortrait,
                children: [
                  Obx(() => GlassOption(
                    title: '播放内核',
                    subtitle: _getPlayerKernelDescription(controller.currentPlayerKernel.value),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          controller.currentPlayerKernel.value == PlayerKernel.vlc ? 'VLC' : 'VideoPlayer',
                          style: TextStyle(
                            color: isPortrait ? Colors.grey[700] : Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.chevron_right, color: isPortrait ? Colors.grey[600] : Colors.white54),
                      ],
                    ),
                    onTap: () => _showPlayerKernelDialog(context, controller),
                    isPortrait: isPortrait,
                  )),
                ],
              ),
              
              // 数据设置区域
              GlassSection(
                title: '数据设置',
                isPortrait: isPortrait,
                children: [
                  Obx(() => GlassOption(
                    title: '默认数据站点',
                    subtitle: controller.getSiteName(controller.currentDefaultSite.value),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          controller.getSiteName(controller.currentDefaultSite.value),
                          style: TextStyle(
                            color: isPortrait ? Colors.grey[700] : Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.chevron_right, color: isPortrait ? Colors.grey[600] : Colors.white54),
                      ],
                    ),
                    onTap: () => _showDataSourceDialog(context, controller),
                    isPortrait: isPortrait,
                  )),
                  
                  Obx(() => GlassOption(
                    title: '数据源',
                    subtitle: controller.useMockData.value ? '使用模拟数据（离线模式）' : '使用在线数据',
                    trailing: Switch(
                      value: controller.useMockData.value,
                      onChanged: (value) {
                        controller.toggleMockData(value);
                        _showSettingToast(value ? '已切换到模拟数据' : '已切换到在线数据');
                      },
                      activeColor: isPortrait ? Colors.grey[700] : Colors.white,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onTap: () {
                      final newValue = !controller.useMockData.value;
                      controller.toggleMockData(newValue);
                      _showSettingToast(newValue ? '已切换到模拟数据' : '已切换到在线数据');
                    },
                    isPortrait: isPortrait,
                  )),
                  
                  GlassOption(
                    title: '数据源说明',
                    subtitle: '模拟数据：无需网络，用于测试\n在线数据：需要网络连接',
                    isPortrait: isPortrait,
                  ),
                ],
              ),
              
              // CMS站点管理区域
              GlassSection(
                title: 'CMS管理',
                isPortrait: isPortrait,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: const CmsSiteManager(),
                  ),
                ],
              ),
              
              // 关于设置区域
              GlassSection(
                title: '关于',
                isPortrait: isPortrait,
                children: [
                  GlassOption(
                    title: '应用版本',
                    subtitle: '1.0.0',
                    trailing: Text(
                      'Beta',
                      style: TextStyle(
                        color: isPortrait ? Colors.grey[600] : Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                    isPortrait: isPortrait,
                  ),
                  
                  GlassOption(
                    title: '使用帮助',
                    subtitle: '查看使用说明和常见问题',
                    trailing: Icon(Icons.chevron_right, color: isPortrait ? Colors.grey[600] : Colors.white54),
                    onTap: () => _showHelpDialog(context),
                    isPortrait: isPortrait,
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        );
      });
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
    final windowController = Get.find<WindowController>();
    final isPortrait = windowController.isPortrait.value;
    
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => Center(
        child: GlassContainer(
          width: 240,
          padding: const EdgeInsets.all(16),
          isPortrait: isPortrait,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '视觉质量',
                style: TextStyle(
                  color: isPortrait ? Colors.grey[800] : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 12),
              
              Column(
                children: [
                  _buildCompactOption('高性能', 2, performance, context, isPortrait),
                  _buildCompactOption('平衡', 1, performance, context, isPortrait),
                  _buildCompactOption('节能', 0, performance, context, isPortrait),
                  _buildCompactOption('智能', 3, performance, context, isPortrait),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showDataSourceDialog(BuildContext context, SettingsController controller) {
    final windowController = Get.find<WindowController>();
    final isPortrait = windowController.isPortrait.value;
    
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => Center(
        child: GlassContainer(
          width: 280,
          padding: const EdgeInsets.all(16),
          isPortrait: isPortrait,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '选择默认数据站点',
                style: TextStyle(
                  color: isPortrait ? Colors.grey[800] : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 12),
              
              Column(
                children: controller.availableSites.map((site) {
                  final siteId = site['id'] as String;
                  final siteName = site['name'] as String;
                  return _buildCompactSiteOption(siteName, siteId, controller, context, isPortrait);
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPlayerKernelDialog(BuildContext context, SettingsController controller) {
    final windowController = Get.find<WindowController>();
    final isPortrait = windowController.isPortrait.value;
    
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => Center(
        child: GlassContainer(
          width: 220,
          padding: const EdgeInsets.all(16),
          isPortrait: isPortrait,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '播放内核',
                style: TextStyle(
                  color: isPortrait ? Colors.grey[800] : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 12),
              
              Column(
                children: [
                  _buildCompactKernelOption('VLC', PlayerKernel.vlc, controller, context, isPortrait),
                  _buildCompactKernelOption('VideoPlayer', PlayerKernel.videoPlayer, controller, context, isPortrait),
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
    final context = Get.context;
    if (context == null) return;
    
    final windowController = Get.find<WindowController>();
    final isPortrait = windowController.isPortrait.value;
    
    Get.snackbar(
      '',
      message,
      backgroundColor: isPortrait 
          ? Colors.white.withValues(alpha: 0.85) // 竖屏：半透明白色
          : Colors.white.withValues(alpha: 0.08), // 横屏：原有样式
      colorText: isPortrait ? Colors.grey[800] : Colors.white,
      duration: const Duration(seconds: 1),
      margin: const EdgeInsets.all(16),
      borderRadius: 16,
      borderColor: isPortrait 
          ? Colors.grey.withValues(alpha: 0.25) // 竖屏：灰色边框
          : Colors.white.withValues(alpha: 0.15), // 横屏：白色边框
      borderWidth: 0.2,
      boxShadows: [
        BoxShadow(
          color: isPortrait 
              ? Colors.grey.withValues(alpha: 0.15) // 竖屏：灰色投影
              : Colors.black.withValues(alpha: 0.05), // 横屏：黑色投影
          blurRadius: 20,
          spreadRadius: -5,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: isPortrait 
              ? Colors.white.withValues(alpha: 0.8) // 竖屏：明显白色高光
              : Colors.white.withValues(alpha: 0.15), // 横屏：原有高光
          blurRadius: 1,
          spreadRadius: 0,
          offset: const Offset(0, -0.3),
        ),
      ],
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// 紧凑的性能选项
  Widget _buildCompactOption(String title, int value, PerformanceManager performance, BuildContext context, bool isPortrait) {
    final isSelected = performance.visualQuality == value;
    final textColor = isPortrait ? Colors.grey[800]! : Colors.white;
    final borderColor = isPortrait ? Colors.grey[700]! : Colors.white.withValues(alpha: 0.6);
    final selectedBgColor = isPortrait 
        ? Colors.grey.withValues(alpha: 0.15) 
        : Colors.white.withValues(alpha: 0.15);
    final selectedBorderColor = isPortrait 
        ? Colors.grey.withValues(alpha: 0.4) 
        : Colors.white.withValues(alpha: 0.3);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: UniversalFocus(
        onTap: () {
          performance.setVisualQuality(value);
          Navigator.of(context).pop();
          _showSettingToast('已切换到$title模式');
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? selectedBgColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected 
              ? Border.all(color: selectedBorderColor, width: 1)
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
                    color: borderColor,
                    width: 1.5,
                  ),
                ),
                child: isSelected 
                  ? Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: textColor,
                        ),
                      ),
                    )
                  : null,
              ),
              const SizedBox(width: 10),
              Text(
                title, 
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 紧凑的数据站点选项
  Widget _buildCompactSiteOption(String siteName, String siteId, SettingsController controller, BuildContext context, bool isPortrait) {
    return Obx(() {
      final isSelected = controller.currentDefaultSite.value == siteId;
      final textColor = isPortrait ? Colors.grey[800]! : Colors.white;
      final borderColor = isPortrait ? Colors.grey[700]! : Colors.white.withValues(alpha: 0.6);
      final selectedBgColor = isPortrait 
          ? Colors.grey.withValues(alpha: 0.15) 
          : Colors.white.withValues(alpha: 0.15);
      final selectedBorderColor = isPortrait 
          ? Colors.grey.withValues(alpha: 0.4) 
          : Colors.white.withValues(alpha: 0.3);
      
      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        child: UniversalFocus(
          onTap: () {
            controller.setDefaultSite(siteId);
            Navigator.of(context).pop();
            _showSettingToast('已切换到$siteName');
            
            // 触发影视页重新加载
            _reloadVideoOnDemandPage();
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: isSelected ? selectedBgColor : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected 
                ? Border.all(color: selectedBorderColor, width: 1)
                : Border.all(color: borderColor.withValues(alpha: 0.3), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? selectedBorderColor : borderColor,
                      width: 2,
                    ),
                    color: isSelected ? selectedBgColor : Colors.transparent,
                  ),
                  child: isSelected 
                    ? Icon(
                        Icons.check,
                        size: 10,
                        color: textColor,
                      )
                    : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    siteName,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  /// 紧凑的播放器内核选项
  Widget _buildCompactKernelOption(String title, PlayerKernel kernel, SettingsController controller, BuildContext context, bool isPortrait) {
    return Obx(() {
      final isSelected = controller.currentPlayerKernel.value == kernel;
      final textColor = isPortrait ? Colors.grey[800]! : Colors.white;
      final borderColor = isPortrait ? Colors.grey[700]! : Colors.white.withValues(alpha: 0.6);
      final selectedBgColor = isPortrait 
          ? Colors.grey.withValues(alpha: 0.15) 
          : Colors.white.withValues(alpha: 0.15);
      final selectedBorderColor = isPortrait 
          ? Colors.grey.withValues(alpha: 0.4) 
          : Colors.white.withValues(alpha: 0.3);
      
      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        child: UniversalFocus(
          onTap: () {
            controller.setPlayerKernel(kernel);
            Navigator.of(context).pop();
            _showSettingToast('已切换到$title内核');
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: isSelected ? selectedBgColor : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected 
                ? Border.all(color: selectedBorderColor, width: 1)
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
                      color: borderColor,
                      width: 1.5,
                    ),
                  ),
                  child: isSelected 
                    ? Center(
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: textColor,
                          ),
                        ),
                      )
                    : null,
                ),
                const SizedBox(width: 10),
                Text(
                  title, 
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
  
  /// 重新加载影视页
  void _reloadVideoOnDemandPage() {
    try {
      if (Get.isRegistered<VodController>()) {
        final vodController = Get.find<VodController>();
        
        if (kDebugMode) {
          print('开始重新加载影视页数据，当前默认站点: ${AppConfig.currentDefaultSiteId}');
        }
        
        // 清除所有缓存的数据和状态
        vodController.homeData.clear();
        vodController.categoryData.clear();
        vodController.currentPages.clear();
        vodController.hasMoreStates.clear();
        vodController.categoryLoadingStates.clear();
        vodController.loadingMoreStates.clear();
        vodController.classList.clear();
        
        // 重新设置加载状态
        vodController.isLoading.value = true;
        
        // 调用VodController的初始化方法重新加载数据
        vodController.initializeData();
        
        if (kDebugMode) {
          print('影视页数据重新加载已触发');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('重新加载影视页出错: $e');
      }
    }
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