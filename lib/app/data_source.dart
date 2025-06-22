import 'package:dio/dio.dart';
import 'config.dart';

/// 数据源类型枚举
enum SourceType {
  bilibili,
  other, // 未来可扩展其他数据源
}

/// 通用数据源服务
class DataSource {
  final Dio _dio = Dio();
  String baseUrl;
  SourceType sourceType;
  
  // 单例模式
  static final DataSource _instance = DataSource._internal(
    baseUrl: AppConfig.apiBaseUrl,
    sourceType: SourceType.bilibili,
  );
  
  factory DataSource({String? baseUrl, SourceType? sourceType}) {
    if (baseUrl != null) {
      _instance.baseUrl = baseUrl;
    }
    if (sourceType != null) {
      _instance.sourceType = sourceType;
    }
    return _instance;
  }
  
  DataSource._internal({
    required this.baseUrl,
    required this.sourceType,
  });

  /// 获取首页数据
  Future<Map<String, dynamic>> fetchHomeData() async {
    try {
      String endpoint = '';
      
      // 根据数据源类型确定接口路径
      switch (sourceType) {
        case SourceType.bilibili:
          endpoint = 'bilibili';
          break;
        case SourceType.other:
          endpoint = 'other';
          break;
      }
      
      final response = await _dio.get(AppConfig.getApiPath(endpoint));
      return response.data;
    } catch (e) {
      print('获取首页数据失败: $e');
      if (AppConfig.useMockData) {
        // 如果配置允许使用模拟数据，则在API请求失败时返回模拟数据
        // 这里我们抛出异常，让调用方处理
        throw Exception('获取首页数据失败: $e');
      } else {
        // 如果配置不允许使用模拟数据，则直接抛出异常
        throw Exception('获取首页数据失败: $e');
      }
    }
  }

  /// 获取分类数据
  /// [categoryName] 分类名称
  /// [page] 页码，默认为1
  Future<Map<String, dynamic>> fetchCategoryData(String categoryName, {int page = 1}) async {
    try {
      String endpoint = '';
      Map<String, dynamic> queryParams = {
        't': categoryName,
        'pg': page.toString(),
      };
      
      // 根据数据源类型确定接口路径
      switch (sourceType) {
        case SourceType.bilibili:
          endpoint = 'bilibili';
          break;
        case SourceType.other:
          endpoint = 'other';
          break;
      }
      
      final response = await _dio.get(
        AppConfig.getApiPath(endpoint),
        queryParameters: queryParams,
      );
      return response.data;
    } catch (e) {
      print('获取分类数据失败: $e');
      if (AppConfig.useMockData) {
        // 如果配置允许使用模拟数据，则在API请求失败时返回模拟数据
        // 这里我们抛出异常，让调用方处理
        throw Exception('获取分类数据失败: $e');
      } else {
        // 如果配置不允许使用模拟数据，则直接抛出异常
        throw Exception('获取分类数据失败: $e');
      }
    }
  }
} 