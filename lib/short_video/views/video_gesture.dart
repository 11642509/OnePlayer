import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// 视频手势封装
/// 单击：暂停
/// 双击：点赞，双击后再次单击也是增加点赞爱心
class VideoGesture extends StatefulWidget {
  const VideoGesture({
    super.key,
    required this.child,
    this.onAddFavorite,
    this.onSingleTap,
  });

  final Function? onAddFavorite;
  final Function? onSingleTap;
  final Widget child;

  @override
  VideoGestureState createState() => VideoGestureState();
}

class VideoGestureState extends State<VideoGesture> {
  final GlobalKey _key = GlobalKey();

  // 内部转换坐标点
  Offset _p(Offset p) {
    try {
      RenderBox? getBox = _key.currentContext?.findRenderObject() as RenderBox?;
      if (getBox == null) return Offset.zero;
      return getBox.globalToLocal(p);
    } catch (e) {
      if (kDebugMode) {
        print('Error converting point: $e');
      }
      return Offset.zero;
    }
  }

  // 使用带有ID的图标对象，便于追踪和移除
  final List<HeartIcon> _hearts = [];
  // 限制同时显示的图标数量
  static const int maxIcons = 5;
  int _nextIconId = 0;

  bool canAddFavorite = false;
  bool justAddFavorite = false;
  Timer? timer;
  
  // 添加防抖，防止快速点击导致卡死
  DateTime? _lastTapTime;
  static const Duration _minTapInterval = Duration(milliseconds: 300);
  
  // 添加标志位，防止重复处理
  bool _processingTap = false;

  @override
  void dispose() {
    timer?.cancel();
    // 清空心形列表，避免内存泄漏
    _hearts.clear();
    super.dispose();
  }

