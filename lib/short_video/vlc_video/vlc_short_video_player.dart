import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'dart:math';
import '../views/video_page.dart';
import '../views/video_side_bar.dart';
import '../views/video_comment.dart';
import '../mock/video.dart';
import 'dart:async';
import '../views/video_progress_bar.dart';
import 'package:flutter/services.dart';
import '../../window_controller.dart';

class VlcDemoShortVideoPlayer extends StatefulWidget {
  const VlcDemoShortVideoPlayer({super.key});

  @override
  State<VlcDemoShortVideoPlayer> createState() => _VlcDemoShortVideoPlayerState();
}

class _VlcDemoShortVideoPlayerState extends State<VlcDemoShortVideoPlayer> with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  final Map<int, VlcPlayerController> _controllers = {};
  List<UserVideo> _videoList = [];
  int _currentIndex = 0;
  final Map<int, bool> _favoriteMap = {};
  bool _isInitialized = false;
  final Map<int, bool> _isVideoReady = {};
  final Map<int, bool> _isPlaying = {};
  final Map<int, bool> _isPrepared = {};
  bool _isLoadingMore = false;
  int _targetLoadingIndex = 0; // 添加跟踪正在加载的目标索引
  final windowController = WindowController();

  // 预加载数量
  static const int preloadCount = 2;
  // 释放数量
  static const int disposeCount = 0; // 设置为0，确保内存释放
  // 加载更多阈值
  static const int loadMoreCount = 1;

  // 添加防抖控制
  int _lastLoadIndex = -1;
  bool _isLoading = false;

  final Map<int, Duration> _currentPositions = {};
  final Map<int, Duration> _durations = {};
  final Map<int, Timer?> _progressTimers = {};
  final Map<int, bool> _isDragging = {};

  // 在类成员变量区域添加操作锁
  bool _isSeekOperationInProgress = false;
  // 增加延迟变量，控制seek操作的最小间隔
  final Map<int, DateTime> _lastSeekTimes = {};
  static const Duration _minSeekInterval = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 设置为全屏模式，让视频顶到状态栏
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _initVideos();
    _setupPageController();
  }

  void _setupPageController() {
    _pageController.addListener(() {
      var page = _pageController.page;
      if (page != null && page % 1 == 0) {
        _loadIndex(page ~/ 1);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeAllControllers();
    _cancelAllTimers();
    _pageController.dispose();
    // 恢复系统UI设置
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    // 确保屏幕方向与按钮设置一致
    windowController.ensureCorrectOrientation();
    super.dispose();
  }

  void _cancelAllTimers() {
    for (var timer in _progressTimers.values) {
      timer?.cancel();
    }
    _progressTimers.clear();
  }

  void _startProgressTimer(int index) {
    // 取消已有定时器
    _progressTimers[index]?.cancel();
    
    // 创建新定时器
    _progressTimers[index] = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      // 检查是否应该更新
      if (_isDragging[index] == true || _isSeekOperationInProgress) return;
      
      final controller = _controllers[index];
      if (controller != null) {
        try {
          // 使用Future.wait同时获取位置和时长，减少等待时间
          final results = await Future.wait([
            controller.getPosition().timeout(const Duration(milliseconds: 100), 
                onTimeout: () => _currentPositions[index] ?? Duration.zero),
            controller.getDuration().timeout(const Duration(milliseconds: 100), 
                onTimeout: () => _durations[index] ?? Duration.zero)
          ]);
          
          if (mounted) {
            setState(() {
              _currentPositions[index] = results[0];
              _durations[index] = results[1];
            });
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error updating position: $e');
          }
        }
      }
    });
  }

  Future<void> _disposeAllControllers() async {
    for (var entry in _controllers.entries) {
      try {
        final controller = entry.value;
        // 先停止播放
        await controller.pause();
        // 停止渲染器扫描
        await controller.stopRendererScanning();
        // 释放资源
        await controller.dispose();
            } catch (e) {
        if (kDebugMode) {
          print('Error disposing controller ${entry.key}: $e');
        }
      }
    }
    _controllers.clear();
    _isVideoReady.clear();
    _isPlaying.clear();
    _isPrepared.clear();
    _currentPositions.clear();
    _durations.clear();
    _isDragging.clear();
  }

  Future<void> _disposeController(int index) async {
    if (!_controllers.containsKey(index)) return;
    try {
      final controller = _controllers[index];
      if (controller != null) {
        await controller.pause();
        await controller.stopRendererScanning();
        await controller.dispose();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error disposing controller $index: $e');
      }
    } finally {
      _controllers.remove(index);
      _isVideoReady.remove(index);
      _isPlaying.remove(index);
      _isPrepared.remove(index);
      _currentPositions.remove(index);
      _durations.remove(index);
      _isDragging.remove(index);
      _progressTimers[index]?.cancel();
      _progressTimers.remove(index);
    }
  }

  Future<void> _initVideos() async {
    try {
      _videoList = UserVideo.fetchVideo();
      // 只初始化第一个视频
      await _initController(0);
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing videos: $e');
      }
    }
  }

  Future<void> _waitForPlaying(VlcPlayerController controller, int index) async {
    final startTime = DateTime.now();
    
    // 使用 Completer 来等待播放状态
    final completer = Completer<void>();
    
    // 添加播放状态监听器
    void listener() {
      if (controller.value.isPlaying) {
        controller.removeListener(listener);
        completer.complete();
      }
    }
    
    controller.addListener(listener);
    
    // 等待播放开始
    await completer.future;
    
    // 确保至少显示 600ms
    final elapsed = DateTime.now().difference(startTime);
    if (elapsed < const Duration(milliseconds: 600)) {
      await Future.delayed(const Duration(milliseconds: 600) - elapsed);
    }
    
    if (mounted) {
      setState(() {
        _isPrepared[index] = true;
        _isVideoReady[index] = true;
        _isPlaying[index] = true;
      });
    }
  }

  Future<void> _loadIndex(int target) async {
    // 防止重复加载
    if (target == _currentIndex || _isLoading) return;
    _isLoading = true;
    _lastLoadIndex = target;
    
    // 设置当前正在加载的索引，用于显示加载界面
    setState(() {
      _targetLoadingIndex = target;
      _isPrepared[target] = false;
    });

    try {
      // 暂停之前的视频
      if (_controllers.containsKey(_currentIndex)) {
        final oldController = _controllers[_currentIndex];
        if (oldController != null) {
          // 异步暂停，不阻塞主线程
          Future.microtask(() async {
            try {
              await oldController.pause();
              if (mounted && _lastLoadIndex == target) {
                setState(() {
                  _isPlaying[_currentIndex] = false;
                });
              }
            } catch (e) {
              if (kDebugMode) {
                print('Error pausing old video: $e');
              }
            }
          });
        }
      }

      // 异步初始化当前视频
      if (!_controllers.containsKey(target)) {
        try {
          await _initController(target);
        } catch (e) {
          if (kDebugMode) {
            print('Error initializing controller: $e');
          }
        }
      }
      
      final currentController = _controllers[target];
      if (currentController != null) {
        // 异步播放，不阻塞主线程
        Future.microtask(() async {
          try {
            if (_isVideoReady[target] == true) {
              await currentController.play();
              if (mounted && _lastLoadIndex == target) {
                setState(() {
                  _isPlaying[target] = true;
                });
              }
            } else {
              // 如果视频还没准备好，等待初始化完成
              await Future.delayed(const Duration(milliseconds: 100));
              if (_isVideoReady[target] == true && mounted && _lastLoadIndex == target) {
                await currentController.play();
                setState(() {
                  _isPlaying[target] = true;
                });
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error playing video: $e');
            }
          }
        });
      }

      // 异步处理预加载/释放内存，不阻塞主线程
      Future.microtask(() async {
        try {
          for (var i = 0; i < _videoList.length; i++) {
            // 释放不需要的视频
            if (i < target - disposeCount || i > target + max(disposeCount, 2)) {
              if (i != target) { // 确保不释放当前视频
                try {
                  await _disposeController(i);
                } catch (e) {
                  if (kDebugMode) {
                    print('Error disposing controller $i: $e');
                  }
                }
              }
            }
            // 预加载下一个视频
            if (i > target && i < target + preloadCount) {
              try {
                await _initController(i);
              } catch (e) {
                if (kDebugMode) {
                  print('Error preloading video $i: $e');
                }
              }
            }
          }

          // 检查是否需要加载更多视频
          if (_videoList.length - target <= loadMoreCount + 1) {
            try {
              await _loadMoreVideos();
            } catch (e) {
              if (kDebugMode) {
                print('Error loading more videos: $e');
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error in async task: $e');
          }
        }
      });

      if (mounted && _lastLoadIndex == target) {
        _currentIndex = target;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading index $target: $e');
      }
    } finally {
      if (_lastLoadIndex == target) {
        _isLoading = false;
      }
    }
  }

  Future<void> _initController(int index) async {
    if (!mounted) return;
    
    if (_controllers.containsKey(index)) {
      try {
        await _disposeController(index);
      } catch (e) {
        if (kDebugMode) {
          print('Error disposing existing controller $index: $e');
        }
      }
    }

    try {
      final video = _videoList[index];
      final controller = VlcPlayerController.network(
        video.url,
        hwAcc: HwAcc.full,
        autoPlay: false,
        options: VlcPlayerOptions(
          advanced: VlcAdvancedOptions([
            '--network-caching=2000',
            '--rtsp-tcp',
            '--repeat',
          ]),
        ),
      );

      // 添加初始化监听器
      controller.addOnInitListener(() async {
        if (!mounted) return;
        
        try {
          // 异步播放，不阻塞主线程
          Future.microtask(() async {
            try {
              await controller.play();
              if (mounted) {
                _waitForPlaying(controller, index);
              }
            } catch (e) {
              if (kDebugMode) {
                print('Error playing video in init: $e');
              }
            }
          });
        } catch (e) {
          if (kDebugMode) {
            print('Error in init listener: $e');
          }
          if (mounted) {
            setState(() {
              _isPrepared[index] = false;
              _isVideoReady[index] = false;
              _isPlaying[index] = false;
              _currentPositions[index] = Duration.zero;
              _durations[index] = Duration.zero;
            });
          }
        }
      });

      _controllers[index] = controller;
      // 初始状态设置为未准备好
      if (mounted) {
        setState(() {
          _isPrepared[index] = false;
          _isVideoReady[index] = false;
          _isPlaying[index] = false;
          _currentPositions[index] = Duration.zero;
          _durations[index] = Duration.zero;
          _isDragging[index] = false;
        });
      }
      _startProgressTimer(index);
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing controller $index: $e');
      }
      if (mounted) {
        setState(() {
          _isPrepared[index] = false;
          _isVideoReady[index] = false;
          _isPlaying[index] = false;
          _currentPositions[index] = Duration.zero;
          _durations[index] = Duration.zero;
          _isDragging[index] = false;
        });
      }
    }
  }

  Future<void> _loadMoreVideos() async {
    if (_isLoadingMore) return;
    _isLoadingMore = true;

    try {
      // 模拟加载更多视频
      final moreVideos = UserVideo.fetchVideo();
      setState(() {
        _videoList.addAll(moreVideos);
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading more videos: $e');
      }
    } finally {
      _isLoadingMore = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      if (_controllers.containsKey(_currentIndex)) {
        _controllers[_currentIndex]?.pause();
        setState(() {
          _isPlaying[_currentIndex] = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      // 移除appBar，让视频顶到状态栏
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Stack(
        children: [
          // 视频页面视图
          PageView.builder(
            physics: const ClampingScrollPhysics(),
            scrollDirection: Axis.vertical,
            controller: _pageController,
            onPageChanged: (index) async {
              await _loadIndex(index);
            },
            itemCount: _videoList.length,
            itemBuilder: (context, index) {
              final video = _videoList[index];
              final controller = _controllers[index];
              bool isFavorite = _favoriteMap[index] ?? false;
              bool isReady = _isVideoReady[index] ?? false;
              bool isPlaying = _isPlaying[index] ?? false;
              Duration position = _currentPositions[index] ?? Duration.zero;
              Duration duration = _durations[index] ?? Duration.zero;
              bool isDragging = _isDragging[index] ?? false;
              
              // 加载状态：当前索引是目标加载索引且尚未准备好
              bool isLoading = index == _targetLoadingIndex && !(_isPrepared[index] ?? false);

              // 转换为UserVideo类型
              final userVideo = UserVideo(
                id: video.id,
                url: video.url,
                cover: video.cover,
                title: video.title,
                author: video.author,
                likeCount: video.likeCount,
                commentCount: video.commentCount,
                desc: video.desc,
              );

              return VideoPage(
                videoData: userVideo,
                video: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (controller != null)
                      SizedBox.expand(
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height,
                            child: VlcPlayer(
                              controller: controller,
                              aspectRatio: MediaQuery.of(context).size.width / MediaQuery.of(context).size.height,
                              placeholder: Container(
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                isLoading: isLoading,
                tag: video.title,
                isPlaying: isPlaying,
                rightButtonColumn: VideoButtonColumn(
                  isFavorite: isFavorite,
                  onFavorite: () {
                    setState(() {
                      _favoriteMap[index] = !isFavorite;
                    });
                  },
                  onComment: () {
                    showModalBottomSheet(
                      backgroundColor: Colors.transparent,
                      context: context,
                      builder: (context) => const CommentBottomSheet(),
                    );
                  },
                ),
                onAddFavorite: () {
                  // 添加点赞功能的回调实现
                  try {
                    if (!mounted) return;
                    // 使用异步处理，避免UI线程阻塞
                    Future.microtask(() {
                      try {
                        if (mounted) {
                          setState(() {
                            _favoriteMap[index] = true;
                          });
                        }
                      } catch (e) {
                        if (kDebugMode) {
                          print('Error setting favorite state: $e');
                        }
                      }
                    });
                  } catch (e) {
                    if (kDebugMode) {
                      print('Error adding favorite: $e');
                    }
                    // 静默处理异常，防止应用卡死
                  }
                },
                onSingleTap: () async {
                  if (!isReady) return;
                  try {
                    final currentController = _controllers[index];
                    if (currentController != null) {
                      // 异步处理播放/暂停，不阻塞主线程
                      Future.microtask(() async {
                        try {
                          if (isPlaying) {
                            await currentController.pause();
                            if (mounted) {
                              setState(() {
                                _isPlaying[index] = false;
                              });
                            }
                          } else {
                            await currentController.play();
                            if (mounted) {
                              setState(() {
                                _isPlaying[index] = true;
                              });
                            }
                          }
                        } catch (e) {
                          if (kDebugMode) {
                            print('Error toggling play state: $e');
                          }
                        }
                      });
                    }
                  } catch (e) {
                    if (kDebugMode) {
                      print('Error in onSingleTap: $e');
                    }
                    // 静默处理异常，防止应用卡死
                  }
                },
                bottomWidget: controller != null && duration.inMilliseconds > 0
                    ? VideoProgressBar(
                        position: position,
                        duration: duration,
                        isDragging: isDragging,
                        onSeek: (d) async {
                          try {
                            // 防止重复操作 - 检查全局锁
                            if (_isSeekOperationInProgress) return;
                            
                            // 检查最小操作间隔
                            final now = DateTime.now();
                            final lastSeekTime = _lastSeekTimes[index] ?? DateTime(2000);
                            if (now.difference(lastSeekTime) < _minSeekInterval) {
                              return;
                            }
                            
                            // 设置锁定状态和最后操作时间
                            _isSeekOperationInProgress = true;
                            _lastSeekTimes[index] = now;
                            
                            // 先更新UI状态，让用户即时看到反馈
                            if (mounted) {
                              setState(() {
                                _isDragging[index] = false;
                                // 预先更新进度位置，让UI立即响应
                                _currentPositions[index] = d;
                              });
                            }
                            
                            try {
                              // 使用隔离的方法执行VLC操作，避免UI阻塞
                              await Future(() async {
                                try {
                                  // 使用timeout限制操作时间，防止永久阻塞
                                  await controller.setTime(d.inMilliseconds)
                                      .timeout(const Duration(seconds: 2), onTimeout: () {
                                    if (kDebugMode) {
                                      print('setTime operation timed out');
                                    }
                                    return;
                                  });
                                  
                                  // 如果视频暂停了，自动播放
                                  if (!isPlaying && isReady && mounted) {
                                    await controller.play().timeout(
                                        const Duration(seconds: 1),
                                        onTimeout: () {
                                          if (kDebugMode) {
                                            print('play operation timed out');
                                          }
                                          return;
                                        });
                                    
                                    if (mounted) {
                                      setState(() {
                                        _isPlaying[index] = true;
                                      });
                                    }
                                  }
                                } catch (e) {
                                  if (kDebugMode) {
                                    print('Error in setTime or play: $e');
                                  }
                                }
                              });
                            } catch (e) {
                              if (kDebugMode) {
                                print('Error in Future execution: $e');
                              }
                            } finally {
                              // 最后重置锁定状态
                              _isSeekOperationInProgress = false;
                            }
                            
                            // 立即重新启动进度条更新定时器，不等待视频操作完成
                            // 但避免重复启动
                            _progressTimers[index]?.cancel();
                            _startProgressTimer(index);
                          } catch (e) {
                            if (kDebugMode) {
                              print('Error seeking video: $e');
                            }
                            // 发生错误时释放锁
                            _isSeekOperationInProgress = false;
                            // 出错时也需要重新启动进度条更新
                            _startProgressTimer(index);
                          }
                        },
                        onDragStatusChanged: (dragging) {
                          try {
                            if (mounted) {
                              setState(() {
                                _isDragging[index] = dragging;
                              });
                            }
                            
                            if (dragging) {
                              // 拖动时暂停进度条更新
                              _progressTimers[index]?.cancel();
                            } else {
                              // 拖动结束后立即恢复进度条更新
                              _startProgressTimer(index);
                            }
                          } catch (e) {
                            if (kDebugMode) {
                              print('Error handling drag status: $e');
                            }
                          }
                        },
                      )
                    : null,
              );
            },
          ),
          
          // 返回和搜索按钮浮在视频上方
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                      onPressed: () async {
                        // 先暂停当前视频
                        if (_controllers.containsKey(_currentIndex)) {
                          final controller = _controllers[_currentIndex];
                          if (controller != null) {
                            await controller.pause();
                          }
                        }
                        // 释放所有控制器
                        await _disposeAllControllers();
                        // 恢复系统UI设置
                        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
                        // 确保屏幕方向与主页面设置一致
                        await windowController.ensureCorrectOrientation();
                        // 返回上一页
                        if (mounted) {
                          if (!mounted) return; // Added to satisfy linter
                          // ignore: use_build_context_synchronously
                          Navigator.pop(context);
                        }
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
          ),
        ],
      ),
    );
  }
} 