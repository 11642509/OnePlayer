import 'package:flutter/material.dart';
import 'main.dart'; // 导入PlayerType枚举和windowController实例
import 'main.dart' show PlayerType, windowController;

/// 竖屏主页布局
class PortraitHomeLayout extends StatefulWidget {
  final Function(BuildContext, PlayerType) onPlayerSelected;
  
  const PortraitHomeLayout({
    required this.onPlayerSelected,
    super.key,
  });

  @override
  State<PortraitHomeLayout> createState() => _PortraitHomeLayoutState();
}

class _PortraitHomeLayoutState extends State<PortraitHomeLayout> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['首页', '热门', '频道', '精选', '动态'];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
        });
      }
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 顶部标签栏 - B站/腾讯视频风格
        _buildTopTabBar(),
        
        // 主内容区域 - 使用浅灰色背景
        Expanded(
          child: Container(
            color: const Color(0xFFF6F7F8), // B站内容区域的浅灰色背景
            child: TabBarView(
              controller: _tabController,
              children: [
                // 首页Tab - 显示原来的播放器选择界面
                _buildHomeContent(),
                
                // 其他Tab - 暂时显示空白页面
                _buildPlaceholderContent('热门内容'),
                _buildPlaceholderContent('发现频道'),
                _buildPlaceholderContent('精选内容'),
                _buildPlaceholderContent('我的动态'),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  // 构建顶部标签栏
  Widget _buildTopTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white, // 确保标签栏为白色背景
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFEEEEEE), // 使用更浅的灰色作为分隔线
            width: 0.5, // 更细的线条
          ),
        ),
      ),
      child: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 6, 15, 8),
            child: Row(
              children: [
                // 头像
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.pink.withAlpha(60), width: 2),
                    image: const DecorationImage(
                      image: NetworkImage('https://wpimg.wallstcn.com/f778738c-e4f8-4870-b634-56703b4acafe.gif'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // 搜索框
                Expanded(
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(15),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        Icon(Icons.search, color: Colors.grey[400], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '搜索视频、番剧、UP主',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // 消息图标
                Icon(Icons.notifications_none, color: Colors.grey[500], size: 24),
                
                // 屏幕旋转按钮
                const SizedBox(width: 10),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.screen_lock_rotation, size: 24),
                  color: Colors.grey[500],
                  onPressed: windowController.toggleOrientation,
                ),
              ],
            ),
          ),
          
          // 标签页
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: const Color(0xFFFF7BB0), // B站风格的粉色
            unselectedLabelColor: Colors.grey[600], 
            indicatorColor: const Color(0xFFFF7BB0),
            indicatorSize: TabBarIndicatorSize.label,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
            ),
            tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
          ),
        ],
      ),
    );
  }
  
  // 构建首页内容，即原来的播放器选择界面
  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            
            // 顶部标题
            const Text(
              '选择播放器类型',
              style: TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121), // 调整为B站风格的深灰色
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            // VLC播放器按钮
            _buildPlayerButton(
              context: context,
              title: 'VLC 播放器',
              subtitle: '基于LibVLC的强大播放器',
              icon: Icons.play_circle_filled,
              color: const Color(0xFFFF7BB0), // B站风格粉色
              onPressed: () => widget.onPlayerSelected(context, PlayerType.vlc),
            ),
            const SizedBox(height: 16),
            
            // Short Video播放器按钮
            _buildPlayerButton(
              context: context,
              title: 'Short Video 播放器',
              subtitle: '短视频播放体验',
              icon: Icons.video_library,
              color: const Color(0xFFFF7BB0), // B站风格粉色
              onPressed: () => widget.onPlayerSelected(context, PlayerType.shortVideo),
            ),
            const SizedBox(height: 16),
            
            // Single Tab测试按钮
            _buildPlayerButton(
              context: context,
              title: 'Single Tab 测试',
              subtitle: 'VLC单页面播放器',
              icon: Icons.tab,
              color: const Color(0xFFFF7BB0), // B站风格粉色
              onPressed: () => widget.onPlayerSelected(context, PlayerType.singleTab),
            ),
            const SizedBox(height: 16),
            
            // Single Video Tab测试按钮
            _buildPlayerButton(
              context: context,
              title: 'Single Video Tab 测试',
              subtitle: '标准视频播放器',
              icon: Icons.video_file,
              color: const Color(0xFFFF7BB0), // B站风格粉色
              onPressed: () => widget.onPlayerSelected(context, PlayerType.singleVideoTab),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  // 构建其他标签页的占位内容
  Widget _buildPlaceholderContent(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFF757575), // B站风格中等灰色
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '内容正在开发中...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建播放器选择按钮
  Widget _buildPlayerButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 1, // 轻微的阴影
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Material(
        color: Colors.white, // 确保卡片内部为白色
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 40,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF212121), // B站风格深灰色
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF757575), // B站风格中等灰色
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}