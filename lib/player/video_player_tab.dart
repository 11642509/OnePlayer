import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'video_player_with_controls.dart';

class SingleVideoTab extends StatefulWidget {
  final bool showBar;
  final VoidCallback? onUserInteraction;
  final VoidCallback? onRequestHideBar;
  const SingleVideoTab({super.key, this.showBar = true, this.onUserInteraction, this.onRequestHideBar});

  @override
  SingleVideoTabState createState() => SingleVideoTabState();
}

class SingleVideoTabState extends State<SingleVideoTab> with WidgetsBindingObserver {
  final _key = GlobalKey<VideoPlayerWithControlsState>();
  late final VideoPlayerController _controller;
  late final String _videoUrl;

  @override
  void initState() {
    super.initState();
    // 添加观察者以监听设备方向变化
    WidgetsBinding.instance.addObserver(this);
    // 保存视频url
    _videoUrl = 'https://static.ybhospital.net/test-video-10.MP4';
    // 默认播放第一个网络视频
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(_videoUrl),
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: false,
        allowBackgroundPlayback: false,
      ),
    );
    
    // 初始化控制器
    _controller.initialize().then((_) {
      // 设置默认音量为100%
      _controller.setVolume(1);
      
      // 开始播放
      _controller.play();
      
      // 控制器初始化完成后，触发一次用户交互回调
      if (widget.onUserInteraction != null && mounted) {
        widget.onUserInteraction!();
      }
      
      // 更新UI
      if (mounted) {
        setState(() {});
      }
    });
  }
  
  @override
  void didChangeMetrics() {
    // 当设备尺寸、方向等变化时调用
    if (mounted) {
      setState(() {
        // 触发重建以适应新的屏幕方向
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: VideoPlayerWithControls(
        key: _key,
        controller: _controller,
        showBar: widget.showBar,
        onUserInteraction: widget.onUserInteraction,
        onRequestHideBar: widget.onRequestHideBar,
      ),
    );
  }

  @override
  void dispose() {
    // 移除观察者
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }
} 