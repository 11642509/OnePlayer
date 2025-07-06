import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import '../app/data_source.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'vlc_player_with_controls.dart'; // 引用新的带控件的播放器

class VlcTab extends StatefulWidget {
  final VideoPlayConfig playConfig;
  final String title;

  const VlcTab({
    super.key,
    required this.playConfig,
    required this.title,
  });

  @override
  State<VlcTab> createState() => _VlcTabState();
}

class _VlcTabState extends State<VlcTab> {
  late VlcPlayerController _controller;
  bool _showControls = true;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _controller = VlcPlayerController.network(
      widget.playConfig.url,
      hwAcc: HwAcc.full,
      autoPlay: true,
      options: VlcPlayerOptions(
        advanced: VlcAdvancedOptions([
          VlcAdvancedOptions.fileCaching(500),
          VlcAdvancedOptions.networkCaching(500),
          VlcAdvancedOptions.liveCaching(500),
          VlcAdvancedOptions.clockJitter(0),
          ':verbose=2',
        ]),
        http: VlcHttpOptions([
          VlcHttpOptions.httpReconnect(true),
          if (widget.playConfig.userAgent != null && widget.playConfig.userAgent!.isNotEmpty)
            ':http-user-agent=${widget.playConfig.userAgent}',
          if (widget.playConfig.referer != null && widget.playConfig.referer!.isNotEmpty)
            VlcHttpOptions.httpReferrer(widget.playConfig.referer!),
        ]),
        extras: [
          ':avcodec-hw=mediacodec',
          ':avcodec-threads=4',
          ':avcodec-fast',
          ':avcodec-skiploopfilter=0'
        ],
      ),
    );
    _controller.addListener(_errorListener);
    // 调用新的等待逻辑
    await _waitForPlaying();
  }
  
  // 新增：等待视频真正开始播放
  Future<void> _waitForPlaying() async {
    final startTime = DateTime.now();
    final completer = Completer<void>();

    void listener() {
      if (!mounted) return;
      if (_controller.value.isPlaying && !_controller.value.isBuffering) {
        // 确保监听到isPlaying后移除监听器，避免不必要的调用
        _controller.removeListener(listener);
        if (!completer.isCompleted) {
          if (kDebugMode) {
            print('VLC 正在播放的真实URL: ${_controller.dataSource}');
          }
          completer.complete();
        }
      }
    }
    
    _controller.addListener(listener);
    
    // 设置超时，以防视频永远无法播放
    try {
      await completer.future.timeout(const Duration(seconds: 15));
    } catch (e) {
      if (mounted && !completer.isCompleted) {
        _controller.removeListener(listener);
        setState(() {
          _hasError = true;
          _errorMessage = '视频加载超时';
          _isLoading = false;
        });
        return;
      }
    }

    // 确保加载动画至少显示一段时间
    final elapsed = DateTime.now().difference(startTime);
    if (elapsed < const Duration(milliseconds: 600)) {
      await Future.delayed(const Duration(milliseconds: 600) - elapsed);
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _errorListener() {
    if (!mounted) return;
    if (_controller.value.hasError && !_hasError) {
      setState(() {
        _hasError = true;
        _errorMessage = _controller.value.errorDescription;
        _isLoading = false; // 发生错误时停止加载
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_errorListener);
    _controller.dispose();
    super.dispose();
  }
  
  void _retry() {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });
    // 重新初始化播放器
    _controller.removeListener(_errorListener);
    _controller.dispose().then((_) {
      _initializePlayer();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        VlcPlayerWithControls(
          controller: _controller,
          title: widget.title,
          showControls: _showControls,
          showBar: _showControls,
          onUserInteraction: () {
            if (!_showControls) setState(() => _showControls = true);
          },
          onRequestHideBar: () {
            if (_showControls) setState(() => _showControls = false);
          },
        ),
        if (_isLoading) _buildLoadingOverlay(),
        if (_hasError) _buildErrorOverlay(),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Colors.blue, Colors.green],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const SpinKitWave(size: 36, color: Colors.white70),
          Container(
            padding: const EdgeInsets.all(50),
            child: const Text(
              '视频加载中...',
              style: TextStyle(
                color: Color.fromARGB(179, 255, 255, 255),
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
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Colors.red, Colors.orange],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.error_outline, color: Colors.white, size: 60),
          Container(
            padding: const EdgeInsets.all(50),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color.fromARGB(179, 255, 255, 255),
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _retry,
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
