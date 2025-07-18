import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../app/data_source.dart';
import '../../../../shared/controllers/window_controller.dart';
import '../widgets/vlc_tab_widget.dart';

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
  final windowController = Get.find<WindowController>();

  @override
  void initState() {
    super.initState();
    // 设置沉浸式全屏模式，不论横竖屏
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    if (kDebugMode) {
      print('VLC播放器页面进入全屏模式');
    }
  }

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
  void dispose() {
    // 恢复系统 UI 设置
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // 确保屏幕方向与按钮设置一致
    windowController.ensureCorrectOrientation();
    if (kDebugMode) {
      print('VLC播放器页面恢复系统 UI 设置');
    }
    super.dispose();
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