import 'dart:async';
import 'dart:math';

import '../../../shared/models/video.dart';
import 'package:flutter/material.dart';

typedef LoadMoreVideoCallback = Future<List<VideoController<dynamic>>> Function(
  int index,
  List<VideoController<dynamic>> list,
);

/// VideoListController是一系列视频的控制器，内部管理了视频控制器数组
/// 提供了预加载/释放/加载更多功能
class VideoListController extends ChangeNotifier {
  VideoListController({
    this.loadMoreCount = 1,
    this.preloadCount = 2,

    /// 设置为0后，任何不在画面内的视频都会被释放
    /// 若不设置为0，安卓将会无法加载第三个开始的视频
    this.disposeCount = 0,
  });

  /// 到第几个触发预加载，例如：1:最后一个，2:倒数第二个
  final int loadMoreCount;

  /// 预加载多少个视频
  final int preloadCount;

  /// 超出多少个，就释放视频
  final int disposeCount;

  /// 提供视频的builder
  LoadMoreVideoCallback? _videoProvider;

  loadIndex(int target, {bool reload = false}) {
    if (!reload) {
      if (index.value == target) return;
    }
    // 播放当前的，暂停其他的
    var oldIndex = index.value;
    var newIndex = target;

    // 暂停之前的视频
    if (!(oldIndex == 0 && newIndex == 0)) {
      playerOfIndex(oldIndex)?.controller.seekTo(Duration.zero);
      // playerOfIndex(oldIndex)?.controller.addListener(_didUpdateValue);
      // playerOfIndex(oldIndex)?.showPauseIcon.addListener(_didUpdateValue);
      playerOfIndex(oldIndex)?.pause();
    }
    // 开始播放当前的视频
    playerOfIndex(newIndex)?.controller.addListener(_didUpdateValue);
    playerOfIndex(newIndex)?.showPauseIcon.addListener(_didUpdateValue);
    playerOfIndex(newIndex)?.play();
    // 处理预加载/释放内存
    for (var i = 0; i < playerList.length; i++) {
      /// 需要释放[disposeCount]之前的视频
      /// i < newIndex - disposeCount 向下滑动时释放视频
      /// i > newIndex + disposeCount 向上滑动，同时避免disposeCount设置为0时失去视频预加载功能
      if (i < newIndex - disposeCount || i > newIndex + max(disposeCount, 2)) {
        playerOfIndex(i)?.controller.removeListener(_didUpdateValue);
        playerOfIndex(i)?.showPauseIcon.removeListener(_didUpdateValue);
        playerOfIndex(i)?.dispose();
        continue;
      }
      // 需要预加载
      if (i > newIndex && i < newIndex + preloadCount) {
        playerOfIndex(i)?.init();
        continue;
      }
    }
    // 快到最底部，添加更多视频
    if (playerList.length - newIndex <= loadMoreCount + 1) {
      _videoProvider?.call(newIndex, playerList).then(
        (list) async {
          playerList.addAll(list);
          notifyListeners();
        },
      );
    }

    // 完成
    index.value = target;
  }

  _didUpdateValue() {
    notifyListeners();
  }

  /// 获取指定index的player
  VideoController<dynamic>? playerOfIndex(int index) {
    if (index < 0 || index > playerList.length - 1) {
      return null;
    }
    return playerList[index];
  }

  /// 视频总数目
  int get videoCount => playerList.length;

  /// 初始化
  init({
    required PageController pageController,
    required List<VideoController<dynamic>> initialList,
    required LoadMoreVideoCallback videoProvider,
  }) async {
    playerList.addAll(initialList);
    _videoProvider = videoProvider;
    pageController.addListener(() {
      var p = pageController.page!;
      if (p % 1 == 0) {
        loadIndex(p ~/ 1);
      }
    });
    loadIndex(0, reload: true);
    notifyListeners();
  }

  /// 目前的视频序号
  ValueNotifier<int> index = ValueNotifier<int>(0);

  /// 视频列表
  List<VideoController<dynamic>> playerList = [];

  ///
  VideoController<dynamic> get currentPlayer => playerList[index.value];

  /// 销毁全部
  @override
  void dispose() {
    // 销毁全部
    for (var player in playerList) {
      player.showPauseIcon.dispose();
      player.dispose();
    }
    playerList = [];
    super.dispose();
  }
}

typedef ControllerSetter<T> = Future<void> Function(T controller);
typedef ControllerBuilder<T> = T Function();

/// 抽象类，作为视频控制器必须实现这些方法
abstract class VideoController<T> {
  /// 获取当前的控制器实例
  T? get controller;

  /// 是否显示暂停按钮
  ValueNotifier<bool> get showPauseIcon;

  /// 是否已准备好播放
  bool get prepared;

  /// 获取视频数据
  UserVideo? get videoData;

  /// 加载视频，在init后，应当开始下载视频内容
  Future<void> init({ControllerSetter<T>? afterInit});

  /// 视频销毁，在dispose后，应当释放任何内存资源
  Future<void> dispose();

  /// 播放
  Future<void> play();

  /// 暂停
  Future<void> pause({bool showPauseIcon = false});
}

