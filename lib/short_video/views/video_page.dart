import '../style/style.dart';
import './video_gesture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:tapped/tapped.dart';
import '../mock/video.dart'; // 导入 UserVideo 类

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

  final bool hidePauseIcon;
  final bool isPlaying;

  final Function? onAddFavorite;
  final Function? onSingleTap;

  final bool isLoading;
  final UserVideo videoData;

  const VideoPage({
    super.key,
    this.bottomPadding = 16,
    this.tag,
    this.rightButtonColumn,
    this.userInfoWidget,
    this.onAddFavorite,
    this.onSingleTap,
    this.video,
    this.aspectRatio = 9 / 16.0,
    this.hidePauseIcon = false,
    this.isPlaying = false,
    this.isLoading = false,
    required this.videoData,
  });

  @override
  Widget build(BuildContext context) {
    // 右边的按钮列表
    Widget rightButtons = rightButtonColumn ?? Container();
    // 用户信息
    Widget userInfo = userInfoWidget ??
        VideoUserInfo(
          bottomPadding: bottomPadding,
          desc: videoData.desc,
        );
    // 视频加载的动画
    Widget videoLoading = isLoading ? VideoLoadingPlaceHolder(tag: tag ?? '') : Container();
    // 视频播放页
    Widget videoContainer = Stack(
      children: <Widget>[
        Container(
          height: double.infinity,
          width: double.infinity,
          color: Colors.black,
          alignment: Alignment.center,
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: video,
          ),
        ),
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
                color: Colors.white.withAlpha((255 * 0.4).round()),
              ),
            ),
          ),
      ],
    );
    Widget body = Stack(
      children: <Widget>[
        videoContainer,
        videoLoading,
        Container(
          height: double.infinity,
          width: double.infinity,
          alignment: Alignment.bottomRight,
          child: rightButtons,
        ),
        Container(
          height: double.infinity,
          width: double.infinity,
          alignment: Alignment.bottomLeft,
          child: DefaultTextStyle(
            style: const TextStyle(color: Colors.white),
            child: userInfo,
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
      decoration: BoxDecoration(
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
            color: Colors.white.withAlpha((255 * 0.3).round()),
          ),
          Container(
            padding: EdgeInsets.all(50),
            child: Text(
              tag,
              style: StandardTextStyle.normalWithOpacity, // ignore: deprecated_member_use
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
      margin: EdgeInsets.only(right: 80),
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
              Icon(Icons.music_note, size: 14),
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
