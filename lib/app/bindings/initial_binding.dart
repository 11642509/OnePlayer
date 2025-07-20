import 'package:get/get.dart';
import '../../shared/controllers/window_controller.dart';
import '../../features/video_on_demand/controllers/vod_controller.dart';
import '../../shared/utils/performance_manager.dart';
import '../../core/remote_control/remote_control_service.dart';
import '../../shared/services/back_button_handler.dart';

/// 初始依赖注入绑定
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // 返回键处理服务 - 最先初始化
    Get.put<BackButtonHandler>(
      BackButtonHandler(),
      permanent: true,
    );
    
    // 性能管理器 - 最先初始化
    Get.put<PerformanceManager>(
      PerformanceManager(),
      permanent: true,
    );
    
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
    
    // 遥控器服务 - 全局单例，永久保持
    Get.put<RemoteControlService>(
      RemoteControlService(),
      permanent: true,
    );
  }
}