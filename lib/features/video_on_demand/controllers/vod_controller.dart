import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../../../shared/models/home_content.dart';
import '../../../shared/models/category_content.dart';
import '../../../app/data_source.dart';
import '../../../app/config/config.dart';

class VodController extends GetxController with GetTickerProviderStateMixin {
  // 响应式状态
  final RxBool isLoading = true.obs;
  final RxMap<String, dynamic> homeData = <String, dynamic>{}.obs;
  final RxList<dynamic> classList = <dynamic>[].obs;
  final RxMap<String, List<dynamic>> categoryData = <String, List<dynamic>>{}.obs;
  final RxMap<String, int> currentPages = <String, int>{}.obs;
  final RxMap<String, int> totalPages = <String, int>{}.obs;
  
  // 每个分类的加载状态
  final RxMap<String, bool> categoryLoadingStates = <String, bool>{}.obs;
  
  // 滚动加载相关状态
  final RxMap<String, bool> loadingMoreStates = <String, bool>{}.obs;
  final RxMap<String, bool> hasMoreStates = <String, bool>{}.obs;
  
  // ScrollController 管理
  final Map<String, ScrollController> _scrollControllers = {};
  
  // 缓存 FutureBuilder 的 Future
  final Map<String, Future<ui.Image>> _imageFutures = {};
  
  // 防止重复初始化的标志
  bool _isInitialized = false;
  
  // 防止重复处理标签变化的标志
  bool _isProcessingTabChange = false;
  
  // 缓存分类数据的Future，避免重复创建
  final Map<String, Future<Map<String, dynamic>>> _categoryFutures = {};
  
  // TabController
  TabController? tabController;
  
  // 当前选中的标签索引 - 响应式变量
  final RxInt selectedTabIndex = 0.obs;
  
  // 数据源
  // 数据源 - 改为getter以便动态获取最新实例
  DataSource get _dataSource => DataSource();
  
  // 添加主页分类
  final Map<String, dynamic> _homeCategory = {"type_id": "0", "type_name": "主页"};
  
  @override
  void onInit() {
    super.onInit();
    if (!_isInitialized) {
      _isInitialized = true;
      _setupWorkers();
      initializeData();
    }
  }
  
  /// 初始化数据（可重复调用）
  void initializeData() {
    _fetchHomeData();
  }
  
  /// 设置GetX Workers进行自动化操作（优化版本）
  void _setupWorkers() {
    // 优化：使用debounce直接监听标签变化，避免重复处理
    debounce(selectedTabIndex, (int index) {
      if (classList.isNotEmpty && index < classList.length && !_isProcessingTabChange) {
        final selectedCategory = classList[index];
        final categoryName = selectedCategory['type_name'] as String;
        ensureCategoryDataLoaded(categoryName);
      }
    }, time: const Duration(milliseconds: 300));
    
    // 优化：减少TabController更新频率，只在必要时更新
    debounce(classList, (List<dynamic> newClassList) {
      if (tabController == null || tabController!.length != newClassList.length) {
        _updateTabController();
      }
    }, time: const Duration(milliseconds: 100));
    
    // 优化：使用interval定期清理缓存，而不是监听每次加载状态变化
    interval(isLoading, (_) {
      if (!isLoading.value) {
        _cleanupExpiredCache();
      }
    }, time: const Duration(minutes: 2)); // 每2分钟检查一次
  }
  
  @override
  void onClose() {
    tabController?.removeListener(_onTabChanged);
    tabController?.dispose();
    
    // 清理 ScrollController
    for (var controller in _scrollControllers.values) {
      controller.dispose();
    }
    _scrollControllers.clear();
    
    // 清理缓存的 Future
    _imageFutures.clear();
    
    super.onClose();
  }
  
  /// 更新TabController
  void _updateTabController() {
    if (tabController == null || tabController!.length != classList.length) {
      tabController?.dispose();
      tabController = TabController(length: classList.length, vsync: this);
      
      // 监听TabController变化，同步到响应式变量
      tabController?.addListener(() {
        if (tabController!.indexIsChanging) {
          selectedTabIndex.value = tabController!.index;
        }
      });
    }
  }
  
