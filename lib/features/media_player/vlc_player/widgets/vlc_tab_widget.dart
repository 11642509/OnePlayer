import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import '../../../../app/data_source.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../pages/vlc_player_with_controls_page.dart';
import '../../../../core/remote_control/focusable_glow.dart';

class VlcTab extends StatefulWidget {
  final VideoPlayConfig playConfig;
  final String title;

  const VlcTab({
    super.key,
    required this.playConfig,
    required this.title,
  });

  @override
  State<VlcTab> createState() => VlcTabState();
}

class VlcTabState extends State<VlcTab> {
  // 将 _controller 声明为可空类型
  late VlcPlayerController? _controller;
  bool _showControls = true;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isDisposing = false;
  Timer? _loadingTimer;
  Timer? _healthCheckTimer;
  bool _isControllerInitialized = false;
  DateTime? _lastPlaybackTime;
  final bool _showPlayer = true;
  final bool _exiting = false;
  bool _hasRequestedExit = false; // 防止多次点击返回
  
  // 焦点管理
  final FocusNode _backButtonFocus = FocusNode();
  final FocusNode _retryButtonFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }
  
  Future<void> _initializePlayer() async {
    try {
      if (kDebugMode) {
        print('=== VLC播放器配置 ===');
        print('URL: ${widget.playConfig.url}');
        print('Format: ${widget.playConfig.format}');
        print('User-Agent: ${widget.playConfig.userAgent}');
        print('Referer: ${widget.playConfig.referer}');
        print('Headers Map:');
        widget.playConfig.headers.forEach((key, value) {
          if (kDebugMode) {
            print('  $key: $value');
          }
        });
        print('开始等待视频真正播放...');
        print('===================');
      }
      
      
      _controller = VlcPlayerController.network(
        widget.playConfig.url,
        hwAcc: HwAcc.full,
        autoPlay: true,
        options: VlcPlayerOptions(
          advanced: VlcAdvancedOptions([
            VlcAdvancedOptions.fileCaching(500),
            VlcAdvancedOptions.networkCaching(500),
            VlcAdvancedOptions.liveCaching(500),
            VlcAdvancedOptions.clockJitter(0),
            ':verbose=2',
          ]),
          http: VlcHttpOptions([
            VlcHttpOptions.httpReconnect(true),
            // 尝试最简配置，只传递必要的headers
            if (widget.playConfig.headers.containsKey('User-Agent'))
              ':http-user-agent=${widget.playConfig.headers['User-Agent']}',
            if (widget.playConfig.headers.containsKey('Referer'))
              VlcHttpOptions.httpReferrer(widget.playConfig.headers['Referer']!),
            // 传递其他headers（排除User-Agent和Referer避免重复）
            ...widget.playConfig.headers.entries
                .where((entry) => entry.key != 'User-Agent' && entry.key != 'Referer')
                .map((entry) => ':http-header=${entry.key}: ${entry.value}'),
          ]),
          extras: [
            ':avcodec-hw=mediacodec',
            ':avcodec-threads=4',
            ':avcodec-fast',
            ':avcodec-skiploopfilter=0'
          ],
        ),
      );
      
      _isControllerInitialized = true;
      _controller!.addListener(_errorListener);
      _controller!.addListener(_playbackListener);
      
      // 对于MPD文件，延迟启动健康检查，给予充分的解析时间
      if (widget.playConfig.format == VideoFormat.dash) {
        // MPD需要更多时间初始化，60秒后再启动检查
        Future.delayed(const Duration(seconds: 60), () {
          if (!_isDisposing && mounted) {
            _startHealthCheck();
          }
        });
      } else {
        // 非MPD文件可以正常启动检查
        _startHealthCheck();
      }
      
      // 调用新的等待逻辑
      await _waitForPlaying();
    } catch (e) {
      if (kDebugMode) {
        print('初始化VLC播放器失败: $e');
      }
      if (mounted && !_isDisposing) {
        setState(() {
          _hasError = true;
          _errorMessage = '播放器初始化失败: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _waitForPlaying() async {
    final startTime = DateTime.now();
    final completer = Completer<void>();
    
    // 用于跟踪播放进度的变量
    Duration? lastPosition;
    Timer? progressCheckTimer;

    void listener() {
      if (!mounted || _isDisposing) return;
      
      // 更严格的条件：只有当真正开始播放且有进度时才隐藏加载界面
      bool isReallyPlaying = _controller != null && _controller!.value.isPlaying && 
                           !_controller!.value.isBuffering &&
                           _controller!.value.position > Duration.zero;
      
      if (isReallyPlaying) {
        _controller!.removeListener(listener);
        progressCheckTimer?.cancel();
        if (!completer.isCompleted) {
          if (kDebugMode) {
            print('VLC 视频真正开始播放');
            print('播放状态: isPlaying=${_controller!.value.isPlaying}, isBuffering=${_controller!.value.isBuffering}');
            print('播放位置: ${_controller!.value.position}');
          }
          completer.complete();
        }
      }
    }
    
    // 强化的进度检查，确保视频真正在播放
    void checkProgress() {
      if (_isDisposing || !mounted) return;
      if (_controller == null) return;
      
      final currentPosition = _controller!.value.position;
      
      // 更严格的条件：进度必须大于0且在持续增长
      bool hasValidProgress = currentPosition > Duration.zero;
      bool progressIncreasing = lastPosition != null && currentPosition > lastPosition!;
      bool isPlaying = _controller!.value.isPlaying && !_controller!.value.isBuffering;
      
      if (hasValidProgress && progressIncreasing && isPlaying) {
        // 确认视频真正在播放
        _controller!.removeListener(listener);
        progressCheckTimer?.cancel();
        if (!completer.isCompleted) {
        if (kDebugMode) {
            print('进度检查确认：视频真正开始播放');
            print('当前位置: ${currentPosition.inMilliseconds}ms');
            print('上次位置: ${lastPosition?.inMilliseconds}ms');
          }
          completer.complete();
        }
      }
      
      lastPosition = currentPosition;
    }
    
    _controller?.addListener(listener);
    
    // 更频繁地检查播放进度，确保及时检测到真正的播放
    progressCheckTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      checkProgress();
    });
    
    // 延长保险机制时间，只在真正异常时才强制隐藏
    Timer(const Duration(seconds: 45), () {
      if (!completer.isCompleted && mounted && !_isDisposing) {
        if (_controller != null && _controller!.value.isInitialized && !_controller!.value.hasError) {
          // 最后检查一次是否真的在播放
          if (_controller!.value.isPlaying && _controller!.value.position > Duration.zero) {
            _controller!.removeListener(listener);
            progressCheckTimer?.cancel();
            if (!completer.isCompleted) {
              if (kDebugMode) {
                print('45秒保险机制：检测到播放中，隐藏加载界面');
              }
              completer.complete();
            }
          } else {
            if (kDebugMode) {
              print('45秒保险机制：视频仍未真正播放，但强制隐藏加载界面');
            }
            _controller!.removeListener(listener);
            progressCheckTimer?.cancel();
            if (!completer.isCompleted) {
              completer.complete();
            }
          }
        }
      }
    });
    
    // 根据视频格式设置不同的超时时间
    final timeout = widget.playConfig.format == VideoFormat.dash 
        ? const Duration(seconds: 45)  // MPD文件需要更长时间
        : const Duration(seconds: 20); // 其他格式的正常时间
        
    _loadingTimer = Timer(timeout, () {
      if (!completer.isCompleted && mounted && !_isDisposing) {
        _controller?.removeListener(listener);
        progressCheckTimer?.cancel();
          setState(() {
          _hasError = true;
          _errorMessage = widget.playConfig.format == VideoFormat.dash
              ? 'MPD文件解析超时（${timeout.inSeconds}秒），请尝试其他播放源或检查网络连接'
              : '视频加载超时，请尝试其他播放源或检查网络连接';
            _isLoading = false;
          });
        }
      });
      
    try {
      await completer.future.timeout(timeout);
    } catch (e) {
      if (mounted && !completer.isCompleted && !_isDisposing) {
        _controller?.removeListener(listener);
        progressCheckTimer.cancel();
        setState(() {
          _hasError = true;
          _errorMessage = widget.playConfig.format == VideoFormat.dash
              ? 'MPD解析超时: $e'
              : '视频加载超时: $e';
          _isLoading = false;
        });
        return;
      }
    }

    // 取消定时器
    _loadingTimer?.cancel();
    progressCheckTimer.cancel();
    
    if (_isDisposing) return;

    // 确保加载动画至少显示一段时间
    final elapsed = DateTime.now().difference(startTime);
    if (elapsed < const Duration(milliseconds: 600) && !_isDisposing) {
      await Future.delayed(const Duration(milliseconds: 600) - elapsed);
    }
    
    if (mounted && !_isDisposing) {
          setState(() {
            _isLoading = false;
      });
    }
  }

  void _errorListener() {
    if (!mounted || _isDisposing || _controller == null) return;
    if (_controller!.value.hasError && !_hasError) {
      final errorDesc = _controller!.value.errorDescription;
      if (kDebugMode) {
        print('===== VLC播放器错误 =====');
        print('错误描述: $errorDesc');
        print('播放URL: ${widget.playConfig.url}');
        print('视频格式: ${widget.playConfig.format}');
        print('User-Agent: ${widget.playConfig.userAgent}');
        print('Referer: ${widget.playConfig.referer}');
        print('Headers: ${widget.playConfig.headers}');
        print('========================');
      }
      setState(() {
            _hasError = true;
        final errorDesc = _controller!.value.errorDescription;
        _errorMessage = errorDesc.isNotEmpty ? errorDesc : '播放出错';
        _isLoading = false;
          });
    }
  }
  
  void _playbackListener() {
    if (!mounted || _isDisposing || _controller == null) return;
    // 更新最后播放时间，但不仅仅在isPlaying时
    // 因为MPD文件在解析过程中状态可能不稳定
    if (_controller!.value.isPlaying || _controller!.value.isBuffering) {
      _lastPlaybackTime = DateTime.now();
    }
  }
  
  void _startHealthCheck() {
    _healthCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_isDisposing || !mounted) {
        timer.cancel();
        return;
      }
      if (_controller == null) return;
      
      // 只在真正无响应时才干预，特别是MPD文件需要更长的容忍时间
      final tolerance = widget.playConfig.format == VideoFormat.dash 
          ? const Duration(minutes: 2)  // MPD文件给予更长时间
          : const Duration(seconds: 30); // 其他格式的正常时间
      
      if (_lastPlaybackTime != null && 
          _controller!.value.isPlaying &&
          DateTime.now().difference(_lastPlaybackTime!) > tolerance) {
        if (kDebugMode) {
          print('检测到播放器长时间无响应（${tolerance.inSeconds}秒），可能卡死');
        }
        _handlePlaybackStuck();
      }
    });
  }
  
  void _handlePlaybackStuck() {
    if (_isDisposing || _controller == null) return;
    
    // 对于MPD文件，直接重试而不是简单的stop/play
    if (widget.playConfig.format == VideoFormat.dash) {
          if (kDebugMode) {
        print('MPD文件播放卡死，执行完整重试');
          }
      _retry();
      return;
    }
    
    // 非MPD文件使用简单的stop/play恢复
    try {
      _controller!.dispose();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_isDisposing && mounted && _controller != null) {
          _controller!.play();
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('恢复播放时出错: $e');
      }
      _retry();
    }
  }

  void forceStop() {
    if (_isDisposing || _controller == null) return;
    _isDisposing = true;
    try {
      // 取消所有定时器
      _loadingTimer?.cancel();
      _healthCheckTimer?.cancel();
      // 移除所有监听器
      if (_isControllerInitialized) {
        _controller!.removeListener(_errorListener);
        _controller!.removeListener(_playbackListener);
        // 强制停止播放
        _controller!.dispose();
        // 直接同步释放资源
              _controller!.dispose();
            }
      if (kDebugMode) {
        print('VLC播放器已强制停止并释放资源');
      }
    } catch (e) {
      if (kDebugMode) {
        print('强制停止播放器时出错: $e');
      }
    }
  }

  @override
  void dispose() {
    // 激进方案：不做任何controller相关操作，只调用super.dispose()
    _backButtonFocus.dispose();
    _retryButtonFocus.dispose();
    super.dispose();
  }

  void _retry() {
    if (_isDisposing) return;
    
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });
    
    // 清理当前控制器
    try {
      _loadingTimer?.cancel();
      _healthCheckTimer?.cancel();
      
      if (_isControllerInitialized && _controller != null) {
        _controller!.removeListener(_errorListener);
        _controller!.removeListener(_playbackListener);
        _controller!.dispose();
      }
    } catch (e) {
      if (kDebugMode) {
        print('清理旧控制器时出错: $e');
      }
    }
    
    _isControllerInitialized = false;
    
    // 重新初始化播放器
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!_isDisposing && mounted) {
        _initializePlayer();
      }
    });
  }

  // 新增：安全返回方法
  Future<void> _onBackPressed() async {
    if (_hasRequestedExit) return;
    _hasRequestedExit = true;
    if (mounted) Navigator.of(context).pop();
    // 激进方案：不做任何资源释放，不setState，不Future，不dispose controller
  }

  @override
  Widget build(BuildContext context) {
    if (_exiting) {
      // 直接返回空widget，彻底无感
      return const SizedBox.shrink();
    }
    return Stack(
      children: [
        if (_showPlayer && _controller != null)
          VlcPlayerWithControls(
            controller: _controller!, // 此时肯定不为null
            title: widget.title,
            showControls: _showControls,
            showBar: _showControls,
            onUserInteraction: () {
              if (!_showControls) setState(() => _showControls = true);
            },
            onRequestHideBar: () {
              if (_showControls) setState(() => _showControls = false);
            },
        ),
        if (_isLoading) _buildLoadingOverlay(),
        if (_hasError) _buildErrorOverlay(),
      ],
    );
  }
  
  Widget _buildLoadingOverlay() {
    return Focus(
      autofocus: true, // 加载界面自动获取焦点以响应按键
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          // 任意按键都将焦点转移到返回按钮
          _backButtonFocus.requestFocus();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Colors.blue, Colors.green],
          ),
        ),
        child: Stack(
          children: [
          // 标题栏
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 153/255.0),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: FocusableGlow(
                        borderRadius: BorderRadius.circular(20),
                        onTap: _onBackPressed,
                        child: Focus(
                          focusNode: _backButtonFocus,
                          onKeyEvent: (node, event) {
                            if (event is KeyDownEvent) {
                              if (event.logicalKey == LogicalKeyboardKey.escape) {
                                _onBackPressed();
                                return KeyEventResult.handled;
                              } else if (event.logicalKey == LogicalKeyboardKey.enter ||
                                         event.logicalKey == LogicalKeyboardKey.select) {
                                _onBackPressed();
                                return KeyEventResult.handled;
                              }
                            }
                            return KeyEventResult.ignored;
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 加载动画
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const SpinKitWave(size: 36, color: Colors.white70),
                Container(
                  padding: const EdgeInsets.all(50),
                  child: const Text(
                    '视频加载中...',
                    style: TextStyle(
                      color: Color.fromARGB(179, 255, 255, 255),
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
  
  Widget _buildErrorOverlay() {
    return Focus(
      autofocus: true, // 错误界面自动获取焦点以响应按键
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          // 任意按键都将焦点转移到重试按钮
          _retryButtonFocus.requestFocus();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Colors.red, Colors.orange],
          ),
        ),
        child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.error_outline, color: Colors.white, size: 60),
          Container(
            padding: const EdgeInsets.all(50),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color.fromARGB(179, 255, 255, 255),
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FocusableGlow(
                borderRadius: BorderRadius.circular(8),
                onTap: _retry,
                child: Focus(
                  focusNode: _retryButtonFocus,
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent) {
                      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                        // 右键移动到返回按钮
                        _backButtonFocus.requestFocus();
                        return KeyEventResult.handled;
                      } else if (event.logicalKey == LogicalKeyboardKey.enter ||
                                 event.logicalKey == LogicalKeyboardKey.select) {
                        _retry();
                        return KeyEventResult.handled;
                      }
                    }
                    return KeyEventResult.ignored;
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 51/255.0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('重新加载', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              FocusableGlow(
                borderRadius: BorderRadius.circular(8),
                onTap: _onBackPressed,
                child: Focus(
                  focusNode: _backButtonFocus,
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent) {
                      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                        // 左键移动到重试按钮
                        _retryButtonFocus.requestFocus();
                        return KeyEventResult.handled;
                      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
                        _onBackPressed();
                        return KeyEventResult.handled;
                      } else if (event.logicalKey == LogicalKeyboardKey.enter ||
                                 event.logicalKey == LogicalKeyboardKey.select) {
                        _onBackPressed();
                        return KeyEventResult.handled;
                      }
                    }
                    return KeyEventResult.ignored;
                  },
                  child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 128/255.0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('返回', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }
}
