import 'package:flutter/material.dart';
import 'dart:io';

/// 字体管理工具类 - 参考主流视频app的字体设计
class AppTypography {
  
  /// 获取最佳系统字体 - 基于平台和主流app使用习惯
  static String? get systemFont {
    if (Platform.isIOS) {
      // iOS: 苹方字体 - B站iOS版、腾讯视频等主流app首选
      return 'PingFang SC';
    } else if (Platform.isAndroid) {
      // Android: 思源黑体 - 开源免费，B站安卓版等广泛使用
      return 'Source Han Sans SC';
    } else if (Platform.isMacOS) {
      // macOS: 苹方字体
      return 'PingFang SC';
    } else if (Platform.isWindows) {
      // Windows: 微软雅黑UI版本
      return 'Microsoft YaHei UI';
    }
    return null;
  }

  /// 字体回退方案 - 确保在字体不可用时的优雅降级
  static List<String> get fontFallbacks {
    if (Platform.isIOS || Platform.isMacOS) {
      return [
        'PingFang SC',      // 苹方 - 首选
        'Helvetica Neue',   // iOS系统字体
        'Arial',            // 通用后备
        'sans-serif',       // 系统默认
      ];
    } else if (Platform.isAndroid) {
      return [
        'Source Han Sans SC',  // 思源黑体 - 首选
        'Noto Sans CJK SC',    // Google Noto字体
        'Roboto',              // Android系统字体
        'Arial',               // 通用后备
        'sans-serif',          // 系统默认
      ];
    } else {
      return [
        'Microsoft YaHei UI',  // 微软雅黑UI
        'Microsoft YaHei',     // 微软雅黑
        'Segoe UI',            // Windows系统字体
        'Arial',               // 通用后备
        'sans-serif',          // 系统默认
      ];
    }
  }

  /// 创建文本样式 - 统一的字体样式创建方法
  static TextStyle createTextStyle({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w400,
    Color color = Colors.white,
    double? height,
    double? letterSpacing,
    TextDecoration decoration = TextDecoration.none,
  }) {
    return TextStyle(
      fontFamily: systemFont,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
      fontFamilyFallback: fontFallbacks,
    );
  }

  // 预定义样式 - 参考主流视频app的文字层级

  /// 显示标题 - 用于splash页面、空状态页面标题
  static TextStyle get displayLarge => createTextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static TextStyle get displayMedium => createTextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.3,
  );

  /// 页面标题 - 用于页面主标题、导航标题
  static TextStyle get headlineLarge => createTextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: -0.2,
  );

  static TextStyle get headlineMedium => createTextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0,
  );

  /// 区块标题 - 用于卡片标题、列表标题
  static TextStyle get titleLarge => createTextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0,
  );

  static TextStyle get titleMedium => createTextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static TextStyle get titleSmall => createTextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
  );

  /// 正文内容 - 用于描述、内容文本
  static TextStyle get bodyLarge => createTextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.15,
  );

  static TextStyle get bodyMedium => createTextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.25,
  );

  static TextStyle get bodySmall => createTextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.4,
    color: const Color(0xB3FFFFFF), // 70% 透明度
  );

  /// 标签文本 - 用于按钮、标签、导航
  static TextStyle get labelLarge => createTextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static TextStyle get labelMedium => createTextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.5,
  );

  static TextStyle get labelSmall => createTextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.5,
    color: const Color(0xB3FFFFFF), // 70% 透明度
  );

  /// 特殊用途样式

  /// 导航标签 - 底部导航、标签页
  static TextStyle get navigationLabel => createTextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 0.3,
  );

  /// 视频标题 - 视频卡片标题
  static TextStyle get videoTitle => createTextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
  );

  /// 视频描述 - 视频详情描述
  static TextStyle get videoDescription => createTextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.25,
    color: const Color(0xE6FFFFFF), // 90% 透明度
  );

  /// 视频元数据 - 播放量、时长、发布时间
  static TextStyle get videoMetadata => createTextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.3,
    letterSpacing: 0.3,
    color: const Color(0xB3FFFFFF), // 70% 透明度
  );

  /// 弹幕样式 - 视频播放器弹幕
  static TextStyle get danmaku => createTextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 0.1,
  );

  /// 按钮文字 - 各种按钮的文字样式
  static TextStyle get buttonText => createTextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
  );

  /// 获取颜色变体 - 在现有样式基础上改变颜色
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// 获取字重变体 - 在现有样式基础上改变字重
  static TextStyle withWeight(TextStyle style, FontWeight fontWeight) {
    return style.copyWith(fontWeight: fontWeight);
  }

  /// 获取字号变体 - 在现有样式基础上改变字号
  static TextStyle withSize(TextStyle style, double fontSize) {
    return style.copyWith(fontSize: fontSize);
  }
}

/// 字体配置常量
class FontConstants {
  // 字体大小常量
  static const double displayLarge = 32.0;
  static const double displayMedium = 28.0;
  static const double headlineLarge = 24.0;
  static const double headlineMedium = 20.0;
  static const double titleLarge = 18.0;
  static const double titleMedium = 16.0;
  static const double titleSmall = 14.0;
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;
  static const double labelLarge = 14.0;
  static const double labelMedium = 12.0;
  static const double labelSmall = 11.0;

  // 字体权重常量
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  // 行高常量
  static const double tightLineHeight = 1.2;
  static const double normalLineHeight = 1.4;
  static const double relaxedLineHeight = 1.5;

  // 字间距常量
  static const double tightSpacing = -0.5;
  static const double normalSpacing = 0.0;
  static const double wideSpacing = 0.25;
  static const double extraWideSpacing = 0.5;
}