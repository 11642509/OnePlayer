import 'package:flutter/material.dart';
import '../../../shared/models/search_source.dart';
import '../../../shared/models/search_result.dart';
import '../../../app/theme/typography.dart';
import '../../../core/remote_control/focusable_glow.dart';

/// 搜索源列表组件
class SearchSourceList extends StatelessWidget {
  final List<SearchSource> sources;
  final String? selectedSourceId;
  final Map<String, SearchResponse> searchResults;
  final Map<String, bool> loadingStates;
  final Function(String) onSourceSelected;
  final ScrollController scrollController;
  final int focusedIndex;
  final bool isSearching;

  const SearchSourceList({
    super.key,
    required this.sources,
    required this.selectedSourceId,
    required this.searchResults,
    required this.loadingStates,
    required this.onSourceSelected,
    required this.scrollController,
    required this.focusedIndex,
    required this.isSearching,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: sources.length,
      itemBuilder: (context, index) {
        final source = sources[index];
        final isSelected = selectedSourceId == source.id;
        final hasResults = searchResults[source.id]?.hasResults ?? false;
        final isLoading = isSearching && (loadingStates[source.id] ?? false);
        final resultCount = searchResults[source.id]?.results.length ?? 0;
        final response = searchResults[source.id];

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: FocusableGlow(
            onTap: () => onSourceSelected(source.id),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected 
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 源站名称和图标
                    Row(
                      children: [
                        // 源站颜色标识
                        Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _parseColor(source.color),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        // 源站名称
                        Expanded(
                          child: Text(
                            source.name,
                            style: AppTypography.titleSmall.copyWith(
                              color: Colors.white,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ),
                        
                        // 状态指示器
                        if (isLoading) ...[
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ] else if (hasResults) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _parseColor(source.color).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$resultCount',
                              style: AppTypography.labelSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ] else if (response != null && !response.isSuccess) ...[
                          Icon(
                            Icons.error_outline,
                            size: 16,
                            color: Colors.redAccent,
                          ),
                        ],
                      ],
                    ),
                    
                    // 错误信息或结果预览
                    if (response != null && !response.isSuccess) ...[
                      const SizedBox(height: 8),
                      Text(
                        response.message,
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.redAccent,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ] else if (hasResults && isSelected) ...[
                      const SizedBox(height: 8),
                      Text(
                        '找到 $resultCount 个结果',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 解析颜色字符串
  Color _parseColor(String colorString) {
    try {
      final hexColor = colorString.replaceAll('#', '');
      return Color(int.parse('FF$hexColor', radix: 16));
    } catch (e) {
      return Colors.blue; // 默认颜色
    }
  }
}