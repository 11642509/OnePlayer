import '../style/style.dart';
import './video_gesture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:tapped/tapped.dart';
import '../../mock/video.dart'; // 导入 UserVideo 类

///
/// TikTok风格的一个视频页组件，覆盖在video上，提供以下功能：
/// 播放按钮的遮罩
/// 单击事件
/// 点赞事件回调（每次）
/// 长宽比控制
/// 底部padding（用于适配有沉浸式底部状态栏时）
///
class VideoPage extends StatelessWidget {
  final Widget? video;
  final double aspectRatio;
  final String? tag;
  final double bottomPadding;

  final Widget? rightButtonColumn;
  final Widget? userInfoWidget;
  final Widget? bottomWidget;

  final bool hidePauseIcon;
  final bool isPlaying;

  final Function? onAddFavorite;
  final Function? onSingleTap;

  final bool isLoading;
  final UserVideo videoData;
  final bool isLandscape; // 添加横屏状态参数

  const VideoPage({
    super.key,
    this.bottomPadding = 16,
    this.tag,
    this.rightButtonColumn,
    this.userInfoWidget,
    this.bottomWidget,
    this.onAddFavorite,
    this.onSingleTap,
    this.video,
    this.aspectRatio = 9 / 16.0,
    this.hidePauseIcon = false,
    this.isPlaying = false,
    this.isLoading = false,
    required this.videoData,
    this.isLandscape = false, // 默认为竖屏模式
  });

  @override
  Widget build(BuildContext context) {
    // 右边的按钮列表
    Widget rightButtons = rightButtonColumn ?? Container();
    // 用户信息
    Widget userInfo = userInfoWidget ??
        VideoUserInfo(
          bottomPadding: bottomWidget != null ? 40 : bottomPadding, // 增加底部间距，防止进度条遮挡
          desc: videoData.desc,
        );
    // 视频加载的动画
    Widget videoLoading = isLoading ? VideoLoadingPlaceHolder(tag: tag ?? '') : Container();
    // 视频播放页 - 填充整个屏幕，包括状态栏区域
    Widget videoContainer = SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          video ?? Container(color: Colors.black),
          Positioned.fill(
            child: VideoGesture(
              onAddFavorite: onAddFavorite,
              onSingleTap: onSingleTap,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(color: Colors.transparent),
                  ),
                ],
              ),
            ),
          ),
          if (!isPlaying && !hidePauseIcon)
            Tapped(
              onTap: onSingleTap,
              child: Container(
                height: double.infinity,
                width: double.infinity,
                alignment: Alignment.center,
                child: Icon(
                  Icons.play_circle_outline,
                  size: 120,
                  color: Colors.white.withAlpha(102),
                ),
              ),
            ),
        ],
      ),
    );
    
    // B站风格：确保标题和简介显示在上方，进度条在最底部但更贴近内容
    Widget body = Stack(
      children: <Widget>[
        videoContainer,
        videoLoading,
          
        // 右侧按钮 - 位于接近底部，刚好在进度条上方
        Positioned(
          right: 12,
          // 调整到接近底部的位置，只比进度条略高一点
          bottom: 50, // 固定高度，接近进度条上方
          child: rightButtons,
        ),
        
        // 底部用户信息
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 主要内容区域
            Expanded(child: Container()), // 占位，让内容移到底部
            
            // 用户信息
            DefaultTextStyle(
              style: const TextStyle(color: Colors.white),
              child: userInfo,
            ),
            
            // 底部安全区域，避免被进度条遮挡，但减少高度使进度条靠近内容
            SizedBox(height: bottomWidget != null ? (isLandscape ? 20 : 30) : 0), // 横屏模式下减小间距
          ],
        ),
        
        // 进度条区域 - 使用GestureDetector拦截事件
        if (bottomWidget != null)
          Positioned(
            left: 0,
            right: 0,
            // 使用负值进一步下移进度条
            bottom: -8,
            child: SafeArea(
              // 使用GestureDetector包装，拦截可能穿透到视频区域的事件
              child: GestureDetector(
                // 阻止事件冒泡
                behavior: HitTestBehavior.opaque,
                // 拦截触摸事件，防止传递给视频区域
                onTap: () {},
                onDoubleTap: () {},
                child: Container(
                  // 统一横竖屏的内边距
                  padding: const EdgeInsets.symmetric(
                    vertical: 0, // 移除垂直内边距
                    horizontal: 0,
                  ),
                  child: bottomWidget!,
                ),
              ),
            ),
          ),
      ],
    );
    return body;
  }
}

class VideoLoadingPlaceHolder extends StatelessWidget {
  const VideoLoadingPlaceHolder({
    super.key,
    required this.tag,
  });

  final String tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          colors: <Color>[
            Colors.blue,
            Colors.green,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SpinKitWave(
            size: 36,
            color: Colors.white.withAlpha(77),
          ),
          Container(
            padding: const EdgeInsets.all(50),
            child: Text(
              tag,
              style: StandardTextStyle.normalWithOpacity,
            ),
          ),
        ],
      ),
    );
  }
}

class VideoUserInfo extends StatelessWidget {
  final String? desc;

  // final Function onGoodGift;
  const VideoUserInfo({
    super.key,
    required this.bottomPadding,
    // @required this.onGoodGift,
    this.desc,
  });

  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        bottom: bottomPadding,
      ),
      margin: const EdgeInsets.only(right: 80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '@朱二旦的枯燥生活',
            style: StandardTextStyle.big,
          ),
          Container(height: 6),
          Text(
            desc ?? '#原创 有钱人的生活就是这么朴实无华，且枯燥 #短视频',
            style: StandardTextStyle.normal,
          ),
          Container(height: 6),
          Row(
            children: <Widget>[
              const Icon(Icons.music_note, size: 14),
              Expanded(
                child: Text(
                  '朱二旦的枯燥生活创作的原声',
                  maxLines: 9,
                  style: StandardTextStyle.normal,
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
