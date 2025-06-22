/// 应用配置类
class AppConfig {
  /// API基础URL
  static const String apiBaseUrl = 'http://localhost:8080';
  
  /// API版本
  static const String apiVersion = 'v1';
  
  /// 是否使用模拟数据（当API不可用时）
  static const bool useMockData = true;
  
  /// 是否强制使用模拟数据（无论API是否可用）
  static const bool forceMockData = false;
  
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
} 