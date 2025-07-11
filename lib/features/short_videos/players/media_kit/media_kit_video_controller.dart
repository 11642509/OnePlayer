import 'dart:async';

import '../../../../shared/models/video.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../controllers/video_list_controller.dart';

/// 异步方法并发锁
Completer<void>? _syncLock;

class MediaKitVideoController extends VideoController<VideoPlayerController> {
  VideoPlayerController? _controller;
  final ValueNotifier<bool> _showPauseIcon = ValueNotifier<bool>(false);

  final UserVideo? videoInfo;

  @override
  UserVideo? get videoData => videoInfo;

  final ControllerBuilder<VideoPlayerController> _builder;
  final ControllerSetter<VideoPlayerController>? _afterInit;

  // 添加播放位置和总时长的值监听器
  final ValueNotifier<Duration> _positionNotifier = ValueNotifier<Duration>(Duration.zero);
  final ValueNotifier<Duration> _durationNotifier = ValueNotifier<Duration>(Duration.zero);
  
  // 添加获取方法
  ValueNotifier<Duration> get positionNotifier => _positionNotifier;
  ValueNotifier<Duration> get durationNotifier => _durationNotifier;
  
  // 添加更新定时器
  Timer? _positionUpdateTimer;

  MediaKitVideoController({
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

  /// 开始定期更新播放位置
  void _startPositionUpdates() {
    // 取消已有定时器
    _positionUpdateTimer?.cancel();
    
    // 创建新定时器，每500毫秒更新一次位置
    _positionUpdateTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (!prepared || controller.value.isInitialized == false) return;
      
      try {
        final position = await controller.position ?? Duration.zero;
        final duration = controller.value.duration;
        
        _positionNotifier.value = position;
        _durationNotifier.value = duration;
      } catch (e) {
        debugPrint('Error updating position: $e');
      }
    });
  }

  @override
  Future<void> dispose() async {
    if (!prepared) return;
    _prepared = false;
    
    // 取消定时器
    _positionUpdateTimer?.cancel();
    _positionUpdateTimer = null;
    
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
      
      // 初始化完成后开始更新位置
      _startPositionUpdates();
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
  
  /// 跳转到指定位置
  Future<void> seekTo(Duration position) async {
    if (!prepared || controller.value.isInitialized == false) return;
    
    try {
      // 更新位置值以立即反映在UI上
      _positionNotifier.value = position;
      
      // 记录当前是否正在播放
      bool wasPlaying = controller.value.isPlaying;
      
      // 执行跳转
      await controller.seekTo(position);
      
      // 如果之前是播放状态，确保跳转后继续播放
      if (wasPlaying && !controller.value.isPlaying) {
        await controller.play();
        _showPauseIcon.value = false;
      }
    } catch (e) {
      debugPrint('Error seeking to position: $e');
    }
  }

  @override
  ValueNotifier<bool> get showPauseIcon => _showPauseIcon;
} 