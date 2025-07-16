import 'search_result.dart';
import 'search_source.dart';

/// 搜索页面状态枚举
enum SearchPageStatus {
  idle, // 初始状态
  loading, // 搜索中
  success, // 搜索成功
  error, // 搜索失败
  empty, // 搜索结果为空
}

/// 搜索页面状态模型
class SearchPageState {
  final SearchPageStatus status;
  final String keyword;
  final String? selectedSourceId;
  final Map<String, SearchResponse> searchResults;
  final Map<String, bool> loadingStates;
  final String? errorMessage;
  final List<SearchSource> sources;
  final List<String> searchHistory;
  final int? focusedSourceIndex;
  final int? focusedResultIndex;
  
  const SearchPageState({
    this.status = SearchPageStatus.idle,
    this.keyword = '',
    this.selectedSourceId,
    this.searchResults = const {},
    this.loadingStates = const {},
    this.errorMessage,
    this.sources = const [],
    this.searchHistory = const [],
    this.focusedSourceIndex,
    this.focusedResultIndex,
  });
  
  /// 复制状态并修改部分属性
  SearchPageState copyWith({
    SearchPageStatus? status,
    String? keyword,
    String? selectedSourceId,
    Map<String, SearchResponse>? searchResults,
    Map<String, bool>? loadingStates,
    String? errorMessage,
    List<SearchSource>? sources,
    List<String>? searchHistory,
    int? focusedSourceIndex,
    int? focusedResultIndex,
  }) {
    return SearchPageState(
      status: status ?? this.status,
      keyword: keyword ?? this.keyword,
      selectedSourceId: selectedSourceId ?? this.selectedSourceId,
      searchResults: searchResults ?? this.searchResults,
      loadingStates: loadingStates ?? this.loadingStates,
      errorMessage: errorMessage ?? this.errorMessage,
      sources: sources ?? this.sources,
      searchHistory: searchHistory ?? this.searchHistory,
      focusedSourceIndex: focusedSourceIndex ?? this.focusedSourceIndex,
      focusedResultIndex: focusedResultIndex ?? this.focusedResultIndex,
    );
  }
  
  /// 清空状态
  SearchPageState clear() {
    return SearchPageState(
      status: SearchPageStatus.idle,
      keyword: '',
      selectedSourceId: null,
      searchResults: const {},
      loadingStates: const {},
      errorMessage: null,
      sources: sources,
      searchHistory: searchHistory,
      focusedSourceIndex: null,
      focusedResultIndex: null,
    );
  }
  
  /// 获取当前选中源的搜索结果
  SearchResponse? get currentSearchResponse {
    if (selectedSourceId == null) return null;
    return searchResults[selectedSourceId];
  }
  
  /// 获取当前选中源的搜索结果列表
  List<SearchResult> get currentResults {
    return currentSearchResponse?.results ?? [];
  }
  
  /// 检查是否有搜索结果
  bool get hasResults {
    return searchResults.values.any((response) => response.hasResults);
  }
  
  /// 检查是否正在搜索
  bool get isSearching {
    return status == SearchPageStatus.loading || 
           loadingStates.values.any((isLoading) => isLoading);
  }
  
  /// 检查指定源是否正在加载
  bool isSourceLoading(String sourceId) {
    return loadingStates[sourceId] == true;
  }
  
  /// 获取搜索结果总数
  int get totalResultsCount {
    return searchResults.values
        .map((response) => response.results.length)
        .fold(0, (sum, count) => sum + count);
  }
  
  /// 获取有结果的源数量
  int get sourcesWithResultsCount {
    return searchResults.values
        .where((response) => response.hasResults)
        .length;
  }
  
  @override
  String toString() {
    return 'SearchPageState(status: $status, keyword: $keyword, '
           'selectedSourceId: $selectedSourceId, '
           'totalResults: $totalResultsCount, '
           'sourcesWithResults: $sourcesWithResultsCount)';
  }
}

/// 搜索历史记录模型
class SearchHistoryItem {
  final String keyword;
  final DateTime timestamp;
  final int clickCount;
  
  const SearchHistoryItem({
    required this.keyword,
    required this.timestamp,
    this.clickCount = 1,
  });
  
  /// 从JSON创建历史记录
  factory SearchHistoryItem.fromJson(Map<String, dynamic> json) {
    return SearchHistoryItem(
      keyword: json['keyword'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      clickCount: json['click_count'] as int? ?? 1,
    );
  }
  
  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'keyword': keyword,
      'timestamp': timestamp.toIso8601String(),
      'click_count': clickCount,
    };
  }
  
  /// 增加点击次数
  SearchHistoryItem incrementClickCount() {
    return SearchHistoryItem(
      keyword: keyword,
      timestamp: DateTime.now(),
      clickCount: clickCount + 1,
    );
  }
  
  @override
  String toString() {
    return 'SearchHistoryItem(keyword: $keyword, timestamp: $timestamp, clickCount: $clickCount)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchHistoryItem && other.keyword == keyword;
  }
  
  @override
  int get hashCode => keyword.hashCode;
}

/// 搜索建议模型
class SearchSuggestion {
  final String text;
  final SearchSuggestionType type;
  final int frequency;
  
  const SearchSuggestion({
    required this.text,
    required this.type,
    this.frequency = 1,
  });
  
  @override
  String toString() {
    return 'SearchSuggestion(text: $text, type: $type, frequency: $frequency)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchSuggestion && other.text == text;
  }
  
  @override
  int get hashCode => text.hashCode;
}

/// 搜索建议类型
enum SearchSuggestionType {
  history, // 历史记录
  hotword, // 热词
  autocomplete, // 自动补全
}