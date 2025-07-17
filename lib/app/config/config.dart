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
  
  /// 支持的数据源
  static const Map<String, String> dataSources = {
    'bilibili': 'bilibili',
    'other': 'other',
  };
  
  /// 默认数据源
  static const String defaultDataSource = 'bilibili';
  
  /// 搜索站点配置
  static const List<Map<String, dynamic>> searchSources = [
    {
      'id': 'bilibili',
      'name': 'B站',
      'apiEndpoint': '/api/v1/bilibili',
      'iconUrl': 'https://www.bilibili.com/favicon.ico',
      'color': '#FF6B9D',
      'isEnabled': true,
    },
    {
      'id': 'iqiyi',
      'name': '爱奇艺',
      'apiEndpoint': '/api/v1/iqiyi',
      'iconUrl': 'https://www.iqiyi.com/favicon.ico',
      'color': '#00C851',
      'isEnabled': true,
    },
    {
      'id': 'youku',
      'name': '优酷',
      'apiEndpoint': '/api/v1/youku',
      'iconUrl': 'https://www.youku.com/favicon.ico',
      'color': '#1976D2',
      'isEnabled': true,
    },
    {
      'id': 'tencent',
      'name': '腾讯视频',
      'apiEndpoint': '/api/v1/tencent',
      'iconUrl': 'https://v.qq.com/favicon.ico',
      'color': '#FF9800',
      'isEnabled': true,
    },
    {
      'id': 'mgtv',
      'name': '芒果TV',
      'apiEndpoint': '/api/v1/mgtv',
      'iconUrl': 'https://www.mgtv.com/favicon.ico',
      'color': '#FFC107',
      'isEnabled': true,
    },
  ];
}

/// 播放器内核枚举
enum PlayerKernel {
  vlc,        // VLC内核
  videoPlayer, // Flutter官方video_player内核
} 