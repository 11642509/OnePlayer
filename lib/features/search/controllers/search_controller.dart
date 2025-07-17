import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../shared/models/search_page_state.dart';
import '../../../shared/models/search_result.dart';
import '../../../shared/models/search_source.dart';
import '../../../shared/services/search_service.dart';

/// 搜索页面控制器
class SearchController extends GetxController {
  // 搜索服务实例
  final SearchService _searchService = SearchService();
  
  // 页面状态管理
  final Rx<SearchPageState> _pageState = SearchPageState().obs;
  
  // 文本输入控制器
  final TextEditingController textController = TextEditingController();
  
  // 焦点管理
  final FocusNode searchFocusNode = FocusNode();
  final RxBool _searchFocused = false.obs;
  final FocusNode clearButtonFocusNode = FocusNode(debugLabel: 'ClearButton');
  final FocusNode backButtonFocusNode = FocusNode(debugLabel: 'BackButton');
  
  // 搜索防抖定时器
  Timer? _searchDebouncer;
  
  // 搜索历史记录
  final RxList<SearchHistoryItem> _searchHistory = <SearchHistoryItem>[].obs;
  
  // 搜索建议
  final RxList<SearchSuggestion> _searchSuggestions = <SearchSuggestion>[].obs;
  
  // 是否显示搜索建议
  final RxBool _showSuggestions = false.obs;
  
  // 焦点管理相关 - 使用真正的FocusNode
  final Map<int, FocusNode> _sourceFocusNodes = {};
  final Map<int, FocusNode> _resultFocusNodes = {};
  final RxInt focusedSourceIndex = (-1).obs;
  final RxInt focusedResultIndex = (-1).obs;
  
  // 滚动控制器
  final ScrollController sourceScrollController = ScrollController();
  final ScrollController resultScrollController = ScrollController();
  
  // Getters
  SearchPageState get pageState => _pageState.value;
  List<SearchHistoryItem> get searchHistory => _searchHistory;
  List<SearchSuggestion> get searchSuggestions => _searchSuggestions;
  bool get showSuggestions => _showSuggestions.value;
  int get focusedSourceIndexValue => focusedSourceIndex.value;
  int get focusedResultIndexValue => focusedResultIndex.value;
  FocusNode get getClearButtonFocusNode => clearButtonFocusNode;
  FocusNode get getBackButtonFocusNode => backButtonFocusNode;
  
  // 便捷访问器
  String get currentKeyword => _pageState.value.keyword;
  List<SearchSource> get availableSources => _pageState.value.sources;
  Map<String, SearchResponse> get searchResults => _pageState.value.searchResults;
  SearchResponse? get currentSearchResponse => _pageState.value.currentSearchResponse;
  List<SearchResult> get currentResults => _pageState.value.currentResults;
  bool get isSearching => _pageState.value.isSearching;
  bool get hasResults => _pageState.value.hasResults;
  String? get selectedSourceId => _pageState.value.selectedSourceId;
  bool get searchFocused => _searchFocused.value;
  
  @override
  void onInit() {
    super.onInit();
    _initializeData();
    _setupTextControllerListener();
    _setupFocusManagement();
  }
  
  @override
  void onClose() {
    _searchDebouncer?.cancel();
    textController.dispose();
    searchFocusNode.dispose();
    clearButtonFocusNode.dispose();
    backButtonFocusNode.dispose();
    sourceScrollController.dispose();
    resultScrollController.dispose();
    
    // 释放所有FocusNode资源
    for (final node in _sourceFocusNodes.values) {
      node.dispose();
    }
    for (final node in _resultFocusNodes.values) {
      node.dispose();
    }
    _sourceFocusNodes.clear();
    _resultFocusNodes.clear();
    
    super.onClose();
  }
  
  /// 初始化数据
  void _initializeData() {
    // 加载搜索源
    final sources = SearchSource.getDefaultSources();
    _pageState.value = _pageState.value.copyWith(
      sources: sources,
      selectedSourceId: sources.isNotEmpty ? sources.first.id : null,
    );
    
    // 加载搜索历史
    _loadSearchHistory();
    
    // 生成搜索建议
    _generateSearchSuggestions();
    
    if (kDebugMode) {
      print('搜索控制器初始化完成，加载了${sources.length}个搜索源');
    }
  }
  
