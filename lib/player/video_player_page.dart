import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'video_player_tab.dart';

class SingleVideoTabPage extends StatefulWidget {
  const SingleVideoTabPage({super.key});

  @override
  State<SingleVideoTabPage> createState() => _SingleVideoTabPageState();
}

class _SingleVideoTabPageState extends State<SingleVideoTabPage> with WidgetsBindingObserver {
  bool showBar = true;
  bool _isLandscape = false;

  @override
  void initState() {
    super.initState();
    // 添加观察者以监听设备方向变化
    WidgetsBinding.instance.addObserver(this);
    // 启用所有方向
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // 设置全屏模式
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // 确保控制栏初始显示，然后会自动隐藏
    showBar = true;
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
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
          SingleVideoTab(
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
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      // 退出全屏模式
                      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
                      Navigator.of(context).maybePop();
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'VideoPlayer 播放器测试',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  // 添加旋转屏幕按钮
                  IconButton(
                    icon: Icon(
                      _isLandscape ? Icons.screen_rotation : Icons.screen_lock_rotation,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      if (_isLandscape) {
                        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
                      } else {
                        SystemChrome.setPreferredOrientations([
                          DeviceOrientation.landscapeLeft,
                          DeviceOrientation.landscapeRight,
                        ]);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 