  // 安全地添加图标
  void _safeAddIcon(Offset position) {
    try {
      if (!mounted) return;
      
      setState(() {
        // 限制图标数量，防止内存问题
        while (_hearts.length >= maxIcons) {
          _hearts.removeAt(0);
        }
        
        // 检查位置是否在合理范围内
        double screenHeight = MediaQuery.of(context).size.height;
        double screenWidth = MediaQuery.of(context).size.width;
        
        double x = position.dx;
        double y = position.dy;
        
        // 确保坐标在屏幕范围内
        if (x < 0) x = 20;
        if (x > screenWidth) x = screenWidth - 20;
        if (y < 0) y = 20;
        if (y > screenHeight) y = screenHeight - 20;
        
        // 使用唯一ID创建图标
        _hearts.add(HeartIcon(id: _nextIconId++, position: Offset(x, y)));
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error adding icon: $e');
      }
    }
  }
  
  // 移除图标
  void _removeHeart(int id) {
    try {
      if (!mounted) return;
      
      setState(() {
        _hearts.removeWhere((heart) => heart.id == id);
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error removing heart: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget iconStack = Container();
    try {
      iconStack = Stack(
        children: _hearts.map<Widget>((heart) {
          return FavoriteAnimationIcon(
            key: Key('heart_${heart.id}'),
            id: heart.id,
            position: heart.position,
            onAnimationComplete: (id) {
              _removeHeart(id);
            },
          );
        }).toList(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error building heart icons: $e');
      }
      // 出错时清空所有心形图标，防止持续崩溃
      _hearts.clear();
    }
    
    return GestureDetector(
      key: _key,
      onTapDown: (detail) {
        // 防抖处理，避免快速连续点击
        final now = DateTime.now();
        if (_lastTapTime != null && 
            now.difference(_lastTapTime!) < _minTapInterval) {
          return;
        }
        _lastTapTime = now;
        
        // 防止重复处理
        if (_processingTap) return;
        _processingTap = true;
        
        try {
          if (!mounted) return;
          
          if (canAddFavorite) {
            final position = _p(detail.globalPosition);
            _safeAddIcon(position);
            
            // 使用Future延迟调用onAddFavorite，防止UI阻塞
            Future.microtask(() {
              try {
                if (mounted) {
                  widget.onAddFavorite?.call();
                }
              } catch (e) {
                if (kDebugMode) {
                  print('Error calling onAddFavorite: $e');
                }
              }
            });
            
            justAddFavorite = true;
          } else {
            justAddFavorite = false;
          }
          
        } catch (e) {
          if (kDebugMode) {
            print('Error in onTapDown: $e');
          }
        } finally {
          _processingTap = false;
        }
      },
      onTapUp: (detail) {
        try {
          timer?.cancel();
          var delay = canAddFavorite ? 1200 : 600;
          timer = Timer(Duration(milliseconds: delay), () {
            canAddFavorite = false;
            timer = null;
            if (!justAddFavorite && mounted) {
              // 使用Future.microtask避免长时间运行的操作阻塞UI线程
              Future.microtask(() {
                try {
                  if (mounted) {
                    widget.onSingleTap?.call();
                  }
                } catch (e) {
                  if (kDebugMode) {
                    print('Error in onSingleTap: $e');
                  }
                }
              });
            }
          });
          canAddFavorite = true;
        } catch (e) {
          if (kDebugMode) {
            print('Error in onTapUp: $e');
          }
        }
      },
      onTapCancel: () {
        // 确保取消时不会有残留状态
        _lastTapTime = null;
        _processingTap = false;
      },
      child: Stack(
        children: <Widget>[
          widget.child,
          iconStack,
        ],
      ),
    );
  }
}

// 带有ID的心形图标数据类
class HeartIcon {
  final int id;
  final Offset position;
  
  HeartIcon({required this.id, required this.position});
}

class FavoriteAnimationIcon extends StatefulWidget {
  final int id;
  final Offset? position;
  final double size;
  final Function(int)? onAnimationComplete;

  const FavoriteAnimationIcon({
    super.key,
    required this.id,
    this.onAnimationComplete,
    this.position,
    this.size = 100,
  });

  @override
  FavoriteAnimationIconState createState() => FavoriteAnimationIconState();
}

class FavoriteAnimationIconState extends State<FavoriteAnimationIcon> with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  bool _disposed = false;
  bool _animationCompleted = false;

  @override
  void dispose() {
    _disposed = true;
    // 确保动画停止
    try {
      _animationController?.stop();
      _animationController?.dispose();
    } catch (e) {
      if (kDebugMode) {
        print('Error disposing animation controller: $e');
      }
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initAnimation();
  }
  
  void _initAnimation() {
    try {
      _animationController = AnimationController(
        lowerBound: 0,
        upperBound: 1,
        duration: const Duration(milliseconds: 1600),
        vsync: this,
      );

      _animationController!.addListener(() {
        if (!_disposed && mounted) {
          setState(() {});
        }
      });
      
      _animationController!.addStatusListener((status) {
        if (status == AnimationStatus.completed && !_animationCompleted) {
          _animationCompleted = true;
          if (!_disposed && mounted) {
            // 使用Future.microtask确保不会在build过程中触发状态更新
            Future.microtask(() {
              // 通知父组件移除此图标
              if (!_disposed && mounted) {
                widget.onAnimationComplete?.call(widget.id);
              }
            });
          }
        }
      });
      
      startAnimation();
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing animation: $e');
      }
    }
  }

  void startAnimation() {
    try {
      if (!_disposed && _animationController != null) {
        _animationController!.forward();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error starting animation: $e');
      }
    }
  }

  double rotate = pi / 10.0 * (2 * Random().nextDouble() - 1);

  double? get value => _animationController?.value;

  double appearDuration = 0.1;
  double dismissDuration = 0.8;

  double get opa {
    if (value == null) return 0;
    if (value! < appearDuration) {
      return 0.99 / appearDuration * value!;
    }
    if (value! < dismissDuration) {
      return 0.99;
    }
    var res = 0.99 - (value! - dismissDuration) / (1 - dismissDuration);
    return res < 0 ? 0 : res;
  }

  double get scale {
    if (value == null) return 1;
    if (value! < appearDuration) {
      return 1 + appearDuration - value!;
    }
    if (value! < dismissDuration) {
      return 1;
    }
    return (value! - dismissDuration) / (1 - dismissDuration) + 1;
  }

  @override
  Widget build(BuildContext context) {
    if (_disposed || widget.position == null) {
      return Container();
    }
    
    try {
      Widget content = Icon(
        Icons.favorite,
        size: widget.size,
        color: Colors.redAccent,
      );
      
      content = ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (Rect bounds) => const RadialGradient(
          center: Alignment(0.66, 0.66),
          colors: [
            Color(0xffEF6F6F),
            Color(0xffF03E3E),
          ],
        ).createShader(bounds),
        child: content,
      );
      
      Widget body = Transform.rotate(
        angle: rotate,
        child: Opacity(
          opacity: opa,
          child: Transform.scale(
            alignment: Alignment.bottomCenter,
            scale: scale,
            child: content,
          ),
        ),
      );
      
      return Positioned(
        left: widget.position!.dx - widget.size / 2,
        top: widget.position!.dy - widget.size / 2,
        child: body,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error building animation: $e');
      }
      return Container();
    }
  }
}