  /// 设置文本控制器监听
  void _setupTextControllerListener() {
    textController.addListener(() {
      final keyword = textController.text.trim();
      _pageState.value = _pageState.value.copyWith(keyword: keyword);
      
      // 显示/隐藏搜索建议
      _showSuggestions.value = keyword.isNotEmpty;
      
      // 搜索防抖
      _searchDebouncer?.cancel();
      if (keyword.isNotEmpty && keyword.length >= 2) {
        // 只有关键词长度>=2时才开始搜索，避免无意义的搜索
        _searchDebouncer = Timer(const Duration(milliseconds: 600), () {
          // 确保搜索时文本框仍有内容
          if (textController.text.trim().isNotEmpty) {
            _pageState.value = _pageState.value.copyWith(
              status: SearchPageStatus.loading,
            );
            performSearch(keyword);
          }
        });
      } else {
        // 关键词为空或太短时，清除结果但保持idle状态
        _clearSearchResults();
      }
    });
  }
  
  /// 设置焦点管理
  void _setupFocusManagement() {
    searchFocusNode.addListener(() {
      _searchFocused.value = searchFocusNode.hasFocus;
      if (searchFocusNode.hasFocus) {
        _showSuggestions.value = textController.text.isNotEmpty;
      }
    });
  }
  
  /// 执行搜索
  Future<void> performSearch(String keyword) async {
    if (keyword.trim().isEmpty) {
      _clearSearchResults();
      return;
    }
    
    try {
      final results = await _searchService.searchAll(keyword);
      
      if (results.isEmpty) {
        _pageState.value = _pageState.value.copyWith(
          status: SearchPageStatus.empty,
          searchResults: {},
          loadingStates: {},
        );
      } else {
        _pageState.value = _pageState.value.copyWith(
          status: SearchPageStatus.success,
          searchResults: results,
          loadingStates: {},
        );
        
        // 如果当前没有选中的源，自动选择第一个有结果的源
        if (_pageState.value.selectedSourceId == null) {
          final firstSourceWithResults = results.entries
              .where((entry) => entry.value.hasResults)
              .map((entry) => entry.key)
              .firstOrNull;
          
          if (firstSourceWithResults != null) {
            selectSource(firstSourceWithResults);
          }
        }
      }
      
      // 添加到搜索历史
      _addToSearchHistory(keyword);
      
    } catch (e) {
      _pageState.value = _pageState.value.copyWith(
        status: SearchPageStatus.error,
        errorMessage: '搜索失败: ${e.toString()}',
        searchResults: {},
        loadingStates: {},
      );
      
      if (kDebugMode) {
        print('搜索失败: $e');
      }
    }
  }
  
  /// 搜索指定源
  Future<void> searchSpecificSource(String sourceId) async {
    final source = availableSources.where((s) => s.id == sourceId).firstOrNull;
    if (source == null || currentKeyword.isEmpty) return;
    
    // 更新单个源的加载状态
    final newLoadingStates = Map<String, bool>.from(_pageState.value.loadingStates);
    newLoadingStates[sourceId] = true;
    _pageState.value = _pageState.value.copyWith(loadingStates: newLoadingStates);
    
    try {
      final response = await _searchService.searchFromSource(source, currentKeyword);
      
      // 更新搜索结果
      final newSearchResults = Map<String, SearchResponse>.from(_pageState.value.searchResults);
      newSearchResults[sourceId] = response;
      
      // 清除加载状态
      newLoadingStates.remove(sourceId);
      
      _pageState.value = _pageState.value.copyWith(
        searchResults: newSearchResults,
        loadingStates: newLoadingStates,
        status: newSearchResults.values.any((r) => r.hasResults) 
            ? SearchPageStatus.success 
            : SearchPageStatus.empty,
      );
      
    } catch (e) {
      // 清除加载状态
      newLoadingStates.remove(sourceId);
      _pageState.value = _pageState.value.copyWith(
        loadingStates: newLoadingStates,
        errorMessage: '搜索${source.name}失败: ${e.toString()}',
      );
      
      if (kDebugMode) {
        print('搜索${source.name}失败: $e');
      }
    }
  }
  
