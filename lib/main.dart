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
        primarySwatch: Colors.pink,
        primaryColor: const Color(0xFFFF7BB0), // B站风格粉色
        brightness: Brightness.light, // 浅色主题
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
        ),
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
    
    // 初始化时设置系统UI模式
    _updateSystemUIMode();
  }

  @override
  void dispose() {
    // 移除监听
    windowController.isPortrait.removeListener(_updateLayout);
    super.dispose();
  }

  // 更新系统UI模式
  void _updateSystemUIMode() {
    if (!windowController.isPortrait.value && Platform.isAndroid) {
      // 横屏模式下隐藏状态栏
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      // 竖屏模式下显示状态栏，并设置为深色图标
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      // 设置状态栏图标为深色，以便在浅色背景下可见
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // 透明状态栏
        statusBarIconBrightness: Brightness.dark, // 深色图标
        statusBarBrightness: Brightness.light, // iOS状态栏亮度
      ));
    }
  }

  // 更新布局
  void _updateLayout() {
    if (mounted) {
      // 方向改变时更新系统UI模式
      _updateSystemUIMode();
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
    return ValueListenableBuilder<bool>(
      valueListenable: windowController.isPortrait,
      builder: (context, isPortrait, _) {
        return Scaffold(
          backgroundColor: isPortrait ? Colors.white : Colors.black, // 竖屏白色背景，横屏黑色背景
          // 竖屏和横屏模式都不显示AppBar，让自定义标签栏显示在顶部
          appBar: null,
          body: isPortrait 
            ? SafeArea(child: PortraitHomeLayout(onPlayerSelected: _openPlayerPage))
            : LandscapeHomeLayout(onPlayerSelected: _openPlayerPage),
                  );
                },
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
