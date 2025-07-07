import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../app/data_source.dart';
import 'vlc_tab.dart';

class VlcPlayerPage extends StatefulWidget {
  final VideoPlayConfig playConfig;
  final String title;

  const VlcPlayerPage({
    super.key,
    required this.playConfig,
    required this.title,
  });

  @override
  State<VlcPlayerPage> createState() => _VlcPlayerPageState();
}

class _VlcPlayerPageState extends State<VlcPlayerPage> {
  final GlobalKey<VlcTabState> _vlcTabKey = GlobalKey<VlcTabState>();
  bool _isExiting = false;

  Future<void> _handleExit() async {
    if (_isExiting) return;
    _isExiting = true;
    
    try {
      // 立即强制停止播放器
      _vlcTabKey.currentState?.forceStop();
      
      // 给予更长时间确保资源完全释放
      await Future.delayed(const Duration(milliseconds: 200));
      
      if (kDebugMode) {
        print('VLC播放器页面退出完成');
      }
    } catch (e) {
      if (kDebugMode) {
        print('退出VLC播放器页面时出错: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isExiting,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop && !_isExiting) {
          await _handleExit();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: VlcTab(
          key: _vlcTabKey,
          playConfig: widget.playConfig,
          title: widget.title,
        ),
      ),
    );
  }
} 