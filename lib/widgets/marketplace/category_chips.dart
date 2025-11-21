import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// 分类标签组件
class CategoryChips extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const CategoryChips({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  static const List<Map<String, String>> categories = [
    {'id': 'all', 'label': '全部', 'emoji': '📦'},
    {'id': 'EFB (Empty Fruit Bunches)', 'label': '棕榈果串', 'emoji': '🌴'},
    {'id': 'POME (Palm Oil Mill Effluent)', 'label': '棕榈废液', 'emoji': '💧'},
    {'id': 'Palm Shell', 'label': '棕榈�?, 'emoji': '🥥'},
    {'id': 'Palm Fiber', 'label': '棕榈纤维', 'emoji': '🌾'},
    {'id': 'Other Biomass', 'label': '其他生物�?, 'emoji': '🎋'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: AppTheme.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMD,
          vertical: AppTheme.spacingSM,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category['id'];

          return Padding(
            padding: const EdgeInsets.only(right: AppTheme.spacingSM),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    category['emoji']!,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    category['label']!,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              selected: isSelected,
              onSelected: (_) => onCategorySelected(category['id']!),
              backgroundColor: AppTheme.surface,
              selectedColor: AppTheme.primaryLight,
              checkmarkColor: AppTheme.primary,
              side: BorderSide(
                color: isSelected ? AppTheme.primary : AppTheme.divider,
                width: isSelected ? 1.5 : 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: AppTheme.borderRadiusStandard,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMD,
                vertical: AppTheme.spacingSM,
              ),
            ),
          );
        },
      ),
    );
  }
}
