import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/page_transitions.dart';
import 'bbx_category_listings_screen.dart';

/// BBX 分类页面
class BBXCategoriesScreen extends StatelessWidget {
  const BBXCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'name': 'Plastic', 'label': '塑料制品', 'icon': Icons.recycling_rounded, 'count': 145},
      {'name': 'Metal', 'label': '金属废料', 'icon': Icons.hardware_rounded, 'count': 98},
      {'name': 'Paper', 'label': '纸类废料', 'icon': Icons.description_rounded, 'count': 76},
      {'name': 'Glass', 'label': '玻璃制品', 'icon': Icons.lightbulb_rounded, 'count': 54},
      {'name': 'Electronic', 'label': '电子废料', 'icon': Icons.devices_rounded, 'count': 123},
      {'name': 'Organic', 'label': '有机废料', 'icon': Icons.eco_rounded, 'count': 32},
      {'name': 'Construction', 'label': '建筑废料', 'icon': Icons.construction_rounded, 'count': 67},
      {'name': 'Textile', 'label': '纺织废料', 'icon': Icons.checkroom_rounded, 'count': 41},
      {'name': 'Others', 'label': '其他', 'icon': Icons.more_horiz_rounded, 'count': 29},
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('商品分类', style: AppTheme.heading2),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              // 打开搜索页面
            },
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.95,
          crossAxisSpacing: AppTheme.spacing16,
          mainAxisSpacing: AppTheme.spacing16,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final color = AppTheme.getCategoryColor(category['name'] as String);

          return GestureDetector(
            onTap: () {
              PageTransitions.navigateTo(
                context,
                BBXCategoryListingsScreen(
                  category: category['name'] as String,
                  categoryLabel: category['label'] as String,
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppTheme.borderRadiusLarge,
                boxShadow: AppTheme.elevation2,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    category['icon'] as IconData,
                    color: Colors.white,
                    size: 64,
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  Text(
                    category['label'] as String,
                    style: AppTheme.heading3.copyWith(
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    '${category['count']} 个商�?,
                    style: AppTheme.caption.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
