import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/foundation.dart';

class VideoProgressBar extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;
  final bool isDragging;
  final ValueChanged<bool>? onDragStatusChanged;

  const VideoProgressBar({
    Key? key,
    required this.position,
    required this.duration,
    required this.onSeek,
    this.isDragging = false,
    this.onDragStatusChanged,
  }) : super(key: key);

  @override
  State<VideoProgressBar> createState() => _VideoProgressBarState();
}

class _VideoProgressBarState extends State<VideoProgressBar> with SingleTickerProviderStateMixin {
  double? _dragValue;
  bool _dragging = false;
  bool _seeking = false; // 添加标志，指示是否正在执行seek操作
  
  // 使用固定的高度和半径，避免突变
  static const double barHeight = 2.5;
  static const double thumbRadius = 4.0;
  
  // 进度条实际宽度引用
  final GlobalKey _progressBarKey = GlobalKey();
  
  // 防抖变量
  DateTime? _lastTapTime;
  static const Duration _minTapInterval = Duration(milliseconds: 300);

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  // 计算显示位置，确保UI流畅
  Duration _displayPosition() {
    if (_dragValue != null) {
      return Duration(milliseconds: _dragValue!.toInt());
    }
    return widget.position;
  }
  
  // 计算进度条实际宽度
  double _getProgressBarWidth() {
    try {
      final RenderBox? box = _progressBarKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        return box.size.width;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting progress bar width: $e');
      }
    }
    return 100; // 默认宽度
  }
  
  // 根据点击位置计算进度值
  double _calculateValueFromPosition(Offset localPosition) {
    try {
      final double progressBarWidth = _getProgressBarWidth();
      // 确保位置在有效范围内
      double localX = localPosition.dx;
      if (localX < 0) localX = 0;
      if (localX > progressBarWidth) localX = progressBarWidth;
      
      // 计算百分比
      final double percentage = localX / progressBarWidth;
      final double total = widget.duration.inMilliseconds > 0 ? widget.duration.inMilliseconds.toDouble() : 1.0;
      return percentage * total;
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating value from position: $e');
      }
      // 出错时返回当前位置
      return widget.position.inMilliseconds.toDouble();
    }
  }
  
  // 安全执行seek操作
  void _safeSeek(Duration duration) {
    try {
      if (!mounted) return;
      // 使用Future.microtask确保在下一个事件循环中执行，避免连续setState
      Future.microtask(() {
        try {
          // 将操作传递给父组件
          widget.onSeek(duration);
        } catch (e) {
          if (kDebugMode) {
            print('Error during seek operation: $e');
          }
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error in _safeSeek: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double total = 1.0;
    double value = 0.0;
    
    try {
      total = widget.duration.inMilliseconds > 0 ? widget.duration.inMilliseconds.toDouble() : 1.0;
      // 使用当前拖动值或实际位置
      value = _dragValue ?? widget.position.inMilliseconds.toDouble();
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating progress values: $e');
      }
    }
    
    // B站粉色
    const Color bilibiliPink = Color(0xFFFF6699);
    
    // 显示位置
    final displayPosition = _displayPosition();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 5), // 向上移动一些
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          children: [
            // 左侧时间
            Text(
              _formatDuration(displayPosition), 
              style: const TextStyle(
                color: Colors.white, 
                fontSize: 10,
                fontWeight: FontWeight.w400,
                shadows: [
                  Shadow(
                    offset: Offset(1.0, 1.0),
                    blurRadius: 2.0,
                    color: Colors.black54,
                  ),
                ],
              )
            ),
            const SizedBox(width: 8),
            // 进度条占据中间空间
            Expanded(
              child: Stack(
                key: _progressBarKey,
                alignment: Alignment.center,
                children: [
                  // 自定义进度条背景
                  Container(
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(barHeight / 2),
                    ),
                  ),
                  // 自定义活动进度条
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: total > 0 ? (value / total).clamp(0.0, 1.0) : 0,
                      child: Container(
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: bilibiliPink,
                          borderRadius: BorderRadius.circular(barHeight / 2),
                        ),
                      ),
                    ),
                  ),
                  // 触摸区域
                  GestureDetector(
                    onHorizontalDragStart: (details) {
                      try {
                        if (_seeking) return;
                        
                        setState(() {
                          _dragging = true;
                          // 计算初始拖动位置
                          _dragValue = _calculateValueFromPosition(details.localPosition);
                        });
                        
                        // 通知父组件
                        widget.onDragStatusChanged?.call(true);
                      } catch (e) {
                        if (kDebugMode) {
                          print('Error in drag start: $e');
                        }
                      }
                    },
                    onHorizontalDragUpdate: (details) {
                      try {
                        if (_seeking) return;
                        
                        setState(() {
                          // 更新拖动位置
                          _dragValue = _calculateValueFromPosition(details.localPosition);
                        });
                      } catch (e) {
                        if (kDebugMode) {
                          print('Error in drag update: $e');
                        }
                      }
                    },
                    onHorizontalDragEnd: (details) {
                      try {
                        if (_seeking) return;
                        
                        if (_dragValue != null) {
                          final seekMs = _dragValue!.toInt();
                          _safeSeek(Duration(milliseconds: seekMs));
                        }
                        
                        setState(() {
                          _dragging = false;
                          _dragValue = null;
                        });
                        
                        // 通知父组件
                        widget.onDragStatusChanged?.call(false);
                      } catch (e) {
                        if (kDebugMode) {
                          print('Error in drag end: $e');
                        }
                        
                        // 确保状态重置
                        setState(() {
                          _dragging = false;
                          _dragValue = null;
                        });
                        
                        widget.onDragStatusChanged?.call(false);
                      }
                    },
                    onTapDown: (details) {
                      try {
                        if (_seeking) return;
                        
                        // 防抖处理，避免短时间内多次点击
                        final now = DateTime.now();
                        if (_lastTapTime != null && 
                            now.difference(_lastTapTime!) < _minTapInterval) {
                          return;
                        }
                        _lastTapTime = now;
                        
                        // 设置状态标识
                        _seeking = true;
                        
                        // 计算点击位置并准备UI状态
                        final double newValue = _calculateValueFromPosition(details.localPosition);
                        final int seekMs = newValue.toInt();
                        
                        setState(() {
                          _dragValue = newValue;
                        });
                        
                        // 使用异步处理seek操作，避免阻塞UI
                        Future.microtask(() {
                          try {
                            // 执行seek并通知父组件
                            _safeSeek(Duration(milliseconds: seekMs));
                            
                            // 简短延迟后重置状态
                            Future.delayed(const Duration(milliseconds: 200), () {
                              if (mounted) {
                                setState(() {
                                  _dragValue = null;
                                  _seeking = false;
                                });
                              }
                            });
                          } catch (e) {
                            if (kDebugMode) {
                              print('Error in tap seek: $e');
                            }
                            
                            // 出错时也要重置状态
                            if (mounted) {
                              setState(() {
                                _dragValue = null;
                                _seeking = false;
                              });
                            }
                          }
                        });
                      } catch (e) {
                        if (kDebugMode) {
                          print('Error in tap down: $e');
                        }
                        
                        // 确保重置状态
                        _seeking = false;
                      }
                    },
                    // 扩大触摸区域
                    child: Container(
                      height: 20, // 减小高度，避免遮挡文字
                      color: Colors.transparent,
                    ),
                  ),
                  // 滑块
                  if (_dragging || widget.isDragging)
                    Positioned(
                      left: total > 0 ? ((value / total).clamp(0.0, 1.0) * _getProgressBarWidth()) - thumbRadius : 0,
                      child: Container(
                        width: thumbRadius * 2,
                        height: thumbRadius * 2,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 2,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 右侧总时长
            Text(
              _formatDuration(widget.duration), 
              style: const TextStyle(
                color: Colors.white, 
                fontSize: 10,
                fontWeight: FontWeight.w400,
                shadows: [
                  Shadow(
                    offset: Offset(1.0, 1.0),
                    blurRadius: 2.0,
                    color: Colors.black54,
                  ),
                ],
              )
            ),
          ],
        ),
      ),
    );
  }
} 