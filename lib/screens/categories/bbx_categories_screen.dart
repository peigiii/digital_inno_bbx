import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/page_transitions.dart';
import 'bbx_category_listings_screen.dart';

class BBXCategoriesScreen extends StatelessWidget {
  const BBXCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'name': 'Plastic', 'label': 'PlasticMakeItem', 'icon': Icons.recycling_rounded, 'count': 145},
      {'name': 'Metal', 'label': 'MetalWaste', 'icon': Icons.hardware_rounded, 'count': 98},
      {'name': 'Paper', 'label': 'PaperWaste', 'icon': Icons.description_rounded, 'count': 76},
      {'name': 'Glass', 'label': 'GlassMakeItem', 'icon': Icons.lightbulb_rounded, 'count': 54},
      {'name': 'Electronic', 'label': 'E-Waste', 'icon': Icons.devices_rounded, 'count': 123},
      {'name': 'Organic', 'label': 'Organic Waste', 'icon': Icons.eco_rounded, 'count': 32},
      {'name': 'Construction', 'label': 'Construction Waste', 'icon': Icons.construction_rounded, 'count': 67},
      {'name': 'Textile', 'label': 'Textile Waste', 'icon': Icons.checkroom_rounded, 'count': 41},
      {'name': 'Others', 'label': 'Other', 'icon': Icons.more_horiz_rounded, 'count': 29},
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Item Category', style: AppTheme.heading2),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
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
                    '${category['count']} Items?,
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