  /// 选择搜索源
  void selectSource(String sourceId) {
    _pageState.value = _pageState.value.copyWith(
      selectedSourceId: sourceId,
      focusedResultIndex: null,
    );
    
    // 重置结果区域焦点
    focusedResultIndex.value = -1;
    
    // 清理FocusNode
    _cleanupFocusNodes();
    
    // 如果该源没有搜索结果且有搜索关键词，则搜索该源
    if (!searchResults.containsKey(sourceId) && currentKeyword.isNotEmpty) {
      searchSpecificSource(sourceId);
    }
  }
  
  /// 清除搜索结果
  void _clearSearchResults() {
    _pageState.value = _pageState.value.copyWith(
      status: SearchPageStatus.idle,
      searchResults: {},
      loadingStates: {},
      errorMessage: null,
    );
    _showSuggestions.value = false;
  }
  
  /// 清除搜索内容
  void clearSearch() {
    textController.clear();
    _clearSearchResults();
    focusedSourceIndex.value = -1;
    focusedResultIndex.value = -1;
  }
  
  /// 快速搜索（来自建议或历史）
  void quickSearch(String keyword) {
    textController.text = keyword;
    _showSuggestions.value = false;
    performSearch(keyword);
  }
  
  /// 添加到搜索历史
  void _addToSearchHistory(String keyword) {
    if (keyword.trim().isEmpty) return;
    
    final existingIndex = _searchHistory.indexWhere((item) => item.keyword == keyword);
    if (existingIndex != -1) {
      // 更新现有历史记录
      _searchHistory[existingIndex] = _searchHistory[existingIndex].incrementClickCount();
    } else {
      // 添加新历史记录
      _searchHistory.insert(0, SearchHistoryItem(
        keyword: keyword,
        timestamp: DateTime.now(),
      ));
      
      // 限制历史记录数量
      if (_searchHistory.length > 50) {
        _searchHistory.removeRange(50, _searchHistory.length);
      }
    }
    
    // 保存到本地存储
    _saveSearchHistory();
  }
  
  /// 加载搜索历史
  Future<void> _loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('search_history');
      
