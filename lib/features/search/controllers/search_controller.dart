import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../../../shared/models/search_source.dart';
import '../../../shared/models/search_result.dart';
import '../../../shared/services/search_service.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/config/config.dart';
import '../../settings/services/cms_site_service.dart';

/// 搜索控制器
class SearchController extends GetxController with GetTickerProviderStateMixin {
  // 核心服务
  final SearchService _searchService = SearchService();
  
  // 文本控制器
  final TextEditingController textController = TextEditingController();
  
  // 焦点节点
  final FocusNode searchFocusNode = FocusNode();
  final FocusNode clearButtonFocusNode = FocusNode();
  final FocusNode backButtonFocusNode = FocusNode();
  
  // 滚动控制器
  final ScrollController sourceScrollController = ScrollController();
  final ScrollController resultScrollController = ScrollController();
  
  // ScrollController 管理 - 复制影视页逻辑
  final Map<String, ScrollController> _scrollControllers = {};
  
  // TabController for source selection
  TabController? sourceTabController;
  
  // 响应式状态
  final RxString keyword = ''.obs;
  final RxBool isSearching = false.obs;
  final RxList<SearchSource> sources = <SearchSource>[].obs;
  final RxString selectedSourceId = ''.obs;
  final RxMap<String, SearchResponse> searchResults = <String, SearchResponse>{}.obs;
  
  // 修改数据结构以匹配影视页逻辑 - 每个sourceId对应一个结果列表
  final RxMap<String, List<SearchResult>> sourceResults = <String, List<SearchResult>>{}.obs;
  final RxMap<String, bool> loadingStates = <String, bool>{}.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isHorizontalLayout = true.obs; // 图片布局方向
  
  // 焦点管理
  final RxInt focusedSourceIndex = (-1).obs;
  final RxInt focusedResultIndex = (-1).obs;
  final RxString focusedArea = 'search'.obs; // search, sources, results
  
  // TabController状态管理
  bool _isProcessingTabChange = false;
  
  // 防抖定时器
  Timer? _debounceTimer;
  
  // 焦点节点映射
  final Map<String, FocusNode> _sourceFocusNodes = {};
  final Map<int, FocusNode> _resultFocusNodes = {};
  
  @override
  void onInit() {
    super.onInit();
    _setupListeners();
    // 延迟初始化，确保CMS服务完全加载
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }
  
  @override
  void onClose() {
    _debounceTimer?.cancel();
    textController.dispose();
    searchFocusNode.dispose();
    clearButtonFocusNode.dispose();
    backButtonFocusNode.dispose();
    sourceScrollController.dispose();
    resultScrollController.dispose();
    
    // 清理TabController及其监听器
    if (sourceTabController != null) {
      sourceTabController!.removeListener(_onTabChanged);
      sourceTabController!.dispose();
    }
    
    // 清理 ScrollController
    for (var controller in _scrollControllers.values) {
      controller.dispose();
    }
    _scrollControllers.clear();
    
    // 清理焦点节点
    for (final node in _sourceFocusNodes.values) {
      node.dispose();
    }
    for (final node in _resultFocusNodes.values) {
      node.dispose();
    }
    
    super.onClose();
  }
  
  /// 初始化数据
  void _initializeData() {
    final allSources = <SearchSource>[];
    
    // 1. 先获取静态配置的搜索源（除了CMS）
    final staticSources = AppConfig.searchSources
        .where((config) => config['isEnabled'] == true && config['id'] != 'cms')
        .map((config) => SearchSource.fromConfig(config))
        .toList();
    allSources.addAll(staticSources);
    
    // 2. 获取CMS站点并转换为搜索源
    final cmsSources = _getCmsSearchSources();
    allSources.addAll(cmsSources);
    
    if (kDebugMode) {
      print('搜索源初始化完成，共 ${allSources.length} 个源：${allSources.map((s) => s.name).join(', ')}');
    }
    
    // 3. 设置到sources变量中
    sources.assignAll(allSources);
    
    // 4. 将完整的源列表保存到全局静态变量中，供SearchService使用
    SearchSource.setGlobalSources(allSources);
    
    if (allSources.isNotEmpty) {
      selectedSourceId.value = allSources.first.id;
      // 初始化TabController
      _updateTabController();
    }
  }
  
