import 'package:flutter/material.dart';
import 'dart:io';

/// 智能图片组件，支持AVIF格式和老设备兼容
/// 在不支持AVIF的设备上直接显示占位符，避免解码错误
class SmartImage extends StatefulWidget {
  final String imageUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final int? cacheWidth;
  final int? cacheHeight;
  final Duration fadeDuration;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  const SmartImage({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    this.cacheHeight,
    this.fadeDuration = const Duration(milliseconds: 200),
    this.loadingWidget,
    this.errorWidget,
  });

  @override
  State<SmartImage> createState() => _SmartImageState();
}

class _SmartImageState extends State<SmartImage> {
  bool _hasError = false;
  static bool? _avifSupported;

  @override
  void didUpdateWidget(SmartImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _resetState();
    }
  }

  void _resetState() {
    _hasError = false;
  }

  bool _isAvifImage(String url) {
    return url.toLowerCase().contains('.avif');
  }

  /// 检测AVIF支持能力
  bool _isAvifSupported() {
    if (_avifSupported != null) {
      return _avifSupported!;
    }

    // 基于平台和版本进行简单判断
    if (Platform.isAndroid) {
      // Android 12+ (API 31+) 原生支持AVIF
      // 但老设备即使有flutter_avif也可能有问题，保守处理
      _avifSupported = false; // 暂时禁用AVIF，使用占位符
    } else if (Platform.isIOS) {
      // iOS 16+ 支持AVIF，但老设备可能有问题
      _avifSupported = false; // 暂时禁用AVIF，使用占位符
    } else {
      // 桌面平台可能支持
      _avifSupported = false; // 保守起见先禁用
    }

    return _avifSupported!;
  }

  Widget _buildLoadingWidget() {
    if (widget.loadingWidget != null) {
      return widget.loadingWidget!;
    }
    
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[850],
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF7BB0)),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    if (widget.errorWidget != null) {
      return widget.errorWidget!;
    }
    
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            color: Colors.grey[600],
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            '封面图片',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvifPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[700]!,
            Colors.grey[800]!,
          ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            color: Colors.grey[500],
            size: 28,
          ),
          const SizedBox(height: 6),
          Text(
            'AVIF图片',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
            ),
          ),
          Text(
            '设备不支持',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorWidget();
    }

    // 如果是AVIF图片
    if (_isAvifImage(widget.imageUrl)) {
      // 检查设备是否支持AVIF
      if (!_isAvifSupported()) {
        // 不支持AVIF，直接显示占位符
        return _buildAvifPlaceholder();
      }
      
      // 支持AVIF的设备（目前暂时不会进入这个分支）
      return _buildAvifPlaceholder();
    }

    // 处理非AVIF图片
    return Image.network(
      widget.imageUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      cacheWidth: widget.cacheWidth,
      cacheHeight: widget.cacheHeight,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildLoadingWidget();
      },
      errorBuilder: (context, error, stackTrace) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _hasError = true);
          }
        });
        return _buildErrorWidget();
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: widget.fadeDuration,
          child: child,
        );
      },
    );
  }
}