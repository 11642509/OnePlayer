import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../app/config/config.dart';
import '../../../app/data_source.dart';
import '../../media_player/vlc_player/pages/vlc_player_page.dart';
import '../../media_player/standard_player/pages/video_player_page.dart';
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

        // 智能选择播放器内核
        bool useVlc = AppConfig.currentPlayerKernel == PlayerKernel.vlc;
        
        // 对于MPD格式，如果配置为VLC但可能存在兼容性问题，提供选择
        if (useVlc && playConfig.format == VideoFormat.dash) {
          if (kDebugMode) {
            print('检测到MPD格式，使用VLC播放器（如遇问题可切换到video_player）');
          }
        }
        
        if (useVlc) {
          // 使用 VLC 播放器
          if (kDebugMode) {
            print('使用VLC内核播放: ${playConfig.url}');
          }
          if (!mounted) return;
          Navigator.pushReplacement(
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
    return KeyedSubtree(
      key: UniqueKey(),
      child: LayoutBuilder(
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
      ),
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
              SizedBox(height: isPortrait ? 24 : 8),

              // 2. 简介区域 - 横屏模式下跳过显示，避免溢出
              if (isPortrait && _videoDetail!['vod_content'] != null && _videoDetail!['vod_content'].toString().isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: _buildDescriptionSection(textColor, isPortrait),
                ),
              
              // 减小竖屏和横屏模式下的间距
              if (isPortrait) SizedBox(height: isPortrait ? 24 : 8),

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
              SizedBox(height: isPortrait ? 32 : 8),
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
            onPressed: () async {
              // 如果当前有正在加载的播放器相关操作，先取消
              if (_isLoading) {
                setState(() {
                  _isLoading = false;
                });
                // 给一个短暂的延迟确保状态更新
                await Future.delayed(const Duration(milliseconds: 50));
              }
              if (!mounted) return;
              Navigator.of(context).pop();
            },
            splashColor: Colors.transparent,
            highlightColor: Colors.white.withValues(alpha: 51/255.0),
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
          return _buildPortraitEpisodeCard(episode, index, textColor);
        },
      );
    }

    // 横屏时，使用更具视觉层次的设计
    return Wrap(
      spacing: 16.0,
      runSpacing: 16.0,
      children: episodes.asMap().entries.map((entry) {
        final index = entry.key;
        final episode = entry.value;
        return _buildLandscapeEpisodeCard(episode, index, textColor);
      }).toList(),
    );
  }
  
  // 竖屏剧集卡片
  Widget _buildPortraitEpisodeCard(Map<String, String> episode, int index, Color textColor) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: InkWell(
          onTap: () {
            if (episode['url'] != null && episode['name'] != null) {
              _playVideo(episode['url']!, episode['name']!);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              // 自然的毛玻璃效果 - 浅色背景
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey[200]!.withValues(alpha: 0.8),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.grey[50]!.withValues(alpha: 0.3),
                      Colors.grey[100]!.withValues(alpha: 0.1),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Center(
                    child: Text(
                      episode['name'] ?? '未知',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // 横屏剧集卡片（电视盒子风格）
  Widget _buildLandscapeEpisodeCard(Map<String, String> episode, int index, Color textColor) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: InkWell(
          onTap: () {
            if (episode['url'] != null && episode['name'] != null) {
              _playVideo(episode['url']!, episode['name']!);
            }
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 64,
            width: 120,
            decoration: BoxDecoration(
              // 自然的毛玻璃效果
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.08),
                      Colors.white.withValues(alpha: 0.03),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Center(
                    child: Text(
                      episode['name'] ?? '未知',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.95),
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // 重构封面英雄区域 - 参考电视盒子设计
  Widget _buildHeroSection(bool isPortrait) {
    final coverUrl = _videoDetail!['vod_pic'] ?? '';
    final String title = _videoDetail!['vod_name'] ?? '未知标题';
    final String? type = _videoDetail!['type_name'];
    final String? year = _videoDetail!['vod_year'];
    final String? area = _videoDetail!['vod_area'];
    final String? remarks = _videoDetail!['vod_remarks'];
    final String? actors = _videoDetail!['vod_actor'];
    final String? director = _videoDetail!['vod_director'];
    final String? content = _videoDetail!['vod_content'];

    if (isPortrait) {
      return _buildPortraitHeroSection(coverUrl, title, type, year, area, remarks, actors, director);
    } else {
      return _buildLandscapeHeroSection(coverUrl, title, type, year, area, remarks, actors, director, content);
    }
  }
  
  // 竖屏英雄区域（保持原有设计）
  Widget _buildPortraitHeroSection(String coverUrl, String title, String? type, String? year, 
      String? area, String? remarks, String? actors, String? director) {
    const double heroHeight = 300;
    
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
          height: heroHeight * 0.8,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 204/255.0),
                  Colors.black,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        // 主要信息内容
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildPlayableCover(coverUrl, false),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      _buildMetadataChips(year, area, type, remarks),
                      const SizedBox(height: 8),
                      if ((actors != null && actors.isNotEmpty) || (director != null && director.isNotEmpty))
                        _buildCrewInfo(actors, director),
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
  
  // 横屏英雄区域（电视盒子风格）
  Widget _buildLandscapeHeroSection(String coverUrl, String title, String? type, String? year, 
      String? area, String? remarks, String? actors, String? director, String? content) {
    return Container(
      height: 320, // 减小高度以适应横屏
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1a1a1a),
            const Color(0xFF2d2d2d),
            Colors.grey[900]!,
          ],
        ),
      ),
      child: Stack(
        children: [
          // 背景模糊效果
          Positioned.fill(
            child: Image.network(
              coverUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(),
            ),
          ),
          // 模糊遮罩
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                backgroundBlendMode: BlendMode.darken,
              ),
            ),
          ),
          // 主要内容
          Padding(
            padding: const EdgeInsets.all(24), // 减小内边距
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 左侧封面
                _buildLandscapeCover(coverUrl),
                const SizedBox(width: 24), // 减小间距
                // 右侧信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 标题
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24, // 减小字体
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12), // 减小间距
                      // 基本信息
                      _buildLandscapeMetadata(year, area, type, remarks),
                      const SizedBox(height: 12), // 减小间距
                      // 演员导演信息
                      if ((actors != null && actors.isNotEmpty) || (director != null && director.isNotEmpty))
                        _buildLandscapeCrewInfo(actors, director),
                      const SizedBox(height: 12), // 减小间距
                      // 简介（横屏显示）
                      if (content != null && content.isNotEmpty)
                        _buildLandscapeDescription(content),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 横屏专用封面组件
  Widget _buildLandscapeCover(String coverUrl) {
    return Container(
      width: 160, // 减小宽度
      height: 220, // 减小高度
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Image.network(
            coverUrl,
            fit: BoxFit.cover,
            width: 160,
            height: 220,
            errorBuilder: (context, error, stackTrace) =>
                Container(color: Colors.grey[800]),
          ),
          // 添加播放按钮悬浮效果
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.center,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
                  ],
                ),
              ),
              child: InkWell(
                onTap: _playFirstEpisode,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 横屏专用元数据显示
  Widget _buildLandscapeMetadata(String? year, String? area, String? type, String? remarks) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        if (remarks != null && remarks.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF7BB0), Color(0xFFFF4081)],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF7BB0).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '⏱ $remarks',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        if (year != null && year.isNotEmpty)
          _buildLandscapeMetadataChip(year, Icons.calendar_today),
        if (area != null && area.isNotEmpty)
          _buildLandscapeMetadataChip(area, Icons.location_on),
        if (type != null && type.isNotEmpty)
          _buildLandscapeMetadataChip(type, Icons.category),
      ],
    );
  }
  
  Widget _buildLandscapeMetadataChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white30, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white70,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  // 横屏专用演员导演信息
  Widget _buildLandscapeCrewInfo(String? actors, String? director) {
    final items = <Widget>[];
    
    if (director != null && director.isNotEmpty) {
      items.add(_buildCrewInfoItem('导演', director, Icons.movie_filter));
    }
    
    if (actors != null && actors.isNotEmpty) {
      items.add(_buildCrewInfoItem('主演', actors, Icons.people));
    }
    
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items,
    );
  }
  
  Widget _buildCrewInfoItem(String label, String content, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: Colors.white70,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              content,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  // 横屏专用简介
  Widget _buildLandscapeDescription(String content) {
    final cleanContent = content
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .trim();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.description,
                color: Colors.white70,
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                '简介',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            cleanContent.isNotEmpty ? cleanContent : '暂无简介',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  
  // 电视盒子风格播放按钮
  
  // 构建可点击的封面
  Widget _buildPlayableCover(String coverUrl, bool isLandscape) {
    final size = isLandscape ? 180.0 : 100.0;
    final height = isLandscape ? 240.0 : 140.0;
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _playFirstEpisode,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
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
            Container(
              width: size,
              height: height,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: Colors.white.withValues(alpha: 0.9),
                size: isLandscape ? 80 : 60,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // 构建元数据标签
  Widget _buildMetadataChips(String? year, String? area, String? type, String? remarks) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        if (remarks != null && remarks.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFF7BB0).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFFF7BB0), width: 1),
            ),
            child: Text(
              '⏱ $remarks',
              style: const TextStyle(
                color: Color(0xFFFF7BB0),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        if (year != null && year.isNotEmpty)
          _buildMetadataChip(year),
        if (area != null && area.isNotEmpty)
          _buildMetadataChip(area),
        if (type != null && type.isNotEmpty)
          _buildMetadataChip(type),
      ],
    );
  }
  
  Widget _buildMetadataChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white30, width: 1),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
        ),
      ),
    );
  }
  
  // 构建演员导演信息
  Widget _buildCrewInfo(String? actors, String? director) {
    final items = [
      if (director != null && director.isNotEmpty) '导演: $director',
      if (actors != null && actors.isNotEmpty) '主演: $actors',
    ];
    
    if (items.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Text(
        items.join(' / '),
        style: const TextStyle(color: Colors.white70, fontSize: 13),
        maxLines: 1,
      ),
    );
  }

  // 自动播放第一集
  void _playFirstEpisode() {
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
  }

  // 构建视频简介区域的容器
  Widget _buildDescriptionSection(Color textColor, bool isPortrait) {
    // 移除双重内边距，防止溢出
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.description_outlined,
              color: textColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              '简介',
              style: TextStyle(
                fontSize: isPortrait ? 18 : 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
        SizedBox(height: isPortrait ? 12 : 8),
        // 横屏模式下限制简介的行数
        isPortrait 
            ? _buildDescriptionSectionContent(textColor)
            : _buildCompactDescriptionContent(textColor),
      ],
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
        color: textColor.withValues(alpha: 204/255.0),
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
        Row(
          children: [
            Icon(
              Icons.play_circle_outline,
              color: textColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '播放源',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12.0,
          runSpacing: 12.0,
          children: sources.map((source) {
            final bool isSelected = source == _currentPlaySource;
            return _buildPlaySourceChip(source, isSelected, textColor, isPortrait);
          }).toList(),
        ),
      ],
    );
  }
  
  // 构建播放源选择芯片
  Widget _buildPlaySourceChip(String source, bool isSelected, Color textColor, bool isPortrait) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: InkWell(
          onTap: () {
            setState(() {
              _currentPlaySource = source;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [Color(0xFFFF7BB0), Color(0xFFFF4081)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected
                  ? null
                  : isPortrait
                      ? Colors.white
                      : Colors.grey[800]?.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFFF7BB0)
                    : isPortrait
                        ? Colors.grey[300]!
                        : Colors.white.withValues(alpha: 0.2),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFF7BB0).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                Text(
                  source,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : textColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 构建简介区域内容的组件
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
        color: textColor.withValues(alpha: 204/255.0),
        fontSize: 14,
        height: 1.6,
      ),
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