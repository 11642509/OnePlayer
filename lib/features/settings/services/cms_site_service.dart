import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// CMS站点数据模型
class CmsSite {
  final String id;
  final String name;
  final String url;
  bool isSelected;

  CmsSite({
    required this.id,
    required this.name,
    required this.url,
    this.isSelected = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'isSelected': isSelected,
    };
  }

  factory CmsSite.fromJson(Map<String, dynamic> json) {
    return CmsSite(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      isSelected: json['isSelected'] as bool? ?? false,
    );
  }

  CmsSite copyWith({
    String? id,
    String? name,
    String? url,
    bool? isSelected,
  }) {
    return CmsSite(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

/// CMS站点管理服务
class CmsSiteService extends GetxController {
  static CmsSiteService get instance => Get.find();
  
  final RxList<CmsSite> _cmsSites = <CmsSite>[].obs;
  final RxString _selectedSiteId = ''.obs;

  List<CmsSite> get cmsSites => _cmsSites;
  String get selectedSiteId => _selectedSiteId.value;
  CmsSite? get selectedSite => _cmsSites.firstWhereOrNull((site) => site.id == _selectedSiteId.value);

  static const String _cmsSitesKey = 'cms_sites';
  static const String _selectedSiteKey = 'selected_cms_site';

  @override
  void onInit() {
    super.onInit();
    _loadFromStorage();
  }

  /// 从本地存储加载CMS站点配置
  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 加载CMS站点列表
    final sitesJson = prefs.getString(_cmsSitesKey);
    if (sitesJson != null) {
      final sitesData = jsonDecode(sitesJson) as List;
      _cmsSites.value = sitesData.map((data) => CmsSite.fromJson(data)).toList();
    } else {
      // 初始化默认CMS站点
      _initializeDefaultSites();
    }

    // 加载选中的站点ID
    _selectedSiteId.value = prefs.getString(_selectedSiteKey) ?? '';
    
    // 如果没有选中的站点且有可用站点，选择第一个
    if (_selectedSiteId.value.isEmpty && _cmsSites.isNotEmpty) {
      _selectedSiteId.value = _cmsSites.first.id;
      _saveSelectedSite();
    }
  }

  /// 初始化默认CMS站点
  void _initializeDefaultSites() {
    _cmsSites.value = [
      CmsSite(
        id: 'ffzyapi',
        name: '非凡资源',
        url: 'https://cj.ffzyapi.com/api.php/provide/vod/from/ffm3u8',
        isSelected: true,
      ),
      CmsSite(
        id: 'kuaibo',
        name: '快播资源',
        url: 'https://www.kuaibozy.com/api.php/provide/vod',
        isSelected: false,
      ),
    ];
    _selectedSiteId.value = 'ffzyapi';
    _saveToStorage();
  }

  /// 添加新的CMS站点
  Future<bool> addCmsSite(String name, String url) async {
    if (name.trim().isEmpty || url.trim().isEmpty) {
      return false;
    }

    // 生成唯一ID
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    
    // 检查URL是否已存在
    if (_cmsSites.any((site) => site.url == url.trim())) {
      return false;
    }

    final newSite = CmsSite(
      id: id,
      name: name.trim(),
      url: url.trim(),
      isSelected: false,
    );

    _cmsSites.add(newSite);
    
    // 如果是第一个站点，自动选中
    if (_cmsSites.length == 1) {
      _selectedSiteId.value = id;
      newSite.isSelected = true;
    }

    await _saveToStorage();
    return true;
  }

  /// 删除CMS站点
  Future<bool> removeCmsSite(String siteId) async {
    final siteIndex = _cmsSites.indexWhere((site) => site.id == siteId);
    if (siteIndex == -1) {
      return false;
    }

    _cmsSites.removeAt(siteIndex);

    // 如果删除的是当前选中的站点，选择第一个可用站点
    if (_selectedSiteId.value == siteId) {
      if (_cmsSites.isNotEmpty) {
        _selectedSiteId.value = _cmsSites.first.id;
        _cmsSites.first.isSelected = true;
      } else {
        _selectedSiteId.value = '';
      }
    }

    await _saveToStorage();
    return true;
  }

  /// 选择CMS站点
  Future<void> selectCmsSite(String siteId) async {
    // 重置所有站点的选中状态
    for (var site in _cmsSites) {
      site.isSelected = false;
    }

    // 设置新选中的站点
    final selectedSite = _cmsSites.firstWhereOrNull((site) => site.id == siteId);
    if (selectedSite != null) {
      selectedSite.isSelected = true;
      _selectedSiteId.value = siteId;
    }

    await _saveToStorage();
  }

  /// 保存到本地存储
  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 保存CMS站点列表
    final sitesJson = jsonEncode(_cmsSites.map((site) => site.toJson()).toList());
    await prefs.setString(_cmsSitesKey, sitesJson);
    
    await _saveSelectedSite();
  }

  /// 保存选中的站点
  Future<void> _saveSelectedSite() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedSiteKey, _selectedSiteId.value);
  }

  /// 获取当前选中站点的API配置
  Map<String, dynamic>? getCmsApiConfig() {
    final selected = selectedSite;
    if (selected == null) return null;

    return {
      'id': 'cms',
      'name': 'CMS采集',
      'apiEndpoint': '/api/v1/cms',
      'apiUrl': 'http://localhost:8080/api/v1/cms',
      'configUrl': selected.url,
      'color': '#FF9800',
      'isEnabled': true,
    };
  }
}