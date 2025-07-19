import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/performance_manager.dart';

/// 全新设计的性能设置界面
/// 去掉所有可能影响对齐的因素，使用最简洁的焦点效果
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
              const SizedBox(height: 24),
              
              // 视觉质量设置
              const Text(
                '视觉质量等级',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 12),
              
              // 使用简洁的列表布局
              Column(
                children: [
                  _buildQualityOption('低性能模式', '流畅优先，关闭特效', 0, performance),
                  const SizedBox(height: 8),
                  _buildQualityOption('平衡模式', '性能与效果兼顾', 1, performance),
                  const SizedBox(height: 8),
                  _buildQualityOption('高质量模式', '效果优先，需要高性能设备', 2, performance),
                  const SizedBox(height: 8),
                  _buildQualityOption('自动模式', '根据设备自动调节', 3, performance),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // 性能状态显示
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '当前性能状态',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'FPS: ${performance.currentFPS.toStringAsFixed(1)}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: performance.isLowEndDevice ? Colors.orange : Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            performance.isLowEndDevice ? '低端设备' : '标准设备',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          performance.enableBackgroundEffects ? Icons.check_circle : Icons.cancel,
                          color: performance.enableBackgroundEffects ? Colors.green : Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '背景特效: ${performance.enableBackgroundEffects ? '开启' : '关闭'}',
                          style: TextStyle(
                            color: performance.enableBackgroundEffects ? Colors.green : Colors.orange,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 说明文字
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  '💡 提示：低端设备建议选择"低性能模式"或"自动模式"以获得最佳流畅度',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
  
  /// 构建质量选项 - 使用最简洁的设计
  Widget _buildQualityOption(String title, String subtitle, int value, PerformanceManager performance) {
    final isSelected = performance.visualQuality == value;
    
    return _SimpleSettingsOption(
      title: title,
      subtitle: subtitle,
      isSelected: isSelected,
      onTap: () {
        performance.setVisualQuality(value);
      },
    );
  }
}

/// 最简洁的设置选项组件 - 使用测试页的Card样式
/// 只有必要的焦点效果，确保完美对齐
class _SimpleSettingsOption extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _SimpleSettingsOption({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SimpleSettingsOption> createState() => _SimpleSettingsOptionState();
}

class _SimpleSettingsOptionState extends State<_SimpleSettingsOption> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: _isFocused ? 3 : 1, // 焦点时增加阴影
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Material(
          color: widget.isSelected 
              ? const Color(0xFFFF7BB0).withValues(alpha: 0.1) // 选中时的背景色
              : Colors.white.withValues(alpha: 0.05), // 默认背景色
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            focusNode: _focusNode,
            onTap: widget.onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: _isFocused 
                    ? Border.all(color: const Color(0xFF81D4FA), width: 2) // 焦点边框
                    : widget.isSelected 
                        ? Border.all(color: const Color(0xFFFF7BB0), width: 1) // 选中边框
                        : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // 选择指示器
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.isSelected 
                              ? const Color(0xFFFF7BB0) 
                              : Colors.white.withValues(alpha: 0.5),
                          width: 2,
                        ),
                        color: widget.isSelected 
                            ? const Color(0xFFFF7BB0) 
                            : Colors.transparent,
                      ),
                      child: widget.isSelected 
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 14,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    // 文字内容
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: widget.isSelected ? Colors.white : Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 性能状态指示器 - 保持不变
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