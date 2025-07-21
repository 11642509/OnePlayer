import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../../../app/config/config.dart';
import '../../../app/data_source.dart';
import '../../../app/routes/app_routes.dart';

class VideoDetailController extends GetxController {
  // 响应式状态变量
  final RxBool isLoading = true.obs;
  final Rx<Map<String, dynamic>?> videoDetail = Rx<Map<String, dynamic>?>(null);
  final RxString errorMessage = ''.obs;
  final RxString currentPlaySource = ''.obs;
  
  // 数据源
  final DataSource _dataSource = DataSource();
  
  // 视频ID
  late String videoId;
  
  /// 初始化控制器
  void initWithVideoId(String id) {
    videoId = id;
    fetchVideoDetail();
  }
  
  /// 获取视频详情
  Future<void> fetchVideoDetail() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final data = await _dataSource.fetchVideoDetail(videoId);
      
      if ((data['code'] == 0 || data['code'] == 200) && data['list'] != null && data['list'].isNotEmpty) {
        videoDetail.value = data['list'][0];
        isLoading.value = false;
        
        // 解析播放源
        final playFrom = videoDetail.value!['vod_play_from']?.toString().split('\$\$\$') ?? [];
        
        // 查找第一个非"相关"的播放源
        String defaultSource = '';
        for (final source in playFrom) {
          if (source != '相关') {
            defaultSource = source;
            break;
          }
        }
        
        // 如果没有找到非"相关"的播放源，则使用第一个播放源（可能是"相关"）
        currentPlaySource.value = defaultSource.isNotEmpty ? defaultSource : (playFrom.isNotEmpty ? playFrom.first : '');
        
        if (kDebugMode) {
          print('设置默认播放源: ${currentPlaySource.value}');
          print('所有播放源: $playFrom');
        }
      } else {
        errorMessage.value = '获取视频详情失败: ${data['message'] ?? '未知错误'}';
        isLoading.value = false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('获取视频详情失败: $e');
      }
      errorMessage.value = '发生错误: $e';
      isLoading.value = false;
    }
  }
  
  /// 切换播放源
  void changePlaySource(String source) {
    currentPlaySource.value = source;
  }
  
  /// 播放视频
  Future<void> playVideo(String episodeUrl, String episodeName, {String? playSource}) async {
    final source = playSource ?? currentPlaySource.value;
    if (videoDetail.value == null || source.isEmpty) {
      Get.snackbar(
        '播放失败',
        '无法播放视频，缺少必要信息',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      // 获取视频播放地址
      final playConfig = await _dataSource.fetchVideoPlayUrl(
        episodeUrl,
        source,
      );

      if (playConfig.url.isNotEmpty) {
        final String title = '${videoDetail.value!['vod_name']} - $episodeName';

        // 智能选择播放器内核
        bool useVlc = AppConfig.currentPlayerKernel == PlayerKernel.vlc;
        
        // 对于MPD格式，如果配置为VLC但可能存在兼容性问题，提供选择
        if (useVlc && playConfig.format == VideoFormat.dash) {
          if (kDebugMode) {
            print('检测到MPD格式，使用VLC播放器（如遇问题可切换到video_player）');
          }
        }
        
        if (useVlc) {
          // 使用 VLC 播放器
          if (kDebugMode) {
            print('使用VLC内核播放: ${playConfig.url}');
          }
          Get.offNamed(
            AppRoutes.vlcPlayer,
            arguments: {
              'playConfig': playConfig,
              'title': title,
            },
          );
        } else {
          // 使用 video_player 播放器
          if (kDebugMode) {
            print('使用video_player内核播放: ${playConfig.url}');
          }
          Get.toNamed(
            AppRoutes.videoPlayer,
            arguments: {
              'playConfig': playConfig,
              'title': title,
            },
          );
        }
      } else {
        Get.snackbar(
          '播放失败',
          '获取播放地址失败: 返回的URL为空',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        '播放失败',
        '获取播放地址失败: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
  
  /// 播放第一集
  void playFirstEpisode() {
    if (videoDetail.value == null) return;
    
    final playFrom = videoDetail.value!['vod_play_from']?.toString().split(r'$$$') ?? [];
    final playUrl = videoDetail.value!['vod_play_url']?.toString().split(r'$$$') ?? [];
    final sourceIndex = playFrom.indexOf(currentPlaySource.value);
    
    if (sourceIndex != -1 && sourceIndex < playUrl.length) {
      final urls = playUrl[sourceIndex].split('#');
      if (urls.isNotEmpty) {
        final parts = urls.first.split('\$');
        if (parts.length >= 2) {
          playVideo(parts[1], parts[0]);
        } else {
          Get.snackbar(
            '播放失败',
            '无法解析播放地址',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
    }
  }
  
  /// 获取播放选项
  Map<String, List<Map<String, String>>> get playOptions {
    if (videoDetail.value == null) return {};
    
    final playFrom = videoDetail.value!['vod_play_from']?.toString().split(r'$$$') ?? [];
    final playUrl = videoDetail.value!['vod_play_url']?.toString().split(r'$$$') ?? [];
    
    final Map<String, List<Map<String, String>>> options = {};
    for (int i = 0; i < playFrom.length && i < playUrl.length; i++) {
      final source = playFrom[i];
      final urls = playUrl[i].split('#');
      
      final List<Map<String, String>> episodes = [];
      for (final url in urls) {
        final parts = url.split('\$');
        if (parts.length >= 2) {
          episodes.add({'name': parts[0], 'url': parts[1]});
        }
      }
      options[source] = episodes;
    }
    
    return options;
  }
  
  /// 获取所有播放源
  List<String> get allPlaySources {
    if (videoDetail.value == null) return [];
    return videoDetail.value!['vod_play_from']?.toString().split(r'$$$') ?? [];
  }
}