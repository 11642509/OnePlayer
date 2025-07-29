import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/unified_site.dart';
import '../models/search_result.dart';
import '../../app/config/config.dart';
import 'package:http/http.dart' as http;

/// 统一站点管理服务 - 所有站点统一存储到SharedPreferences
class UnifiedSiteService extends GetxController {
  static UnifiedSiteService get instance => Get.find();
  
  final RxList<UnifiedSite> _allSites = <UnifiedSite>[].obs;
  final RxString _selectedSiteId = ''.obs;
  final RxBool _isInitialized = false.obs; // 初始化完成标志

  List<UnifiedSite> get allSites => _allSites;
  String get selectedSiteId => _selectedSiteId.value;
  UnifiedSite? get selectedSite => _allSites.firstWhereOrNull((site) => site.id == _selectedSiteId.value);
  bool get isInitialized => _isInitialized.value; // 获取初始化状态

  // 缓存管理
  final Map<String, SearchResponse> _searchCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiration = Duration(minutes: 5);
  static const Duration _timeout = Duration(seconds: 10);

  static const String _selectedSiteKey = 'unified_selected_site';
  static const String _allSitesKey = 'unified_all_sites';
  static const String _initializedKey = 'unified_sites_initialized';

  @override
  void onInit() {
    super.onInit();
    // 异步初始化，但立即开始
    _initializeData();
  }
  
  /// 同步初始化 - 应用启动时调用，确保站点数据立即可用
  void initializeSync() {
    // 首先加载默认配置
    _loadDefaultSites();
    // 然后异步加载用户自定义的站点
    _initializeData();
  }
  
  /// 加载默认站点配置（同步）
  void _loadDefaultSites() {
    // 从AppConfig加载源站点
    final sourceSites = AppConfig.enabledSites
        .where((config) => config['id'] != 'cms')
        .map((config) => UnifiedSite.fromSourceConfig(config))
        .toList();
    
    // 从AppConfig加载默认CMS站点
    final defaultCmsSites = AppConfig.defaultCmsSites
        .map((config) => UnifiedSite(
          id: config['id'] as String,
          name: config['name'] as String,
          url: config['url'] as String,
          type: SiteType.cms,
          iconUrl: config['iconUrl'] as String,
          color: config['color'] as String,
          isEnabled: config['isEnabled'] as bool,
        ))
        .toList();
    
    _allSites.clear();
    _allSites.addAll(sourceSites);
    _allSites.addAll(defaultCmsSites);
    
    // 设置默认选中站点
    if (_allSites.isNotEmpty) {
      _selectedSiteId.value = _allSites.first.id;
    }
    
    _isInitialized.value = true;
    
    if (kDebugMode) {
      print('UnifiedSiteService: 同步加载了 ${sourceSites.length} 个源站点和 ${defaultCmsSites.length} 个CMS站点');
    }
  }

  /// 初始化数据 - 统一从本地存储加载所有站点
  Future<void> _initializeData() async {
    final prefs = await SharedPreferences.getInstance();
    final isInitialized = prefs.getBool(_initializedKey) ?? false;
    
    if (!isInitialized) {
      // 首次启动：从config初始化默认站点
      await _initializeFromConfig();
    } else {
      // 后续启动：直接从本地存储加载
      await _loadFromStorage();
    }
    
    // 清除缓存确保后续获取最新数据
    _clearEnabledSitesCache();
    
    await _loadSelectedSite();
    
    if (kDebugMode) {
      print('UnifiedSiteService: 初始化完成，共 ${_allSites.length} 个站点');
      for (var site in _allSites) {
        print('  - ${site.name} (${site.type.toString().split('.').last})');
      }
    }
    
    _isInitialized.value = true; // 标记初始化完成
  }

  /// 首次启动：从config初始化默认站点到本地存储
  Future<void> _initializeFromConfig() async {
    if (kDebugMode) {
      print('UnifiedSiteService: 首次启动，从config初始化站点');
    }
    
    // 从AppConfig加载源站点
    final sourceSites = AppConfig.enabledSites
        .where((config) => config['id'] != 'cms')
        .map((config) => UnifiedSite.fromSourceConfig(config))
        .toList();
    
    // 从AppConfig加载默认CMS站点
    final defaultCmsSites = AppConfig.defaultCmsSites
        .map((config) => UnifiedSite(
          id: config['id'] as String,
          name: config['name'] as String,
          url: config['url'] as String,
          type: SiteType.cms,
          iconUrl: config['iconUrl'] as String,
          color: config['color'] as String,
          isEnabled: config['isEnabled'] as bool,
        ))
        .toList();
    
    _allSites.addAll(sourceSites);
    _allSites.addAll(defaultCmsSites);
    
    // 保存到本地存储并标记已初始化
    await _saveToStorage();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_initializedKey, true);
    
