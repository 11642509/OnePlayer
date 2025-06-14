import 'package:flutter/material.dart';
import 'main.dart'; // 导入PlayerType枚举

/// 横屏主页布局
class LandscapeHomeLayout extends StatelessWidget {
  final Function(BuildContext, PlayerType) onPlayerSelected;
  
  const LandscapeHomeLayout({
    required this.onPlayerSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        children: [
          // 左侧信息区域
          Expanded(
            flex: 2,
            child: Container(
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
                  const Text(
                    'OnePlayer',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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
          
          const SizedBox(width: 24),
          
          // 右侧播放器选择区域
          Expanded(
            flex: 3,
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
                  onTap: () => onPlayerSelected(context, PlayerType.vlc),
                ),
                
                // Short Video播放器卡片
                _buildPlayerCard(
                  title: 'Short Video 播放器',
                  icon: Icons.video_library,
                  color: Colors.orangeAccent,
                  onTap: () => onPlayerSelected(context, PlayerType.shortVideo),
                ),
                
                // Single Tab测试卡片
                _buildPlayerCard(
                  title: 'Single Tab 测试',
                  icon: Icons.tab,
                  color: Colors.blueAccent,
                  onTap: () => onPlayerSelected(context, PlayerType.singleTab),
                ),
                
                // Single Video Tab测试卡片
                _buildPlayerCard(
                  title: 'Single Video Tab 测试',
                  icon: Icons.video_file,
                  color: Colors.greenAccent,
                  onTap: () => onPlayerSelected(context, PlayerType.singleVideoTab),
                ),
              ],
            ),
          ),
        ],
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
} 