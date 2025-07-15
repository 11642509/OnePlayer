import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/video_player_tab_widget.dart';
import '../../../../shared/controllers/window_controller.dart';
import 'package:get/get.dart';
import '../../../../app/data_source.dart';

class SingleVideoTabPage extends StatefulWidget {
  final VideoPlayConfig playConfig;
  final String title;
  
  const SingleVideoTabPage({
    super.key,
    required this.playConfig,
    required this.title,
  });

  @override
  State<SingleVideoTabPage> createState() => _SingleVideoTabPageState();
}

class _SingleVideoTabPageState extends State<SingleVideoTabPage> with WidgetsBindingObserver {
  bool showBar = true;
  bool _isLandscape = false;
  final windowController = Get.find<WindowController>();

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
          SingleVideoTab(
            playConfig: widget.playConfig,
            showBar: showBar,
            onUserInteraction: showBars,
            onRequestHideBar: hideBars,
            title: widget.title,
          ),
          // 注释掉独立的标题栏，因为VideoPlayerWithControls内部已经有了
          // 标题栏已经集成到播放器控件中
        ],
      ),
    );
  }
} 