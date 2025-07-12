import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/performance_manager.dart';

/// 性能设置界面
class PerformanceSettings extends StatelessWidget {
  final bool isDialog;
  
  const PerformanceSettings({
    super.key,
    this.isDialog = false,
  });

  @override
  Widget build(BuildContext context) {
    final performance = Get.find<PerformanceManager>();
    return Obx(() => SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Container(
            padding: EdgeInsets.all(isDialog ? 0 : 16),
            decoration: isDialog ? null : BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              const Text(
                '性能设置',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // 视觉质量设置
              const Text(
                '视觉质量等级',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              
              // 使用GridView替代Wrap以更好控制布局
              LayoutBuilder(
                builder: (context, constraints) {
                  return GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: [
                      _buildQualityChip('低', 0, performance),
                      _buildQualityChip('中', 1, performance),
                      _buildQualityChip('高', 2, performance),
                      _buildQualityChip('自动', 3, performance),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 16),
              
              // 性能状态显示
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '当前性能状态',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'FPS: ${performance.currentFPS.toStringAsFixed(1)}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          performance.isLowEndDevice ? '低端设备' : '标准设备',
                          style: TextStyle(
                            color: performance.isLowEndDevice 
                                ? Colors.orange 
                                : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '特效状态: ',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                        ),
                        Icon(
                          performance.enableBackgroundEffects 
                              ? Icons.check_circle 
                              : Icons.cancel,
                          color: performance.enableBackgroundEffects 
                              ? Colors.green 
                              : Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          performance.enableBackgroundEffects ? '开启' : '简化',
                          style: TextStyle(
                            color: performance.enableBackgroundEffects 
                                ? Colors.green 
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // 说明文字
              Text(
                '• 低端设备建议选择"低"或"自动"\n• 自动模式会根据实时性能调整',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
  
  Widget _buildQualityChip(String label, int value, PerformanceManager performance) {
    final isSelected = performance.visualQuality == value;
    
    return GestureDetector(
      onTap: () {
        performance.setVisualQuality(value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFFFF7BB0) 
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFFFF7BB0) 
                : Colors.white.withValues(alpha: 0.3),
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFFFF7BB0).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              shadows: isSelected ? [
                const Shadow(
                  color: Colors.black26,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ] : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// 性能状态指示器 - 可以放在任何界面的角落
class PerformanceIndicator extends StatelessWidget {
  const PerformanceIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PerformanceManager>(
      builder: (performance) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                performance.enableBackgroundEffects 
                    ? Icons.speed 
                    : Icons.battery_saver,
                color: performance.enableBackgroundEffects 
                    ? Colors.green 
                    : Colors.orange,
                size: 12,
              ),
              const SizedBox(width: 4),
              Text(
                performance.currentFPS.toStringAsFixed(0),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}