  /// 清理过期的缓存
  void _cleanupExpiredCache() {
    // 清理图片缓存（保留最近使用的10个）
    if (_imageFutures.length > 10) {
      final keysToRemove = _imageFutures.keys.take(_imageFutures.length - 10).toList();
      for (final key in keysToRemove) {
        _imageFutures.remove(key);
      }
    }
    
    // 清理分类数据缓存（保留最近使用的5个）
    if (_categoryFutures.length > 5) {
      final keysToRemove = _categoryFutures.keys.take(_categoryFutures.length - 5).toList();
      for (final key in keysToRemove) {
        _categoryFutures.remove(key);
      }
    }
  }
  
  // 获取首页数据
  Future<void> _fetchHomeData() async {
    isLoading.value = true;
    
    try {
      // 检查是否强制使用mock数据
      if (AppConfig.forceMockData) {
        // 强制使用mock数据
        final mockData = HomeContent.getMockData();
        _processHomeData(mockData);
        return;
      }
      
      // 尝试从真实接口获取数据
      final data = await _dataSource.fetchHomeData();
      _processHomeData(data);
      
    } catch (e) {
      // 如果接口调用失败，回退到使用mock数据
      if (kDebugMode) {
        print('API调用失败，使用mock数据: $e');
      }
      final mockData = HomeContent.getMockData();
      _processHomeData(mockData);
    }
  }
  
  // 处理首页数据
  void _processHomeData(Map<String, dynamic> data) {
    homeData.assignAll(data);
    classList.assignAll([_homeCategory, ...(data['class'] as List)]);
    
    // 初始化每个分类的页码和数据状态
    for (var category in classList) {
      final typeName = category['type_name'] as String;
      currentPages[typeName] = 1;
      totalPages[typeName] = 1;
      
      // 初始化分类数据缓存
      if (!categoryData.containsKey(typeName)) {
        categoryData[typeName] = [];
      }
      
      // 初始化滚动加载状态
      loadingMoreStates[typeName] = false;
      hasMoreStates[typeName] = true;
    }
    
    // 缓存首页数据
    if (homeData.containsKey('list')) {
      categoryData["主页"] = homeData['list'] as List;
    }
    
    // 只有当TabController不存在或长度不匹配时才创建新的
    if (tabController == null || tabController!.length != classList.length) {
      tabController?.dispose();
      tabController = TabController(length: classList.length, vsync: this);
      
      // 监听标签变化
      tabController?.addListener(_onTabChanged);
    }
    
    isLoading.value = false;
  }
  
  // 刷新当前选中的分类数据
  Future<void> refreshCurrentCategory() async {
    if (tabController != null && tabController!.index < classList.length) {
      final selectedCategory = classList[tabController!.index];
      final selectedTypeName = selectedCategory['type_name'] as String;
      await refreshData(selectedTypeName);
    }
  }

  // 单独的标签变化处理方法
  void _onTabChanged() {
    if (tabController!.indexIsChanging && !_isProcessingTabChange) {
      _isProcessingTabChange = true;
      
      // 延迟加载，确保UI切换完成
      Future.delayed(const Duration(milliseconds: 300), () async {
        if (tabController != null && tabController!.index < classList.length) {
          // 获取当前选中的分类
          final selectedCategory = classList[tabController!.index];
          final selectedTypeName = selectedCategory['type_name'] as String;
          final selectedTypeId = selectedCategory['type_id']?.toString() ?? '';
          
          // 如果不是主页，则重新加载该分类的数据
          if (selectedTypeName != "主页" && selectedTypeId.isNotEmpty) {
            categoryLoadingStates[selectedTypeName] = true;
            try {
              await fetchCategoryData(selectedTypeId, typeName: selectedTypeName, isInitialLoad: true);
            } finally {
              categoryLoadingStates[selectedTypeName] = false;
            }
          }
        }
        
        _isProcessingTabChange = false;
      });
    }
  }
  
  // 确保分类数据已加载（用于UI触发）
  void ensureCategoryDataLoaded(String typeName) {
    // 如果数据不存在且没有正在加载，则开始加载
    if (!categoryData.containsKey(typeName) || categoryData[typeName]!.isEmpty) {
      final isCurrentlyLoading = categoryLoadingStates[typeName] ?? false;
      if (!isCurrentlyLoading) {
        // 从classList中查找对应的typeId
        final typeId = _getTypeIdByName(typeName);
        if (typeId.isNotEmpty) {
          // 延迟执行避免在build期间触发状态更新
          Future.microtask(() {
            categoryLoadingStates[typeName] = true;
            fetchCategoryData(typeId, typeName: typeName, isInitialLoad: true).then((_) {
              categoryLoadingStates[typeName] = false;
            }).catchError((error) {
              categoryLoadingStates[typeName] = false;
            });
          });
        }
      }
    }
  }

