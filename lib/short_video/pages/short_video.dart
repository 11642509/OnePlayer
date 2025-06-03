import '../mock/video.dart';
import '../views/video_page.dart';
import '../views/video_side_bar.dart';
import '../views/video_comment.dart';
import '../controller/video_list_controller.dart';
import 'package:flutter/material.dart';
import 'package:safemap/safemap.dart';
import 'package:video_player/video_player.dart';
import '../video_players/video_player_impl/vp_video_controller.dart';


class ShortVideoPage extends StatefulWidget {
  final Function? onUserTap;
  final Function? onCommentTap;
  final Function? onShareTap;
  final Function? onFavoriteTap;
  final bool showHeader;
  final bool showBottomBar;

  const ShortVideoPage({
    super.key,
    this.onUserTap,
    this.onCommentTap,
    this.onShareTap,
    this.onFavoriteTap,
    this.showHeader = true,
    this.showBottomBar = true,
  });

  @override
  ShortVideoPageState createState() => ShortVideoPageState();
}

class ShortVideoPageState extends State<ShortVideoPage> with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  final VideoListController _videoListController = VideoListController();
  Map<int, bool> favoriteMap = {};
  List<UserVideo> videoDataList = [];

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state != AppLifecycleState.resumed) {
      _videoListController.currentPlayer.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _videoListController.currentPlayer.pause();
    super.dispose();
  }

  @override
  void initState() {
    videoDataList = UserVideo.fetchVideo();
    WidgetsBinding.instance.addObserver(this);
    _videoListController.init(
      pageController: _pageController,
      initialList: videoDataList
          .map(
            (e) => VPVideoController(
              videoInfo: e,
              builder: () => VideoPlayerController.networkUrl(Uri.parse(e.url)),
            ),
          )
          .toList(),
      videoProvider: (int index, List<VideoController<dynamic>> list) async {
        return videoDataList
            .map(
              (e) => VPVideoController(
                videoInfo: e,
                builder: () =>
                    VideoPlayerController.networkUrl(Uri.parse(e.url)),
              ),
            )
            .toList();
      },
    );
    _videoListController.addListener(() {
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          PageView.builder(
            key: Key('short_video'),
            physics: ClampingScrollPhysics(),
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _videoListController.videoCount,
            itemBuilder: (context, i) {
              bool isF = SafeMap(favoriteMap)[i].boolean;
              var player = _videoListController.playerOfIndex(i)!;
              var data = player.videoData!;
              
              Widget buttons = VideoButtonColumn(
                isFavorite: isF,
                onAvatar: widget.onUserTap,
                onFavorite: () {
                  setState(() {
                    favoriteMap[i] = !isF;
                  });
                  widget.onFavoriteTap?.call();
                },
                onComment: () {
                  showModalBottomSheet(
                    backgroundColor: Colors.transparent,
                    context: context,
                    builder: (BuildContext context) =>
                        CommentBottomSheet(),
                  );
                  widget.onCommentTap?.call();
                },
                onShare: widget.onShareTap,
              );

              Widget currentVideo = Center(
                child: AspectRatio(
                  aspectRatio: player.controller.value.aspectRatio,
                  child: VideoPlayer(player.controller),
                ),
              );

              currentVideo = VideoPage(
                hidePauseIcon: !player.showPauseIcon.value,
                aspectRatio: 9 / 16.0,
                key: Key('${data.url}$i'),
                tag: data.url,
                bottomPadding: 16.0,
                onSingleTap: () async {
                  if (player.controller.value.isPlaying) {
                    player.showPauseIcon.value = true;
                    await player.pause();
                  } else {
                    player.showPauseIcon.value = false;
                    await player.play();
                  }
                },
                onAddFavorite: () {
                  setState(() {
                    favoriteMap[i] = true;
                  });
                  widget.onFavoriteTap?.call();
                },
                rightButtonColumn: buttons,
                video: currentVideo,
                isLoading: !player.prepared,
                videoData: data,
              );
              return currentVideo;
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    onPressed: () {
                      _videoListController.currentPlayer.pause();
                      Navigator.pop(context);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.search, color: Colors.white),
                    onPressed: () {
                      // 实现搜索功能
                    },
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: double.infinity,
            // ... existing code ...
          ),
        ],
      ),
    );
  }
}
