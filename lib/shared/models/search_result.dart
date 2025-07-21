/// 搜索结果模型
class SearchResult {
  final String vodId;
  final String vodName;
  final String vodPic;
  final String vodRemarks;
  final String sourceId; // 数据来源站点ID
  
  const SearchResult({
    required this.vodId,
    required this.vodName,
    required this.vodPic,
    required this.vodRemarks,
    required this.sourceId,
  });
  
  /// 从API响应数据创建SearchResult
  factory SearchResult.fromJson(Map<String, dynamic> json, String sourceId) {
    return SearchResult(
      vodId: json['vod_id']?.toString() ?? '',
      vodName: json['vod_name']?.toString() ?? '',
      vodPic: json['vod_pic']?.toString() ?? '',
      vodRemarks: json['vod_remarks']?.toString() ?? '',
      sourceId: sourceId,
    );
  }
  
  /// 转换为Map
  Map<String, dynamic> toJson() {
    return {
      'vod_id': vodId,
      'vod_name': vodName,
      'vod_pic': vodPic,
      'vod_remarks': vodRemarks,
      'source_id': sourceId,
    };
  }
  
  /// 兼容现有视频模型的转换方法
  Map<String, dynamic> toVideoJson() {
    return {
      'vod_id': vodId,
      'vod_name': vodName,
      'vod_pic': vodPic,
      'vod_remarks': vodRemarks,
    };
  }
  
  @override
  String toString() => 'SearchResult(vodId: $vodId, vodName: $vodName, sourceId: $sourceId)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchResult && 
           other.vodId == vodId && 
           other.sourceId == sourceId;
  }
  
  @override
  int get hashCode => vodId.hashCode ^ sourceId.hashCode;
}

/// 搜索响应模型
class SearchResponse {
  final int code;
  final String message;
  final List<SearchResult> results;
  final String sourceId;
  
  const SearchResponse({
    required this.code,
    required this.message,
    required this.results,
    required this.sourceId,
  });
  
  /// 从API响应数据创建SearchResponse
  factory SearchResponse.fromJson(Map<String, dynamic> json, String sourceId) {
    final List<dynamic> listData = json['list'] ?? [];
    final List<SearchResult> results = listData
        .map((item) => SearchResult.fromJson(item, sourceId))
        .toList();
    
    return SearchResponse(
      code: json['code'] ?? 0,
      message: json['message']?.toString() ?? '',
      results: results,
      sourceId: sourceId,
    );
  }
  
  /// 检查响应是否成功
  bool get isSuccess => code == 0 || code == 200;
  
  /// 检查是否有结果
  bool get hasResults => results.isNotEmpty;
  
  @override
  String toString() => 'SearchResponse(code: $code, message: $message, results: ${results.length}, sourceId: $sourceId)';
}