  /// 获取CMS站点并转换为搜索源格式
  List<SearchSource> _getCmsSearchSources() {
    final cmsSources = <SearchSource>[];
    
    if (kDebugMode) {
      print('开始获取CMS站点...');
      print('CMS服务注册状态: ${Get.isRegistered<CmsSiteService>()}');
    }
    
    try {
      if (Get.isRegistered<CmsSiteService>()) {
        final cmsService = Get.find<CmsSiteService>();
        final cmsSites = cmsService.cmsSites;
        
        if (kDebugMode) {
          print('CMS服务实例获取成功');
          print('找到 ${cmsSites.length} 个CMS站点：${cmsSites.map((s) => s.name).join(', ')}');
        }
        
        for (final site in cmsSites) {
          cmsSources.add(SearchSource(
            id: 'cms_${site.id}',
            name: site.name,
            apiEndpoint: '/api/v1/cms',
            iconUrl: 'https://www.example.com/favicon.ico',
            color: '#FF9800',
            isEnabled: true,
          ));
          
          if (kDebugMode) {
            print('添加CMS搜索源: ${site.name} -> cms_${site.id}');
          }
        }
      } else {
        if (kDebugMode) {
          print('CMS服务未注册，跳过CMS站点');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('获取CMS站点失败: $e');
      }
    }
    
    if (kDebugMode) {
      print('CMS搜索源构建完成，共 ${cmsSources.length} 个源');
    }
    
    return cmsSources;
  }
  
  /// 更新TabController
  void _updateTabController() {
    if (sources.isEmpty) return;
    
    // 只有当TabController不存在或长度不匹配时才创建新的
    if (sourceTabController == null || sourceTabController!.length != sources.length) {
      // 清理旧的TabController
      if (sourceTabController != null) {
        sourceTabController!.removeListener(_onTabChanged);
        sourceTabController!.dispose();
      }
      
      sourceTabController = TabController(length: sources.length, vsync: this);
      
      // 监听TabController变化
      sourceTabController!.addListener(_onTabChanged);
    }
    
    // 设置初始选中的tab
    final selectedIndex = sources.indexWhere((source) => source.id == selectedSourceId.value);
    if (selectedIndex >= 0 && sourceTabController != null && sourceTabController!.index != selectedIndex) {
      sourceTabController!.index = selectedIndex;
    }
  }
  
  /// 处理Tab变化
  void _onTabChanged() {
    if (sourceTabController != null && 
        sourceTabController!.indexIsChanging && 
        !_isProcessingTabChange) {
      _isProcessingTabChange = true;
      
      // 延迟处理，确保UI切换完成
      Future.delayed(const Duration(milliseconds: 300), () {
        if (sourceTabController != null && 
            sourceTabController!.index >= 0 && 
            sourceTabController!.index < sources.length) {
          final selectedIndex = sourceTabController!.index;
          final source = sources[selectedIndex];
          selectSource(source.id);
        }
        _isProcessingTabChange = false;
      });
    }
  }
  
  /// 设置监听器
  void _setupListeners() {
    // 监听文本变化
    textController.addListener(() {
      keyword.value = textController.text.trim();
      _handleTextChange();
    });
    
    // 监听搜索框焦点
    searchFocusNode.addListener(() {
      if (searchFocusNode.hasFocus) {
        focusedArea.value = 'search';
        focusedSourceIndex.value = -1;
        focusedResultIndex.value = -1;
      }
    });
  }
  
  /// 处理文本变化
  void _handleTextChange() {
    _debounceTimer?.cancel();
    
    if (keyword.value.isEmpty) {
      _clearResults();
      return;
    }
    
    if (keyword.value.length >= 2) {
      _debounceTimer = Timer(const Duration(milliseconds: 800), () {
        if (keyword.value.isNotEmpty) {
          performSearch();
        }
      });
    }
  }
  
  /// 执行搜索
  Future<void> performSearch() async {
    if (keyword.value.isEmpty) return;
    
    isSearching.value = true;
    errorMessage.value = '';
    loadingStates.clear();
    
    try {
      // 设置所有源为加载状态
      for (final source in sources) {
        loadingStates[source.id] = true;
      }
      
      // 执行搜索
      final results = await _searchService.searchAll(keyword.value);
      
      // 更新结果
      searchResults.assignAll(results);
      
      // 同时更新sourceResults以匹配影视页逻辑
      sourceResults.clear();
      for (final entry in results.entries) {
        sourceResults[entry.key] = entry.value.results;
      }
      
      loadingStates.clear();
      
      // 如果当前选中的源没有结果，自动选择第一个有结果的源
      if (!results.containsKey(selectedSourceId.value) || 
          !results[selectedSourceId.value]!.hasResults) {
        final firstSourceWithResults = results.entries
            .where((entry) => entry.value.hasResults)
            .map((entry) => entry.key)
            .firstOrNull;
        
        if (firstSourceWithResults != null) {
          selectedSourceId.value = firstSourceWithResults;
        }
      }
      
      // 检测第一张图片的方向
      _checkFirstImageOrientation();
      
    } catch (e) {
      errorMessage.value = '搜索失败: ${e.toString()}';
      loadingStates.clear();
    } finally {
      isSearching.value = false;
    }
  }
  
  /// 检测第一张图片的方向
  Future<void> _checkFirstImageOrientation() async {
    final currentResults = getCurrentResults();
    if (currentResults.isEmpty) return;
    
    final firstResult = currentResults.first;
    final imageUrl = firstResult.vodPic;
    if (imageUrl.isEmpty) return;
    
    try {
      // 创建一个Image对象来获取图片尺寸
      final image = Image.network(imageUrl);
      final completer = Completer<ImageInfo>();
      final imageStream = image.image.resolve(const ImageConfiguration());
      
      imageStream.addListener(ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(info);
      }));
      
      final imageInfo = await completer.future;
      final isHorizontal = imageInfo.image.width > imageInfo.image.height;
      
      if (isHorizontalLayout.value != isHorizontal) {
        isHorizontalLayout.value = isHorizontal;
      }
    } catch (e) {
      // 如果检测失败，保持默认布局
      if (kDebugMode) {
        print('检测图片方向失败: $e');
      }
    }
  }
  
  /// 清除搜索结果
  void _clearResults() {
    searchResults.clear();
    sourceResults.clear();
    loadingStates.clear();
    errorMessage.value = '';
    isSearching.value = false;
  }
  
  /// 清除搜索
  void clearSearch() {
    textController.clear();
    keyword.value = '';
    _clearResults();
    searchFocusNode.requestFocus();
  }
  
  /// 选择搜索源
  void selectSource(String sourceId) {
    selectedSourceId.value = sourceId;
    focusedResultIndex.value = -1;
    
    // 只有在不是Tab变化处理过程中时才同步TabController
    if (!_isProcessingTabChange) {
      final selectedIndex = sources.indexWhere((source) => source.id == sourceId);
      if (selectedIndex >= 0 && sourceTabController != null && sourceTabController!.index != selectedIndex) {
        sourceTabController!.animateTo(selectedIndex);
      }
    }
    
    // 切换源时重新检测图片方向
    _checkFirstImageOrientation();
  }
  
  /// 获取源的焦点节点
  FocusNode getSourceFocusNode(String sourceId) {
    if (!_sourceFocusNodes.containsKey(sourceId)) {
      _sourceFocusNodes[sourceId] = FocusNode(debugLabel: 'Source_$sourceId');
    }
    return _sourceFocusNodes[sourceId]!;
  }
  
  /// 获取结果的焦点节点
  FocusNode getResultFocusNode(int index) {
    if (!_resultFocusNodes.containsKey(index)) {
      _resultFocusNodes[index] = FocusNode(debugLabel: 'Result_$index');
    }
    return _resultFocusNodes[index]!;
  }
  
  /// 导航到搜索框
  void navigateToSearch() {
    focusedArea.value = 'search';
    focusedSourceIndex.value = -1;
    focusedResultIndex.value = -1;
    searchFocusNode.requestFocus();
  }
  
  /// 导航到源列表
  void navigateToSources() {
    if (sources.isEmpty) return;
    
    focusedArea.value = 'sources';
    focusedSourceIndex.value = 0;
    focusedResultIndex.value = -1;
    
    final focusNode = getSourceFocusNode(sources[0].id);
    focusNode.requestFocus();
    _scrollToFocusedSource();
  }
  
  /// 导航到结果区域
  void navigateToResults() {
    final currentResults = getCurrentResults();
    if (currentResults.isEmpty) return;
    
    focusedArea.value = 'results';
    focusedSourceIndex.value = -1;
    focusedResultIndex.value = 0;
    
    final focusNode = getResultFocusNode(0);
    focusNode.requestFocus();
    _scrollToFocusedResult();
  }
  
  /// 在源列表中向上移动
  void moveSourceUp() {
    if (focusedSourceIndex.value > 0) {
      focusedSourceIndex.value--;
      final source = sources[focusedSourceIndex.value];
      final focusNode = getSourceFocusNode(source.id);
      focusNode.requestFocus();
      _scrollToFocusedSource();
    } else {
      // 如果已经在第一项，跳转到搜索框
      navigateToSearch();
    }
  }
  
  /// 在源列表中向下移动
  void moveSourceDown() {
    if (focusedSourceIndex.value < sources.length - 1) {
      focusedSourceIndex.value++;
      final source = sources[focusedSourceIndex.value];
      final focusNode = getSourceFocusNode(source.id);
      focusNode.requestFocus();
      _scrollToFocusedSource();
    }
  }
  
  /// 在结果网格中移动
  void moveResultUp() {
    final currentResults = getCurrentResults();
    if (currentResults.isEmpty) return;
    
    final columns = 4; // 横屏4列
    final newIndex = focusedResultIndex.value - columns;
    
    if (newIndex >= 0) {
      focusedResultIndex.value = newIndex;
      final focusNode = getResultFocusNode(newIndex);
      focusNode.requestFocus();
      _scrollToFocusedResult();
    } else {
      // 如果已经在第一行，跳转到搜索框
      navigateToSearch();
    }
  }
  
  void moveResultDown() {
    final currentResults = getCurrentResults();
    if (currentResults.isEmpty) return;
    
    final columns = 4; // 横屏4列
    final newIndex = focusedResultIndex.value + columns;
    
    if (newIndex < currentResults.length) {
      focusedResultIndex.value = newIndex;
      final focusNode = getResultFocusNode(newIndex);
      focusNode.requestFocus();
      _scrollToFocusedResult();
    }
  }
  
  void moveResultLeft() {
    if (focusedResultIndex.value > 0) {
      focusedResultIndex.value--;
      final focusNode = getResultFocusNode(focusedResultIndex.value);
      focusNode.requestFocus();
      _scrollToFocusedResult();
    }
  }
  
  void moveResultRight() {
    final currentResults = getCurrentResults();
    if (focusedResultIndex.value < currentResults.length - 1) {
      focusedResultIndex.value++;
      final focusNode = getResultFocusNode(focusedResultIndex.value);
      focusNode.requestFocus();
      _scrollToFocusedResult();
    }
  }
  
  /// 确认选择
  void confirmSelection() {
    switch (focusedArea.value) {
      case 'sources':
        if (focusedSourceIndex.value >= 0) {
          final source = sources[focusedSourceIndex.value];
          selectSource(source.id);
        }
        break;
      case 'results':
        if (focusedResultIndex.value >= 0) {
          final results = getCurrentResults();
          if (focusedResultIndex.value < results.length) {
            final result = results[focusedResultIndex.value];
            Get.toNamed(
              AppRoutes.videoDetail,
              parameters: {'videoId': result.vodId},
            );
          }
        }
        break;
    }
  }
  
  /// 获取当前选中源的结果
  List<SearchResult> getCurrentResults() {
    if (selectedSourceId.value.isEmpty) return [];
    return sourceResults[selectedSourceId.value] ?? [];
  }
  
  /// 检查源是否有结果
  bool hasSourceResults(String sourceId) {
    return (sourceResults[sourceId]?.isNotEmpty) ?? false;
  }
  
  /// 获取源的结果数量
  int getSourceResultCount(String sourceId) {
    return sourceResults[sourceId]?.length ?? 0;
  }
  
  /// 检查源是否正在加载
  bool isSourceLoading(String sourceId) {
    return loadingStates[sourceId] ?? false;
  }
  
  /// 滚动到焦点源
  void _scrollToFocusedSource() {
    if (focusedSourceIndex.value >= 0 && sourceScrollController.hasClients) {
      final itemHeight = 80.0;
      final targetOffset = focusedSourceIndex.value * itemHeight;
      sourceScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }
  
  /// 滚动到焦点结果
  void _scrollToFocusedResult() {
    if (focusedResultIndex.value >= 0 && resultScrollController.hasClients) {
      final itemHeight = 200.0;
      final columns = 4;
      final row = focusedResultIndex.value ~/ columns;
      final targetOffset = row * itemHeight;
      
      resultScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }
  
  /// 获取或创建 ScrollController - 复制影视页逻辑
  ScrollController getScrollController(String sourceName) {
    if (!_scrollControllers.containsKey(sourceName)) {
      _scrollControllers[sourceName] = ScrollController();
    }
    return _scrollControllers[sourceName]!;
  }
}