  // 获取分类数据
  Future<Map<String, dynamic>> fetchCategoryData(String typeId, {String? typeName, bool isInitialLoad = false}) async {
    final displayName = typeName ?? typeId; // 用于显示和缓存键的名称
    final page = currentPages[displayName] ?? 1;
    final cacheKey = '${displayName}_$page';
    
    // 如果已经有缓存的Future，返回它
    if (_categoryFutures.containsKey(cacheKey)) {
      return _categoryFutures[cacheKey]!;
    }

    // 创建新的Future并缓存
    final future = _fetchCategoryDataInternal(typeId, displayName, page);
    _categoryFutures[cacheKey] = future;
    
    return future;
  }
  
  // 内部实际获取数据的方法
  Future<Map<String, dynamic>> _fetchCategoryDataInternal(String typeId, String displayName, int page) async {
    // 检查是否强制使用mock数据
    if (AppConfig.forceMockData) {
      final mockData = CategoryContent.getMockData(typeId, page: page);
      
      _updateDataAndPages(displayName, mockData, isLoadMore: page > 1);
      return mockData;
    }
    
    try {
      // 尝试从真实接口获取数据，传递typeId
      final data = await _dataSource.fetchCategoryData(typeId, page: page);
      _updateDataAndPages(displayName, data, isLoadMore: page > 1);
      return data;
    } catch (e) {
      if (kDebugMode) {
        print('分类API调用失败，使用mock数据: $e');
      }
      // 如果API调用失败，回退到使用mock数据
      final mockData = CategoryContent.getMockData(typeId, page: page);
      _updateDataAndPages(displayName, mockData, isLoadMore: page > 1);
      return mockData;
    }
  }
  
  // 获取或创建 ScrollController
  ScrollController getScrollController(String typeName) {
    if (!_scrollControllers.containsKey(typeName)) {
      _scrollControllers[typeName] = ScrollController();
    }
    return _scrollControllers[typeName]!;
  }
  
  // 获取或创建缓存的 Future
  Future<ui.Image> getCachedImageFuture(String typeName, String imageUrl) {
    final cacheKey = '${typeName}_$imageUrl';
    if (!_imageFutures.containsKey(cacheKey)) {
      _imageFutures[cacheKey] = getImageInfo(imageUrl);
    }
    return _imageFutures[cacheKey]!;
  }
  
