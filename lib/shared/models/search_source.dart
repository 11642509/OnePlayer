import 'package:flutter/foundation.dart';
import '../../app/config/config.dart';

/// 搜索源站点模型
class SearchSource {
  final String id;
  final String name;
  final String apiEndpoint;
  final String iconUrl;
  final bool isEnabled;
  final String color; // 主题色
  
  // 全局搜索源列表，由SearchController设置
  static List<SearchSource>? _globalSources;
  
  /// 设置全局搜索源列表
  static void setGlobalSources(List<SearchSource> sources) {
    _globalSources = List.from(sources);
  }
  
  const SearchSource({
    required this.id,
    required this.name,
    required this.apiEndpoint,
    required this.iconUrl,
    this.isEnabled = true,
    required this.color,
  });
  
  /// 从配置数据创建SearchSource
  factory SearchSource.fromConfig(Map<String, dynamic> config) {
    return SearchSource(
      id: config['id'] as String,
      name: config['name'] as String,
      apiEndpoint: config['apiEndpoint'] as String,
      iconUrl: config['iconUrl'] as String,
      isEnabled: config['isEnabled'] as bool? ?? true,
      color: config['color'] as String,
    );
  }
  
  /// 从配置文件获取搜索源列表
  static List<SearchSource> getDefaultSources() {
    // 优先使用全局源列表（包含CMS站点）
    if (_globalSources != null && _globalSources!.isNotEmpty) {
      if (kDebugMode) {
        print('使用全局搜索源列表，共 ${_globalSources!.length} 个源：${_globalSources!.map((s) => s.name).join(', ')}');
      }
      return List.from(_globalSources!);
    }
    
    // 回退到静态配置（不包含CMS）
    final sources = AppConfig.searchSources
        .where((config) => config['isEnabled'] == true && config['id'] != 'cms')
        .map((config) => SearchSource.fromConfig(config))
        .toList();
    
    if (kDebugMode) {
      print('回退使用静态搜索源列表，共 ${sources.length} 个源：${sources.map((s) => s.name).join(', ')}');
    }
    
    return sources;
  }
  
  @override
  String toString() => 'SearchSource(id: $id, name: $name)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchSource && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}