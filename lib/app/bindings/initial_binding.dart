import 'package:get/get.dart';
import '../../shared/controllers/window_controller.dart';
import '../../features/video_on_demand/controllers/vod_controller.dart';

/// 初始依赖注入绑定
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // 窗口控制器 - 全局单例，永久保持
    Get.put<WindowController>(
      WindowController(),
      permanent: true,
    );
    
    // VOD控制器 - 全局单例，永久保持
    Get.put<VodController>(
      VodController(),
      permanent: true,
    );
  }
}