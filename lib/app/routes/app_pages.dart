import 'package:get/get.dart';
import '../../features/search/pages/search_page.dart';
import '../../features/search/controllers/search_controller.dart' as search_ctrl;
import '../../features/video_on_demand/pages/video_detail_page.dart';
import '../../features/media_player/vlc_player/pages/vlc_player_page.dart';
import '../../features/media_player/standard_player/pages/video_player_page.dart';
import '../../features/video_on_demand/controllers/video_detail_controller.dart';
import 'app_routes.dart';

/// GetX 路由页面配置
class AppPages {
  // 禁止实例化
  AppPages._();

  /// 初始路由
  static const initial = AppRoutes.home;

  /// 路由页面列表
  static final routes = [
    // 搜索页面
    GetPage(
      name: AppRoutes.search,
      page: () => const SearchPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<search_ctrl.SearchController>(() => search_ctrl.SearchController());
      }),
      transition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    // 视频详情页
    GetPage(
      name: AppRoutes.videoDetail,
      page: () {
        final videoId = Get.parameters['videoId'] ?? '';
        return VideoDetailPage(videoId: videoId);
      },
      binding: BindingsBuilder(() {
        final videoId = Get.parameters['videoId'] ?? '';
        Get.lazyPut<VideoDetailController>(
          () => VideoDetailController(),
          tag: videoId,
        );
      }),
      transition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // VLC播放器页面
    GetPage(
      name: AppRoutes.vlcPlayer,
      page: () {
        final arguments = Get.arguments as Map<String, dynamic>;
        return VlcPlayerPage(
          playConfig: arguments['playConfig'],
          title: arguments['title'],
        );
      },
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // 标准视频播放器页面
    GetPage(
      name: AppRoutes.videoPlayer,
      page: () {
        final arguments = Get.arguments as Map<String, dynamic>;
        return SingleVideoTabPage(
          playConfig: arguments['playConfig'],
          title: arguments['title'],
        );
      },
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
    ),
  ];
}