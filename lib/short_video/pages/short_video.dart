import '../mock/video.dart';
import '../views/video_page.dart';
import '../views/video_side_bar.dart';
import '../views/video_comment.dart';
import '../controller/video_list_controller.dart';
import '../views/video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:safemap/safemap.dart';
import 'package:video_player/video_player.dart';
import '../video_players/video_player_impl/video_player_factory.dart';
import '../video_players/video_player_impl/media_kit_video_controller.dart';
import '../../window_controller.dart';
import 'dart:math';

// 访问全局窗口控制器
final windowController = WindowController();

class ShortVideoPage extends StatefulWidget {
  final Function? onUserTap;
  final Function? onCommentTap;
  final Function? onFavoriteTap;
  final bool showHeader;
  final bool showBottomBar;

  const ShortVideoPage({
    super.key,
    this.onUserTap,
    this.onCommentTap,
    this.onFavoriteTap,
    this.showHeader = true,
    this.showBottomBar = true,
  });

  @override
  ShortVideoPageState createState() => ShortVideoPageState();
}

class ShortVideoPageState extends State<ShortVideoPage> with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  final VideoListController _videoListController = VideoListController();
  Map<int, bool> favoriteMap = {};
  List<UserVideo> videoDataList = [];
  
  // 添加进度条相关状态
  final Map<int, bool> _isDragging = {};
  final Map<int, bool> _isSeekOperationInProgress = {};
  final Map<int, DateTime> _lastSeekTimes = {};
  static const Duration _minSeekInterval = Duration(milliseconds: 300);
  
  // 添加标志变量，用于控制异步操作
  bool _isDisposed = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    // 添加mounted和disposed检查，防止在页面销毁后调用setState
    if (!mounted || _isDisposed) return;
    
    if (state != AppLifecycleState.resumed) {
      _videoListController.currentPlayer.pause();
    }
  }

  @override
  void dispose() {
    debugPrint('ShortVideoPage disposing...');
    // 标记为已销毁，避免后续异步操作触发setState
    _isDisposed = true;
    
    // 清理所有资源
    WidgetsBinding.instance.removeObserver(this);
    
    // 清理页面控制器
    _pageController.dispose();
    
    // 释放视频播放器资源
    try {
      // 暂停所有播放器，避免后台继续播放
      _videoListController.currentPlayer.pause();
          
      // 清理视频控制器资源
      _videoListController.dispose();
    } catch (e) {
      debugPrint('Error disposing video controllers: $e');
    }
    
    // 清理拖动状态
    _isDragging.clear();
    _isSeekOperationInProgress.clear();
    _lastSeekTimes.clear();
    
    // 移除方向监听
    windowController.isPortrait.removeListener(_handleOrientationChange);
    
    super.dispose();
  }

  @override
  void initState() {
    videoDataList = UserVideo.fetchVideo();
    WidgetsBinding.instance.addObserver(this);
    _videoListController.init(
      pageController: _pageController,
      initialList: createMediaKitControllers(videoDataList),
      videoProvider: (int index, List<VideoController<dynamic>> list) async {
        return createMediaKitControllers(videoDataList);
      },
    );
    _videoListController.addListener(() {
      if (mounted && !_isDisposed) {
        setState(() {});
      }
    });
    
    // 监听全局屏幕方向变化
    windowController.isPortrait.addListener(_handleOrientationChange);
    
    super.initState();
  }
  
  // 处理方向变化
  void _handleOrientationChange() {
    if (mounted && !_isDisposed) {
      setState(() {}); // 更新UI
    }
  }

  // 安全的setState方法，避免在组件销毁后调用
  void _safeSetState(VoidCallback fn) {
    if (mounted && !_isDisposed) {
      setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 从全局获取设备方向
    final isLandscape = !windowController.isPortrait.value;
    
    return WillPopScope(
      // 拦截返回按钮，确保资源正确释放
      onWillPop: () async {
        // 暂停当前播放器
        _videoListController.currentPlayer.pause();
        return true; // 允许返回
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: <Widget>[
            // 使用SafeArea确保在横屏模式下内容在安全区域内展示
            SafeArea(
              child: PageView.builder(
                key: const Key('short_video'),
                physics: const ClampingScrollPhysics(),
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: _videoListController.videoCount,
                itemBuilder: (context, i) {
                  bool isF = SafeMap(favoriteMap)[i].boolean;
                  var player = _videoListController.playerOfIndex(i)!;
                  var data = player.videoData!;
                  
                  Widget buttons = VideoButtonColumn(
                    // 在横屏模式下适当减少右侧按钮底部边距
                    bottomPadding: isLandscape ? 16 : null,
                    isFavorite: isF,
                    onAvatar: widget.onUserTap,
                    onFavorite: () {
                      _safeSetState(() {
                        favoriteMap[i] = !isF;
                      });
                      widget.onFavoriteTap?.call();
                    },
                    onComment: () {
                      if (!mounted || _isDisposed) return;
                      showModalBottomSheet(
                        backgroundColor: Colors.transparent,
                        context: context,
                        builder: (BuildContext context) =>
                            CommentBottomSheet(),
                      );
                      widget.onCommentTap?.call();
                    },
                  );

                  Widget currentVideo = Center(
                    child: Builder(
                      builder: (context) {
                        // 获取视频的宽高比
                        final videoAspectRatio = player.controller.value.aspectRatio;
                        
                        // 判断是横向还是竖向视频
                        final isLandscapeVideo = videoAspectRatio > 1.0;
                        
                        if (isLandscapeVideo) {
                          // 对于横向视频，填满宽度
                          return AspectRatio(
                            aspectRatio: videoAspectRatio,
                            child: Transform.scale(
                              scale: max(
                                1.0,
                                MediaQuery.of(context).size.width / 
                                (MediaQuery.of(context).size.height * videoAspectRatio)
                              ),
                              child: VideoPlayer(player.controller),
                            ),
                          );
                        } else {
                          // 对于竖向视频
                          if (isLandscape) {
                            // 设备横屏时，竖屏视频保持原始比例
                            return AspectRatio(
                              aspectRatio: videoAspectRatio,
                              child: VideoPlayer(player.controller),
                            );
                          } else {
                            // 设备竖屏时，确保视频铺满屏幕宽度
                            final screenWidth = MediaQuery.of(context).size.width;
                            final screenHeight = MediaQuery.of(context).size.height;
                            final screenRatio = screenWidth / screenHeight;
                            
                            // 计算需要的缩放比例，确保视频至少铺满屏幕宽度
                            final scale = max(1.0, screenRatio / videoAspectRatio);
                            
                            return Transform.scale(
                              scale: scale,
                              child: AspectRatio(
                                aspectRatio: videoAspectRatio,
                                child: VideoPlayer(player.controller),
                              ),
                            );
                          }
                        }
                      }
                    ),
                  );

                  // 获取视频当前位置和总时长（针对MediaKit控制器）
                  Duration position = Duration.zero;
                  Duration duration = Duration.zero;
                  bool isDragging = _isDragging[i] ?? false;
                  
                  // 尝试获取播放位置和时长
                  try {
                    if (player is MediaKitVideoController) {
                      position = player.positionNotifier.value;
                      duration = player.durationNotifier.value;
                    }
                  } catch (e) {
                    debugPrint('Error getting position/duration: $e');
                  }

                  // 创建进度条小部件
                  Widget? progressBar;
                  if (duration.inMilliseconds > 0) {
                    progressBar = VideoProgressBar(
                      position: position,
                      duration: duration,
                      isDragging: isDragging,
                      isLandscape: isLandscape,
                      onDragStatusChanged: (dragging) {
                        _safeSetState(() {
                          _isDragging[i] = dragging;
                        });
                      },
                      onSeek: (seekPosition) async {
                        // 防止在组件销毁后执行
                        if (!mounted || _isDisposed) return;
                        
                        // 防止重复操作
                        if (_isSeekOperationInProgress[i] == true) return;
                        
                        // 检查最小操作间隔
                        final now = DateTime.now();
                        final lastSeekTime = _lastSeekTimes[i] ?? DateTime(2000);
                        if (now.difference(lastSeekTime) < _minSeekInterval) {
                          return;
                        }
                        
                        // 设置锁定状态和最后操作时间
                        _safeSetState(() {
                          _isSeekOperationInProgress[i] = true;
                          _lastSeekTimes[i] = now;
                          _isDragging[i] = false;
                        });
                        
                        try {
                          // 执行跳转
                          if (player is MediaKitVideoController && mounted && !_isDisposed) {
                            await player.seekTo(seekPosition);
                          }
                        } catch (e) {
                          debugPrint('Error seeking: $e');
                        } finally {
                          // 重置锁定状态
                          if (mounted && !_isDisposed) {
                            _safeSetState(() {
                              _isSeekOperationInProgress[i] = false;
                            });
                          }
                        }
                      },
                    );
                  }

                  return VideoPage(
                    hidePauseIcon: !player.showPauseIcon.value,
                    // 根据屏幕方向调整视频宽高比
                    aspectRatio: isLandscape ? 16 / 9.0 : 9 / 16.0,
                    key: Key('${data.url}$i'),
                    tag: data.url,
                    // 根据横竖屏调整底部边距
                    bottomPadding: isLandscape ? 8.0 : 16.0,
                    onSingleTap: () async {
                      // 防止在组件销毁后执行
                      if (!mounted || _isDisposed) return;
                      
                      // 如果正在拖动进度条，不触发播放/暂停
                      if (_isDragging[i] == true || _isSeekOperationInProgress[i] == true) {
                        return;
                      }
                        
                      if (player.controller.value.isPlaying) {
                        player.showPauseIcon.value = true;
                        await player.pause();
                      } else {
                        player.showPauseIcon.value = false;
                        await player.play();
                      }
                      
                      // 确保UI更新
                      if (mounted && !_isDisposed) {
                        setState(() {});
                      }
                    },
                    onAddFavorite: () {
                      _safeSetState(() {
                        favoriteMap[i] = true;
                      });
                      widget.onFavoriteTap?.call();
                    },
                    rightButtonColumn: buttons,
                    video: currentVideo,
                    isLoading: !player.prepared,
                    videoData: data,
                    bottomWidget: progressBar, // 添加进度条
                    isLandscape: isLandscape, // 传递横屏状态到VideoPage
                  );
                },
              ),
            ),
            // 顶部导航按钮区域也使用SafeArea确保安全区域内显示
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                      onPressed: () {
                        // 确保暂停播放，并在返回前清理资源
                        _videoListController.currentPlayer.pause();
                                              Navigator.pop(context);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.search, color: Colors.white),
                      onPressed: () {
                        // 实现搜索功能
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
