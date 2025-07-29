import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../../../app/config/config.dart';
import '../../../app/data_source.dart';
import '../../../shared/services/unified_site_service.dart';

/// 设置控制器
class SettingsController extends GetxController {
  // 播放器内核设置
  final Rx<PlayerKernel> _currentPlayerKernel = PlayerKernel.videoPlayer.obs;
  
  // 默认站点设置
  final RxString _currentDefaultSite = ''.obs;
  
  // Getters
  Rx<PlayerKernel> get currentPlayerKernel => _currentPlayerKernel;
  RxString get currentDefaultSite => _currentDefaultSite;
  
  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }
  
  /// 加载当前设置
  void _loadSettings() {
    // 从AppConfig加载当前设置
    _currentPlayerKernel.value = AppConfig.currentPlayerKernel;
    _currentDefaultSite.value = AppConfig.currentDefaultSiteId;
    
    if (kDebugMode) {
      print('设置加载完成: 播放器=${_currentPlayerKernel.value}, 默认站点=${_currentDefaultSite.value}');
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
  
  /// 设置默认站点
  void setDefaultSite(String siteId) {
    _currentDefaultSite.value = siteId;
    AppConfig.setRuntimeDefaultSite(siteId);
    
    // 切换DataSource到新的默认站点
    DataSource(siteId: siteId);
    
    if (kDebugMode) {
      print('默认站点已切换: $siteId');
    }
  }
  
  /// 获取站点显示名称
  String getSiteName(String siteId) {
    try {
      if (Get.isRegistered<UnifiedSiteService>()) {
        final siteService = Get.find<UnifiedSiteService>();
        final site = siteService.getSiteById(siteId);
        if (site != null) {
          return site.name;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('从UnifiedSiteService获取站点名称失败: $e');
      }
    }
    
    // 回退到AppConfig
    final config = AppConfig.getSiteConfig(siteId);
    return config?['name'] as String? ?? siteId;
  }
  
  /// 获取所有站点（包括源站点和CMS） - 响应式
  List<Map<String, dynamic>> get availableSites {
    try {
      if (Get.isRegistered<UnifiedSiteService>()) {
        final siteService = Get.find<UnifiedSiteService>();
        // 直接访问响应式变量，确保UI能响应变化
        final sites = siteService.allSites.map((site) => {
          'id': site.id,
          'name': site.name,
          'type': site.type.toString(),
          'url': site.url,
          'isEnabled': site.isEnabled,
        }).toList();
        
        if (kDebugMode) {
          print('SettingsController: 获取到 ${sites.length} 个站点');
          for (var site in sites) {
            print('  - ${site['name']} (${site['type']})');
          }
        }
        
        return sites;
      }
    } catch (e) {
      if (kDebugMode) {
        print('获取统一站点列表失败: $e');
      }
    }
    
    // 回退到原有配置
    if (kDebugMode) {
      print('SettingsController: 回退到AppConfig配置，共 ${AppConfig.dataSourceOptions.length} 个站点');
    }
    return AppConfig.dataSourceOptions;
  }
  
  /// 重置所有设置为默认值
  void resetToDefaults() {
    setPlayerKernel(PlayerKernel.videoPlayer);
    setDefaultSite(AppConfig.defaultSiteId);
  }
}