import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../shared/widgets/backgrounds/cosmic_background.dart';
import '../../../shared/widgets/backgrounds/optimized_cosmic_background.dart';
import '../../../shared/widgets/backgrounds/optimized_cosmic_background_v2.dart';
import '../../../shared/utils/performance_manager.dart';
import '../controllers/video_detail_controller.dart';

class VideoDetailPage extends GetView<VideoDetailController> {
  final String videoId;
  
  const VideoDetailPage({
    super.key,
    required this.videoId,
  });

  @override
  String? get tag => videoId;

  @override
  Widget build(BuildContext context) {
    // 通过GetView自动获取控制器（由路由绑定管理）
    controller.initWithVideoId(videoId);
    
    return KeyedSubtree(
      key: UniqueKey(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isPortrait = constraints.maxHeight > constraints.maxWidth;
          // 竖屏模式文字颜色需要适配背景，横屏模式使用白色
          final textColor = isPortrait ? Colors.grey[800]! : Colors.white;

          Widget content = Scaffold(
            backgroundColor: Colors.transparent, // 统一透明，让背景组件生效
            extendBodyBehindAppBar: true,
            appBar: null, // 移除AppBar
            body: Obx(() => controller.isLoading.value
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFF7BB0),
                    ),
                  )
                : controller.errorMessage.value.isNotEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            controller.errorMessage.value,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : _buildDetailContent(controller, textColor, isPortrait)),
          );
          
