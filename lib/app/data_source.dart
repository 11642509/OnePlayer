import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'config.dart';

/// 数据源类型枚举
enum SourceType {
  bilibili,
  other, // 未来可扩展其他数据源
}

/// 视频格式枚举
enum VideoFormat {
  mp4,    // 标准MP4格式
  hls,    // HLS流媒体格式 (.m3u8)
  dash,   // MPEG-DASH格式 (.mpd)
  webm,   // WebM格式
  other,  // 其他格式
}

/// 视频播放配置类
class VideoPlayConfig {
  final String url;
  final Map<String, String> headers;
  final String? userAgent;
  final String? referer;
  final Map<String, dynamic> extra;
  final VideoFormat format;
  
  VideoPlayConfig({
    required this.url,
    this.headers = const {},
    this.userAgent,
    this.referer,
    this.extra = const {},
    this.format = VideoFormat.other,
  });
  
  /// 根据URL或其他信息检测视频格式
  static VideoFormat detectVideoFormat(String url, Map<String, dynamic> data) {
    // 检查URL扩展名
    final String lowerUrl = url.toLowerCase();
    
    // 检查是否为DASH格式
    if (lowerUrl.endsWith('.mpd') || 
        lowerUrl.contains('type=mpd') || 
        data['format'] == 'dash' || 
        data['type'] == 'mpd') {
      return VideoFormat.dash;
    }
    
    // 检查是否为HLS格式
    if (lowerUrl.endsWith('.m3u8') || 
        lowerUrl.contains('type=m3u8') || 
        data['format'] == 'hls' || 
        data['type'] == 'm3u8') {
      return VideoFormat.hls;
    }
    
    // 检查是否为MP4格式
    if (lowerUrl.endsWith('.mp4') || 
        data['format'] == 'mp4' || 
        data['type'] == 'mp4') {
      return VideoFormat.mp4;
    }
    
    // 检查是否为WebM格式
    if (lowerUrl.endsWith('.webm') || 
        data['format'] == 'webm' || 
        data['type'] == 'webm') {
      return VideoFormat.webm;
    }
    
    // 默认为其他格式
    return VideoFormat.other;
  }
  
  /// 判断是否需要使用VLC播放器
  bool needsVlcPlayer() {
    // DASH格式需要使用VLC播放器
    if (format == VideoFormat.dash) {
      return true;
    }
    
    // 其他特殊情况也可能需要VLC播放器
    // 例如某些特殊的HLS流
    if (format == VideoFormat.hls && url.contains('special_parameter')) {
      return true;
    }
    
    // 检查URL中是否包含需要VLC播放器的特定标记
    if (url.contains('use_vlc=true')) {
      return true;
    }
    
    // 默认情况下，对于普通格式使用标准播放器
    return false;
  }
  
  /// 处理代理URL，将 proxy:// 格式转换为实际的HTTP地址
  static String _processProxyUrl(String originalUrl) {
    if (originalUrl.startsWith('proxy://')) {
      try {
        // 移除 proxy:// 前缀
        final urlWithoutPrefix = originalUrl.substring(8);
        
        // 分离URL和片段（如果有）
        String urlPart = urlWithoutPrefix;
        if (urlWithoutPrefix.contains('#')) {
          final parts = urlWithoutPrefix.split('#');
          urlPart = parts[0];
        }
        
        // 解码URL中的参数
        final decodedUrl = Uri.decodeFull(urlPart);
        
        // 将参数转换为查询字符串
        final params = decodedUrl.split('&');
        final queryParams = <String, String>{};
        
        for (final param in params) {
          if (param.contains('=')) {
            final keyValue = param.split('=');
            final key = keyValue[0];
            final value = keyValue.length > 1 ? keyValue[1] : '';
            queryParams[key] = value;
          }
        }
        
        // 使用AppConfig构建代理URL
        final proxyUrl = AppConfig.getProxyUrl(queryParams);
        
        if (kDebugMode) {
          print('原始代理URL: $originalUrl');
          print('转换后的URL: $proxyUrl');
        }
        
        return proxyUrl;
      } catch (e) {
        if (kDebugMode) {
          print('处理代理URL时出错: $e');
          print('使用原始URL: $originalUrl');
        }
        return originalUrl;
      }
    }
    
    return originalUrl;
  }
  
