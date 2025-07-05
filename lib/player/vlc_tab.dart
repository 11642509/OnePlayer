import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import '../app/data_source.dart';
import 'vlc_player_with_controls.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class SingleTabPage extends StatefulWidget {
  final VideoPlayConfig playConfig;
  final String title;

  const SingleTabPage({
    super.key,
    required this.playConfig,
    required this.title,
  });

  @override
  State<SingleTabPage> createState() => _SingleTabPageState();
}

class _SingleTabPageState extends State<SingleTabPage> with WidgetsBindingObserver {
  late final VlcPlayerController _controller;
  bool showBar = true;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _initializeController();
  }
  
  void _initializeController() {
    try {
      // 创建VLC控制器选项
      final List<String> httpOptions = [];
      
      // 添加User-Agent
      if (widget.playConfig.userAgent != null) {
        httpOptions.add('--http-user-agent=${widget.playConfig.userAgent}');
      }
      
      // 添加Referer
      if (widget.playConfig.referer != null) {
        httpOptions.add('--http-referrer=${widget.playConfig.referer}');
      }
      
      // 创建VLC控制器
      _controller = VlcPlayerController.network(
        widget.playConfig.url,
        hwAcc: HwAcc.full,
        options: VlcPlayerOptions(
          advanced: VlcAdvancedOptions([
            '--network-caching=2000',
          ]),
          http: VlcHttpOptions(httpOptions),
          video: VlcVideoOptions([
            '--video-track=1',
          ]),
        ),
      );
      
      // 监听初始化完成事件
      _controller.addOnInitListener(() async {
        if (kDebugMode) {
          print('VLC播放器初始化完成');
        }
        
        // 设置音量为100%
        await _controller.setVolume(100);
        
        // 开始播放
        await _controller.play();
        
        // 标记加载完成
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
      
      // 监听播放状态变化
      _controller.addListener(() {
        // 检测播放错误
        if (_controller.value.hasError && mounted && !_hasError) {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = '视频播放出错';
          });
          if (kDebugMode) {
            print('VLC播放器状态错误');
          }
        }
      });
      
      // 初始化VLC控制器
      _controller.initialize();
    } catch (e) {
      if (kDebugMode) {
        print('VLC播放器初始化失败: $e');
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = '视频加载失败: ${e.toString()}';
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  void showBars() {
    if (!showBar) setState(() => showBar = true);
  }

  void hideBars() {
    if (showBar) setState(() => showBar = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox.expand(
          child: VlcPlayerWithControls(
            controller: _controller,
            showBar: showBar,
            onUserInteraction: showBars,
            onRequestHideBar: hideBars,
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
              
              _controller.dispose();
              _initializeController();
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
}