    if (kDebugMode) {
      print('UnifiedSiteService: 初始化了 ${sourceSites.length} 个源站点和 ${defaultCmsSites.length} 个CMS站点');
    }
  }

  /// 从本地存储加载所有站点
  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sitesJson = prefs.getString(_allSitesKey);
      
      if (sitesJson != null) {
        final sitesData = jsonDecode(sitesJson) as List;
        _allSites.value = sitesData.map((data) => UnifiedSite.fromJson(data)).toList();
        
        if (kDebugMode) {
          print('UnifiedSiteService: 从本地存储加载了 ${_allSites.length} 个站点');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('UnifiedSiteService: 从本地存储加载站点失败: $e');
      }
    }
  }

  /// 保存所有站点到本地存储
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sitesData = _allSites.map((site) => site.toJson()).toList();
      final sitesJson = jsonEncode(sitesData);
      await prefs.setString(_allSitesKey, sitesJson);
      
      if (kDebugMode) {
        print('UnifiedSiteService: 已保存 ${_allSites.length} 个站点到本地存储');
      }
    } catch (e) {
      if (kDebugMode) {
        print('UnifiedSiteService: 保存站点到本地存储失败: $e');
      }
    }
  }

  /// 添加新站点
  Future<bool> addSite(String name, String url, SiteType type) async {
    if (name.trim().isEmpty || url.trim().isEmpty) {
      return false;
    }

    // 检查URL是否已存在
    if (_allSites.any((site) => site.url == url.trim())) {
      return false;
    }

    // 生成唯一ID
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    
    final newSite = UnifiedSite(
      id: id,
      name: name.trim(),
      url: url.trim(),
      type: type,
      iconUrl: type == SiteType.cms ? 'https://www.example.com/favicon.ico' : '',
      color: type == SiteType.cms ? '#FF9800' : '#2196F3',
      isEnabled: true,
    );

    _allSites.add(newSite);
    _clearEnabledSitesCache(); // 清除缓存，因为新增了启用的站点
    await _saveToStorage();
    
    if (kDebugMode) {
      print('UnifiedSiteService: 已添加站点 $name');
    }
    
    return true;
  }

  /// 加载选中的站点
  Future<void> _loadSelectedSite() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSiteId = prefs.getString(_selectedSiteKey);
      
      if (savedSiteId != null && _allSites.any((site) => site.id == savedSiteId)) {
        _selectedSiteId.value = savedSiteId;
      } else if (_allSites.isNotEmpty) {
        _selectedSiteId.value = _allSites.first.id;
        _saveSelectedSite();
      }
    } catch (e) {
      if (kDebugMode) {
        print('UnifiedSiteService: 加载选中站点失败: $e');
      }
    }
  }

  /// 保存选中的站点
  Future<void> _saveSelectedSite() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedSiteKey, _selectedSiteId.value);
    } catch (e) {
      if (kDebugMode) {
        print('UnifiedSiteService: 保存选中站点失败: $e');
      }
    }
  }

  /// 删除站点（支持源站点和CMS站点）
  Future<bool> removeSite(String siteId) async {
    try {
      final siteIndex = _allSites.indexWhere((site) => site.id == siteId);
      if (siteIndex == -1) {
        return false;
      }
      
      // 直接从本地列表删除
      _allSites.removeAt(siteIndex);
      _clearEnabledSitesCache(); // 清除缓存，因为删除了站点
      
      // 如果删除的是当前选中的站点，选择第一个可用站点
      if (_selectedSiteId.value == siteId) {
        if (_allSites.isNotEmpty) {
          _selectedSiteId.value = _allSites.first.id;
          await _saveSelectedSite();
        } else {
          _selectedSiteId.value = '';
        }
      }
      
      await _saveToStorage();
      
      if (kDebugMode) {
        print('UnifiedSiteService: 已删除站点 $siteId');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('UnifiedSiteService: 删除站点失败 $e');
      }
      return false;
    }
  }

  /// 选择站点
  Future<void> selectSite(String siteId) async {
    if (_allSites.any((site) => site.id == siteId)) {
      _selectedSiteId.value = siteId;
      await _saveSelectedSite();
      
      if (kDebugMode) {
        print('UnifiedSiteService: 已选择站点 $siteId');
      }
    }
  }

  /// 统一的搜索方法
  Future<SearchResponse> searchFromSite(UnifiedSite site, String keyword) async {
    if (keyword.trim().isEmpty) {
      return SearchResponse(
        code: -1,
        message: '搜索关键词不能为空',
        results: [],
        sourceId: site.id,
      );
    }

    final cacheKey = '${site.id}_$keyword';
    
    // 检查缓存
    if (_searchCache.containsKey(cacheKey)) {
      final cachedTime = _cacheTimestamps[cacheKey];
      if (cachedTime != null && DateTime.now().difference(cachedTime) < _cacheExpiration) {
        return _searchCache[cacheKey]!;
      }
    }

    try {
      final endpoint = site.getApiEndpoint();
      final params = site.getApiParams(keyword);
      
      final uri = Uri.parse('${AppConfig.apiBaseUrl}$endpoint').replace(
        queryParameters: params.map((key, value) => MapEntry(key, value.toString())),
      );

      if (kDebugMode) {
        print('UnifiedSiteService: 搜索请求 ${site.name} - $uri');
      }

      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final searchResponse = SearchResponse.fromJson(jsonData, site.id);

        // 缓存结果
        _searchCache[cacheKey] = searchResponse;
        _cacheTimestamps[cacheKey] = DateTime.now();

        return searchResponse;
      } else {
        return SearchResponse(
          code: response.statusCode,
          message: '请求失败: ${response.statusCode}',
          results: [],
          sourceId: site.id,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('UnifiedSiteService: 搜索失败 [${site.name}]: $e');
      }

      return SearchResponse(
        code: -1,
        message: '网络错误: ${e.toString()}',
        results: [],
        sourceId: site.id,
      );
    }
  }

  /// 搜索所有站点
  Future<Map<String, SearchResponse>> searchAllSites(String keyword) async {
    if (keyword.trim().isEmpty) {
      return {};
    }

    final enabledSites = _allSites.where((site) => site.isEnabled).toList();
    final List<Future<MapEntry<String, SearchResponse>>> futures = enabledSites
        .map((site) async {
          final response = await searchFromSite(site, keyword);
          return MapEntry(site.id, response);
        })
        .toList();

    try {
      final results = await Future.wait(futures);
      return Map.fromEntries(results);
    } catch (e) {
      if (kDebugMode) {
        print('UnifiedSiteService: 批量搜索失败: $e');
      }
      return {};
    }
  }

  /// 获取源站点列表
  List<UnifiedSite> get sourceSites => _allSites.where((site) => site.type == SiteType.source).toList();

  /// 获取CMS站点列表
  List<UnifiedSite> get cmsSites => _allSites.where((site) => site.type == SiteType.cms).toList();

  // 缓存启用站点列表，避免每次重新创建导致UI重建
  List<UnifiedSite>? _enabledSitesCache;
  
  /// 获取启用的站点列表
  List<UnifiedSite> get enabledSites {
    _enabledSitesCache ??= _allSites.where((site) => site.isEnabled).toList();
    return _enabledSitesCache!;
  }
  
  /// 清除启用站点缓存（在站点状态变化时调用）
  void _clearEnabledSitesCache() {
    _enabledSitesCache = null;
  }

  /// 根据ID获取站点
  UnifiedSite? getSiteById(String siteId) {
    return _allSites.firstWhereOrNull((site) => site.id == siteId);
  }

  /// 清理过期缓存
  void clearExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = _cacheTimestamps.entries
        .where((entry) => now.difference(entry.value) >= _cacheExpiration)
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      _searchCache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  /// 清理所有缓存
  void clearAllCache() {
    _searchCache.clear();
    _cacheTimestamps.clear();
  }

  /// 获取缓存统计信息
  Map<String, int> getCacheStats() {
    return {
      'total_cached': _searchCache.length,
      'expired_count': _cacheTimestamps.entries
          .where((entry) => DateTime.now().difference(entry.value) >= _cacheExpiration)
          .length,
    };
  }

  /// 重置站点到默认配置 - 供设置页面调用
  Future<void> resetToDefaultConfiguration() async {
    try {
      if (kDebugMode) {
        print('UnifiedSiteService: 开始重置到默认配置');
      }
      
      // 清除当前数据
      _allSites.clear();
      
      // 清除SharedPreferences中的站点数据
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_allSitesKey);
      await prefs.remove(_initializedKey);
      await prefs.remove(_selectedSiteKey);
      
      // 重新从config.dart初始化默认站点
      await _initializeFromConfig();
      
      if (kDebugMode) {
        print('UnifiedSiteService: 重置完成，当前站点数量: ${_allSites.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('UnifiedSiteService: 重置配置失败: $e');
      }
      rethrow;
    }
  }
}