      if (historyJson != null) {
        final List<dynamic> historyList = json.decode(historyJson);
        _searchHistory.assignAll(
          historyList.map((item) => SearchHistoryItem.fromJson(item)).toList(),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('加载搜索历史失败: $e');
      }
    }
  }
  
  /// 保存搜索历史
  Future<void> _saveSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = json.encode(
        _searchHistory.map((item) => item.toJson()).toList(),
      );
      await prefs.setString('search_history', historyJson);
    } catch (e) {
      if (kDebugMode) {
        print('保存搜索历史失败: $e');
      }
    }
  }
  
  /// 清除搜索历史
  void clearSearchHistory() {
    _searchHistory.clear();
    _saveSearchHistory();
  }
  
  /// 生成搜索建议
  void _generateSearchSuggestions() {
    _searchSuggestions.clear();
    
    // 从历史记录生成建议
    final historyItems = _searchHistory.take(10).map((item) => 
      SearchSuggestion(
        text: item.keyword,
        type: SearchSuggestionType.history,
        frequency: item.clickCount,
      )
    ).toList();
    
    _searchSuggestions.addAll(historyItems);
    
    // 添加一些热门搜索建议
    const hotwords = [
      '电影', '电视剧', '综艺', '动漫', '纪录片',
      '新片', '热门', '经典', '国产', '美剧',
    ];
    
    final hotwordItems = hotwords.map((word) => 
      SearchSuggestion(
        text: word,
        type: SearchSuggestionType.hotword,
        frequency: 0,
      )
    ).toList();
    
    _searchSuggestions.addAll(hotwordItems);
  }
  
  /// 获取或创建源列表的FocusNode
  FocusNode getSourceFocusNode(int index) {
    if (!_sourceFocusNodes.containsKey(index)) {
      _sourceFocusNodes[index] = FocusNode(debugLabel: 'Source $index');
    }
    return _sourceFocusNodes[index]!;
  }

  /// 获取或创建结果列表的FocusNode
  FocusNode getResultFocusNode(int index) {
    if (!_resultFocusNodes.containsKey(index)) {
      _resultFocusNodes[index] = FocusNode(debugLabel: 'Result $index');
    }
    return _resultFocusNodes[index]!;
  }

  /// 清理不需要的FocusNode
  void _cleanupFocusNodes() {
    // 清理源列表超出的节点
    final sourceKeysToRemove = _sourceFocusNodes.keys
        .where((index) => index >= availableSources.length)
        .toList();
    for (final key in sourceKeysToRemove) {
      _sourceFocusNodes.remove(key)?.dispose();
    }

    // 清理结果列表超出的节点
    final resultKeysToRemove = _resultFocusNodes.keys
        .where((index) => index >= currentResults.length)
        .toList();
    for (final key in resultKeysToRemove) {
      _resultFocusNodes.remove(key)?.dispose();
    }
  }

  /// 从搜索框导航到下方控件
  void navigateFromSearchToSources() {
    if (availableSources.isNotEmpty) {
      final firstNode = getSourceFocusNode(0);
      focusedSourceIndex.value = 0;
      firstNode.requestFocus();
      _scrollToFocusedSource();
    }
  }

  /// 从源列表导航到结果区域
  void navigateFromSourcesToResults() {
    if (currentResults.isNotEmpty) {
      final firstNode = getResultFocusNode(0);
      focusedResultIndex.value = 0;
      focusedSourceIndex.value = -1;
      firstNode.requestFocus();
      scrollToFocusedResult();
    }
  }

  /// 从结果区域导航回源列表
  void navigateFromResultsToSources() {
    if (availableSources.isNotEmpty) {
      final firstNode = getSourceFocusNode(0);
      focusedSourceIndex.value = 0;
      focusedResultIndex.value = -1;
      firstNode.requestFocus();
      _scrollToFocusedSource();
    }
  }

  /// 从任何地方导航回搜索框
  void navigateToSearchBox() {
    focusedSourceIndex.value = -1;
    focusedResultIndex.value = -1;
    searchFocusNode.requestFocus();
  }

  /// 焦点管理 - 遥控器导航（保持兼容性）
  void moveFocusUp() {
    if (focusedSourceIndex.value > 0) {
      focusedSourceIndex.value--;
      final targetNode = getSourceFocusNode(focusedSourceIndex.value);
      targetNode.requestFocus();
      _scrollToFocusedSource();
    }
  }
  
  void moveFocusDown() {
    if (focusedSourceIndex.value < availableSources.length - 1) {
      focusedSourceIndex.value++;
      final targetNode = getSourceFocusNode(focusedSourceIndex.value);
      targetNode.requestFocus();
      _scrollToFocusedSource();
    }
  }
  
  void moveFocusLeft() {
    if (focusedResultIndex.value > 0) {
      focusedResultIndex.value--;
      final targetNode = getResultFocusNode(focusedResultIndex.value);
      targetNode.requestFocus();
      scrollToFocusedResult();
    }
  }
  
  void moveFocusRight() {
    if (focusedResultIndex.value < currentResults.length - 1) {
      focusedResultIndex.value++;
      final targetNode = getResultFocusNode(focusedResultIndex.value);
      targetNode.requestFocus();
      scrollToFocusedResult();
    }
  }
  
  void confirmSelection() {
    if (focusedSourceIndex.value >= 0 && focusedSourceIndex.value < availableSources.length) {
      final source = availableSources[focusedSourceIndex.value];
      selectSource(source.id);
    }
  }
  
  /// 滚动到焦点源
  void _scrollToFocusedSource() {
    if (focusedSourceIndex.value >= 0 && sourceScrollController.hasClients) {
      final itemHeight = 60.0; // 假设每个源项目高度
      final targetOffset = focusedSourceIndex.value * itemHeight;
      sourceScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }
  
  /// 滚动到焦点结果
  void scrollToFocusedResult() {
    if (focusedResultIndex.value >= 0 && resultScrollController.hasClients) {
      final itemWidth = 160.0; // 假设每个结果项目宽度
      final targetOffset = focusedResultIndex.value * itemWidth;
      resultScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }
  
  /// 获取源的搜索结果数量
  int getSourceResultCount(String sourceId) {
    return searchResults[sourceId]?.results.length ?? 0;
  }
  
  /// 检查源是否有搜索结果
  bool hasSourceResults(String sourceId) {
    return searchResults[sourceId]?.hasResults ?? false;
  }
  
  /// 获取源的加载状态
  bool isSourceLoading(String sourceId) {
    return _pageState.value.loadingStates[sourceId] ?? false;
  }
  
  /// 刷新搜索结果
  Future<void> refreshSearch() async {
    if (currentKeyword.isNotEmpty) {
      await performSearch(currentKeyword);
    }
  }
  
  /// 清理缓存
  void clearCache() {
    _searchService.clearAllCache();
  }
}