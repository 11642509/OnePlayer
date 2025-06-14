import 'dart:async';

import '../../../mock/video.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../controller/video_list_controller.dart'; // 导入抽象类和 typedefs

/// 异步方法并发锁
Completer<void>? _syncLock;

class VPVideoController extends VideoController<VideoPlayerController> {
  VideoPlayerController? _controller;
  final ValueNotifier<bool> _showPauseIcon = ValueNotifier<bool>(false);

  final UserVideo? videoInfo;

  @override
  UserVideo? get videoData => videoInfo;

  final ControllerBuilder<VideoPlayerController> _builder;
  final ControllerSetter<VideoPlayerController>? _afterInit;

  VPVideoController({
    this.videoInfo,
    required ControllerBuilder<VideoPlayerController> builder,
    ControllerSetter<VideoPlayerController>? afterInit,
  })  : _builder = builder,
        _afterInit = afterInit;

  @override
  VideoPlayerController get controller {
    _controller ??= _builder.call();
    return _controller!;
  }

  @override
  bool get prepared => _prepared;
  bool _prepared = false;

  Completer<void>? _disposeLock;

  /// 防止异步方法并发
  Future<void> _syncCall(Future Function()? fn) async {
    // 设置同步等待
    var lastCompleter = _syncLock;
    var completer = Completer<void>();
    _syncLock = completer;
    // 等待其他同步任务完成
    await lastCompleter?.future;
    // 主任务
    await fn?.call();
    // 结束
    completer.complete();
  }

  @override
  Future<void> dispose() async {
    if (!prepared) return;
    _prepared = false;
    await _syncCall(() async {
      await controller.dispose();
      _controller = null;
      _disposeLock = Completer<void>();
    });
  }

  @override
  Future<void> init({
    ControllerSetter<VideoPlayerController>? afterInit,
  }) async {
    if (prepared) return;
    await _syncCall(() async {
      await controller.initialize();
      await controller.setLooping(true);
      afterInit ??= _afterInit;
      await afterInit?.call(controller);
      _prepared = true;
    });
    if (_disposeLock != null) {
      _disposeLock?.complete();
      _disposeLock = null;
    }
  }

  @override
  Future<void> pause({bool showPauseIcon = false}) async {
    await init(); // 确保已初始化
    if (!prepared) return; // 如果未准备好则返回
    // 移除等待disposeLock，直接暂停
    await controller.pause();
    _showPauseIcon.value = true;
  }

  @override
  Future<void> play() async {
    await init(); // 确保已初始化
    if (!prepared) return; // 如果未准备好则返回
    // 移除等待disposeLock，直接播放
    await controller.play();
    _showPauseIcon.value = false;
  }

  @override
  ValueNotifier<bool> get showPauseIcon => _showPauseIcon;
}

// 需要引入 TikTokVideoController 抽象类
// import '../../controller/tiktok_video_list_controller.dart'; // 这个文件现在只包含抽象类和其他通用代码 