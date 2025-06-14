import 'package:flutter/material.dart';
import '../mock/home_content.dart';
import '../mock/category_content.dart'; // 导入分类内容数据
import '../window_controller.dart'; // 导入窗口控制器

class VodPage extends StatefulWidget {
  const VodPage({super.key});

  @override
  State<VodPage> createState() => _VodPageState();
}

class _VodPageState extends State<VodPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, dynamic> _homeData = HomeContent.getMockData();
// 当前选中的分类ID
  bool _isLoading = false;
  
  // 添加主页分类
  final Map<String, dynamic> _homeCategory = {"type_id": "0", "type_name": "主页"};
  

  
  @override
  void initState() {
    super.initState();
    // 获取分类列表并在前面添加"主页"分类
    final classList = [_homeCategory, ...(_homeData['class'] as List)];
    _tabController = TabController(length: classList.length, vsync: this);
    
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
    // 获取分类列表并在前面添加"主页"分类
    final classList = [_homeCategory, ...(_homeData['class'] as List)];
    
    // 获取窗口控制器实例
    final windowController = WindowController();
    // 根据窗口方向设置背景色：横屏黑色，竖屏浅灰色(与PortraitHomeLayout一致)
    final backgroundColor = !windowController.isPortrait.value 
        ? Colors.black 
        : const Color(0xFFF6F7F8); // 与PortraitHomeLayout一致的浅灰色背景
    
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
            tabs: classList.map((item) {
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
        children: classList.map((category) {
          final typeId = category['type_id'] as String;
          
          // 如果是主页，使用HomeContent的数据
          if (typeId == "0") {
            return _buildVideoGridPage(_homeData['list'] as List);
          } else {
            // 其他分类使用CategoryContent的数据
            return FutureBuilder(
              // 使用Future.microtask模拟网络请求
              future: Future.microtask(() => CategoryContent.getMockData(typeId)),
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
                
                final data = snapshot.data as Map<String, dynamic>;
                final videoList = data['list'] as List;
                return _buildVideoGridPage(videoList);
              },
            );
          }
        }).toList(),
      ),
    );
  }
  
  // 构建视频网格页面
  Widget _buildVideoGridPage(List videoList) {
    return RefreshIndicator(
      color: const Color(0xFFFF7BB0),
      backgroundColor: Colors.grey[900],
      onRefresh: () async {
        // 模拟刷新
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          setState(() {});
        }
      },
      child: _buildVideoGrid(videoList),
    );
  }
  
  // 构建视频网格
  Widget _buildVideoGrid(List videoList) {
    // 获取窗口控制器实例
    final windowController = WindowController();
    // 根据窗口方向设置网格布局
    final isPortrait = windowController.isPortrait.value;
    
    return GridView.builder(
      padding: EdgeInsets.all(isPortrait ? 16 : 20), // 竖屏模式下减小内边距
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isPortrait ? 2 : 4, // 竖屏模式下每行2个，横屏模式下每行4个
        childAspectRatio: isPortrait ? 0.58 : 0.65, // 竖屏模式下调整宽高比例
        crossAxisSpacing: isPortrait ? 12 : 24, // 竖屏模式下减小水平间距
        mainAxisSpacing: isPortrait ? 16 : 30, // 竖屏模式下减小垂直间距
      ),
      itemCount: videoList.length,
      itemBuilder: (context, index) {
        final video = videoList[index];
        return _buildVideoCard(video, index);
      },
    );
  }
  
  // 构建视频卡片
  Widget _buildVideoCard(dynamic video, int index) {
    // 获取窗口控制器实例
    final windowController = WindowController();
    // 根据窗口方向设置文本颜色
    final textColor = !windowController.isPortrait.value ? Colors.white : Colors.black;
    final isPortrait = windowController.isPortrait.value;
    
    return InkWell(
      onTap: () {
        // 点击视频项的处理逻辑
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('即将播放: ${video['vod_name']}'),
            backgroundColor: const Color(0xFFFF7BB0),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      borderRadius: BorderRadius.circular(isPortrait ? 10 : 8), // 竖屏模式下增大圆角
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 视频封面部分（占据大部分空间）
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isPortrait ? 10 : 8), // 竖屏模式下增大圆角
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isPortrait ? 10 : 8), // 竖屏模式下增大圆角
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 封面图
                    Image.network(
                      video['vod_pic'] as String,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[800],
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.white54,
                              size: 30,
                            ),
                          ),
                        );
                      },
                    ),
                    
                    // 序号标签 - 左上角 (仅显示前10个)
                    if (index < 10)
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          width: isPortrait ? 32 : 28, // 竖屏模式下增大尺寸
                          height: isPortrait ? 32 : 28, // 竖屏模式下增大尺寸
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _getRankingColor(index),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(isPortrait ? 10 : 8), // 竖屏模式下增大圆角
                              bottomRight: Radius.circular(isPortrait ? 10 : 8), // 竖屏模式下增大圆角
                            ),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: isPortrait ? 16 : 14, // 竖屏模式下增大字体
                            ),
                          ),
                        ),
                      ),
                    
                    // 更新信息 - 右下角
                    if (video['vod_remarks'] != null)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        left: 0,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isPortrait ? 10 : 8, 
                            vertical: isPortrait ? 5 : 4
                          ), // 竖屏模式下增大内边距
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5), // 降低不透明度，使背景更透明
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(isPortrait ? 10 : 8), // 竖屏模式下增大圆角
                              bottomRight: Radius.circular(isPortrait ? 10 : 8), // 竖屏模式下增大圆角
                            ),
                          ),
                          child: Text(
                            video['vod_remarks'],
                            style: TextStyle(
                              fontSize: isPortrait ? 12 : 10, // 竖屏模式下增大字体
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          
          // 视频标题 - 图片下方
          Padding(
            padding: EdgeInsets.only(
              top: isPortrait ? 10 : 8, 
              left: isPortrait ? 3 : 2
            ), // 竖屏模式下增大内边距
            child: Text(
              video['vod_name'] as String,
              style: TextStyle(
                fontSize: isPortrait ? 18 : 16, // 竖屏模式下增大字体
                color: textColor,
                fontWeight: FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
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
}
