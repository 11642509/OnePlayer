import '../../features/settings/services/cms_site_service.dart';

/// 站点类型枚举
enum SiteType {
  source,  // 源站点（ptt、bilibili等）
  cms,     // CMS采集站点
}

/// 统一站点模型 - 整合源站点和CMS站点
class UnifiedSite {
  final String id;
  final String name;
  final String url;  // 对于CMS是采集地址，对于源站点是本地路径名
  final SiteType type;
  final String iconUrl;
  final String color;
  final bool isEnabled;
  final bool isSelected;
  
  const UnifiedSite({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    required this.iconUrl,
    required this.color,
    this.isEnabled = true,
    this.isSelected = false,
  });

  /// 从源站点配置创建UnifiedSite
  factory UnifiedSite.fromSourceConfig(Map<String, dynamic> config) {
    return UnifiedSite(
      id: config['id'] as String,
      name: config['name'] as String,
      url: config['id'] as String, // 源站点的url就是id
      type: SiteType.source,
      iconUrl: config['iconUrl'] as String,
      color: config['color'] as String,
      isEnabled: config['isEnabled'] as bool? ?? true,
      isSelected: false,
    );
  }

  /// 从CMS站点创建UnifiedSite
  factory UnifiedSite.fromCms(CmsSite cms) {
    return UnifiedSite(
      id: 'cms_${cms.id}',
      name: cms.name,
      url: cms.url,
      type: SiteType.cms,
      iconUrl: 'https://www.example.com/favicon.ico',
      color: '#FF9800',
      isEnabled: true,
      isSelected: cms.isSelected,
    );
  }

  /// 获取API端点
  String getApiEndpoint() {
    return type == SiteType.cms ? '/api/v1/cms' : '/api/v1/$url';
  }

  /// 获取API参数
  Map<String, dynamic> getApiParams(String keyword) {
    if (type == SiteType.cms) {
      return {'wd': keyword, 'config': url}; // CMS传config参数
    } else {
      return {'wd': keyword}; // 源站点只传关键词
    }
  }

  /// 获取显示用的副标题
  String getSubtitle() {
    return type == SiteType.cms ? url : '本地源站点';
  }

  /// 获取类型描述
  String getTypeDescription() {
    return type == SiteType.cms ? 'CMS采集' : '本地源';
  }

  /// 复制并修改部分属性
  UnifiedSite copyWith({
    String? id,
    String? name,
    String? url,
    SiteType? type,
    String? iconUrl,
    String? color,
    bool? isEnabled,
    bool? isSelected,
  }) {
    return UnifiedSite(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      type: type ?? this.type,
      iconUrl: iconUrl ?? this.iconUrl,
      color: color ?? this.color,
      isEnabled: isEnabled ?? this.isEnabled,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'type': type.toString(),
      'iconUrl': iconUrl,
      'color': color,
      'isEnabled': isEnabled,
      'isSelected': isSelected,
    };
  }

  /// 从JSON创建
  factory UnifiedSite.fromJson(Map<String, dynamic> json) {
    return UnifiedSite(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      type: SiteType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => SiteType.source,
      ),
      iconUrl: json['iconUrl'] as String,
      color: json['color'] as String,
      isEnabled: json['isEnabled'] as bool? ?? true,
      isSelected: json['isSelected'] as bool? ?? false,
    );
  }

  @override
  String toString() => 'UnifiedSite(id: $id, name: $name, type: $type)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UnifiedSite && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}