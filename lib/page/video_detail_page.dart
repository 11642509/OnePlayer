import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../app/config.dart';
import '../app/data_source.dart';
import '../player/vlc_player_page.dart';
import '../player/video_player_page.dart';
import 'package:flutter/foundation.dart';

class VideoDetailPage extends StatefulWidget {
  final String videoId;
  
  const VideoDetailPage({
    super.key,
    required this.videoId,
  });

  @override
  State<VideoDetailPage> createState() => _VideoDetailPageState();
}

class _VideoDetailPageState extends State<VideoDetailPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _videoDetail;
  String? _errorMessage;
  String _currentPlaySource = '';
  final DataSource _dataSource = DataSource();
  
  @override
  void initState() {
    super.initState();
    _fetchVideoDetail();
  }
  
  Future<void> _fetchVideoDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final url = '${AppConfig.apiBaseUrl}/api/v1/bilibili?ids=${widget.videoId}';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 0 && data['list'] != null && data['list'].isNotEmpty) {
          setState(() {
            _videoDetail = data['list'][0];
            _isLoading = false;
            
            // 解析播放源
            final playFrom = _videoDetail!['vod_play_from']?.toString().split('\$\$\$') ?? [];
            
            // 查找第一个非"相关"的播放源
            String defaultSource = '';
            for (final source in playFrom) {
              if (source != '相关') {
                defaultSource = source;
                break;
              }
            }
            
            // 如果没有找到非"相关"的播放源，则使用第一个播放源（可能是"相关"）
            _currentPlaySource = defaultSource.isNotEmpty ? defaultSource : (playFrom.isNotEmpty ? playFrom.first : '');
            
            if (kDebugMode) {
              print('设置默认播放源: $_currentPlaySource');
              print('所有播放源: $playFrom');
            }
          });
        } else {
          setState(() {
            _errorMessage = '获取视频详情失败: ${data['message'] ?? '未知错误'}';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = '网络请求失败，状态码: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('获取视频详情失败: $e');
      }
      setState(() {
        _errorMessage = '发生错误: $e';
        _isLoading = false;
      });
    }
  }

  // 播放视频
  Future<void> _playVideo(String episodeUrl, String episodeName, {String? playSource}) async {
    final source = playSource ?? _currentPlaySource;
    if (_videoDetail == null || source.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('无法播放视频，缺少必要信息'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // 获取视频播放地址
      final playConfig = await _dataSource.fetchVideoPlayUrl(
        episodeUrl,
        source,
      );

      if (!mounted) return;

      if (playConfig.url.isNotEmpty) {
        final String title = '${_videoDetail!['vod_name']} - $episodeName';

        // 根据AppConfig中的设置选择播放器内核
        if (AppConfig.currentPlayerKernel == PlayerKernel.vlc) {
          // 使用 VLC 播放器
          if (kDebugMode) {
            print('使用VLC内核播放: ${playConfig.url}');
          }
          if (!mounted) return;
          Navigator.push(
            context,
            FadeRoute(page: VlcPlayerPage(
              playConfig: playConfig,
              title: title,
            )),
          );
        } else {
          // 使用 video_player 播放器
          if (kDebugMode) {
            print('使用video_player内核播放: ${playConfig.url}');
          }
          if (!mounted) return;
          Navigator.push(
            context,
            FadeRoute(page: SingleVideoTabPage(
              playConfig: playConfig,
              title: title,
            )),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('获取播放地址失败: 返回的URL为空'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('获取播放地址失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isPortrait = constraints.maxHeight > constraints.maxWidth;
        final backgroundColor = isPortrait ? const Color(0xFFF6F7F8) : Colors.black;
        final textColor = isPortrait ? Colors.black : Colors.white;

        return Scaffold(
          backgroundColor: backgroundColor,
          extendBodyBehindAppBar: true,
          appBar: null, // 移除AppBar
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFFF7BB0),
                  ),
                )
              : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : _buildDetailContent(textColor, isPortrait),
        );
      },
    );
  }
  
  Widget _buildDetailContent(Color textColor, bool isPortrait) {
    if (_videoDetail == null) {
      return Center(
        child: Text(
          '没有找到视频信息',
          style: TextStyle(color: textColor, fontSize: 16),
        ),
      );
    }
    
    // 解析播放源和播放地址
    final playFrom = _videoDetail!['vod_play_from']?.toString().split(r'$$$') ?? [];
    final playUrl = _videoDetail!['vod_play_url']?.toString().split(r'$$$') ?? [];
    
    // 将播放源和地址组合成Map
    final Map<String, List<Map<String, String>>> playOptions = {};
    for (int i = 0; i < playFrom.length && i < playUrl.length; i++) {
      final source = playFrom[i];
      final urls = playUrl[i].split('#');
      
      final List<Map<String, String>> episodes = [];
      for (final url in urls) {
        final parts = url.split('\$');
        if (parts.length >= 2) {
          episodes.add({'name': parts[0], 'url': parts[1]});
        }
      }
      playOptions[source] = episodes;
    }
    
    // 分离播放源和相关推荐
    final List<String> allPlaySources = playFrom;
    
    final horizontalPadding = isPortrait ? 16.0 : 30.0;
    
    // 统一使用SingleChildScrollView和Column，解决横屏割裂感
    return Stack( // 将内容包裹在Stack中
      children: [
        SingleChildScrollView(
          key: PageStorageKey(widget.videoId),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 全新的Hero Section
              _buildHeroSection(isPortrait),
              
              // 减小竖屏和横屏模式下的间距
              SizedBox(height: isPortrait ? 24 : 12),

              // 2. 简介区域 - 横屏模式下可选显示
              if (_videoDetail!['vod_content'] != null && _videoDetail!['vod_content'].toString().isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: _buildDescriptionSection(textColor, isPortrait),
                ),
              
              // 减小竖屏和横屏模式下的间距
              SizedBox(height: isPortrait ? 24 : 12),

              // 3. 播放列表区域
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (allPlaySources.isNotEmpty)
                      _buildPlaySourceSelector(allPlaySources, textColor, isPortrait),
                    
                    if (_currentPlaySource.isNotEmpty && playOptions.containsKey(_currentPlaySource) && playOptions[_currentPlaySource]!.isNotEmpty) ...[
                      const SizedBox(height: 12), // 减小间距
                      _buildTiledPlayList(playOptions[_currentPlaySource]!, textColor, isPortrait: isPortrait),
                    ],
                  ],
                ),
              ),

              // 减小底部间距
              SizedBox(height: isPortrait ? 32 : 16),
            ],
          ),
        ),
        // 将返回按钮作为独立的层放置在顶部，并使用动画平滑过渡
        AnimatedPositioned(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          top: MediaQuery.of(context).padding.top,
          left: 10,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
            splashColor: Colors.transparent,
            highlightColor: Colors.white.withAlpha(51),
          ),
        ),
      ],
    );
  }

  // 构建竖屏布局 - 此方法已被移除
  /*
  Widget _buildPortraitLayout(...) { ... }
  */

  // 构建横屏布局 - 此方法将被移除
  /*
  Widget _buildLandscapeLayout(...) { ... }
  */
  
  // 为横屏构建平铺的剧集列表
  Widget _buildTiledPlayList(List<Map<String, String>> episodes, Color textColor, {bool isPortrait = false}) {
    // 竖屏时使用更紧凑、更适合竖向浏览的GridView
    if (isPortrait) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: episodes.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          childAspectRatio: 1.5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemBuilder: (context, index) {
          final episode = episodes[index];
          return MouseRegion(
            cursor: SystemMouseCursors.click, // 设置鼠标指针为点击样式
            child: InkWell(
              onTap: () {
                if (episode['url'] != null && episode['name'] != null) {
                  _playVideo(episode['url']!, episode['name']!);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text(
                      episode['name'] ?? '未知',
                      style: TextStyle(
                        color: textColor, // 将使用黑色
                        fontSize: 13,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    // 横屏时，维持原有为深色背景设计的Wrap布局
    return Wrap(
      spacing: 12.0,
      runSpacing: 12.0,
      children: episodes.map((episode) {
        return MouseRegion(
          cursor: SystemMouseCursors.click, // 设置鼠标指针为点击样式
          child: InkWell(
            onTap: () {
              if (episode['url'] != null && episode['name'] != null) {
                _playVideo(episode['url']!, episode['name']!);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 64, // 固定高度以容纳两行文字
              width: 120, // 固定宽度
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                // 统一使用深色主题下的样式
                color: Colors.grey[900]?.withAlpha(204),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[800]!, width: 1),
              ),
              child: Center(
                child: Text(
                  episode['name'] ?? '未知',
                  style: TextStyle(
                    color: textColor.withAlpha(230), // 将使用白色
                    fontSize: 14,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
  
  // 构建封面英雄区域
  Widget _buildHeroSection(bool isPortrait) {
    final coverUrl = _videoDetail!['vod_pic'] ?? '';
    // 适配横竖屏高度 - 减小横屏模式下的高度
    final double heroHeight = isPortrait ? 300 : 250; // 从350减小到250
    final String title = _videoDetail!['vod_name'] ?? '未知标题';
    final String? type = _videoDetail!['type_name'];
    final String? year = _videoDetail!['vod_year'];
    final String? area = _videoDetail!['vod_area'];
    final String? remarks = _videoDetail!['vod_remarks'];
    final String? score = _videoDetail!['vod_score'];
    final String? actors = _videoDetail!['vod_actor'];
    final String? director = _videoDetail!['vod_director'];

    return Stack(
      children: [
        // 背景大图 + 模糊
        SizedBox(
          height: heroHeight,
          width: double.infinity,
          child: Image.network(
            coverUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[900]),
          ),
        ),
        // 底部渐变遮罩
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: heroHeight * 0.8, // 渐变范围更大，确保文字清晰
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withAlpha(204),
                  Colors.black,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        // 将主要信息内容通过Positioned固定在底部，彻底避免因状态栏高度变化引起的跳动
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Padding(
            padding: EdgeInsets.only(
              left: isPortrait ? 16 : 30, 
              right: isPortrait ? 16 : 30,
              bottom: 16, // 统一底部间距
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 封面小卡片，现在带有播放按钮
                MouseRegion(
                  cursor: SystemMouseCursors.click, // 设置鼠标指针为点击样式
                  child: GestureDetector(
                    onTap: () {
                      // 自动播放第一集
                      final playFrom = _videoDetail!['vod_play_from']?.toString().split(r'$$$') ?? [];
                      final playUrl = _videoDetail!['vod_play_url']?.toString().split(r'$$$') ?? [];
                      final sourceIndex = playFrom.indexOf(_currentPlaySource);
                      if (sourceIndex != -1 && sourceIndex < playUrl.length) {
                        final urls = playUrl[sourceIndex].split('#');
                        if (urls.isNotEmpty) {
                          final parts = urls.first.split('\$');
                          if (parts.length >= 2) {
                            if (!mounted) return;
                            _playVideo(parts[1], parts[0]);
                          } else {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('无法解析播放地址')),
                            );
                          }
                        }
                      }
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          // 横屏模式下稍微减小封面尺寸
                          width: isPortrait ? 100 : 110,
                          height: isPortrait ? 140 : 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(77),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.network(
                            coverUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(color: Colors.grey[800]),
                          ),
                        ),
                        // 播放图标遮罩
                        Container(
                          // 横屏模式下稍微减小封面尺寸
                          width: isPortrait ? 100 : 110,
                          height: isPortrait ? 140 : 150,
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(64),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white.withAlpha(242),
                            size: 60,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                // 右侧主信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // 标题
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isPortrait ? 22 : 24, // 横屏模式下稍微减小字体
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black.withAlpha(179),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8), // 减小间距
                      // 标签/评分/年份/地区/时长
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          if (score != null && score.isNotEmpty)
                            Text(
                              '$score分',
                              style: TextStyle(
                                color: Colors.amber[400],
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          if (year != null && year.isNotEmpty)
                            Text(year, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          if (area != null && area.isNotEmpty)
                            Text(area, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          if (type != null && type.isNotEmpty)
                            Text(type, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          if (remarks != null && remarks.isNotEmpty)
                            Text(remarks, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 8), // 减小间距
                      // 演员/导演信息 - 横屏模式下可以选择性显示
                      if (isPortrait && ((actors != null && actors.isNotEmpty) || (director != null && director.isNotEmpty)))
                        _buildInfoSectionContent(Colors.white, isPortrait: isPortrait),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 构建信息小部件，例如带图标的标签

  // 构建演员、导演等信息的Chip集合
  Widget _buildInfoSectionContent(Color textColor, {required bool isPortrait}) {
    final String? actors = _videoDetail!['vod_actor'];
    final String? director = _videoDetail!['vod_director'];

    // 组合所有贡献者
    final items = [
      if (director != null && director.isNotEmpty) '导演: $director',
      if (actors != null && actors.isNotEmpty) '主演: $actors',
    ];
    
    // 用一个Text组件显示，可横向滚动
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Text(
        items.join(' / '),
        style: const TextStyle(color: Colors.white70, fontSize: 13),
        maxLines: 1,
      ),
    );
  }

  // 构建视频简介区域的内容
  Widget _buildDescriptionSectionContent(Color textColor) {
    // 移除HTML标签并整理文本
    final content = _videoDetail!['vod_content']
            ?.toString()
            .trim()
            .replaceAll(RegExp(r'<[^>]*>'), '') ??
        '暂无简介';
    return Text(
      content,
      style: TextStyle(
        color: textColor.withAlpha(204),
        fontSize: 14,
        height: 1.6,
      ),
    );
  }

  // 构建视频简介区域的容器
  Widget _buildDescriptionSection(Color textColor, bool isPortrait) {
    final horizontalPadding = isPortrait ? 16.0 : 24.0;
    // 横屏模式下使用更紧凑的布局
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '简介',
            style: TextStyle(
              fontSize: isPortrait ? 18 : 16, // 横屏模式下减小字体
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          SizedBox(height: isPortrait ? 12 : 8), // 减小间距
          // 横屏模式下限制简介的行数
          isPortrait 
              ? _buildDescriptionSectionContent(textColor)
              : _buildCompactDescriptionContent(textColor),
        ],
      ),
    );
  }
  
  // 横屏模式下的简洁简介内容
  Widget _buildCompactDescriptionContent(Color textColor) {
    // 移除HTML标签并整理文本
    final content = _videoDetail!['vod_content']
            ?.toString()
            .trim()
            .replaceAll(RegExp(r'<[^>]*>'), '') ??
        '暂无简介';
    return Text(
      content,
      style: TextStyle(
        color: textColor.withAlpha(204),
        fontSize: 13, // 减小字体
        height: 1.5,
      ),
      maxLines: 2, // 限制行数
      overflow: TextOverflow.ellipsis,
    );
  }

  // 构建播放源选择器
  Widget _buildPlaySourceSelector(
      List<String> sources, Color textColor, bool isPortrait) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '播放源',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12.0,
          runSpacing: 12.0,
          children: sources.map((source) {
            final bool isSelected = source == _currentPlaySource;
            return MouseRegion(
              cursor: SystemMouseCursors.click, // 设置鼠标指针为点击样式
              child: ChoiceChip(
                label: Text(source),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _currentPlaySource = source;
                    });
                  }
                },
                backgroundColor: isPortrait ? Colors.white : Colors.grey[900]?.withAlpha(204),
                selectedColor: const Color(0xFFFF7BB0),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : textColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isPortrait ? Colors.grey[200]! : Colors.transparent,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // 构建平铺的剧集列表（用于竖屏）
}

// 自定义路由，实现淡入淡出过渡效果
class FadeRoute extends PageRouteBuilder {
  final Widget page;
  FadeRoute({required this.page})
      : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              page,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) =>
              FadeTransition(
                opacity: animation,
                child: child,
              ),
        );
}