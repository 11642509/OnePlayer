import '../../app/config/config.dart';

/// 搜索源站点模型
class SearchSource {
  final String id;
  final String name;
  final String apiEndpoint;
  final String iconUrl;
  final bool isEnabled;
  final String color; // 主题色
  
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
    return AppConfig.searchSources
        .where((config) => config['isEnabled'] == true)
        .map((config) => SearchSource.fromConfig(config))
        .toList();
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