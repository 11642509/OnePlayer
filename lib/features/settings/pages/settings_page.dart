import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../shared/utils/performance_manager.dart';
import '../../../shared/widgets/common/glass_container.dart';
import '../../../app/config/config.dart';
import '../controllers/settings_controller.dart';
import '../../../core/remote_control/universal_focus.dart';
import '../../../core/remote_control/focusable_glow.dart';
import '../../../shared/controllers/window_controller.dart';
import '../../../features/video_on_demand/controllers/vod_controller.dart';
import '../services/cms_site_service.dart';

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
                  
                  GlassOption(
                    title: 'CMS采集站点',
                    subtitle: _getCmsSubtitle(),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getCmsStatusText(),
                          style: TextStyle(
                            color: isPortrait ? Colors.grey[700] : Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.chevron_right, color: isPortrait ? Colors.grey[600] : Colors.white54),
                      ],
                    ),
                    onTap: () => _showCmsManagementDialog(context),
                    isPortrait: isPortrait,
                  ),
                  
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
  
  /// 获取CMS副标题
  String _getCmsSubtitle() {
    try {
      if (Get.isRegistered<CmsSiteService>()) {
        final cmsService = Get.find<CmsSiteService>();
        final sitesCount = cmsService.cmsSites.length;
        final selectedSite = cmsService.selectedSite;
        
        if (sitesCount == 0) {
          return '未配置CMS站点';
        } else if (selectedSite != null) {
          return '已选择: ${selectedSite.name} (共$sitesCount个站点)';
        } else {
          return '共$sitesCount个站点，未选择';
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('获取CMS副标题失败: $e');
      }
    }
    return '暂无配置';
  }
  
  /// 获取CMS状态文本
  String _getCmsStatusText() {
    try {
      if (Get.isRegistered<CmsSiteService>()) {
        final cmsService = Get.find<CmsSiteService>();
        return '${cmsService.cmsSites.length}个站点';
      }
    } catch (e) {
      if (kDebugMode) {
        print('获取CMS状态文本失败: $e');
      }
    }
    return '0个站点';
  }
  
  /// 显示CMS管理弹窗
  void _showCmsManagementDialog(BuildContext context) {
    final windowController = Get.find<WindowController>();
    final isPortrait = windowController.isPortrait.value;
    
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => Center(
        child: GlassContainer(
          width: isPortrait ? 320 : 400,
          padding: const EdgeInsets.all(20),
          isPortrait: isPortrait,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题
              Text(
                'CMS采集站点管理',
                style: TextStyle(
                  color: isPortrait ? Colors.grey[800] : Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // CMS站点列表
              Obx(() {
                final cmsService = Get.find<CmsSiteService>();
                final sites = cmsService.cmsSites;
                final selectedSiteId = cmsService.selectedSiteId;
                
                if (sites.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isPortrait 
                          ? Colors.grey[200]?.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isPortrait ? Colors.grey[300]! : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      '暂无CMS站点\n点击"添加站点"开始配置',
                      style: TextStyle(
                        color: isPortrait ? Colors.grey[600] : Colors.grey[400],
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                
                return Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    child: Column(
                      children: sites.map((site) => 
                        _buildCmsSiteOption(site, selectedSiteId, isPortrait)
                      ).toList(),
                    ),
                  ),
                );
              }),
              
              const SizedBox(height: 16),
              
              // 按钮行
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 添加站点按钮
                  _buildCmsDialogButton(
                    '添加站点',
                    const Color(0xFFFF7BB0),
                    () => _showAddCmsSiteDialog(context),
                    isPortrait,
                  ),
                  
                  // 关闭按钮
                  _buildCmsDialogButton(
                    '关闭',
                    Colors.grey,
                    () => Navigator.of(context).pop(),
                    isPortrait,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// 构建CMS站点选项
  Widget _buildCmsSiteOption(CmsSite site, String selectedSiteId, bool isPortrait) {
    final isSelected = site.id == selectedSiteId;
    final textColor = isPortrait ? Colors.grey[800]! : Colors.white;
    final borderColor = isPortrait ? Colors.grey[700]! : Colors.white.withValues(alpha: 0.6);
    final selectedBgColor = isPortrait 
        ? Colors.grey.withValues(alpha: 0.15) 
        : Colors.white.withValues(alpha: 0.15);
    final selectedBorderColor = isPortrait 
        ? Colors.grey.withValues(alpha: 0.4) 
        : Colors.white.withValues(alpha: 0.3);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: UniversalFocus(
        onTap: () async {
          await Get.find<CmsSiteService>().selectCmsSite(site.id);
          _showSettingToast('已选择: ${site.name}');
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
              // 选择状态指示器
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
              
              // 站点信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      site.name,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      site.url,
                      style: TextStyle(
                        color: isPortrait ? Colors.grey[600] : Colors.grey[400],
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // 删除按钮
              UniversalFocus(
                onTap: () => _confirmDeleteCmsSite(site),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: Colors.red.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// 构建CMS弹窗按钮
  Widget _buildCmsDialogButton(String text, Color color, VoidCallback onPressed, bool isPortrait) {
    return FocusableGlow(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      customGlowColor: color.withValues(alpha: 0.8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
  
  /// 显示添加CMS站点弹窗
  void _showAddCmsSiteDialog(BuildContext context) {
    final windowController = Get.find<WindowController>();
    final isPortrait = windowController.isPortrait.value;
    
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      barrierDismissible: true,
      builder: (context) => _AddCmsSiteDialog(
        key: ValueKey('cms_dialog_${DateTime.now().millisecondsSinceEpoch}'),
        isPortrait: isPortrait,
      ),
    );
  }
  
  /// 确认删除CMS站点
  void _confirmDeleteCmsSite(CmsSite site) {
    final windowController = Get.find<WindowController>();
    final isPortrait = windowController.isPortrait.value;
    
    showDialog(
      context: Get.context!,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => Center(
        child: GlassContainer(
          width: isPortrait ? 280 : 350,
          padding: const EdgeInsets.all(20),
          isPortrait: isPortrait,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '确认删除',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isPortrait ? Colors.grey[800] : Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '确定要删除站点"${site.name}"吗？',
                style: TextStyle(
                  fontSize: 14,
                  color: isPortrait ? Colors.grey[600] : Colors.grey[300],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCmsDialogButton(
                    '取消',
                    Colors.grey,
                    () => Navigator.of(context).pop(),
                    isPortrait,
                  ),
                  _buildCmsDialogButton(
                    '删除',
                    Colors.red,
                    () async {
                      final navigator = Navigator.of(context);
                      await Get.find<CmsSiteService>().removeCmsSite(site.id);
                      navigator.pop();
                      _showSettingToast('站点删除成功');
                    },
                    isPortrait,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 添加CMS站点弹窗组件
class _AddCmsSiteDialog extends StatefulWidget {
  final bool isPortrait;
  
  const _AddCmsSiteDialog({
    super.key,
    required this.isPortrait,
  });
  
  @override
  State<_AddCmsSiteDialog> createState() => _AddCmsSiteDialogState();
}

class _AddCmsSiteDialogState extends State<_AddCmsSiteDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _urlController;
  late final FocusNode _nameFocusNode;
  late final FocusNode _urlFocusNode;
  late final FocusNode _cancelButtonFocusNode;
  late final FocusNode _addButtonFocusNode;
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: '');
    _urlController = TextEditingController(text: '');
    _nameFocusNode = FocusNode();
    _urlFocusNode = FocusNode();
    _cancelButtonFocusNode = FocusNode();
    _addButtonFocusNode = FocusNode();
    
    // 弹窗打开后自动聚焦到第一个输入框
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocusNode.requestFocus();
    });
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _nameFocusNode.dispose();
    _urlFocusNode.dispose();
    _cancelButtonFocusNode.dispose();
    _addButtonFocusNode.dispose();
    super.dispose();
  }
  
  void _showSettingToast(String message) {
    final windowController = Get.find<WindowController>();
    final isPortrait = windowController.isPortrait.value;
    
    Get.snackbar(
      '',
      message,
      backgroundColor: isPortrait 
          ? Colors.white.withValues(alpha: 0.85)
          : Colors.white.withValues(alpha: 0.08),
      colorText: isPortrait ? Colors.grey[800] : Colors.white,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 16,
      borderColor: isPortrait 
          ? Colors.grey.withValues(alpha: 0.25)
          : Colors.white.withValues(alpha: 0.15),
      borderWidth: 0.2,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
  
  Widget _buildDialogButton(String text, Color color, VoidCallback onPressed, FocusNode? focusNode) {
    return FocusableGlow(
      onTap: onPressed,
      focusNode: focusNode,
      borderRadius: BorderRadius.circular(8),
      customGlowColor: color.withValues(alpha: 0.8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;
          
          if (key == LogicalKeyboardKey.arrowDown) {
            if (_nameFocusNode.hasFocus) {
              _urlFocusNode.requestFocus();
            } else if (_urlFocusNode.hasFocus) {
              _cancelButtonFocusNode.requestFocus();
            }
          } else if (key == LogicalKeyboardKey.arrowUp) {
            if (_urlFocusNode.hasFocus) {
              _nameFocusNode.requestFocus();
            } else if (_cancelButtonFocusNode.hasFocus || _addButtonFocusNode.hasFocus) {
              _urlFocusNode.requestFocus();
            }
          } else if (key == LogicalKeyboardKey.arrowLeft) {
            if (_addButtonFocusNode.hasFocus) {
              _cancelButtonFocusNode.requestFocus();
            }
          } else if (key == LogicalKeyboardKey.arrowRight) {
            if (_cancelButtonFocusNode.hasFocus) {
              _addButtonFocusNode.requestFocus();
            }
          }
        }
      },
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: widget.isPortrait ? 350 : 450,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: widget.isPortrait 
                  ? Colors.white.withValues(alpha: 0.95)
                  : Colors.grey[900]!.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: widget.isPortrait 
                    ? Colors.grey.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.15),
                width: 0.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: -5,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.15),
                  blurRadius: 1,
                  spreadRadius: 0,
                  offset: const Offset(0, -0.3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
            Text(
              '添加CMS站点',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: widget.isPortrait ? Colors.grey[800] : Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            
            // 站点名称输入
            Material(
              color: Colors.transparent,
              child: TextField(
                key: const ValueKey('cms_site_name_input'),
                controller: _nameController,
                focusNode: _nameFocusNode,
                textInputAction: TextInputAction.next,
                onSubmitted: (value) {
                  _urlFocusNode.requestFocus();
                },
                decoration: InputDecoration(
                  labelText: '站点名称',
                  hintText: '例如：非凡资源',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: widget.isPortrait ? Colors.grey[400]! : Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: widget.isPortrait ? Colors.grey[400]! : Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: widget.isPortrait ? Colors.grey[600]! : Colors.white.withValues(alpha: 0.6),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: widget.isPortrait 
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.05),
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                ),
                style: TextStyle(
                  color: widget.isPortrait ? Colors.grey[800] : Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // 站点URL输入
            Material(
              color: Colors.transparent,
              child: TextField(
                key: const ValueKey('cms_site_url_input'),
                controller: _urlController,
                focusNode: _urlFocusNode,
                textInputAction: TextInputAction.done,
                onSubmitted: (value) {
                  _cancelButtonFocusNode.requestFocus();
                },
                decoration: InputDecoration(
                  labelText: '站点URL',
                  hintText: 'https://example.com/api.php/provide/vod',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: widget.isPortrait ? Colors.grey[400]! : Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: widget.isPortrait ? Colors.grey[400]! : Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: widget.isPortrait ? Colors.grey[600]! : Colors.white.withValues(alpha: 0.6),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: widget.isPortrait 
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.05),
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                ),
                style: TextStyle(
                  color: widget.isPortrait ? Colors.grey[800] : Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // 按钮行
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDialogButton(
                  '取消',
                  Colors.grey,
                  () => Navigator.of(context).pop(),
                  _cancelButtonFocusNode,
                ),
                _buildDialogButton(
                  '添加',
                  const Color(0xFFFF7BB0),
                  () async {
                    final name = _nameController.text.trim();
                    final url = _urlController.text.trim();
                    
                    if (name.isEmpty || url.isEmpty) {
                      _showSettingToast('请填写完整的站点信息');
                      return;
                    }
                    
                    final navigator = Navigator.of(context);
                    final success = await Get.find<CmsSiteService>().addCmsSite(name, url);
                    if (mounted) {
                      if (success) {
                        navigator.pop();
                        _showSettingToast('站点添加成功');
                      } else {
                        _showSettingToast('站点添加失败，可能URL已存在');
                      }
                    }
                  },
                  _addButtonFocusNode,
                ),
              ],
            ),
          ],
        ),
      ))),
    );
  }
}