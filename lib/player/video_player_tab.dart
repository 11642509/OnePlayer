import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import '../app/data_source.dart';
import 'video_player_with_controls.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class SingleVideoTab extends StatefulWidget {
  final bool showBar;
  final VideoPlayConfig playConfig;
  final VoidCallback? onUserInteraction;
  final VoidCallback? onRequestHideBar;
  
  const SingleVideoTab({
    super.key, 
    required this.playConfig,
    this.showBar = true, 
    this.onUserInteraction, 
    this.onRequestHideBar,
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
    return Container(
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
                color: Colors.white.withAlpha(179),
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorOverlay() {
    return Container(
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
                color: Colors.white.withAlpha(179),
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          ElevatedButton(
            onPressed: () {
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
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withAlpha(51),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('重新加载'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }
} 