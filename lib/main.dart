import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'window_controller.dart';
import 'short_video/vlc_video/vlc_short_video_player.dart';
import 'short_video/pages/short_video.dart';
import 'short_video/video_players/video_player_impl/video_player_factory.dart';
import 'player/vlc_player_page.dart';
import 'player/video_player_page.dart';
import 'portrait_home_layout.dart';
import 'landscape_home_layout.dart';

// 全局窗口控制器
final windowController = WindowController();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化窗口
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    await windowController.initialize();
  } else if (Platform.isAndroid || Platform.isIOS) {
    // 默认设置为横屏模式
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
    ]);
    // 初始化为横屏状态
    windowController.isPortrait.value = false;
  }
  
  // 初始化MediaKit视频播放器
  initMediaKitPlayer();
  
  // 允许HTTP请求（解决网络图片加载问题）
  if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
    HttpOverrides.global = MyHttpOverrides();
  }
  
  runApp(const MyApp());
}

// 自定义HTTP覆盖，解决证书问题
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Player Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    
    // 监听窗口方向变化
    windowController.isPortrait.addListener(_updateLayout);
  }

  @override
  void dispose() {
    // 移除监听
    windowController.isPortrait.removeListener(_updateLayout);
    super.dispose();
  }

  // 更新布局
  void _updateLayout() {
    if (mounted) {
      setState(() {});
    }
  }
  
  // 打开播放器页面，根据当前方向选择合适的播放器
  void _openPlayerPage(BuildContext context, PlayerType type) {
    
    switch (type) {
      case PlayerType.vlc:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const VlcDemoShortVideoPlayer(),
          ),
        ).then((_) => windowController.ensureCorrectOrientation());
        break;
      case PlayerType.shortVideo:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ShortVideoPage(),
          ),
        ).then((_) => windowController.ensureCorrectOrientation());
        break;
      case PlayerType.singleTab:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SingleTabPage(),
          ),
        ).then((_) => windowController.ensureCorrectOrientation());
        break;
      case PlayerType.singleVideoTab:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SingleVideoTabPage(),
          ),
        ).then((_) => windowController.ensureCorrectOrientation());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('视频播放器'),
        backgroundColor: Colors.black,
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: windowController.isPortrait,
            builder: (context, isPortrait, _) {
              return IconButton(
                icon: Icon(isPortrait ? Icons.screen_lock_rotation : Icons.screen_lock_portrait),
                tooltip: isPortrait ? '切换为横屏' : '切换为竖屏',
                onPressed: windowController.toggleOrientation,
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: windowController.isPortrait,
        builder: (context, isPortrait, _) {
          if (isPortrait) {
            return PortraitHomeLayout(onPlayerSelected: _openPlayerPage);
          } else {
            return LandscapeHomeLayout(onPlayerSelected: _openPlayerPage);
          }
        },
      ),
    );
  }
}

// 播放器类型枚举
enum PlayerType {
  vlc,
  shortVideo,
  singleTab,
  singleVideoTab,
}
