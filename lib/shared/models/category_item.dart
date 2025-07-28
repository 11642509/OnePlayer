/// 通用分类项模型
/// 可用于影视分类、搜索站点等
class CategoryItem {
  final String id;
  final String name;
  final String? description;
  final int? count; // 添加count支持
  final Map<String, dynamic>? extra; // 额外数据
  
  const CategoryItem({
    required this.id,
    required this.name,
    this.description,
    this.count,
    this.extra,
  });
  
  /// 从影视分类数据创建
  factory CategoryItem.fromVodCategory(Map<String, dynamic> data) {
    return CategoryItem(
      id: data['type_id'] as String,
      name: data['type_name'] as String,
      extra: data,
    );
  }
  
  /// 从搜索源数据创建
  factory CategoryItem.fromSearchSource(dynamic source) {
    if (source is Map<String, dynamic>) {
      return CategoryItem(
        id: source['id'] as String,
        name: source['name'] as String,
        description: source['description'] as String?,
        extra: source,
      );
    } else {
      // 假设source有id和name属性
      return CategoryItem(
        id: source.id as String,
        name: source.name as String,
        extra: {'source': source},
      );
    }
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}