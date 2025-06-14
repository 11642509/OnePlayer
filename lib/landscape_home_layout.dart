import 'package:flutter/material.dart';
import 'app/app.dart' as app; // 使用前缀导入以避免命名冲突
import 'main.dart' show PlayerType, windowController; // 引入PlayerType枚举和windowController实例

/// 横屏主页布局
class LandscapeHomeLayout extends StatefulWidget {
  final Function(BuildContext, PlayerType) onPlayerSelected;
  
  const LandscapeHomeLayout({
    required this.onPlayerSelected,
    super.key,
  });

  @override
  State<LandscapeHomeLayout> createState() => _LandscapeHomeLayoutState();
}

class _LandscapeHomeLayoutState extends State<LandscapeHomeLayout> {
  String _currentTab = '热门'; // 默认选中热门页面
  final _navBarKey = GlobalKey<app.NavigationBarState>();

  void _handleTabChanged(String tab) {
    setState(() => _currentTab = tab);
  }

  @override
  Widget build(BuildContext context) {
    // 计算导航栏的估计高度（根据app.dart中的设置）
    final navBarHeight = 46.0; // 标签栏估计高度
    final navBarOffset = navBarHeight / 3; // 下移标签栏高度的1/3

    return Stack(
      children: [
        // 导航栏 - 从屏幕顶部下移1/3的导航栏高度
        Positioned(
          top: navBarOffset, // 下移1/3导航栏高度
          left: 0,
          right: 0,
          child: app.NavigationBar(
            key: _navBarKey,
            currentTab: _currentTab,
            onTabChanged: _handleTabChanged,
          ),
        ),
        
        // 横竖屏切换按钮 - 右上角，与导航栏对齐
        Positioned(
          top: navBarOffset + 5, // 下移1/3导航栏高度后再加5像素的偏移
          right: 10,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(100),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.screen_lock_portrait),
              tooltip: '切换为竖屏',
              onPressed: () => windowController.toggleOrientation(),
              color: Colors.white,
            ),
          ),
        ),
        
        // 主内容区域 - 直接调整内部Row的margin
        Row(
          children: [
            // 左侧信息区域
            Expanded(
              flex: 2,
              child: Container(
                margin: EdgeInsets.only(
                  left: 24.0, 
                  right: 12.0,
                  top: navBarHeight + navBarOffset + 14.0, // 导航栏高度 + 偏移 + 额外空间
                  bottom: 16.0
                ),
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.grey[900]?.withAlpha(179),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withAlpha(77), width: 1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'OnePlayer',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withAlpha(77),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _currentTab,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '多功能视频播放器',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.blue[300],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '支持多种播放引擎，包括VLC和标准播放器。\n可以播放本地和网络视频，支持多种格式。',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[300], size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          '选择右侧播放器类型开始体验',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // 右侧播放器选择区域
            Expanded(
              flex: 3,
              child: Container(
                margin: EdgeInsets.only(
                  left: 12.0, 
                  right: 24.0,
                  top: navBarHeight + navBarOffset + 14.0, // 导航栏高度 + 偏移 + 额外空间
                  bottom: 16.0
                ),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    // VLC播放器卡片
                    _buildPlayerCard(
                      title: 'VLC 播放器',
                      icon: Icons.play_circle_filled,
                      color: Colors.redAccent,
                      onTap: () => widget.onPlayerSelected(context, PlayerType.vlc),
                    ),
                    
                    // Short Video播放器卡片
                    _buildPlayerCard(
                      title: 'Short Video 播放器',
                      icon: Icons.video_library,
                      color: Colors.orangeAccent,
                      onTap: () => widget.onPlayerSelected(context, PlayerType.shortVideo),
                    ),
                    
                    // Single Tab测试卡片
                    _buildPlayerCard(
                      title: 'Single Tab 测试',
                      icon: Icons.tab,
                      color: Colors.blueAccent,
                      onTap: () => widget.onPlayerSelected(context, PlayerType.singleTab),
                    ),
                    
                    // Single Video Tab测试卡片
                    _buildPlayerCard(
                      title: 'Single Video Tab 测试',
                      icon: Icons.video_file,
                      color: Colors.greenAccent,
                      onTap: () => widget.onPlayerSelected(context, PlayerType.singleVideoTab),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  /// 构建播放器卡片
  Widget _buildPlayerCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(51),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withAlpha(51),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '点击进入',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 