          // 横屏模式下使用性能优化的宇宙背景，与主页保持一致
          // 使背景选择响应性能设置变化
          return Obx(() {
            final performance = Get.find<PerformanceManager>();
            
            if (isPortrait) {
              // 竖屏模式：使用清新亮色背景，对应性能等级
              return performance.getOptimizedFreshBackground(child: content);
            } else {
              // 横屏模式：使用宇宙暗色背景，智能选择优化版本
              if (performance.enableBackgroundEffects) {
                if (performance.isLowEndDevice || performance.visualQuality == 3) {
                  // 低端设备或智能模式：使用V2优化版本，保持视觉效果
                  return OptimizedCosmicBackgroundV2(intensity: 0.9, child: content);
                } else {
                  // 高端设备手动高性能：使用原始版本
                  return CosmicBackground(child: content);
                }
              } else {
                // 中低性能：使用性能优化背景
                return OptimizedCosmicBackground(child: content);
              }
            }
          });
        },
      ),
    );
  }
  
  Widget _buildDetailContent(VideoDetailController controller, Color textColor, bool isPortrait) {
    return Obx(() {
      if (controller.videoDetail.value == null) {
        return Center(
          child: Text(
            '没有找到视频信息',
            style: TextStyle(color: textColor, fontSize: 16),
          ),
        );
      }
      
      final videoDetail = controller.videoDetail.value!;
      final playOptions = controller.playOptions;
      final allPlaySources = controller.allPlaySources;
      
      final horizontalPadding = isPortrait ? 16.0 : 30.0;
      
      // 统一使用SingleChildScrollView和Column，解决横屏割裂感
      return Stack( // 将内容包裹在Stack中
        children: [
          SingleChildScrollView(
            key: PageStorageKey(videoId),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 全新的Hero Section
                _buildHeroSection(controller, isPortrait),
                
                // 减小竖屏和横屏模式下的间距
                SizedBox(height: isPortrait ? 24 : 4),

                // 2. 简介区域 - 横屏模式下跳过显示，避免溢出
                if (isPortrait && videoDetail['vod_content'] != null && videoDetail['vod_content'].toString().isNotEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: _buildDescriptionSection(videoDetail, textColor, isPortrait),
                  ),
                
                // 减小竖屏和横屏模式下的间距
                if (isPortrait) SizedBox(height: isPortrait ? 24 : 4),

                // 3. 播放列表区域
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (allPlaySources.isNotEmpty)
                        _buildPlaySourceSelector(controller, allPlaySources, textColor, isPortrait),
                      
                      if (controller.currentPlaySource.value.isNotEmpty && 
                          playOptions.containsKey(controller.currentPlaySource.value) && 
                          playOptions[controller.currentPlaySource.value]!.isNotEmpty) ...[
                        SizedBox(height: isPortrait ? 12 : 8), // 横屏模式下进一步减小间距
                        _buildTiledPlayList(controller, playOptions[controller.currentPlaySource.value]!, textColor, isPortrait: isPortrait),
                      ],
                    ],
                  ),
                ),

                // 减小底部间距
                SizedBox(height: isPortrait ? 32 : 4),
              ],
            ),
          ),
          // 将返回按钮作为独立的层放置在顶部，并使用动画平滑过渡
          Builder(
            builder: (context) => AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              top: MediaQuery.of(context).padding.top,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Get.back(),
                splashColor: Colors.transparent,
                highlightColor: Colors.white.withValues(alpha: 51/255.0),
              ),
            ),
          ),
        ],
      );
    });
  }

  
  // 为横屏构建平铺的剧集列表
  Widget _buildTiledPlayList(VideoDetailController controller, List<Map<String, String>> episodes, Color textColor, {bool isPortrait = false}) {
    // 竖屏时使用更紧凑、更适合竖向浏览的GridView
    if (isPortrait) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: episodes.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, // 减少列数，让每个卡片更宽
          childAspectRatio: 1.1, // 调整高宽比，增加高度
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemBuilder: (context, index) {
          final episode = episodes[index];
          return _buildPortraitEpisodeCard(controller, episode, index, textColor);
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
        return _buildLandscapeEpisodeCard(controller, episode, index, textColor);
      }).toList(),
    );
  }
  
  // 竖屏剧集卡片
  Widget _buildPortraitEpisodeCard(VideoDetailController controller, Map<String, String> episode, int index, Color textColor) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: InkWell(
          onTap: () {
            if (episode['url'] != null && episode['name'] != null) {
              controller.playVideo(episode['url']!, episode['name']!);
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
                  padding: const EdgeInsets.all(10),
                  child: Center(
                    child: Text(
                      episode['name'] ?? '未知',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13, // 增加字体大小
                        height: 1.2, // 减少行高，节省空间
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3, // 增加最大行数
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
  Widget _buildLandscapeEpisodeCard(VideoDetailController controller, Map<String, String> episode, int index, Color textColor) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: InkWell(
          onTap: () {
            if (episode['url'] != null && episode['name'] != null) {
              controller.playVideo(episode['url']!, episode['name']!);
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
  Widget _buildHeroSection(VideoDetailController controller, bool isPortrait) {
    return Obx(() {
      final videoDetail = controller.videoDetail.value!;
      final coverUrl = videoDetail['vod_pic'] ?? '';
      final String title = videoDetail['vod_name'] ?? '未知标题';
      final String? type = videoDetail['type_name'];
      final String? year = videoDetail['vod_year'];
      final String? area = videoDetail['vod_area'];
      final String? remarks = videoDetail['vod_remarks'];
      final String? actors = videoDetail['vod_actor'];
      final String? director = videoDetail['vod_director'];
      final String? content = videoDetail['vod_content'];

      if (isPortrait) {
        return _buildPortraitHeroSection(controller, coverUrl, title, type, year, area, remarks, actors, director);
      } else {
        return _buildLandscapeHeroSection(controller, coverUrl, title, type, year, area, remarks, actors, director, content);
      }
    });
  }
  
  // 竖屏英雄区域（保持原有设计）
  Widget _buildPortraitHeroSection(VideoDetailController controller, String coverUrl, String title, String? type, String? year, 
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
                _buildPlayableCover(controller, coverUrl, false),
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
  Widget _buildLandscapeHeroSection(VideoDetailController controller, String coverUrl, String title, String? type, String? year, 
      String? area, String? remarks, String? actors, String? director, String? content) {
    return SizedBox(
      height: 300, // 适当增加高度以适应调整后的布局
      child: Stack(
        children: [
          // 背景图片，让宇宙光线透射进来
          Positioned.fill(
            child: Stack(
              children: [
                // 背景图片
                Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(coverUrl),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.white.withValues(alpha: 0.85), // 让图片稍微透明，允许宇宙光线透射
                        BlendMode.modulate,
                      ),
                    ),
                  ),
                ),
                // 轻微的黑色遮罩确保文字可读性
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                  ),
                ),
              ],
            ),
          ),
          // 主要内容
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 40, bottom: 7), // 减小底部边距到一半
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end, // 改为底部对齐
              children: [
                // 左侧封面
                _buildLandscapeCover(controller, coverUrl),
                const SizedBox(width: 20), // 进一步减小间距
                // 右侧信息
                Expanded(
                  child: SizedBox(
                    height: 250, // 与封面图高度一致
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end, // 底部对齐
                      children: [
                        // 使用Flexible让内容能够适应空间
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
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
                              const SizedBox(height: 8), // 进一步减小间距
                              // 基本信息
                              _buildLandscapeMetadata(year, area, type, remarks),
                              const SizedBox(height: 8), // 进一步减小间距
                              // 演员导演信息
                              if ((actors != null && actors.isNotEmpty) || (director != null && director.isNotEmpty))
                                _buildLandscapeCrewInfo(actors, director),
                              const SizedBox(height: 8), // 进一步减小间距
                              // 简介（横屏显示）- 固定高度
                              if (content != null && content.isNotEmpty)
                                _buildLandscapeDescription(content),
                            ],
                          ),
                        ),
                      ],
                    ),
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
  Widget _buildLandscapeCover(VideoDetailController controller, String coverUrl) {
    return Container(
      width: 170, // 进一步增加宽度
      height: 250, // 进一步增加高度
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
            width: 170,
            height: 250,
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
                onTap: () => controller.playFirstEpisode(),
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
      height: 80, // 适中的简介高度，避免溢出
      padding: const EdgeInsets.all(10), // 进一步减小内边距
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
                size: 12, // 进一步减小图标尺寸
              ),
              SizedBox(width: 4), // 进一步减小间距
              Text(
                '简介',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12, // 进一步减小字体
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4), // 进一步减小间距
          Expanded( // 使用Expanded确保文本不会溢出
            child: Text(
              cleanContent.isNotEmpty ? cleanContent : '暂无简介',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13, // 保持字体大小
                height: 1.3, // 紧凑的行高，确保完整显示
              ),
              maxLines: 2, // 只显示2行完整文本
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  // 电视盒子风格播放按钮
  
  // 构建可点击的封面
  Widget _buildPlayableCover(VideoDetailController controller, String coverUrl, bool isLandscape) {
    final size = isLandscape ? 180.0 : 100.0;
    final height = isLandscape ? 240.0 : 140.0;
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => controller.playFirstEpisode(),
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

  // 构建视频简介区域的容器
  Widget _buildDescriptionSection(Map<String, dynamic> videoDetail, Color textColor, bool isPortrait) {
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
            ? _buildDescriptionSectionContent(videoDetail, textColor)
            : _buildCompactDescriptionContent(videoDetail, textColor),
      ],
    );
  }
  
  // 横屏模式下的简洁简介内容
  Widget _buildCompactDescriptionContent(Map<String, dynamic> videoDetail, Color textColor) {
    // 移除HTML标签并整理文本
    final content = videoDetail['vod_content']
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
  Widget _buildPlaySourceSelector(VideoDetailController controller, List<String> sources, Color textColor, bool isPortrait) {
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
        Obx(() => Wrap(
          spacing: 12.0,
          runSpacing: 12.0,
          children: sources.map((source) {
            final bool isSelected = source == controller.currentPlaySource.value;
            return _buildPlaySourceChip(controller, source, isSelected, textColor, isPortrait);
          }).toList(),
        )),
      ],
    );
  }
  
  // 构建播放源选择芯片
  Widget _buildPlaySourceChip(VideoDetailController controller, String source, bool isSelected, Color textColor, bool isPortrait) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: InkWell(
          onTap: () => controller.changePlaySource(source),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      : Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFFF7BB0)
                    : isPortrait
                        ? Colors.grey[300]!
                        : Colors.white30,
                width: 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFF7BB0).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? Icons.check_circle : Icons.play_circle_outline,
                  color: isSelected
                      ? Colors.white
                      : isPortrait
                          ? textColor
                          : Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  source,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : isPortrait
                            ? textColor
                            : Colors.white70,
                    fontWeight: FontWeight.w500,
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
  Widget _buildDescriptionSectionContent(Map<String, dynamic> videoDetail, Color textColor) {
    // 移除HTML标签并整理文本
    final content = videoDetail['vod_content']
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