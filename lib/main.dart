import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'shared/controllers/window_controller.dart';
import 'features/short_videos/players/vlc/vlc_short_video_player.dart';
import 'features/short_videos/pages/short_videos_page.dart';
import 'features/short_videos/players/media_kit/video_player_factory.dart';
import 'features/media_player/vlc_player/pages/vlc_player_page.dart';
import 'features/media_player/standard_player/pages/video_player_page.dart';
import 'shared/widgets/layouts/portrait_home_layout.dart';
import 'shared/widgets/layouts/landscape_home_layout.dart';
import 'app/data_source.dart';
import 'app/routes/app_pages.dart';
import 'app/bindings/initial_binding.dart';

// 测试视频URL
const String testVideoUrl = 'https://static.ybhospital.net/test-video-10.MP4';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
    return GetMaterialApp(
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
      initialBinding: InitialBinding(),
      getPages: AppPages.routes,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // 更新系统UI模式
  void _updateSystemUIMode(bool isPortrait) {
    if (!isPortrait && Platform.isAndroid) {
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

  // 打开播放器页面，根据当前方向选择合适的播放器
  void _openPlayerPage(BuildContext context, PlayerType type) {
    final windowController = Get.find<WindowController>();
    
    // 创建测试用的播放配置
    final testPlayConfig = VideoPlayConfig(
      url: testVideoUrl,
      headers: const {},
    );
    
    switch (type) {
      case PlayerType.vlc:
        Get.to(() => const VlcDemoShortVideoPlayer())
            ?.then((_) => windowController.ensureCorrectOrientation());
        break;
      case PlayerType.shortVideo:
        Get.to(() => const ShortVideoPage())
            ?.then((_) => windowController.ensureCorrectOrientation());
        break;
      case PlayerType.singleTab:
        Get.to(() => VlcPlayerPage(
              playConfig: testPlayConfig,
              title: 'VLC 播放器测试',
            ))?.then((_) => windowController.ensureCorrectOrientation());
        break;
      case PlayerType.singleVideoTab:
        Get.to(() => SingleVideoTabPage(
              playConfig: testPlayConfig,
              title: 'VideoPlayer 播放器测试',
            ))?.then((_) => windowController.ensureCorrectOrientation());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final windowController = Get.find<WindowController>();
      final isPortrait = windowController.isPortrait.value;
      _updateSystemUIMode(isPortrait);
      
      
      return Scaffold(
        backgroundColor: isPortrait ? Colors.white : Colors.black, // 竖屏白色背景，横屏黑色背景
        // 竖屏和横屏模式都不显示AppBar，让自定义标签栏显示在顶部
        appBar: null,
        body: isPortrait 
          ? SafeArea(child: PortraitHomeLayout(onPlayerSelected: _openPlayerPage))
          : LandscapeHomeLayout(onPlayerSelected: _openPlayerPage),
      );
    });
  }
}

// 播放器类型枚举
enum PlayerType {
  vlc,
  shortVideo,
  singleTab,
  singleVideoTab,
}
