import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui' as ui;
import '../../../shared/controllers/window_controller.dart';
import '../controllers/vod_controller.dart';
import 'video_detail_page.dart';

class VideoOnDemandPage extends StatelessWidget {
  const VideoOnDemandPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用 Get.put 懒加载控制器，确保只创建一次
    final controller = Get.put(VodController(), permanent: true);
    final windowController = Get.find<WindowController>();
    
    return Obx(() {
      // 根据窗口方向设置背景色：横屏黑色，竖屏浅灰色(与PortraitHomeLayout一致)
      final backgroundColor = !windowController.isPortrait.value 
          ? Colors.black 
          : const Color(0xFFF6F7F8); // 与PortraitHomeLayout一致的浅灰色背景
          
      // 如果数据正在加载中，显示加载指示器
      if (controller.isLoading.value && controller.homeData.isEmpty) {
        return Scaffold(
          backgroundColor: backgroundColor,
          body: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFF7BB0), // B站粉色
            ),
          ),
        );
      }
      
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          // 根据屏幕方向调整AppBar样式
          toolbarHeight: windowController.isPortrait.value ? 48 : null, // 竖屏模式下调整高度
          // 使用B站风格的顶部导航，但内容是我们自己的分类
          title: SizedBox(
            height: windowController.isPortrait.value ? 36 : 40, // 竖屏模式下高度稍小
            width: double.infinity, // 确保宽度占满
            child: controller.tabController != null ? TabBar(
              controller: controller.tabController,
              isScrollable: true,
              tabs: controller.classList.map((item) {
                return Tab(
                  height: windowController.isPortrait.value ? 36 : 40, // 竖屏模式下高度稍小
                  child: Text(
                    item['type_name'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: windowController.isPortrait.value ? 15 : 16, // 竖屏模式下字体稍小
                    ),
                  ),
                );
              }).toList(),
              labelColor: const Color(0xFFFF7BB0), // B站粉色
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFFFF7BB0), // B站粉色
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              indicator: UnderlineTabIndicator(
                borderSide: const BorderSide(
                  color: Color(0xFFFF7BB0),
                  width: 3,
                ),
                insets: EdgeInsets.symmetric(
                  horizontal: windowController.isPortrait.value ? 12 : 16, // 竖屏模式下指示器宽度稍小
                ),
              ),
              // 竖屏模式下靠左对齐
              padding: windowController.isPortrait.value 
                  ? const EdgeInsets.only(left: 16) 
                  : null,
              // 确保标签可以滚动
              tabAlignment: windowController.isPortrait.value 
                  ? TabAlignment.start  // 竖屏模式下靠左对齐
                  : TabAlignment.center, // 横屏模式下居中对齐
              // 调整标签间距
              labelPadding: EdgeInsets.symmetric(
                horizontal: windowController.isPortrait.value ? 12 : 16, // 竖屏模式下标签间距稍小
              ),
            ) : const SizedBox(),
          ),
          // 竖屏模式下让标题居左对齐
          titleSpacing: windowController.isPortrait.value ? 0 : null,
          centerTitle: !windowController.isPortrait.value, // 横屏居中，竖屏靠左
        ),
        body: controller.tabController != null ? TabBarView(
          controller: controller.tabController,
          children: controller.classList.map((category) {
            final typeId = category['type_id'] as String;
            final typeName = category['type_name'] as String;
            
            // 如果是主页，使用HomeData的数据
            if (typeId == "0") {
              if (controller.categoryData.containsKey("主页") && controller.categoryData["主页"]!.isNotEmpty) {
                return _buildVideoGridPage(controller, controller.categoryData["主页"]!, typeName);
              } else if (controller.homeData.isNotEmpty && controller.homeData.containsKey('list')) {
                // 缓存首页数据
                controller.categoryData["主页"] = controller.homeData['list'] as List;
                return _buildVideoGridPage(controller, controller.categoryData["主页"]!, typeName);
              } else {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFFF7BB0), // B站粉色
                  ),
                );
              }
            } else {
              // 如果已有缓存数据，直接显示
              if (controller.categoryData.containsKey(typeName) && controller.categoryData[typeName]!.isNotEmpty) {
                return _buildVideoGridPage(controller, controller.categoryData[typeName]!, typeName);
              }
              
              // 否则显示加载状态，并触发数据加载
              controller.ensureCategoryDataLoaded(typeName);
              
              // 检查是否正在加载
              final isCurrentlyLoading = controller.categoryLoadingStates[typeName] ?? false;
              if (isCurrentlyLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFFF7BB0), // B站粉色
                  ),
                );
              }
              
              // 如果没有数据且没有在加载，显示错误或空状态
              return const Center(
                child: Text(
                  '暂无数据',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }
          }).toList(),
        ) : const SizedBox(),
      );
    });
  }
  
  // 构建视频网格页面
  Widget _buildVideoGridPage(VodController controller, List videoList, String typeName) {
    if (videoList.isEmpty) {
      return controller.isLoading.value
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7BB0)))
          : Center(child: Text("此分类下暂无内容", style: TextStyle(color: Colors.grey[600])));
    }

    final firstVideo = videoList.first;
    final firstImageUrl = firstVideo['vod_pic'] as String;

    // 使用FutureBuilder来异步决定布局
    return FutureBuilder<ui.Image>(
      future: controller.getImageInfo(firstImageUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFF7BB0)));
        }

        bool isLandscapeLayout;
        if (snapshot.hasData) {
          // 根据真实的图片尺寸决定布局
          final image = snapshot.data!;
          isLandscapeLayout = image.width > image.height;
        } else {
          // 如果获取图片尺寸失败，则回退到默认布局（竖向）
          isLandscapeLayout = false; 
        }

        // 使用决定的布局来构建网格
        return _buildGridWithLayout(controller, videoList, typeName, isLandscapeLayout);
      },
    );
  }
  
  // 实际构建网格和RefreshIndicator的辅助方法
  Widget _buildGridWithLayout(VodController controller, List videoList, String typeName, bool isLandscapeLayout) {
    final windowController = Get.find<WindowController>();
    final isPortrait = windowController.isPortrait.value;
    
    return RefreshIndicator(
      color: const Color(0xFFFF7BB0),
      backgroundColor: Colors.grey[900],
      onRefresh: () async {
        // 刷新数据
        await controller.refreshData(typeName);
      },
      child: Column(
        children: [
          Expanded(
            child: _buildVideoGrid(controller, videoList, typeName, isLandscapeLayout, isPortrait),
          ),
          if (typeName != "主页") 
            isPortrait 
              ? _buildPortraitPageNavigator(controller, typeName) 
              : _buildLandscapePageNavigator(controller, typeName),
        ],
      ),
    );
  }

  // 构建视频网格
  Widget _buildVideoGrid(VodController controller, List videoList, String typeName, bool isLandscapeLayout, bool isPortrait) {
    int crossAxisCount;

    if (isPortrait) {
      // 竖屏模式，固定2列
      crossAxisCount = 2;
    } else {
      // 横屏模式，固定4列
      crossAxisCount = 4;
    }

    // 标题高度 - 固定两行文本高度
    final double titleHeight = 36;
    // 图片与标题之间的间距
    final double spacing = 2;
    
    return Builder(builder: (context) {
      // 计算每个网格项的宽度
      final double screenWidth = MediaQuery.of(context).size.width;
      final double itemWidth = isPortrait 
          ? (screenWidth - 28) / 2 // 竖屏2列，减去边距和间距
          : (screenWidth - 58) / 4; // 横屏4列，减去边距和间距
      
      // 根据16:9比例计算图片高度
      final double imageHeight = itemWidth * 9 / 16;
      
      // 计算网格项总高度
      final double itemHeight = imageHeight + spacing + titleHeight;
      
      // 计算网格项宽高比
      final double childAspectRatio = itemWidth / itemHeight;

      return GridView.builder(
        padding: EdgeInsets.all(isPortrait ? 10 : 12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: isPortrait ? 8 : 10,
          mainAxisSpacing: isPortrait ? 12 : 16,
        ),
        itemCount: videoList.length,
        itemBuilder: (context, index) {
          final video = videoList[index];
          return _buildVideoCard(video, index, itemWidth, imageHeight, titleHeight, spacing, isPortrait);
        },
      );
    });
  }

  // 构建视频卡片
  Widget _buildVideoCard(dynamic video, int index, double itemWidth, double imageHeight, double titleHeight, double spacing, bool isPortrait) {
    final textColor = !isPortrait ? Colors.white : Colors.black;
    final cardBgColor = isPortrait ? Colors.white : Colors.grey[900];

    final String? remarks = video['vod_remarks'];
    // 判断备注是否应该显示（长度小于等于30个字符）
    final bool shouldShowRemarks = remarks != null && remarks.length <= 30;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. 图片卡片 - 固定16:9比例
        Card(
          elevation: isPortrait ? 2 : 1,
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isPortrait ? 8 : 6),
          ),
          color: cardBgColor,
          child: SizedBox(
            width: itemWidth,
            height: imageHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 图片
                Image.network(
                  video['vod_pic'],
                  width: itemWidth,
                  height: imageHeight,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => 
                    Container(color: Colors.grey[800]),
                ),
                // 备注（如果有）- 右下角，背景铺满整个宽度
                if (shouldShowRemarks)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withAlpha(179),
                            Colors.black.withAlpha(51),
                          ],
                        ),
                      ),
                      child: Text(
                        remarks,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),
                // 点击效果
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Get.to(() => VideoDetailPage(videoId: video['vod_id']));
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        // 间距
        SizedBox(height: spacing),
        // 2. 标题 - 固定高度
        SizedBox(
          height: titleHeight,
          width: itemWidth,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isPortrait ? 4 : 6),
            child: Text(
              video['vod_name'],
              style: TextStyle(
                fontSize: isPortrait ? 13 : 12,
                fontWeight: isPortrait ? FontWeight.w500 : FontWeight.normal,
                color: textColor,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
  
  // 构建页面导航器
  Widget _buildPortraitPageNavigator(VodController controller, String typeName) {
    return Obx(() {
      final currentPage = controller.currentPages[typeName] ?? 1;
      final totalPages = controller.totalPages[typeName] ?? 1;

      // 如果总页数小于等于1，则不显示分页器
      if (totalPages <= 1) {
        return const SizedBox.shrink();
      }
      
      // 创建页码列表
      List<int> pageNumbers = controller.generatePageNumbers(currentPage, totalPages);

      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: pageNumbers.map((pageNum) {
            if (pageNum == -1) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0),
                child: Text("..."),
              );
            }
            
            final bool isCurrentPage = pageNum == currentPage;

            return GestureDetector(
              onTap: () {
                if (pageNum != currentPage) {
                  controller.onPageChanged(typeName, pageNum);
                }
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isCurrentPage ? const Color(0xFFFF7BB0) : null,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isCurrentPage ? Colors.transparent : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    pageNum.toString(),
                    style: TextStyle(
                      color: isCurrentPage ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    });
  }
  
  // 构建横屏模式下的页面导航器
  Widget _buildLandscapePageNavigator(VodController controller, String typeName) {
    return Obx(() {
      final currentPage = controller.currentPages[typeName] ?? 1;
      final totalPages = controller.totalPages[typeName] ?? 1;

      // 如果总页数小于等于1，则不显示分页器
      if (totalPages <= 1) {
        return const SizedBox.shrink();
      }

      List<int> pageNumbers = controller.generatePageNumbers(currentPage, totalPages);

      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: pageNumbers.map((pageNum) {
            if (pageNum == -1) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0),
                child: Text("...", style: TextStyle(color: Colors.white)),
              );
            }

            final isCurrentPage = pageNum == currentPage;

            return InkWell(
              onTap: () {
                if (pageNum != currentPage) {
                  controller.onPageChanged(typeName, pageNum);
                }
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: isCurrentPage ? const Color(0xFFFF7BB0) : Colors.grey[800],
                  border: Border.all(
                    color: isCurrentPage ? Colors.transparent : Colors.grey[700]!,
                  ),
                  boxShadow: isCurrentPage
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFF7BB0).withAlpha(51),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Text(
                  pageNum.toString(),
                  style: TextStyle(
                    color: isCurrentPage ? Colors.white : Colors.grey[300],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    });
  }
}