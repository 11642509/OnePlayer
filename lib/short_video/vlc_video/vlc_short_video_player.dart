import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'dart:math';
import '../../vlc_short_video/mock/vlc_video.dart';
import '../views/video_page.dart';
import '../views/video_side_bar.dart';
import '../views/video_comment.dart';
import '../mock/video.dart';
import 'dart:async';

class VlcDemoShortVideoPlayer extends StatefulWidget {
  const VlcDemoShortVideoPlayer({super.key});

  @override
  State<VlcDemoShortVideoPlayer> createState() => _VlcDemoShortVideoPlayerState();
}

class _VlcDemoShortVideoPlayerState extends State<VlcDemoShortVideoPlayer> with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  final Map<int, VlcPlayerController> _controllers = {};
  List<VlcVideo> _videoList = [];
  int _currentIndex = 0;
  final Map<int, bool> _favoriteMap = {};
  bool _isInitialized = false;
  final Map<int, bool> _isVideoReady = {};
  final Map<int, bool> _isPlaying = {};
  final Map<int, bool> _isPrepared = {};
  bool _isLoadingMore = false;

  // 预加载数量
  static const int preloadCount = 2;
  // 释放数量
  static const int disposeCount = 0; // 设置为0，确保内存释放
  // 加载更多阈值
  static const int loadMoreCount = 1;

  // 添加防抖控制
  int _lastLoadIndex = -1;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    // 确保所有资源都被正确释放
    _disposeAllControllers();
    _pageController.dispose();
    super.dispose();
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
  }

  Future<void> _disposeController(int index) async {
    if (!_controllers.containsKey(index)) return;
    try {
      final controller = _controllers[index];
      if (controller != null) {
        // 先停止播放
        await controller.pause();
        // 停止渲染器扫描
        await controller.stopRendererScanning();
        // 释放资源
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
    }
  }

  Future<void> _initVideos() async {
    try {
      _videoList = VlcVideo.fetchVideo();
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
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing controller $index: $e');
      }
      if (mounted) {
        setState(() {
          _isPrepared[index] = false;
          _isVideoReady[index] = false;
          _isPlaying[index] = false;
        });
      }
    }
  }

  Future<void> _loadMoreVideos() async {
    if (_isLoadingMore) return;
    _isLoadingMore = true;

    try {
      // 模拟加载更多视频
      final moreVideos = VlcVideo.fetchVideo();
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
      body: Stack(
        children: [
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
                  children: [
                    if (controller != null)
                      VlcPlayer(
                        controller: controller,
                        aspectRatio: 9 / 16,
                        placeholder: Container(
                          color: Colors.black,
                        ),
                      ),
                  ],
                ),
                isLoading: index == _currentIndex && !(_isPrepared[index] ?? false),
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
                onSingleTap: () async {
                  if (!isReady) return;
                  final currentController = _controllers[index];
                  if (currentController != null) {
                    // 异步处理播放/暂停，不阻塞主线程
                    Future.microtask(() async {
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
                    });
                  }
                },
              );
            },
          ),
          SafeArea(
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
        ],
      ),
    );
  }
} 