  // 更新数据和页码（高性能优化版本）
  void _updateDataAndPages(String typeName, Map<String, dynamic> data, {bool isLoadMore = false}) {
    // 更新总页数
    if (data.containsKey('pagecount')) {
      final pageCountValue = data['pagecount'];
      int newTotalPages;
      if (pageCountValue is int) {
        newTotalPages = pageCountValue > 0 ? pageCountValue : 1;
      } else if (pageCountValue is String) {
        newTotalPages = int.tryParse(pageCountValue) ?? 1;
      } else {
        newTotalPages = 1;
      }
      
      // 只有值改变时才更新
      if (totalPages[typeName] != newTotalPages) {
        totalPages[typeName] = newTotalPages;
      }
    } else if (!totalPages.containsKey(typeName)) {
      totalPages[typeName] = 1;
    }

    // 更新是否有更多数据的状态
    final currentPage = currentPages[typeName] ?? 1;
    final totalPage = totalPages[typeName] ?? 1;
    final newHasMore = currentPage < totalPage;
    
    // 只有值改变时才更新
    if (hasMoreStates[typeName] != newHasMore) {
      hasMoreStates[typeName] = newHasMore;
    }

    // 处理数据 - 优化数据更新逻辑
    if (data.containsKey('list')) {
      final newList = data['list'] as List;
      
      if (isLoadMore) {
        // 加载更多：延迟追加数据以避免阻塞UI
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final existingData = categoryData[typeName] ?? [];
          // 使用List.from创建新列表，避免引用问题
          categoryData[typeName] = List.from(existingData)..addAll(newList);
        });
      } else {
        // 初始加载或刷新：只有数据真正改变时才更新
        final currentData = categoryData[typeName] ?? [];
        if (currentData.length != newList.length || 
            !_listsAreEqual(currentData, newList)) {
          categoryData[typeName] = List.from(newList);
        }
      }
    } else if (!isLoadMore && categoryData.containsKey(typeName)) {
      // 只有非空数据才清空
      if (categoryData[typeName]?.isNotEmpty == true) {
        categoryData[typeName] = [];
      }
    }
  }
  
  // 辅助方法：比较列表是否相等（浅比较）
  bool _listsAreEqual(List? list1, List? list2) {
    if (list1 == null || list2 == null) return list1 == list2;
    if (list1.length != list2.length) return false;
    
    // 只比较前几个元素的ID，避免深度比较影响性能
    final checkCount = math.min(5, list1.length);
    for (int i = 0; i < checkCount; i++) {
      final item1 = list1[i];
      final item2 = list2[i];
      if (item1['vod_id'] != item2['vod_id']) {
        return false;
      }
    }
    return true;
  }
  
  // 根据分类名称获取分类ID
  String _getTypeIdByName(String typeName) {
    for (var category in classList) {
      if (category['type_name'] == typeName) {
        return category['type_id']?.toString() ?? "";
      }
    }
    return "1"; // 默认返回第一个分类ID
  }
  
  // 刷新数据
  Future<void> refreshData(String typeName) async {
    if (typeName == "主页") {
      // 清空主页数据，让用户看到刷新效果
      homeData.clear();
      categoryData["主页"] = [];
      await _fetchHomeData();
    } else {
      categoryLoadingStates[typeName] = true;
      currentPages[typeName] = 1;
      hasMoreStates[typeName] = true;
      
      // 强制清空现有数据，让用户看到刷新效果
      categoryData[typeName] = [];
      
      // 清除缓存的Future
      final page = currentPages[typeName] ?? 1;
      final cacheKey = '${typeName}_$page';
      _categoryFutures.remove(cacheKey);
      
      try {
        final typeId = _getTypeIdByName(typeName);
        await fetchCategoryData(typeId, typeName: typeName, isInitialLoad: true);
      } finally {
        categoryLoadingStates[typeName] = false;
      }
    }
  }
  
  // 加载更多数据
  Future<void> loadMoreData(String typeName) async {
    // 如果已经在加载或者没有更多数据，则不执行
    if (loadingMoreStates[typeName] == true || hasMoreStates[typeName] == false) {
      return;
    }
    
    loadingMoreStates[typeName] = true;
    
    try {
      // 计算下一页
      final nextPage = (currentPages[typeName] ?? 1) + 1;
      currentPages[typeName] = nextPage;
      
      // 清除缓存的Future
      final cacheKey = '${typeName}_$nextPage';
      _categoryFutures.remove(cacheKey);
      
      // 获取下一页数据
      final typeId = _getTypeIdByName(typeName);
      await fetchCategoryData(typeId, typeName: typeName, isInitialLoad: false);
    } finally {
      loadingMoreStates[typeName] = false;
    }
  }
  
  // 生成页码列表
  List<int> generatePageNumbers(int currentPage, int totalPages) {
    if (totalPages <= 7) {
      return List.generate(totalPages, (index) => index + 1);
    }

    List<int> pages = [];
    if (currentPage <= 4) {
      pages.addAll([1, 2, 3, 4, 5, -1, totalPages]);
    } else if (currentPage > totalPages - 4) {
      pages.addAll([1, -1, totalPages - 4, totalPages - 3, totalPages - 2, totalPages - 1, totalPages]);
    } else {
      pages.addAll([1, -1, currentPage - 1, currentPage, currentPage + 1, -1, totalPages]);
    }
    return pages;
  }
  
  // 获取图片信息
  Future<ui.Image> getImageInfo(String imageUrl) async {
    final Completer<ui.Image> completer = Completer();
    final image = NetworkImage(imageUrl);
    
    image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        if (!completer.isCompleted) {
          completer.complete(info.image);
        }
      }, onError: (dynamic exception, StackTrace? stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(exception);
        }
      }),
    );
    
    return completer.future;
  }
}