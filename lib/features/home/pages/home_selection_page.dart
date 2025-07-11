import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../shared/models/home_content.dart';
import '../../../main.dart' show PlayerType;
import '../../../shared/controllers/window_controller.dart';

class HomeSelection extends StatefulWidget {
  final Function(BuildContext, PlayerType)? onPlayerSelected;
  
  const HomeSelection({
    super.key,
    this.onPlayerSelected,
  });

  @override
  State<HomeSelection> createState() => _HomeSelectionState();
}

class _HomeSelectionState extends State<HomeSelection> {
  final Map<String, dynamic> _homeData = HomeContent.getMockData();

  // 打开播放器页面
  void _openPlayerPage(BuildContext context, PlayerType type) {
    if (widget.onPlayerSelected != null) {
      widget.onPlayerSelected!(context, type);
    } else {
      // 如果找不到回调，显示提示信息
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法打开播放器，请检查配置')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final windowController = Get.find<WindowController>();
      // 根据窗口方向选择不同的内容布局
      final isPortrait = windowController.isPortrait.value;
      
      if (isPortrait) {
        // 竖屏模式
        return _buildPortraitContent();
      } else {
        // 横屏模式
        return _buildLandscapeContent();
      }
    });
  }
  
  // 横屏内容
  Widget _buildLandscapeContent() {
    final classList = _homeData['class'] as List;

    return Container(
      padding: EdgeInsets.only(
        top: 10, // 减少顶部内边距
      ),
      child: Row(
        children: [
          // 左侧信息区域
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(20.0), // 减少内边距
              height: double.infinity, // 设置高度为无限
              decoration: BoxDecoration(
                color: Colors.grey[900]?.withAlpha(179),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.withAlpha(77), width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max, // 设置为最大
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'OnePlayer',
                        style: TextStyle(
                          fontSize: 28, // 减小字体大小
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
                          classList[0]['type_name'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6), // 减少间距
                  Text(
                    '多功能视频播放器',
                    style: TextStyle(
                      fontSize: 16, // 减小字体大小
                      color: Colors.blue[300],
                    ),
                  ),
                  const SizedBox(height: 16), // 减少间距
                  const Text(
                    '支持多种播放引擎，包括VLC和标准播放器。\n可以播放本地和网络视频，支持多种格式。',
                    style: TextStyle(
                      fontSize: 14, // 减小字体大小
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[300], size: 18), // 减小图标大小
                      const SizedBox(width: 6), // 减少间距
                      const Text(
                        '选择右侧播放器类型开始体验',
                        style: TextStyle(
                          fontSize: 12, // 减小字体大小
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
              margin: const EdgeInsets.all(16.0),
              height: double.infinity, // 设置高度为无限
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
                    onTap: () => _openPlayerPage(context, PlayerType.vlc),
                  ),
                  
                  // Short Video播放器卡片
                  _buildPlayerCard(
                    title: 'Short Video 播放器',
                    icon: Icons.video_library,
                    color: Colors.orangeAccent,
                    onTap: () => _openPlayerPage(context, PlayerType.shortVideo),
                  ),
                  
                  // Single Tab测试卡片
                  _buildPlayerCard(
                    title: 'Single Tab 测试',
                    icon: Icons.tab,
                    color: Colors.blueAccent,
                    onTap: () => _openPlayerPage(context, PlayerType.singleTab),
                  ),
                  
                  // Single Video Tab测试卡片
                  _buildPlayerCard(
                    title: 'Single Video Tab 测试',
                    icon: Icons.video_file,
                    color: Colors.greenAccent,
                    onTap: () => _openPlayerPage(context, PlayerType.singleVideoTab),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 竖屏内容
  Widget _buildPortraitContent() {
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
              onPressed: () {
                if (widget.onPlayerSelected != null) {
                  widget.onPlayerSelected!(context, PlayerType.vlc);
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Short Video播放器按钮
            _buildPlayerButton(
              context: context,
              title: 'Short Video 播放器',
              subtitle: '短视频播放体验',
              icon: Icons.video_library,
              color: const Color(0xFFFF7BB0), // B站风格粉色
              onPressed: () {
                if (widget.onPlayerSelected != null) {
                  widget.onPlayerSelected!(context, PlayerType.shortVideo);
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Single Tab测试按钮
            _buildPlayerButton(
              context: context,
              title: 'Single Tab 测试',
              subtitle: 'VLC单页面播放器',
              icon: Icons.tab,
              color: const Color(0xFFFF7BB0), // B站风格粉色
              onPressed: () {
                if (widget.onPlayerSelected != null) {
                  widget.onPlayerSelected!(context, PlayerType.singleTab);
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Single Video Tab测试按钮
            _buildPlayerButton(
              context: context,
              title: 'Single Video Tab 测试',
              subtitle: '标准视频播放器',
              icon: Icons.video_file,
              color: const Color(0xFFFF7BB0), // B站风格粉色
              onPressed: () {
                if (widget.onPlayerSelected != null) {
                  widget.onPlayerSelected!(context, PlayerType.singleVideoTab);
                }
              },
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
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

// 竖屏内容组件
class PortraitHomeContent extends StatefulWidget {
  final int tabIndex;
  final Function(BuildContext, PlayerType)? onPlayerSelected;
  
  const PortraitHomeContent({
    super.key,
    required this.tabIndex,
    this.onPlayerSelected,
  });
  
  @override
  State<PortraitHomeContent> createState() => _PortraitHomeContentState();
}

class _PortraitHomeContentState extends State<PortraitHomeContent> {
  @override
  Widget build(BuildContext context) {
    // 根据标签索引返回不同的内容
    switch (widget.tabIndex) {
      case 0: // 首页
        return _buildHomeContent();
      case 1: // 热门
        return _buildPlaceholderContent('热门内容');
      case 2: // 频道
        return _buildPlaceholderContent('发现频道');
      case 3: // 精选
        return _buildPlaceholderContent('精选内容');
      case 4: // 动态
        return _buildPlaceholderContent('我的动态');
      default:
        return _buildPlaceholderContent('未知页面');
    }
  }
  
  // 构建首页内容
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
              onPressed: () {
                if (widget.onPlayerSelected != null) {
                  widget.onPlayerSelected!(context, PlayerType.vlc);
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Short Video播放器按钮
            _buildPlayerButton(
              context: context,
              title: 'Short Video 播放器',
              subtitle: '短视频播放体验',
              icon: Icons.video_library,
              color: const Color(0xFFFF7BB0), // B站风格粉色
              onPressed: () {
                if (widget.onPlayerSelected != null) {
                  widget.onPlayerSelected!(context, PlayerType.shortVideo);
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Single Tab测试按钮
            _buildPlayerButton(
              context: context,
              title: 'Single Tab 测试',
              subtitle: 'VLC单页面播放器',
              icon: Icons.tab,
              color: const Color(0xFFFF7BB0), // B站风格粉色
              onPressed: () {
                if (widget.onPlayerSelected != null) {
                  widget.onPlayerSelected!(context, PlayerType.singleTab);
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Single Video Tab测试按钮
            _buildPlayerButton(
              context: context,
              title: 'Single Video Tab 测试',
              subtitle: '标准视频播放器',
              icon: Icons.video_file,
              color: const Color(0xFFFF7BB0), // B站风格粉色
              onPressed: () {
                if (widget.onPlayerSelected != null) {
                  widget.onPlayerSelected!(context, PlayerType.singleVideoTab);
                }
              },
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