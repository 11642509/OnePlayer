import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../../../app/data_source.dart';
import '../pages/video_player_with_controls_page.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../../core/remote_control/focusable_glow.dart';

class SingleVideoTab extends StatefulWidget {
  final bool showBar;
  final VideoPlayConfig playConfig;
  final VoidCallback? onUserInteraction;
  final VoidCallback? onRequestHideBar;
  final String? title;
  
  const SingleVideoTab({
    super.key, 
    required this.playConfig,
    this.showBar = true, 
    this.onUserInteraction, 
    this.onRequestHideBar,
    this.title,
  });

  @override
  SingleVideoTabState createState() => SingleVideoTabState();
}

class SingleVideoTabState extends State<SingleVideoTab> with WidgetsBindingObserver {
  final _key = GlobalKey<VideoPlayerWithControlsState>();
  late final VideoPlayerController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  
  // 焦点管理
  final FocusNode _backButtonFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    if (kDebugMode) {
      print('=== VideoPlayer播放器配置 ===');
      print('URL: ${widget.playConfig.url}');
      print('Format: ${widget.playConfig.format}');
      print('User-Agent: ${widget.playConfig.userAgent}');
      print('Referer: ${widget.playConfig.referer}');
      print('Headers Map:');
      widget.playConfig.headers.forEach((key, value) {
        if (kDebugMode) {
          print('  $key: $value');
        }
      });
      print('========================');
    }
    
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.playConfig.url),
      httpHeaders: widget.playConfig.headers,
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: false,
        allowBackgroundPlayback: false,
      ),
    );
    
    _controller.initialize().then((_) {
      _controller.setVolume(1);
      
      _controller.play();
      
      if (widget.onUserInteraction != null && mounted) {
        widget.onUserInteraction!();
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = '视频加载失败: ${error.toString()}';
        });
      }
      if (kDebugMode) {
        print('视频加载失败: $error');
      }
    });
  }
  
  @override
  void didChangeMetrics() {
    if (mounted) {
      setState(() {
        // 触发重建以适应新的屏幕方向
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox.expand(
          child: VideoPlayerWithControls(
            key: _key,
            controller: _controller,
            showBar: widget.showBar,
            onUserInteraction: widget.onUserInteraction,
            onRequestHideBar: widget.onRequestHideBar,
            title: widget.title,
          ),
        ),
        
        if (_isLoading)
          _buildLoadingOverlay(),
          
        if (_hasError)
          _buildErrorOverlay(),
      ],
    );
  }
  
  Widget _buildLoadingOverlay() {
    return Focus(
      autofocus: true, // 加载界面自动获取焦点以响应按键
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          // 任意按键都将焦点转移到返回按钮
          _backButtonFocus.requestFocus();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Colors.blue,
              Colors.green,
            ],
          ),
        ),
        child: Stack(
        children: [
          // 标题栏
          if (widget.title != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
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
                              if (event.logicalKey == LogicalKeyboardKey.escape) {
                                Navigator.pop(context);
                                return KeyEventResult.handled;
                              } else if (event.logicalKey == LogicalKeyboardKey.enter ||
                                         event.logicalKey == LogicalKeyboardKey.select) {
                                Navigator.pop(context);
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
          // 加载动画
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const SpinKitWave(
                  size: 36,
                  color: Colors.white70,
                ),
                Container(
                  padding: const EdgeInsets.all(50),
                  child: Text(
                    '视频加载中...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 179/255.0),
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
  
  Widget _buildErrorOverlay() {
    return Focus(
      autofocus: true, // 错误界面自动获取焦点以响应按键
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          // 任意按键都执行重新加载
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.space) {
            _retry();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.pop(context);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Colors.red,
              Colors.orange,
            ],
          ),
        ),
        child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(
            Icons.error_outline,
            color: Colors.white,
            size: 60,
          ),
          Container(
            padding: const EdgeInsets.all(50),
            child: Text(
              _errorMessage,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 179/255.0),
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          FocusableGlow(
            borderRadius: BorderRadius.circular(8),
            onTap: _retry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 51/255.0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('重新加载', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
        ),
      ),
    );
  }

  void _retry() {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    
    _controller.initialize().then((_) {
      _controller.setVolume(1);
      _controller.play();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = '视频加载失败: ${error.toString()}';
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _backButtonFocus.dispose();
    super.dispose();
  }
} 