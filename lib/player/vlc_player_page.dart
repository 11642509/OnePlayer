import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'vlc_tab.dart';
import '../window_controller.dart';

class SingleTabPage extends StatefulWidget {
  const SingleTabPage({super.key});

  @override
  State<SingleTabPage> createState() => _SingleTabPageState();
}

class _SingleTabPageState extends State<SingleTabPage> with WidgetsBindingObserver {
  bool showBar = true;
  bool _isLandscape = false;
  final windowController = WindowController();

  @override
  void initState() {
    super.initState();
    // 添加观察者以监听设备方向变化
    WidgetsBinding.instance.addObserver(this);
    // 设置全屏模式
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // 确保控制栏初始显示，然后会自动隐藏
    showBar = true;
    // 检查当前方向状态
    _isLandscape = !windowController.isPortrait.value;
  }

  @override
  void didChangeMetrics() {
    // 当设备尺寸、方向等变化时调用
    if (mounted) {
      final orientation = MediaQuery.of(context).orientation;
      if (_isLandscape != (orientation == Orientation.landscape)) {
        setState(() {
          _isLandscape = orientation == Orientation.landscape;
        });
      }
    }
  }

  void showBars() {
    if (!showBar) setState(() => showBar = true);
  }

  void hideBars() {
    if (showBar) setState(() => showBar = false);
  }

  @override
  void dispose() {
    // 移除观察者
    WidgetsBinding.instance.removeObserver(this);
    // 恢复系统UI设置
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // 确保屏幕方向与按钮设置一致
    windowController.ensureCorrectOrientation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 获取当前屏幕方向
    _isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 视频播放器，传递控制栏显示/隐藏回调
          SingleTab(
            showBar: showBar,
            onUserInteraction: showBars,
            onRequestHideBar: hideBars,
          ),
          // 悬浮标题栏
          AnimatedOpacity(
            opacity: showBar ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              height: 56,
              padding: EdgeInsets.only(top: _isLandscape ? 0 : MediaQuery.of(context).padding.top),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      // 退出全屏模式
                      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                      Navigator.of(context).maybePop();
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '单标签播放器测试',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 