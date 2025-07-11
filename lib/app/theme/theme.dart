import 'package:flutter/material.dart';
import 'dart:ui';

class AppTheme {
  // 预定义颜色常量
  static const primaryColor = Color(0xFF2196F3);
  static const backgroundColor = Color(0xFF121212);
  static const surfaceColor = Color(0xFF1E1E1E);
  static const cardColor = Color(0xFF242424);

  // 半透明颜色
  static const overlayLight = Color(0x1AFFFFFF); // 10% 白色
  static const overlayMedium = Color(0x4DFFFFFF); // 30% 白色
  static const overlayDark = Color(0x80FFFFFF); // 50% 白色

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    cardColor: cardColor,

    // AppBar 主题
    appBarTheme: const AppBarTheme(
      backgroundColor: surfaceColor,
      elevation: 0,
    ),

    // 卡片主题 - 修复类型不匹配问题
    cardTheme: const CardThemeData(
      color: cardColor,
      elevation: 0,
      margin: EdgeInsets.zero,
    ),

    // 文本主题
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      titleMedium: TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: TextStyle(
        color: Colors.white,
        fontSize: 14,
      ),
      bodySmall: TextStyle(
        color: Color(0xB3FFFFFF), // 70% 白色
        fontSize: 12,
      ),
    ),

    // 图标主题
    iconTheme: const IconThemeData(
      color: Color(0xB3FFFFFF), // 70% 白色
      size: 24,
    ),

    // 分割线主题
    dividerTheme: const DividerThemeData(
      color: Color(0x1AFFFFFF), // 10% 白色
      thickness: 1,
      space: 1,
    ),
  );
}

class FrostedBackground extends StatelessWidget {
  final Widget child;

  const FrostedBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 背景颜色
        Container(
          color: Colors.black, // 改为纯黑色背景
        ),

        // 毛玻璃效果
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: const Color(0x1AFFFFFF),
          ),
        ),

        // 内容
        child,
      ],
    );
  }
}