  /// 从API响应中创建配置
  factory VideoPlayConfig.fromApiResponse(Map<String, dynamic> data) {
    // 提取URL - 优先使用playUrl字段
    String url = '';
    
    // 检查是否有playUrl字段
    if (data['playUrl'] != null && data['playUrl'] is String) {
      String playUrlStr = data['playUrl'] as String;
      
      if (kDebugMode) {
        print('发现playUrl字段: $playUrlStr');
      }
      
      // playUrl可能包含多个播放选项，格式如：
      // "清晰 480P#proxy://...#流畅 360P#proxy://..."
      // 我们取第一个选项
      if (playUrlStr.contains('#')) {
        final parts = playUrlStr.split('#');
        // 确保我们取的是URL部分，而不是标题
        for (int i = 0; i < parts.length; i++) {
          if (parts[i].startsWith('proxy://') || 
              parts[i].startsWith('http://') || 
              parts[i].startsWith('https://')) {
            url = parts[i];
            break;
          }
        }
        
        // 如果没有找到合适的URL，取第二个元素（通常是第一个URL）
        if (url.isEmpty && parts.length >= 2) {
          url = parts[1];
        }
      } else {
        url = playUrlStr;
      }
    }
    
    // 如果playUrl字段没有有效的URL，回退到url字段
    if (url.isEmpty && data['url'] != null) {
      url = data['url'] as String;
    }
    
    if (kDebugMode) {
      print('最终使用的URL: $url');
    }
    
    // 处理代理URL
    if (url.startsWith('proxy://')) {
      url = _processProxyUrl(url);
    }
    
    // 提取HTTP头信息
    final Map<String, String> headers = {};
    if (data['header'] != null && data['header'] is Map) {
      final Map<String, dynamic> rawHeaders = data['header'] as Map<String, dynamic>;
      rawHeaders.forEach((key, value) {
        if (value is String) {
          headers[key] = value;
        }
      });
    }
    
    // 提取User-Agent
    String? userAgent = data['ua'] as String?;
    
    // 提取Referer
    String? referer = data['referer'] as String?;
    
    // 如果headers中没有User-Agent但有单独的UA字段，添加到headers
    if (userAgent != null && !headers.containsKey('User-Agent')) {
      headers['User-Agent'] = userAgent;
    }
    
    // 如果headers中没有Referer但有单独的referer字段，添加到headers
    if (referer != null && !headers.containsKey('Referer')) {
      headers['Referer'] = referer;
    }
    
    // 提取其他额外信息
    final Map<String, dynamic> extra = {};
    data.forEach((key, value) {
      if (key != 'url' && key != 'playUrl' && key != 'header' && key != 'ua' && key != 'referer') {
        extra[key] = value;
      }
    });
    
    // 检测视频格式
    final format = detectVideoFormat(url, data);
    
    if (kDebugMode) {
      print('检测到的视频格式: $format');
    }
    
    return VideoPlayConfig(
      url: url,
      headers: headers,
      userAgent: userAgent,
      referer: referer,
      extra: extra,
      format: format,
    );
  }
  
  @override
  String toString() {
    return 'VideoPlayConfig{url: $url, format: $format, headers: $headers, userAgent: $userAgent, referer: $referer, extra: $extra}';
  }
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
      if (kDebugMode) {
        print('获取首页数据失败: $e');
      }
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
      if (kDebugMode) {
        print('获取分类数据失败: $e');
      }
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
  
  /// 获取视频播放地址
  Future<VideoPlayConfig> fetchVideoPlayUrl(String id, String flag) async {
    try {
      if (kDebugMode) {
        print('获取视频播放地址: ${AppConfig.apiBaseUrl}/api/v1/bilibili');
        print('参数: {flag: $flag, id: $id}');
      }
      
      final response = await _dio.get(
        '${AppConfig.apiBaseUrl}/api/v1/bilibili',
        queryParameters: {
          'flag': flag,
          'id': id,
        },
      );
      
      if (kDebugMode) {
        print('视频播放地址响应: ${response.data}');
      }
      
      if (response.data['code'] == 0) {
        final Map<String, dynamic> data = response.data;
        
        // 提取HTTP头信息
        Map<String, String> headers = {};
        String? userAgent;
        String? referer;
        
        if (data['header'] != null && data['header'] is Map) {
          final headerData = data['header'] as Map;
          headers = Map<String, String>.from(headerData.map((key, value) => 
            MapEntry(key.toString(), value.toString())));
            
          // 提取特定的头信息
          userAgent = headers['User-Agent'];
          referer = headers['Referer'];
        }
        
        // 创建播放配置
        final videoUrl = VideoPlayConfig.fromApiResponse(data);
        
        // 检测视频格式
        final format = VideoPlayConfig.detectVideoFormat(videoUrl.url, data);
        
        return VideoPlayConfig(
          url: videoUrl.url,
          headers: headers,
          userAgent: userAgent,
          referer: referer,
          format: format,
          extra: {
            'parse': data['parse'],
            'from': data['from'],
          },
        );
      } else {
        throw Exception('获取播放地址失败: ${response.data['message'] ?? '未知错误'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('获取视频播放地址出错: $e');
      }
      rethrow;
    }
  }
  
  /// 解析视频详情中的播放信息
  /// [playUrl] 视频详情中的 vod_play_url 字段
  /// [playFrom] 视频详情中的 vod_play_from 字段
  /// 返回一个Map，键为播放源名称，值为该播放源下的剧集列表
  static Map<String, List<Map<String, String>>> parsePlayInfo(String playUrl, String playFrom) {
    final Map<String, List<Map<String, String>>> result = {};
    
    final List<String> fromList = playFrom.split('\$\$\$');
    final List<String> urlList = playUrl.split('\$\$\$');
    
    for (int i = 0; i < fromList.length && i < urlList.length; i++) {
      final String source = fromList[i];
      final String urlsStr = urlList[i];
      
      final List<Map<String, String>> episodes = [];
      final List<String> episodeList = urlsStr.split('#');
      
      for (String episode in episodeList) {
        final List<String> parts = episode.split('\$');
        if (parts.length >= 2) {
          episodes.add({
            'name': parts[0],
            'url': parts[1],
          });
        }
      }
      
      result[source] = episodes;
    }
    
    return result;
  }
} 