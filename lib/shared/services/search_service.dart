import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/search_source.dart';
import '../models/search_result.dart';

/// 搜索API服务
class SearchService {
  static const String _baseUrl = 'http://localhost:8080';
  static const Duration _timeout = Duration(seconds: 10);
  
  // 搜索结果缓存
  final Map<String, SearchResponse> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiration = Duration(minutes: 5);
  
  /// 单例实例
  static final SearchService _instance = SearchService._internal();
  factory SearchService() => _instance;
  SearchService._internal();
  
  /// 搜索指定源的内容
  Future<SearchResponse> searchFromSource(SearchSource source, String keyword) async {
    if (keyword.trim().isEmpty) {
      return SearchResponse(
        code: -1,
        message: '搜索关键词不能为空',
        results: [],
        sourceId: source.id,
      );
    }
    
    final cacheKey = '${source.id}_$keyword';
    
    // 检查缓存
    if (_cache.containsKey(cacheKey)) {
      final cachedTime = _cacheTimestamps[cacheKey];
      if (cachedTime != null && DateTime.now().difference(cachedTime) < _cacheExpiration) {
        return _cache[cacheKey]!;
      }
    }
    
    try {
      final uri = Uri.parse('$_baseUrl${source.apiEndpoint}').replace(
        queryParameters: {'wd': keyword},
      );
      
      final response = await http.get(uri).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final searchResponse = SearchResponse.fromJson(jsonData, source.id);
        
        // 缓存结果
        _cache[cacheKey] = searchResponse;
        _cacheTimestamps[cacheKey] = DateTime.now();
        
        return searchResponse;
      } else {
        return SearchResponse(
          code: response.statusCode,
          message: '请求失败: ${response.statusCode}',
          results: [],
          sourceId: source.id,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('搜索API调用失败 [${source.name}]: $e');
      }
      
      return SearchResponse(
        code: -1,
        message: '网络错误: ${e.toString()}',
        results: [],
        sourceId: source.id,
      );
    }
  }
  
  /// 搜索多个源（并发）
  Future<Map<String, SearchResponse>> searchFromMultipleSources(
    List<SearchSource> sources, 
    String keyword,
  ) async {
    if (keyword.trim().isEmpty) {
      return {};
    }
    
    final List<Future<MapEntry<String, SearchResponse>>> futures = sources
        .where((source) => source.isEnabled)
        .map((source) async {
          final response = await searchFromSource(source, keyword);
          return MapEntry(source.id, response);
        })
        .toList();
    
    try {
      final results = await Future.wait(futures);
      return Map.fromEntries(results);
    } catch (e) {
      if (kDebugMode) {
        print('批量搜索失败: $e');
      }
      return {};
    }
  }
  
  /// 搜索所有默认源
  Future<Map<String, SearchResponse>> searchAll(String keyword) async {
    final sources = SearchSource.getDefaultSources();
    return await searchFromMultipleSources(sources, keyword);
  }
  
  /// 清理过期缓存
  void clearExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = _cacheTimestamps.entries
        .where((entry) => now.difference(entry.value) >= _cacheExpiration)
        .map((entry) => entry.key)
        .toList();
    
    for (final key in expiredKeys) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }
  
  /// 清理所有缓存
  void clearAllCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }
  
  /// 获取缓存统计信息
  Map<String, int> getCacheStats() {
    return {
      'total_cached': _cache.length,
      'expired_count': _cacheTimestamps.entries
          .where((entry) => DateTime.now().difference(entry.value) >= _cacheExpiration)
          .length,
    };
  }
}