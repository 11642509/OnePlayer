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
  
  /// 获取预定义的搜索源列表
  static List<SearchSource> getDefaultSources() {
    return [
      const SearchSource(
        id: 'bilibili',
        name: 'B站',
        apiEndpoint: '/api/v1/bilibili',
        iconUrl: 'https://www.bilibili.com/favicon.ico',
        color: '#FF6B9D',
      ),
      const SearchSource(
        id: 'iqiyi',
        name: '爱奇艺',
        apiEndpoint: '/api/v1/iqiyi',
        iconUrl: 'https://www.iqiyi.com/favicon.ico',
        color: '#00C851',
      ),
      const SearchSource(
        id: 'youku',
        name: '优酷',
        apiEndpoint: '/api/v1/youku',
        iconUrl: 'https://www.youku.com/favicon.ico',
        color: '#1976D2',
      ),
      const SearchSource(
        id: 'tencent',
        name: '腾讯视频',
        apiEndpoint: '/api/v1/tencent',
        iconUrl: 'https://v.qq.com/favicon.ico',
        color: '#FF9800',
      ),
      const SearchSource(
        id: 'mgtv',
        name: '芒果TV',
        apiEndpoint: '/api/v1/mgtv',
        iconUrl: 'https://www.mgtv.com/favicon.ico',
        color: '#FFC107',
      ),
    ];
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