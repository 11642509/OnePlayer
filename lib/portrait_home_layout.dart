import 'package:flutter/material.dart';
import 'main.dart'; // 导入PlayerType枚举

/// 竖屏主页布局
class PortraitHomeLayout extends StatelessWidget {
  final Function(BuildContext, PlayerType) onPlayerSelected;
  
  const PortraitHomeLayout({
    required this.onPlayerSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 顶部标题
              const Text(
                '选择播放器类型',
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              // VLC播放器按钮
              _buildPlayerButton(
                context: context,
                title: 'VLC 播放器',
                subtitle: '基于LibVLC的强大播放器',
                icon: Icons.play_circle_filled,
                color: Colors.redAccent,
                onPressed: () => onPlayerSelected(context, PlayerType.vlc),
              ),
              const SizedBox(height: 20),
              
              // Short Video播放器按钮
              _buildPlayerButton(
                context: context,
                title: 'Short Video 播放器',
                subtitle: '短视频播放体验',
                icon: Icons.video_library,
                color: Colors.orangeAccent,
                onPressed: () => onPlayerSelected(context, PlayerType.shortVideo),
              ),
              const SizedBox(height: 20),
              
              // Single Tab测试按钮
              _buildPlayerButton(
                context: context,
                title: 'Single Tab 测试',
                subtitle: 'VLC单页面播放器',
                icon: Icons.tab,
                color: Colors.blueAccent,
                onPressed: () => onPlayerSelected(context, PlayerType.singleTab),
              ),
              const SizedBox(height: 20),
              
              // Single Video Tab测试按钮
              _buildPlayerButton(
                context: context,
                title: 'Single Video Tab 测试',
                subtitle: '标准视频播放器',
                icon: Icons.video_file,
                color: Colors.greenAccent,
                onPressed: () => onPlayerSelected(context, PlayerType.singleVideoTab),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(77),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
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
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[600],
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