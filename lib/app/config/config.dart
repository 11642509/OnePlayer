
/// 播放器内核枚举
enum PlayerKernel {
  videoPlayer,  // 原生 video_player
  vlc,         // VLC Player
}

/// 应用配置类
class AppConfig {
  /// 是否强制使用mock数据
  static bool forceMockData = false;
  
  /// 服务器主机和端口配置（统一API和代理服务器）
  static const String serverHost = '192.168.5.182';
  static const int serverPort = 8080;
  
  /// API相关配置
  static const String apiVersion = 'v1';
  static String get apiBaseUrl => 'http://$serverHost:$serverPort';
  
  /// 代理服务器相关配置
  static const String proxyPath = '/proxy';
  
  /// 播放器内核选择
  static PlayerKernel currentPlayerKernel = PlayerKernel.videoPlayer;
  
  /// 当前选中的数据源类型
  static String currentDataSource = 'ptt';
  
  /// 获取代理服务器URL
  static String getProxyUrl(Map<String, String> queryParams) {
    final uri = Uri(
      scheme: 'http',
      host: serverHost,
      port: serverPort,
      path: proxyPath,
      queryParameters: queryParams,
    );
    return uri.toString();
  }
  
  /// 是否使用模拟数据（当API不可用时）
  static const bool useMockData = true;
  
  /// 获取完整的API路径
  static String getApiPath(String endpoint) {
    return '$apiBaseUrl/api/$apiVersion/$endpoint';
  }
  
  /// 站点配置模型
  static const Map<String, Map<String, dynamic>> siteConfigs = {
    'ptt': {
      'id': 'ptt',
      'name': 'PTT',
      'apiEndpoint': '/api/v1/ptt',
      'apiUrl': 'http://$serverHost:$serverPort/api/v1/ptt',
      'iconUrl': 'https://www.ptt.cc/favicon.ico',
      'color': '#9C27B0',
      'isEnabled': true,
      'isDefault': true,
    },
    'jianpian': {
      'id': 'jianpian',
      'name': '简片',
      'apiEndpoint': '/api/v1/jianpian',
      'apiUrl': 'http://$serverHost:$serverPort/api/v1/jianpian',
      'iconUrl': 'https://www.jianpian.com/favicon.ico',
      'color': '#E91E63',
      'isEnabled': true,
      'isDefault': false,
    },
    'yhdm': {
      'id': 'yhdm',
      'name': '樱花动漫',
      'apiEndpoint': '/api/v1/yhdm',
      'apiUrl': 'http://$serverHost:$serverPort/api/v1/yhdm',
      'iconUrl': 'https://www.yhdm.tv/favicon.ico',
      'color': '#FF5722',
      'isEnabled': true,
      'isDefault': false,
    },
    'bilibili': {
      'id': 'bilibili',
      'name': 'B站',
      'apiEndpoint': '/api/v1/bilibili',
      'apiUrl': 'http://$serverHost:$serverPort/api/v1/bilibili',
      'iconUrl': 'https://www.bilibili.com/favicon.ico',
      'color': '#FF6B9D',
      'isEnabled': true,
      'isDefault': false,
    },
    'iqiyi': {
      'id': 'iqiyi',
      'name': '爱奇艺',
      'apiEndpoint': '/api/v1/iqiyi',
      'apiUrl': 'http://$serverHost:$serverPort/api/v1/iqiyi',
      'iconUrl': 'https://www.iqiyi.com/favicon.ico',
      'color': '#00C851',
      'isEnabled': true,
      'isDefault': false,
    },
    'youku': {
      'id': 'youku',
      'name': '优酷',
      'apiEndpoint': '/api/v1/youku',
      'apiUrl': 'http://$serverHost:$serverPort/api/v1/youku',
      'iconUrl': 'https://www.youku.com/favicon.ico',
      'color': '#1976D2',
      'isEnabled': true,
      'isDefault': false,
    },
    'tencent': {
      'id': 'tencent',
      'name': '腾讯视频',
      'apiEndpoint': '/api/v1/tencent',
      'apiUrl': 'http://$serverHost:$serverPort/api/v1/tencent',
      'iconUrl': 'https://v.qq.com/favicon.ico',
      'color': '#FF9800',
      'isEnabled': false,
      'isDefault': false,
    },
    'mgtv': {
      'id': 'mgtv',
      'name': '芒果TV',
      'apiEndpoint': '/api/v1/mgtv',
      'apiUrl': 'http://$serverHost:$serverPort/api/v1/mgtv',
      'iconUrl': 'https://www.mgtv.com/favicon.ico',
      'color': '#FFC107',
      'isEnabled': false,
      'isDefault': false,
    },
    'cms': {
      'id': 'cms',
      'name': 'CMS采集',
      'apiEndpoint': '/api/v1/cms',
      'apiUrl': 'http://$serverHost:$serverPort/api/v1/cms',
      'iconUrl': 'https://www.example.com/favicon.ico',
      'color': '#FF9800',
      'isEnabled': true,
      'isDefault': false,
    },
  };

  /// 获取数据源选项列表（包括标准站点和CMS）
  static List<Map<String, dynamic>> get dataSourceOptions {
    final List<Map<String, dynamic>> options = [];
    
    // 添加启用的标准站点
    options.addAll(enabledSites);
    
    // CMS选项已经通过enabledSites包含，不需要重复添加
    
    return options;
  }
  
  /// 获取默认站点ID
  static String get defaultSiteId {
    return siteConfigs.entries
        .firstWhere((entry) => entry.value['isDefault'] == true)
        .key;
  }
  
  /// 获取启用的站点列表
  static List<Map<String, dynamic>> get enabledSites {
    return siteConfigs.entries
        .where((entry) => entry.value['isEnabled'] == true)
        .map((entry) => entry.value)
        .toList();
  }
  
  /// 根据站点ID获取站点配置
  static Map<String, dynamic>? getSiteConfig(String siteId) {
    return siteConfigs[siteId];
  }
  
  /// 根据站点ID获取API URL
  static String? getSiteApiUrl(String siteId) {
    final config = getSiteConfig(siteId);
    return config?['apiUrl'] as String?;
  }
  
  /// 获取搜索站点配置（向后兼容）
  static List<Map<String, dynamic>> get searchSources {
    return enabledSites;
  }
  
  // 运行时的默认站点ID（可动态修改）
  static String _runtimeDefaultSiteId = '';
  
  /// 设置运行时默认站点
  static void setRuntimeDefaultSite(String siteId) {
    if (siteConfigs.containsKey(siteId)) {
      _runtimeDefaultSiteId = siteId;
    }
  }
  
  /// 获取当前运行时默认站点ID（优先使用运行时设置）
  static String get currentDefaultSiteId {
    if (_runtimeDefaultSiteId.isNotEmpty && siteConfigs.containsKey(_runtimeDefaultSiteId)) {
      return _runtimeDefaultSiteId;
    }
    return defaultSiteId; // 回退到配置文件中的默认站点
  }
} 