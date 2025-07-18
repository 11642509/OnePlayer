import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:tapped/tapped.dart';
import 'package:oneplayer/core/remote_control/focusable_glow.dart';

typedef OnStopRecordingCallback = void Function(String);

class VideoPlayerWithControls extends StatefulWidget {
  final VideoPlayerController controller;
  final bool showControls;
  final bool showBar;
  final VoidCallback? onUserInteraction;
  final VoidCallback? onRequestHideBar;
  final String? title;

  const VideoPlayerWithControls({
    required this.controller,
    this.showControls = true,
    this.showBar = true,
    this.onUserInteraction,
    this.onRequestHideBar,
    this.title,
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

  // 焦点管理
  final FocusNode _playButtonFocus = FocusNode();
  final FocusNode _sliderFocus = FocusNode();
  final FocusNode _videoAreaFocus = FocusNode();
  final FocusNode _backButtonFocus = FocusNode();
  bool _isSliderFocused = false;

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
    _playButtonFocus.dispose();
    _sliderFocus.dispose();
    _videoAreaFocus.dispose();
    _backButtonFocus.dispose();
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
          Focus(
            focusNode: _videoAreaFocus,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.enter ||
                    event.logicalKey == LogicalKeyboardKey.select) {
                  _resetHideBarTimer();
                  // 记录用户暂停状态
                  if (_controller.value.isPlaying) {
                    _userPaused = true;
                  } else {
                    _userPaused = false;
                  }
                  _togglePlaying();
                  return KeyEventResult.handled;
                } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                  // 下键：显示控制栏并聚焦到播放按钮
                  _resetHideBarTimer();
                  if (!widget.showBar && widget.onUserInteraction != null) {
                    widget.onUserInteraction!();
                    // 延迟一帧后聚焦，确保控制栏已显示
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _playButtonFocus.requestFocus();
                    });
                  } else {
                    _playButtonFocus.requestFocus();
                  }
                  return KeyEventResult.handled;
                } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                  // 上键：显示控制栏并聚焦到返回按钮（如果有标题）
                  _resetHideBarTimer();
                  if (!widget.showBar && widget.onUserInteraction != null) {
                    widget.onUserInteraction!();
                    if (widget.title != null) {
                      // 延迟一帧后聚焦，确保控制栏已显示
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _backButtonFocus.requestFocus();
                      });
                    }
                  } else if (widget.title != null) {
                    _backButtonFocus.requestFocus();
                  }
                  return KeyEventResult.handled;
                } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                  // 左键快退10秒（无论控制栏是否显示）
                  if (_controller.value.isInitialized && validPosition) {
                    final currentPosition = _controller.value.position.inSeconds.toDouble();
                    final newPosition = (currentPosition - 10).clamp(0.0, _controller.value.duration.inSeconds.toDouble());
                    _controller.seekTo(Duration(seconds: newPosition.toInt()));
                    _resetHideBarTimer();
                  }
                  return KeyEventResult.handled;
                } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                  // 右键快进10秒（无论控制栏是否显示）
                  if (_controller.value.isInitialized && validPosition) {
                    final currentPosition = _controller.value.position.inSeconds.toDouble();
                    final newPosition = (currentPosition + 10).clamp(0.0, _controller.value.duration.inSeconds.toDouble());
                    _controller.seekTo(Duration(seconds: newPosition.toInt()));
                    _resetHideBarTimer();
                  }
                  return KeyEventResult.handled;
                } else if (event.logicalKey == LogicalKeyboardKey.escape) {
                  // ESC键退出播放器
                  Navigator.pop(context);
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            child: GestureDetector(
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
                        color: Colors.white.withValues(alpha: 102/255.0),
                      ),
                    ),
                  ),
              ],
            ),
            ),
          ),
          // 新增的顶部标题栏
          if (widget.title != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: widget.showBar ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 153/255.0),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: FocusableGlow(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => Navigator.pop(context),
                          child: Focus(
                            focusNode: _backButtonFocus,
                            onKeyEvent: (node, event) {
                              if (event is KeyDownEvent) {
                                if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                                  // 下键聚焦到视频区域
                                  _videoAreaFocus.requestFocus();
                                  return KeyEventResult.handled;
                                }
                              }
                              return KeyEventResult.ignored;
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.title ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
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
              onEnd: () {
                // 不自动聚焦，等待用户操作
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FocusableGlow(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        _resetHideBarTimer();
                        if (_controller.value.isPlaying) {
                          _userPaused = true;
                        } else {
                          _userPaused = false;
                        }
                        _togglePlaying();
                      },
                      child: Focus(
                        focusNode: _playButtonFocus,
                        onKeyEvent: (node, event) {
                          if (event is KeyDownEvent) {
                            if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                              // 右键聚焦到进度条
                              _sliderFocus.requestFocus();
                              return KeyEventResult.handled;
                            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                              // 上键聚焦回视频区域
                              _videoAreaFocus.requestFocus();
                              return KeyEventResult.handled;
                            }
                          }
                          return KeyEventResult.ignored;
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: _controller.value.isPlaying
                              ? const Icon(Icons.pause_rounded, size: 28, color: Colors.white)
                              : const BiliPlayIcon(size: 28),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      position,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: FocusableGlow(
                        borderRadius: BorderRadius.circular(4),
                        customGlowColor: Colors.pinkAccent,
                        onTap: () {
                          _sliderFocus.requestFocus();
                        },
                        child: Focus(
                          focusNode: _sliderFocus,
                          onFocusChange: (hasFocus) {
                            setState(() {
                              _isSliderFocused = hasFocus;
                            });
                          },
                          onKeyEvent: (node, event) {
                            if (event is KeyDownEvent && validPosition) {
                              final seekAmount = 10.0; // 10秒快进/快退
                              if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                                // 左键快退
                                final newValue = (sliderValue - seekAmount).clamp(
                                  0.0, 
                                  _controller.value.duration.inSeconds.toDouble()
                                );
                                _onSliderPositionChanged(newValue);
                                _onSliderChangeEnd(newValue);
                                return KeyEventResult.handled;
                              } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                                // 右键快进
                                final newValue = (sliderValue + seekAmount).clamp(
                                  0.0, 
                                  _controller.value.duration.inSeconds.toDouble()
                                );
                                _onSliderPositionChanged(newValue);
                                _onSliderChangeEnd(newValue);
                                return KeyEventResult.handled;
                              } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                                // 上键聚焦回视频区域
                                _videoAreaFocus.requestFocus();
                                return KeyEventResult.handled;
                              }
                            }
                            if (event is KeyDownEvent && 
                                event.logicalKey == LogicalKeyboardKey.arrowLeft &&
                                !validPosition) {
                              // 进度条不可用时，左键聚焦回播放按钮
                              _playButtonFocus.requestFocus();
                              return KeyEventResult.handled;
                            }
                            return KeyEventResult.ignored;
                          },
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: _isSliderFocused ? Colors.pink : Colors.pinkAccent,
                              inactiveTrackColor: Colors.white.withValues(alpha: _isSliderFocused ? 0.5 : 0.3),
                              thumbColor: _isSliderFocused ? Colors.pink : Colors.pinkAccent,
                              overlayColor: Colors.pinkAccent.withValues(alpha: 51/255.0),
                              trackHeight: _isSliderFocused ? 4 : 2,
                              thumbShape: RoundSliderThumbShape(
                                enabledThumbRadius: _isSliderFocused ? 8 : 4
                              ),
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