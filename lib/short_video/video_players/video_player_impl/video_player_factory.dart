import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_media_kit/video_player_media_kit.dart';

import '../../controller/video_list_controller.dart';
import '../../../mock/video.dart';
import 'media_kit_video_controller.dart';

/// 初始化MediaKit视频播放器
void initMediaKitPlayer() {
  // 延迟初始化确保界面准备好后再加载
  Future.delayed(Duration.zero, () {
    try {
      VideoPlayerMediaKit.ensureInitialized(
        android: true,
        iOS: true,
        macOS: Platform.isMacOS, // 显式指定macOS
        windows: Platform.isWindows,
        linux: Platform.isLinux,
      );
      debugPrint('MediaKit初始化成功');
    } catch (e) {
      debugPrint('MediaKit初始化失败: $e');
    }
  });
}

/// 创建基于MediaKit的视频控制器
VideoController<VideoPlayerController> createMediaKitController(UserVideo video) {
  return MediaKitVideoController(
    videoInfo: video,
    builder: () {
      return VideoPlayerController.networkUrl(
        Uri.parse(video.url),
        httpHeaders: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
        },
      );
    },
  );
}

/// 从视频列表创建控制器列表
List<VideoController<VideoPlayerController>> createMediaKitControllers(List<UserVideo> videos) {
  return videos.map((video) => createMediaKitController(video)).toList();
} 