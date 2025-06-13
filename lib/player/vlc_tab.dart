import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'vlc_player_with_controls.dart';

class SingleTab extends StatefulWidget {
  final bool showBar;
  final VoidCallback? onUserInteraction;
  final VoidCallback? onRequestHideBar;
  const SingleTab({super.key, this.showBar = true, this.onUserInteraction, this.onRequestHideBar});

  @override
  SingleTabState createState() => SingleTabState();
}

class SingleTabState extends State<SingleTab> with WidgetsBindingObserver {
  static const _networkCachingMs = 2000;
  static const _subtitlesFontSize = 30;

  final _key = GlobalKey<VlcPlayerWithControlsState>();
  late final VlcPlayerController _controller;
  late final String _videoUrl;

  @override
  void initState() {
    super.initState();
    // 添加观察者以监听设备方向变化
    WidgetsBinding.instance.addObserver(this);
    // 保存视频url
    _videoUrl = 'https://static.ybhospital.net/test-video-10.MP4';
    // 默认播放第一个网络视频
    _controller = VlcPlayerController.network(
      _videoUrl,
      hwAcc: HwAcc.full,
      options: VlcPlayerOptions(
        advanced: VlcAdvancedOptions([
          VlcAdvancedOptions.networkCaching(_networkCachingMs),
        ]),
        subtitle: VlcSubtitleOptions([
          VlcSubtitleOptions.boldStyle(true),
          VlcSubtitleOptions.fontSize(_subtitlesFontSize),
          VlcSubtitleOptions.outlineColor(VlcSubtitleColor.yellow),
          VlcSubtitleOptions.outlineThickness(VlcSubtitleThickness.normal),
          VlcSubtitleOptions.color(VlcSubtitleColor.navy),
        ]),
        http: VlcHttpOptions([
          VlcHttpOptions.httpReconnect(true),
        ]),
        rtp: VlcRtpOptions([
          VlcRtpOptions.rtpOverRtsp(true),
        ]),
      ),
    );
    _controller.addOnInitListener(() async {
      await _controller.startRendererScanning();
      
      // 控制器初始化完成后，触发一次用户交互回调
      if (widget.onUserInteraction != null) {
        widget.onUserInteraction!();
      }
    });
    _controller.addOnRendererEventListener((type, id, name) {
      if (!kReleaseMode) {
        debugPrint('OnRendererEventListener $type $id $name');
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
      child: VlcPlayerWithControls(
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
    _controller.stopRecording();
    _controller.stopRendererScanning();
    _controller.dispose();
    super.dispose();
  }
}
