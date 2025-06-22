import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui' as ui;
import '../mock/home_content.dart';
import '../mock/category_content.dart'; // 导入分类内容数据
import '../window_controller.dart'; // 导入窗口控制器
import '../app/data_source.dart'; // 导入数据源服务
import '../app/config.dart'; // 导入配置

class VodPage extends StatefulWidget {
  const VodPage({super.key});

  @override
  State<VodPage> createState() => _VodPageState();
}

class _VodPageState extends State<VodPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _homeData;
  bool _isLoading = true;
  
  // 添加主页分类
  final Map<String, dynamic> _homeCategory = {"type_id": "0", "type_name": "主页"};
  
  // 创建数据源实例 - 使用单例模式
  final DataSource _dataSource = DataSource();
  
  // 分类列表
  List<dynamic> _classList = [];
  
  // 当前页码，用于分页加载
  final Map<String, int> _currentPages = {};
  
  // 分类数据缓存
  final Map<String, List<dynamic>> _categoryData = {};
  
  // 是否正在加载更多数据
  bool _isLoadingMore = false;
  
  // 是否还有更多数据可加载
  final Map<String, bool> _hasMoreData = {};
  
  // 滚动控制器
  final Map<String, ScrollController> _scrollControllers = {};
  
  @override
  void initState() {
    super.initState();
    _fetchHomeData().then((_) {
      _tabController.addListener(() {
        if (_tabController.indexIsChanging) {
          final tabIndex = _tabController.index;
          if (tabIndex >= 0 && tabIndex < _classList.length) {
            final category = _classList[tabIndex];
            final typeName = category['type_name'] as String;

            if (typeName == "主页") {
              _refreshHomeData();
            } else {
              _refreshCategoryData(typeName);
            }
          }
        }
      });
    });
  }
  
  // 获取首页数据
  Future<void> _fetchHomeData({bool isRefresh = false}) async {
    if (!isRefresh) {
      setState(() => _isLoading = true);
    }
    
    try {
      // 检查是否强制使用mock数据
      if (AppConfig.forceMockData) {
        // 强制使用mock数据
        final mockData = HomeContent.getMockData();
        setState(() {
          _homeData = mockData;
          _classList = [_homeCategory, ...(_homeData!['class'] as List)];
          
          // 初始化每个分类的页码和数据状态
          for (var category in _classList) {
            final typeName = category['type_name'] as String;
            _currentPages[typeName] = 1;
            _hasMoreData[typeName] = true;
            
            // 为每个分类创建滚动控制器
            if (!_scrollControllers.containsKey(typeName)) {
              _scrollControllers[typeName] = ScrollController()
                ..addListener(() {
                  _scrollListener(typeName);
                });
            }
            
            // 初始化分类数据缓存
            if (!_categoryData.containsKey(typeName)) {
              _categoryData[typeName] = [];
            }
          }
          
          // 缓存首页数据
          if (_homeData!.containsKey('list')) {
            _categoryData["主页"] = _homeData!['list'] as List;
          }
          
          _tabController = TabController(length: _classList.length, vsync: this);
          _isLoading = false;
        });
        
        // 监听标签变化
        _tabController.addListener(() {
          if (_tabController.indexIsChanging) {
            setState(() {
              _isLoading = true;
            });
            
            // 延迟加载，确保UI切换完成
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            });
          }
        });
        
        return;
      }
      
      // 尝试从真实接口获取数据
      final data = await _dataSource.fetchHomeData();
      setState(() {
        _homeData = data;
        _classList = [_homeCategory, ...(_homeData!['class'] as List)];
        
        // 初始化每个分类的页码和数据状态
        for (var category in _classList) {
          final typeName = category['type_name'] as String;
          _currentPages[typeName] = 1;
          _hasMoreData[typeName] = true;
          
          // 为每个分类创建滚动控制器
          if (!_scrollControllers.containsKey(typeName)) {
            _scrollControllers[typeName] = ScrollController()
              ..addListener(() {
                _scrollListener(typeName);
              });
          }
          
          // 初始化分类数据缓存
          if (!_categoryData.containsKey(typeName)) {
            _categoryData[typeName] = [];
          }
        }
        
        // 缓存首页数据
        if (_homeData!.containsKey('list')) {
          _categoryData["主页"] = _homeData!['list'] as List;
        }
        
        _tabController = TabController(length: _classList.length, vsync: this);
        _isLoading = false;
      });
      
      // 监听标签变化
      _tabController.addListener(() {
        if (_tabController.indexIsChanging) {
          setState(() {
            _isLoading = true;
          });
          
          // 延迟加载，确保UI切换完成
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          });
        }
      });
    } catch (e) {
      // 如果接口调用失败，回退到使用mock数据
      print('API调用失败，使用mock数据: $e');
      final mockData = HomeContent.getMockData();
      setState(() {
        _homeData = mockData;
        _classList = [_homeCategory, ...(_homeData!['class'] as List)];
        
        // 初始化每个分类的页码和数据状态
        for (var category in _classList) {
          final typeName = category['type_name'] as String;
          _currentPages[typeName] = 1;
          _hasMoreData[typeName] = true;
          
          // 为每个分类创建滚动控制器
          if (!_scrollControllers.containsKey(typeName)) {
            _scrollControllers[typeName] = ScrollController()
              ..addListener(() {
                _scrollListener(typeName);
              });
          }
          
          // 初始化分类数据缓存
          if (!_categoryData.containsKey(typeName)) {
            _categoryData[typeName] = [];
          }
        }
        
        // 缓存首页数据
        if (_homeData!.containsKey('list')) {
          _categoryData["主页"] = _homeData!['list'] as List;
        }
        
        _tabController = TabController(length: _classList.length, vsync: this);
        _isLoading = false;
      });
      
      // 监听标签变化
      _tabController.addListener(() {
        if (_tabController.indexIsChanging) {
          setState(() {
            _isLoading = true;
          });
          
          // 模拟加载延迟
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          });
        }
      });
    }
  }
  
  // 滚动监听器
  void _scrollListener(String typeName) {
    final controller = _scrollControllers[typeName];
    if (controller == null) return;
    
    // 如果是主页，不需要加载更多
    if (typeName == "主页") return;
    
    // 如果没有更多数据，不需要加载
    if (_hasMoreData[typeName] == false) return;
    
    // 如果正在加载，不需要重复加载
    if (_isLoadingMore) return;
    
    // 如果滚动到接近底部，加载更多数据
    if (controller.position.pixels >= controller.position.maxScrollExtent - 200) {
      _loadMoreData(typeName);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    // 释放所有滚动控制器
    for (var controller in _scrollControllers.values) {
      controller.dispose();
    }
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 获取窗口控制器实例
    final windowController = WindowController();
    // 根据窗口方向设置背景色：横屏黑色，竖屏浅灰色(与PortraitHomeLayout一致)
    final backgroundColor = !windowController.isPortrait.value 
        ? Colors.black 
        : const Color(0xFFF6F7F8); // 与PortraitHomeLayout一致的浅灰色背景
    
    // 如果数据正在加载中，显示加载指示器
    if (_isLoading && _homeData == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFF7BB0), // B站粉色
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        // 根据屏幕方向调整AppBar样式
        toolbarHeight: windowController.isPortrait.value ? 48 : null, // 竖屏模式下调整高度
        // 使用B站风格的顶部导航，但内容是我们自己的分类
        title: SizedBox(
          height: windowController.isPortrait.value ? 36 : 40, // 竖屏模式下高度稍小
          width: double.infinity, // 确保宽度占满
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: _classList.map((item) {
              return Tab(
                height: windowController.isPortrait.value ? 36 : 40, // 竖屏模式下高度稍小
                child: Text(
                  item['type_name'] as String,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: windowController.isPortrait.value ? 15 : 16, // 竖屏模式下字体稍小
                  ),
                ),
              );
            }).toList(),
            labelColor: const Color(0xFFFF7BB0), // B站粉色
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFFFF7BB0), // B站粉色
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            indicator: UnderlineTabIndicator(
              borderSide: const BorderSide(
                color: Color(0xFFFF7BB0),
                width: 3,
              ),
              insets: EdgeInsets.symmetric(
                horizontal: windowController.isPortrait.value ? 12 : 16, // 竖屏模式下指示器宽度稍小
              ),
            ),
            // 竖屏模式下靠左对齐
            padding: windowController.isPortrait.value 
                ? const EdgeInsets.only(left: 16) 
                : null,
            // 确保标签可以滚动
            tabAlignment: windowController.isPortrait.value 
                ? TabAlignment.start  // 竖屏模式下靠左对齐
                : TabAlignment.center, // 横屏模式下居中对齐
            // 调整标签间距
            labelPadding: EdgeInsets.symmetric(
              horizontal: windowController.isPortrait.value ? 12 : 16, // 竖屏模式下标签间距稍小
            ),
          ),
        ),
        // 竖屏模式下让标题居左对齐
        titleSpacing: windowController.isPortrait.value ? 0 : null,
        centerTitle: !windowController.isPortrait.value, // 横屏居中，竖屏靠左
      ),
      body: TabBarView(
        controller: _tabController,
        children: _classList.map((category) {
          final typeId = category['type_id'] as String;
          final typeName = category['type_name'] as String;
          
          // 如果是主页，使用HomeData的数据
          if (typeId == "0") {
            if (_categoryData.containsKey("主页") && _categoryData["主页"]!.isNotEmpty) {
              return _buildVideoGridPage(_categoryData["主页"]!, typeName);
            } else if (_homeData != null && _homeData!.containsKey('list')) {
              // 缓存首页数据
              _categoryData["主页"] = _homeData!['list'] as List;
              return _buildVideoGridPage(_categoryData["主页"]!, typeName);
            } else {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFF7BB0), // B站粉色
                ),
              );
            }
          } else {
            // 如果已有缓存数据，直接显示
            if (_categoryData.containsKey(typeName) && _categoryData[typeName]!.isNotEmpty) {
              return _buildVideoGridPage(_categoryData[typeName]!, typeName);
            }
            
            // 否则从API获取数据
            return FutureBuilder(
              future: _fetchCategoryData(typeName, isInitialLoad: true),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting || _isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFF7BB0), // B站粉色
                    ),
                  );
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      '加载失败: ${snapshot.error}',
                      style: TextStyle(
                        color: !windowController.isPortrait.value ? Colors.white : Colors.black,
                      ),
                    ),
                  );
                }
                
                // 确保分类数据已缓存
                if (!_categoryData.containsKey(typeName) || _categoryData[typeName]!.isEmpty) {
                  final data = snapshot.data as Map<String, dynamic>;
                  if (data.containsKey('list')) {
                    _categoryData[typeName] = data['list'] as List;
                  } else {
                    _categoryData[typeName] = [];
                  }
                }
                
                return _buildVideoGridPage(_categoryData[typeName]!, typeName);
              },
            );
          }
        }).toList(),
      ),
    );
  }
  
  // 获取分类数据，先尝试API，失败则使用mock
  Future<Map<String, dynamic>> _fetchCategoryData(String typeName, {bool isInitialLoad = false}) async {
    // 检查是否强制使用mock数据
    if (AppConfig.forceMockData) {
      // 强制使用mock数据
      final typeId = _getTypeIdByName(typeName);
      final mockData = await CategoryContent.getMockData(typeId);
      
      // 如果不是初始加载，将新数据添加到现有数据中
      if (!isInitialLoad && _categoryData.containsKey(typeName)) {
        final newList = mockData['list'] as List;
        if (newList.isNotEmpty) {
          _categoryData[typeName]!.addAll(newList);
        } else {
          // 如果返回的列表为空，表示没有更多数据了
          _hasMoreData[typeName] = false;
        }
      } else {
        // 初始加载，直接替换数据
        if (mockData.containsKey('list')) {
          _categoryData[typeName] = mockData['list'] as List;
        } else {
          _categoryData[typeName] = [];
        }
      }
      
      return mockData;
    }
    
    try {
      // 如果是初始加载，重置页码为1
      if (isInitialLoad) {
        _currentPages[typeName] = 1;
      }
      
      // 获取当前分类的页码
      final page = _currentPages[typeName] ?? 1;
      
      // 尝试从真实接口获取数据
      final data = await _dataSource.fetchCategoryData(typeName, page: page);
      
      // 如果不是初始加载，将新数据添加到现有数据中
      if (!isInitialLoad && _categoryData.containsKey(typeName)) {
        final newList = data['list'] as List;
        if (newList.isNotEmpty) {
          _categoryData[typeName]!.addAll(newList);
        } else {
          // 如果返回的列表为空，表示没有更多数据了
          _hasMoreData[typeName] = false;
        }
      } else {
        // 初始加载，直接替换数据
        if (data.containsKey('list')) {
          _categoryData[typeName] = data['list'] as List;
        } else {
          _categoryData[typeName] = [];
        }
      }
      
      return data;
    } catch (e) {
      print('分类API调用失败，使用mock数据: $e');
      // 如果API调用失败，回退到使用mock数据
      // 注意：这里我们仍然使用typeId，因为mock数据是按照typeId组织的
      final typeId = _getTypeIdByName(typeName);
      final mockData = await CategoryContent.getMockData(typeId);
      
      // 如果不是初始加载，将新数据添加到现有数据中
      if (!isInitialLoad && _categoryData.containsKey(typeName)) {
        final newList = mockData['list'] as List;
        if (newList.isNotEmpty) {
          _categoryData[typeName]!.addAll(newList);
        } else {
          // 如果返回的列表为空，表示没有更多数据了
          _hasMoreData[typeName] = false;
        }
      } else {
        // 初始加载，直接替换数据
        if (mockData.containsKey('list')) {
          _categoryData[typeName] = mockData['list'] as List;
        } else {
          _categoryData[typeName] = [];
        }
      }
      
      return mockData;
    }
  }
  
  // 根据分类名称获取分类ID
  String _getTypeIdByName(String typeName) {
    for (var category in _classList) {
      if (category['type_name'] == typeName) {
        return category['type_id'] as String;
      }
    }
    return "1"; // 默认返回第一个分类ID
  }
  
  // 构建视频网格页面
  Widget _buildVideoGridPage(List videoList, String typeName) {
    if (videoList.isEmpty) {
      return _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7BB0)))
          : Center(child: Text("此分类下暂无内容", style: TextStyle(color: Colors.grey[600])));
    }

    final firstVideo = videoList.first;
    final firstImageUrl = firstVideo['vod_pic'] as String;

    // 使用FutureBuilder来异步决定布局
    return FutureBuilder<ui.Image>(
      future: _getImageInfo(firstImageUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFF7BB0)));
        }

        bool isLandscapeLayout;
        if (snapshot.hasData) {
          // 根据真实的图片尺寸决定布局
          final image = snapshot.data!;
          isLandscapeLayout = image.width > image.height;
        } else {
          // 如果获取图片尺寸失败，则回退到默认布局（竖向）
          isLandscapeLayout = false; 
        }

        // 使用决定的布局来构建网格
        return _buildGridWithLayout(videoList, typeName, isLandscapeLayout);
      },
    );
  }
  
  // 实际构建网格和RefreshIndicator的辅助方法
  Widget _buildGridWithLayout(List videoList, String typeName, bool isLandscapeLayout) {
    return RefreshIndicator(
      color: const Color(0xFFFF7BB0),
      backgroundColor: Colors.grey[900],
      onRefresh: () async {
        if (typeName == "主页") {
          await _refreshHomeData();
        } else {
          await _refreshCategoryData(typeName);
        }
      },
      child: Column(
        children: [
          Expanded(
            child: _buildVideoGrid(videoList, typeName, isLandscapeLayout),
          ),
          if (_isLoadingMore && typeName != "主页")
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF7BB0), strokeWidth: 3),
              ),
            ),
          if (_hasMoreData[typeName] == false && typeName != "主页")
            Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: const Text('没有更多内容了', style: TextStyle(color: Colors.grey, fontSize: 14)),
            ),
        ],
      ),
    );
  }

  // 构建视频网格
  Widget _buildVideoGrid(List videoList, String typeName, bool isLandscapeLayout) {
    final windowController = WindowController();
    final isPortrait = windowController.isPortrait.value;

    int crossAxisCount;
    double childAspectRatio;

    if (isPortrait) {
      // 竖屏模式，固定2列
      crossAxisCount = 2;
      childAspectRatio = isLandscapeLayout ? 1.3 : 0.65; // 恢复之前的比例
    } else {
      // 横屏模式，固定4列
      crossAxisCount = 4;
      childAspectRatio = isLandscapeLayout ? 1.6 : 0.75; // 恢复之前的比例
    }

    return GridView.builder(
      controller: _scrollControllers[typeName],
      padding: EdgeInsets.all(isPortrait ? 12 : 15),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: isPortrait ? 10 : 12,
        mainAxisSpacing: isPortrait ? 12 : 15,
      ),
      itemCount: videoList.length,
      itemBuilder: (context, index) {
        final video = videoList[index];
        return _buildVideoCard(video, index, isLandscapeLayout);
      },
    );
  }

  // 构建视频卡片
  Widget _buildVideoCard(dynamic video, int index, bool isLandscapeLayout) {
    final windowController = WindowController();
    final textColor = !windowController.isPortrait.value ? Colors.white : Colors.black;
    final isPortrait = windowController.isPortrait.value;

    final String? remarks = video['vod_remarks'];
    // 判断备注是否应该显示（长度小于等于15个字符）
    final bool shouldShowRemarks = remarks != null && remarks.length <= 30;

    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('即将播放: ${video['vod_name']}'),
            backgroundColor: const Color(0xFFFF7BB0),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      borderRadius: BorderRadius.circular(isPortrait ? 8 : 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(isPortrait ? 8 : 6),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 3, offset: const Offset(0, 2)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isPortrait ? 8 : 6),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildCoverImage(video['vod_pic'] as String, isLandscapeLayout),
                    if (index < 10)
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          width: isPortrait ? 28 : 24,
                          height: isPortrait ? 28 : 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _getRankingColor(index),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(isPortrait ? 8 : 6),
                              bottomRight: Radius.circular(isPortrait ? 8 : 6),
                            ),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isPortrait ? 14 : 12),
                          ),
                        ),
                      ),
                    
                    // 根据判断结果决定是否显示备注
                    if (shouldShowRemarks)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        left: 0,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: isPortrait ? 8 : 6, vertical: isPortrait ? 4 : 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(isPortrait ? 8 : 6),
                              bottomRight: Radius.circular(isPortrait ? 8 : 6),
                            ),
                          ),
                          child: Text(
                            remarks!, // 此时 remarks 必不为 null
                            style: TextStyle(fontSize: isPortrait ? 11 : 10, color: Colors.white, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            height: isPortrait ? 40 : 34,
            padding: EdgeInsets.only(top: isPortrait ? 8 : 6, left: isPortrait ? 2 : 1, right: isPortrait ? 2 : 1),
            child: Text(
              video['vod_name'] as String,
              style: TextStyle(fontSize: isPortrait ? 13 : 11, color: textColor, fontWeight: FontWeight.normal, height: 1.2),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // 构建封面图片
  Widget _buildCoverImage(String imageUrl, bool isLandscapeLayout) {
    return Image.network(
      imageUrl,
      fit: BoxFit.fill, // 保持拉伸填充
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[800],
          child: const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 20)),
        );
      },
    );
  }
  
  // 获取排名颜色
  Color _getRankingColor(int index) {
    switch (index) {
      case 0:
        return Colors.orange; // 第一名
      case 1:
        return Colors.cyan; // 第二名
      case 2:
        return Colors.pink; // 第三名
      default:
        return Colors.grey.withValues(alpha: 0.8); // 其他名次
    }
  }
  
  // 加载更多数据
  Future<void> _loadMoreData(String typeName) async {
    // 如果正在加载或没有更多数据，则不执行
    if (_isLoadingMore || _hasMoreData[typeName] == false) return;
    
    setState(() {
      _isLoadingMore = true;
      
      // 增加当前分类的页码
      _currentPages[typeName] = (_currentPages[typeName] ?? 1) + 1;
    });
    
    try {
      // 获取下一页数据
      await _fetchCategoryData(typeName);
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  // 重新引入获取图片信息的方法
  Future<ui.Image> _getImageInfo(String imageUrl) async {
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

  // 刷新主页数据
  Future<void> _refreshHomeData() async {
    await _fetchHomeData(isRefresh: true);
  }

  // 刷新分类数据
  Future<void> _refreshCategoryData(String typeName) async {
    setState(() {
      _currentPages[typeName] = 1;
      _hasMoreData[typeName] = true;
      _categoryData[typeName]?.clear();
    });
    await _fetchCategoryData(typeName, isInitialLoad: true);
  }
}
