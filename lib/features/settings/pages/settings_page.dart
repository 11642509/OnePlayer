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
import '../../../shared/services/unified_site_service.dart';
import '../../../shared/models/unified_site.dart';
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
                  Obx(() => Row(
                    crossAxisAlignment: CrossAxisAlignment.start, // 确保顶部对齐
                    children: [
                      // 左侧：默认数据站点选择区域
                      Expanded(
                        child: GlassOption(
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
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.chevron_right, color: isPortrait ? Colors.grey[600] : Colors.white54),
                            ],
                          ),
                          onTap: () => _showDataSourceDialog(context, controller),
                          isPortrait: isPortrait,
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // 右侧：添加站点按钮 - 使用相同的GlassOption结构
                      SizedBox(
                        width: 60,
                        child: GlassOption(
                          title: '\u200B', // 零宽空格，保持高度但不显示内容
                          subtitle: '\u200B', // 也需要副标题来匹配左侧高度
                          trailing: Icon(
                            Icons.add_circle_outline,
                            color: isPortrait ? Colors.grey[600] : Colors.white54,
                            size: 20,
                          ),
                          onTap: () => _showAddSiteDialog(context),
                          isPortrait: isPortrait,
                        ),
                      ),
                    ],
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
    
    // 强制刷新站点数据 - 新架构下数据统一管理，无需额外操作
    
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
              
              // 恢复为单列布局
              Column(
                children: controller.availableSites.map((site) {
                  final siteId = site['id'] as String;
                  final siteName = site['name'] as String;
                  // 所有站点都可以删除
                  return _buildSingleRowSiteOption(siteName, siteId, controller, context, isPortrait, isDeletable: true);
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

  /// 构建单行左右分开的站点选项
  Widget _buildSingleRowSiteOption(String siteName, String siteId, SettingsController controller, BuildContext context, bool isPortrait, {bool isDeletable = false}) {
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
        child: Row(
          children: [
            // 左侧：站点信息（可点击选择）
            Expanded(
              child: UniversalFocus(
                onTap: () {
                  controller.setDefaultSite(siteId);
                  Navigator.of(context).pop();
                  _showSettingToast('已切换到$siteName');
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
            ),
            
            // 右侧：删除按钮（如果可删除）
            if (isDeletable) ...[
              const SizedBox(width: 12),
              FocusableGlow(
                onTap: () => _deleteSiteDirectly(siteId, siteName, controller, context),
                borderRadius: BorderRadius.circular(8),
                customGlowColor: isPortrait ? Colors.grey.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.2),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isPortrait 
                        ? Colors.grey.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.05),
                    border: Border.all(
                      color: isPortrait ? Colors.grey.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: isPortrait ? Colors.grey[600] : Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }



  /// 直接删除站点（无二次确认）
  void _deleteSiteDirectly(String siteId, String siteName, SettingsController controller, BuildContext context) async {
    if (kDebugMode) {
      print('开始删除站点: $siteId ($siteName)');
    }
    
    bool success = false;
    
    try {
      // 优先使用统一服务删除
      if (Get.isRegistered<UnifiedSiteService>()) {
        final unifiedService = Get.find<UnifiedSiteService>();
        success = await unifiedService.removeSite(siteId);
        if (kDebugMode) {
          print('统一服务删除结果: $success');
        }
      }
      
      // 如果统一服务删除失败，尝试CMS服务删除
      if (!success && Get.isRegistered<CmsSiteService>()) {
        final cmsService = Get.find<CmsSiteService>();
        if (cmsService.cmsSites.any((site) => site.id == siteId)) {
          success = await cmsService.removeCmsSite(siteId);
          if (kDebugMode) {
            print('CMS服务删除结果: $success');
          }
        }
      }
      
      if (success) {
        _showSettingToast('已删除: $siteName');
        
        // 检查是否删除的是当前选中的站点，如果是则需要选择新的默认站点
        if (controller.currentDefaultSite.value == siteId) {
          // 等待一下让数据更新
          await Future.delayed(Duration(milliseconds: 100));
          final availableSites = controller.availableSites;
          if (availableSites.isNotEmpty) {
            final firstSite = availableSites.first;
            controller.setDefaultSite(firstSite['id'] as String);
            _showSettingToast('已自动切换到: ${firstSite['name']}');
          }
        }
      } else {
        _showSettingToast('删除失败: 站点可能不存在或无法删除');
        if (kDebugMode) {
          print('删除站点失败: $siteId');
        }
      }
    } catch (e) {
      _showSettingToast('删除失败: ${e.toString()}');
      if (kDebugMode) {
        print('删除站点异常: $e');
      }
    }
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
  
  /// 显示添加站点弹窗
  void _showAddSiteDialog(BuildContext context) {
    final windowController = Get.find<WindowController>();
    final isPortrait = windowController.isPortrait.value;
    
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      barrierDismissible: true,
      builder: (context) => _AddSiteDialog(
        key: ValueKey('add_site_dialog_${DateTime.now().millisecondsSinceEpoch}'),
        isPortrait: isPortrait,
      ),
    );
  }
  
  
  
  
  
  
  
}

/// 添加站点弹窗组件 - 简洁的单层设计
class _AddSiteDialog extends StatefulWidget {
  final bool isPortrait;
  
  const _AddSiteDialog({
    super.key,
    required this.isPortrait,
  });
  
  @override
  State<_AddSiteDialog> createState() => _AddSiteDialogState();
}

class _AddSiteDialogState extends State<_AddSiteDialog> {
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
        child: GlassContainer(
          width: widget.isPortrait ? 320 : 400,
          padding: const EdgeInsets.all(20),
          isPortrait: widget.isPortrait,
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
              const SizedBox(height: 16),
              
              Text(
                '添加新的CMS采集站点到您的数据源列表',
                style: TextStyle(
                  fontSize: 12,
                  color: widget.isPortrait ? Colors.grey[600] : Colors.grey[400],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              
              // 站点名称输入
              Material(
                color: Colors.transparent,
                child: TextField(
                  key: const ValueKey('site_name_input'),
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
                  key: const ValueKey('site_url_input'),
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
                      final success = await Get.find<UnifiedSiteService>().addSite(name, url, SiteType.cms);
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
        ),
      ),
    );
  }
}