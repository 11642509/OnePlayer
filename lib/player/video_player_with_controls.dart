import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:tapped/tapped.dart';

typedef OnStopRecordingCallback = void Function(String);

class VideoPlayerWithControls extends StatefulWidget {
  final VideoPlayerController controller;
  final bool showControls;
  final bool showBar;
  final VoidCallback? onUserInteraction;
  final VoidCallback? onRequestHideBar;

  const VideoPlayerWithControls({
    required this.controller,
    this.showControls = true,
    this.showBar = true,
    this.onUserInteraction,
    this.onRequestHideBar,
    super.key,
  });

  @override
  VideoPlayerWithControlsState createState() => VideoPlayerWithControlsState();
}

class VideoPlayerWithControlsState extends State<VideoPlayerWithControls> {
  late VideoPlayerController _controller;
  double sliderValue = 0.0;
  String position = '';
  String duration = '';
  bool validPosition = false;
  bool _initialPlay = true;
  bool _userPaused = false;

  // 新增：接收url参数

  Timer? _hideBarTimer;
  Timer? _positionUpdateTimer;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _controller.addListener(listener);
    
    // 添加初始自动隐藏控制栏的计时器
    if (widget.showBar) {
      _hideBarTimer = Timer(const Duration(seconds: 5), () {
        if (widget.onRequestHideBar != null) widget.onRequestHideBar!();
      });
    }
    
    // 添加定时器更新进度
    _positionUpdateTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted && _controller.value.isInitialized) {
        _updatePosition();
      }
    });
  }

  void listener() {
    if (!mounted) return;
    //
    if (_controller.value.isInitialized) {
      _updatePosition();
      
      // 检测视频是否开始播放，如果是首次播放则更新状态
      if (_initialPlay && _controller.value.isPlaying) {
        setState(() {
          _initialPlay = false;
        });
      }
    }
  }
  
  void _updatePosition() {
    final oPosition = _controller.value.position;
    final oDuration = _controller.value.duration;
    if (oDuration.inHours == 0) {
      final strPosition = oPosition.toString().split('.').first;
      final strDuration = oDuration.toString().split('.').first;
      setState(() {
        position =
            "${strPosition.split(':')[1]}:${strPosition.split(':')[2]}";
        duration =
            "${strDuration.split(':')[1]}:${strDuration.split(':')[2]}";
      });
    } else {
      setState(() {
        position = oPosition.toString().split('.').first;
        duration = oDuration.toString().split('.').first;
      });
    }
    setState(() {
      validPosition = oDuration.compareTo(oPosition) >= 0;
      sliderValue = validPosition ? oPosition.inSeconds.toDouble() : 0;
    });
  }

  void _resetHideBarTimer() {
    _hideBarTimer?.cancel();
    if (widget.onUserInteraction != null) widget.onUserInteraction!();
    _hideBarTimer = Timer(const Duration(seconds: 5), () {
      if (widget.onRequestHideBar != null) widget.onRequestHideBar!();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(listener);
    _hideBarTimer?.cancel();
    _positionUpdateTimer?.cancel();
    super.dispose();
  }

  Widget _wrapWithInteraction(Widget child) {
    return Listener(
      onPointerDown: (_) => _resetHideBarTimer(),
      onPointerMove: (_) => _resetHideBarTimer(),
      onPointerUp: (_) => _resetHideBarTimer(),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _wrapWithInteraction(
      Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // 视频区域+点击控制
          GestureDetector(
            onTap: () {
              _resetHideBarTimer();
              // 记录用户暂停状态
              if (_controller.value.isPlaying) {
                _userPaused = true;
              } else {
                _userPaused = false;
              }
              _togglePlaying();
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                ColoredBox(
                  color: Colors.black,
                  child: SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: Builder(
                        builder: (context) {
                          // 获取屏幕方向和尺寸
                          final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
                          final screenWidth = MediaQuery.of(context).size.width;
                          final screenHeight = MediaQuery.of(context).size.height;
                          
                          // 根据屏幕方向设置合适的宽高比
                          final aspectRatio = isLandscape
                              ? screenWidth / screenHeight  // 横屏时使用屏幕宽高比
                              : 16 / 9;  // 竖屏时使用16:9比例
                          
                          return SizedBox(
                            width: screenWidth,
                            height: screenHeight,
                            child: AspectRatio(
                              aspectRatio: aspectRatio,
                              child: VideoPlayer(_controller),
                            ),
                          );
                        }
                      ),
                    ),
                  ),
                ),
                // 暂停时中央大暂停按钮 - 修改条件，只有用户暂停时才显示
                if (_userPaused && !_controller.value.isPlaying)
                  Tapped(
                    onTap: _togglePlaying,
                    child: Container(
                      height: double.infinity,
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.play_circle_outline,
                        size: 120,
                        color: Colors.white.withAlpha(102),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // 底部B站风格控制栏
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedOpacity(
              opacity: widget.showBar ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      color: Colors.white,
                      icon: _controller.value.isPlaying
                          ? const Icon(Icons.pause_rounded, size: 28)
                          : const BiliPlayIcon(size: 28),
                      iconSize: 28,
                      onPressed: () {
                        _resetHideBarTimer();
                        _togglePlaying();
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      position,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Colors.pinkAccent,
                          inactiveTrackColor: Colors.white,
                          thumbColor: Colors.pinkAccent,
                          overlayColor: Colors.pinkAccent.withAlpha(51),
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                        ),
                        child: Slider(
                          value: sliderValue,
                          max: !validPosition
                              ? 1.0
                              : _controller.value.duration.inSeconds.toDouble(),
                          onChanged: validPosition ? _onSliderPositionChanged : null,
                          onChangeEnd: validPosition ? _onSliderChangeEnd : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      duration,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _togglePlaying() async {
    if (_controller.value.isCompleted) {
      await _controller.seekTo(Duration.zero);
      await _controller.play();
      return;
    }
    _controller.value.isPlaying
        ? await _controller.pause()
        : await _controller.play();
  }

  void _onSliderPositionChanged(double progress) {
    setState(() {
      sliderValue = progress.floor().toDouble();
    });
  }

  void _onSliderChangeEnd(double progress) async {
    final seekTo = progress.floor().toDouble();
    if (_controller.value.isCompleted) {
      await _controller.seekTo(Duration.zero);
      await _controller.play();
      await _controller.seekTo(Duration(seconds: seekTo.toInt()));
    } else {
      await _controller.seekTo(Duration(seconds: seekTo.toInt()));
    }
  }
}

class BiliPlayIcon extends StatelessWidget {
  final double size;
  const BiliPlayIcon({this.size = 28, super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _BiliPlayIconPainter(),
    );
  }
}

class _BiliPlayIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    // 画一个更钝角的三角形
    final double w = size.width;
    final double h = size.height;
    final Path path = Path();
    path.moveTo(w * 0.32, h * 0.22); // 左上，往右下偏移更多
    path.lineTo(w * 0.32, h * 0.78); // 左下，往右上偏移更多
    path.lineTo(w * 0.80, h * 0.5);  // 右中
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 