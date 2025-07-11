import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui' as ui;
import '../mock/home_content.dart';
import '../mock/category_content.dart'; // 导入分类内容数据
import '../window_controller.dart'; // 导入窗口控制器
import '../app/data_source.dart'; // 导入数据源服务
import '../app/config.dart'; // 导入配置
import 'video_detail_page.dart'; // 导入视频详情页

class VodPage extends StatefulWidget {
  const VodPage({super.key});

  @override
  State<VodPage> createState() => _VodPageState();
}

class _VodPageState extends State<VodPage> with TickerProviderStateMixin {
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
  
  // 总页数
  final Map<String, int> _totalPages = {};
  
  @override
  void initState() {
    super.initState();
    _fetchHomeData();
  }
  
  // 获取首页数据
  Future<void> _fetchHomeData() async {
    setState(() {
      _isLoading = true;
    });
    
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
            _totalPages[typeName] = 1;
            
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
            Future.delayed(const Duration(milliseconds: 300), () async {
              if (mounted) {
                // 获取当前选中的分类
                final selectedCategory = _classList[_tabController.index];
                final selectedTypeName = selectedCategory['type_name'] as String;
                
                // 如果不是主页，则重新加载该分类的数据
                if (selectedTypeName != "主页") {
                  await _fetchCategoryData(selectedTypeName, isInitialLoad: true);
                }
                
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
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
          _totalPages[typeName] = 1;
          
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
          Future.delayed(const Duration(milliseconds: 300), () async {
            if (mounted) {
              // 获取当前选中的分类
              final selectedCategory = _classList[_tabController.index];
              final selectedTypeName = selectedCategory['type_name'] as String;
              
              // 如果不是主页，则重新加载该分类的数据
              if (selectedTypeName != "主页") {
                await _fetchCategoryData(selectedTypeName, isInitialLoad: true);
              }
              
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            }
          });
        }
      });
    } catch (e) {
      // 如果接口调用失败，回退到使用mock数据
      if (kDebugMode) {
        print('API调用失败，使用mock数据: $e');
      }
      final mockData = HomeContent.getMockData();
      setState(() {
        _homeData = mockData;
        _classList = [_homeCategory, ...(_homeData!['class'] as List)];
        
        // 初始化每个分类的页码和数据状态
        for (var category in _classList) {
          final typeName = category['type_name'] as String;
          _currentPages[typeName] = 1;
          _totalPages[typeName] = 1;
          
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
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
    final page = _currentPages[typeName] ?? 1;

    // 检查是否强制使用mock数据
    if (AppConfig.forceMockData) {
      final typeId = _getTypeIdByName(typeName);
      final mockData = CategoryContent.getMockData(typeId, page: page);
      
      _updateDataAndPages(typeName, mockData);
      return mockData;
    }
    
    try {
      // 尝试从真实接口获取数据
      final data = await _dataSource.fetchCategoryData(typeName, page: page);
      _updateDataAndPages(typeName, data);
      return data;
    } catch (e) {
      if (kDebugMode) {
        print('分类API调用失败，使用mock数据: $e');
      }
      // 如果API调用失败，回退到使用mock数据
      final typeId = _getTypeIdByName(typeName);
      final mockData = CategoryContent.getMockData(typeId, page: page);
      _updateDataAndPages(typeName, mockData);
      return mockData;
    }
  }

  void _updateDataAndPages(String typeName, Map<String, dynamic> data) {
    // 更新总页数
    if (data.containsKey('pagecount')) {
      final pageCountValue = data['pagecount'];
      if (pageCountValue is int) {
        _totalPages[typeName] = pageCountValue > 0 ? pageCountValue : 1;
      } else if (pageCountValue is String) {
        _totalPages[typeName] = int.tryParse(pageCountValue) ?? 1;
      } else {
        _totalPages[typeName] = 1;
      }
    } else {
      _totalPages[typeName] = 1;
    }

    // 初始加载或翻页，直接替换数据
    if (data.containsKey('list')) {
      _categoryData[typeName] = data['list'] as List;
    } else {
      _categoryData[typeName] = [];
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
    final windowController = WindowController();
    final isPortrait = windowController.isPortrait.value;
    
    return RefreshIndicator(
      color: const Color(0xFFFF7BB0),
      backgroundColor: Colors.grey[900],
      onRefresh: () async {
        // 刷新数据
        if (typeName == "主页") {
          await _fetchHomeData();
        } else {
          setState(() {
            _isLoading = true;
            _currentPages[typeName] = 1;
          });
          try {
            await _fetchCategoryData(typeName, isInitialLoad: true);
          } finally {
            if (mounted) setState(() => _isLoading = false);
          }
        }
      },
      child: Column(
        children: [
          Expanded(
            child: _buildVideoGrid(videoList, typeName, isLandscapeLayout),
          ),
          if (typeName != "主页") 
            isPortrait 
              ? _buildPortraitPageNavigator(typeName) 
              : _buildLandscapePageNavigator(typeName),
        ],
      ),
    );
  }

  // 构建视频网格
  Widget _buildVideoGrid(List videoList, String typeName, bool isLandscapeLayout) {
    final windowController = WindowController();
    final isPortrait = windowController.isPortrait.value;

    int crossAxisCount;

    if (isPortrait) {
      // 竖屏模式，固定2列
      crossAxisCount = 2;
    } else {
      // 横屏模式，固定4列
      crossAxisCount = 4;
    }

    // 标题高度 - 固定两行文本高度
    final double titleHeight = 36;
    // 图片与标题之间的间距
    final double spacing = 2;
    
    // 计算每个网格项的宽度
    final double screenWidth = MediaQuery.of(context).size.width;
    final double itemWidth = isPortrait 
        ? (screenWidth - 28) / 2 // 竖屏2列，减去边距和间距
        : (screenWidth - 58) / 4; // 横屏4列，减去边距和间距
    
    // 根据16:9比例计算图片高度
    final double imageHeight = itemWidth * 9 / 16;
    
    // 计算网格项总高度
    final double itemHeight = imageHeight + spacing + titleHeight;
    
    // 计算网格项宽高比
    final double childAspectRatio = itemWidth / itemHeight;

    return GridView.builder(
      padding: EdgeInsets.all(isPortrait ? 10 : 12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: isPortrait ? 8 : 10,
        mainAxisSpacing: isPortrait ? 12 : 16,
      ),
      itemCount: videoList.length,
      itemBuilder: (context, index) {
        final video = videoList[index];
        return _buildVideoCard(video, index, itemWidth, imageHeight, titleHeight, spacing);
      },
    );
  }

  // 构建视频卡片
  Widget _buildVideoCard(dynamic video, int index, double itemWidth, double imageHeight, double titleHeight, double spacing) {
    final windowController = WindowController();
    final textColor = !windowController.isPortrait.value ? Colors.white : Colors.black;
    final isPortrait = windowController.isPortrait.value;
    final cardBgColor = isPortrait ? Colors.white : Colors.grey[900];

    final String? remarks = video['vod_remarks'];
    // 判断备注是否应该显示（长度小于等于30个字符）
    final bool shouldShowRemarks = remarks != null && remarks.length <= 30;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. 图片卡片 - 固定16:9比例
        Card(
      elevation: isPortrait ? 2 : 1,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isPortrait ? 8 : 6),
      ),
          color: cardBgColor,
          child: SizedBox(
            width: itemWidth,
            height: imageHeight,
      child: Stack(
              fit: StackFit.expand,
        children: [
                // 图片
                Image.network(
                  video['vod_pic'],
                  width: itemWidth,
                  height: imageHeight,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => 
                    Container(color: Colors.grey[800]),
      ),
                // 备注（如果有）- 右下角，背景铺满整个宽度
                if (shouldShowRemarks)
                  Positioned(
                    bottom: 0,
      left: 0,
                    right: 0,
      child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), // 从4减少到3，约为原来的75%
        decoration: BoxDecoration(
                        // 增加透明度，使背景更加透明
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withAlpha(179), // 替换withOpacity(0.7)，179约等于0.7*255
                            Colors.black.withAlpha(51),  // 替换withOpacity(0.2)，51约等于0.2*255
                          ],
          ),
        ),
        child: Text(
          remarks,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right, // 文字靠右对齐
        ),
      ),
                  ),
                // 点击效果
                Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                          builder: (context) => VideoDetailPage(videoId: video['vod_id']),
              ),
            );
          },
        ),
      ),
              ],
            ),
          ),
        ),
        // 间距
        SizedBox(height: spacing),
        // 2. 标题 - 固定高度
        SizedBox(
          height: titleHeight,
          width: itemWidth,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isPortrait ? 4 : 6),
            child: Text(
              video['vod_name'],
              style: TextStyle(
                fontSize: isPortrait ? 13 : 12,
                fontWeight: isPortrait ? FontWeight.w500 : FontWeight.normal,
                color: textColor,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
  
  // 构建页面导航器
  Widget _buildPortraitPageNavigator(String typeName) {
    final currentPage = _currentPages[typeName] ?? 1;
    final totalPages = _totalPages[typeName] ?? 1;

    // 如果总页数小于等于1，则不显示分页器
    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }
    
    // 创建页码列表
    List<int> pageNumbers = _generatePageNumbers(currentPage, totalPages);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: pageNumbers.map((pageNum) {
          if (pageNum == -1) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.0),
              child: Text("..."),
            );
          }
          
          final bool isCurrentPage = pageNum == currentPage;

          return GestureDetector(
            onTap: () {
              if (pageNum != currentPage) {
                _onPageChanged(typeName, pageNum);
              }
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isCurrentPage ? const Color(0xFFFF7BB0) : null,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isCurrentPage ? Colors.transparent : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  pageNum.toString(),
                  style: TextStyle(
                    color: isCurrentPage ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  // 构建横屏模式下的页面导航器
  Widget _buildLandscapePageNavigator(String typeName) {
    final currentPage = _currentPages[typeName] ?? 1;
    final totalPages = _totalPages[typeName] ?? 1;

    // 如果总页数小于等于1，则不显示分页器
    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }

    List<int> pageNumbers = _generatePageNumbers(currentPage, totalPages);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: pageNumbers.map((pageNum) {
          if (pageNum == -1) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.0),
              child: Text("...", style: TextStyle(color: Colors.white)),
            );
          }

          final isCurrentPage = pageNum == currentPage;

          return InkWell(
            onTap: () {
              if (pageNum != currentPage) {
                _onPageChanged(typeName, pageNum);
              }
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: isCurrentPage ? const Color(0xFFFF7BB0) : Colors.grey[800],
                border: Border.all(
                  color: isCurrentPage ? Colors.transparent : Colors.grey[700]!,
                ),
                boxShadow: isCurrentPage
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFF7BB0).withAlpha(51),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : [],
              ),
              child: Text(
                pageNum.toString(),
                style: TextStyle(
                  color: isCurrentPage ? Colors.white : Colors.grey[300],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  // 页面改变时的回调
  void _onPageChanged(String typeName, int newPage) {
    setState(() {
      _isLoading = true;
      _currentPages[typeName] = newPage;
    });
    
    // 延迟0.3秒以显示加载动画
    Future.delayed(const Duration(milliseconds: 300), () async {
      if (mounted) {
        try {
          await _fetchCategoryData(typeName, isInitialLoad: false);
        } finally {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      }
    });
  }

  // 生成页码列表
  List<int> _generatePageNumbers(int currentPage, int totalPages) {
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
}
