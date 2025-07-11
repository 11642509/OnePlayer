/// API相关常量
class ApiConstants {
  // 基础URL
  static const String baseUrl = 'https://api.oneplayer.app';
  
  // API版本
  static const String apiVersion = 'v1';
  
  // 端点
  static const String categoriesEndpoint = '/categories';
  static const String videosEndpoint = '/videos';
  static const String searchEndpoint = '/search';
  
  // 超时设置 (毫秒)
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
  static const int sendTimeout = 30000;
  
  // 分页
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
}