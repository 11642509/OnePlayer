import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/performance_manager.dart';
import '../../constants/app_colors.dart';

/// 竖屏清新亮色系宇宙背景 - 支持性能模式调节
class FreshCosmicBackground extends StatefulWidget {
  final Widget child;

  const FreshCosmicBackground({
    super.key,
    required this.child,
  });

  @override
  State<FreshCosmicBackground> createState() => _FreshCosmicBackgroundState();
}

class _FreshCosmicBackgroundState extends State<FreshCosmicBackground> {

  @override
  void initState() {
    super.initState();
  }



  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final performance = PerformanceManager.to;
      
      // 使用与横屏一致的性能判断逻辑
      if (performance.enableBackgroundEffects) {
        // 高性能模式 - 完整微光效果
        return _buildFullEffectBackground();
      } else if (performance.enableGradientEffects) {
        // 平衡模式 - 渐变背景 + 微弱金光
        return _buildGradientBackground();
      } else {
        // 节能模式 - 纯色背景
        return _buildSolidBackground();
      }
    });
  }

  /// 节能模式 - 纯色背景
  Widget _buildSolidBackground() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.freshSkyWhite,
      ),
      child: widget.child,
    );
  }

  /// 平衡模式 - 渐变背景
  Widget _buildGradientBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.freshSkyWhite,
            AppColors.freshMorningBlue,
            AppColors.freshAliceBlue,
          ],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // 添加明显的左上角微光照射效果
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft, // 光源位置
                  radius: 1.0,
                  colors: [
                    AppColors.goldWithAlpha(0.15), // 明显金光
                    AppColors.goldWithAlpha(0.12, baseColor: AppColors.goldOrange), // 橙光
                    AppColors.goldWithAlpha(0.08, baseColor: AppColors.goldDeepOrange), // 深橙
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 0.6, 1.0],
                ),
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }

  /// 高性能模式 - 完整微光效果（无光点光线）
  Widget _buildFullEffectBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.freshSkyWhite,
            AppColors.freshMorningBlue,
            AppColors.freshAliceBlue,
          ],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // 主要的金色微光照射效果
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft, // 光源位置
                  radius: 1.0,
                  colors: [
                    AppColors.goldWithAlpha(0.25), // 强烈金光
                    AppColors.goldWithAlpha(0.18, baseColor: AppColors.goldOrange), // 明显橙光
                    AppColors.goldWithAlpha(0.12, baseColor: AppColors.goldDeepOrange), // 深橙
                    AppColors.goldWithAlpha(0.06, baseColor: AppColors.goldSpreadOrange), // 扩散橙
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                ),
              ),
            ),
          ),
          
          // 增加聚焦的强光效果
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 0.4, // 更小半径，更聚焦
                  colors: [
                    AppColors.goldWithAlpha(0.2, baseColor: AppColors.goldBrightYellow), // 强烈黄光
                    AppColors.goldWithAlpha(0.15), // 金光
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),
          
          // 内容层
          widget.child,
        ],
      ),
    );
  }

}