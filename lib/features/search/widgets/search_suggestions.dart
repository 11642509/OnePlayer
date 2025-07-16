import 'package:flutter/material.dart';
import '../../../shared/models/search_page_state.dart';
import '../../../shared/widgets/common/glass_container.dart';
import '../../../app/theme/typography.dart';
import '../../../core/remote_control/focusable_glow.dart';

/// 搜索建议组件
class SearchSuggestions extends StatelessWidget {
  final List<SearchSuggestion> suggestions;
  final Function(String) onSuggestionSelected;
  final int maxItems;

  const SearchSuggestions({
    super.key,
    required this.suggestions,
    required this.onSuggestionSelected,
    this.maxItems = 8,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    // 按类型和频率排序建议
    final sortedSuggestions = suggestions.take(maxItems).toList();
    sortedSuggestions.sort((a, b) {
      // 历史记录优先级最高
      if (a.type == SearchSuggestionType.history && b.type != SearchSuggestionType.history) {
        return -1;
      }
      if (b.type == SearchSuggestionType.history && a.type != SearchSuggestionType.history) {
        return 1;
      }
      // 按频率排序
      return b.frequency.compareTo(a.frequency);
    });

    return GlassContainer(
      borderRadius: 12,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 300),
        child: ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.all(8),
          itemCount: sortedSuggestions.length,
          itemBuilder: (context, index) {
            final suggestion = sortedSuggestions[index];
            return _buildSuggestionItem(suggestion);
          },
        ),
      ),
    );
  }

  /// 构建建议项
  Widget _buildSuggestionItem(SearchSuggestion suggestion) {
    return FocusableGlow(
      onTap: () => onSuggestionSelected(suggestion.text),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // 建议类型图标
            Icon(
              _getIconForType(suggestion.type),
              size: 16,
              color: Colors.white70,
            ),
            
            const SizedBox(width: 12),
            
            // 建议文本
            Expanded(
              child: Text(
                suggestion.text,
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // 频率指示器（仅历史记录）
            if (suggestion.type == SearchSuggestionType.history && suggestion.frequency > 1) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${suggestion.frequency}',
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white54,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 获取建议类型对应的图标
  IconData _getIconForType(SearchSuggestionType type) {
    switch (type) {
      case SearchSuggestionType.history:
        return Icons.history;
      case SearchSuggestionType.hotword:
        return Icons.trending_up;
      case SearchSuggestionType.autocomplete:
        return Icons.search;
    }
  }
}