import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bbx_button.dart';
import '../../widgets/bbx_chip.dart';
import '../../widgets/bbx_card.dart';
import '../../widgets/bbx_empty_state.dart';
import '../../widgets/bbx_loading.dart';
import '../../models/listing_model.dart';
import '../search/bbx_new_search_screen.dart';
import '../categories/bbx_categories_screen.dart';
import '../categories/bbx_category_listings_screen.dart';
import '../../utils/page_transitions.dart';

/// BBX 全新首页（按照UI/UX重构指令设计）
class BBXNewHomeScreen extends StatefulWidget {
  const BBXNewHomeScreen({super.key});

  @override
  State<BBXNewHomeScreen> createState() => _BBXNewHomeScreenState();
}

class _BBXNewHomeScreenState extends State<BBXNewHomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppTheme.primary500,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // 顶部AppBar
              _buildAppBar(),

              // 搜索栏区域
              _buildSearchBar(),

              // 快捷分类卡片
              _buildQuickCategories(),

              // 功能卡片区域
              _buildFeatureCards(),

              // 推荐商品区域
              _buildRecommendedListings(),
            ],
          ),
        ),
      ),
    );
  }

  /// 顶部AppBar
  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 80,
      title: Row(
        children: [
          // Logo (可以替换为实际logo)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primary500,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'BBX',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: AppTheme.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacing12),
          const Text(
            'BBX Marketplace',
            style: AppTheme.heading3,
          ),
        ],
      ),
      actions: [
        BBXIconButton(
          icon: Icons.notifications_rounded,
          onPressed: () {},
          showBadge: true,
        ),
        BBXIconButton(
          icon: Icons.qr_code_scanner_rounded,
          onPressed: () {},
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: AppTheme.neutral300,
        ),
      ),
    );
  }

  /// 搜索栏区域
  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Container(
        color: AppTheme.neutral100,
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: GestureDetector(
          onTap: () {
            PageTransitions.navigateTo(context, const BBXNewSearchScreen());
          },
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppTheme.borderRadiusLarge,
              boxShadow: AppTheme.elevation1,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  color: AppTheme.neutral500,
                ),
                const SizedBox(width: AppTheme.spacing12),
                const Expanded(
                  child: Text(
                    '搜索废料类型、商品...',
                    style: TextStyle(
                      color: AppTheme.neutral500,
                      fontSize: 16,
                    ),
                  ),
                ),
                BBXIconButton(
                  icon: Icons.tune_rounded,
                  onPressed: () {},
                  size: 40,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 快捷分类卡片
  Widget _buildQuickCategories() {
    final categories = [
      {'name': 'Plastic', 'label': '塑料', 'icon': Icons.recycling_rounded},
      {'name': 'Metal', 'label': '金属', 'icon': Icons.hardware_rounded},
      {'name': 'Paper', 'label': '纸类', 'icon': Icons.description_rounded},
      {'name': 'Glass', 'label': '玻璃', 'icon': Icons.lightbulb_rounded},
      {'name': 'Electronic', 'label': '电子', 'icon': Icons.devices_rounded},
      {'name': 'Organic', 'label': '有机', 'icon': Icons.eco_rounded},
      {'name': 'all', 'label': '全部', 'icon': Icons.apps_rounded},
    ];

    return SliverToBoxAdapter(
      child: Container(
        height: 120,
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final isAll = category['name'] == 'all';
            final color = isAll
                ? AppTheme.neutral500
                : AppTheme.getCategoryColor(category['name'] as String);

            return GestureDetector(
              onTap: () {
                if (isAll) {
                  PageTransitions.navigateTo(
                    context,
                    const BBXCategoriesScreen(),
                  );
                } else {
                  PageTransitions.navigateTo(
                    context,
                    BBXCategoryListingsScreen(
                      category: category['name'] as String,
                      categoryLabel: category['label'] as String,
                    ),
                  );
                }
              },
              child: Container(
                width: 100,
                margin: const EdgeInsets.only(right: AppTheme.spacing12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppTheme.borderRadiusLarge,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      category['icon'] as IconData,
                      color: Colors.white,
                      size: 40,
                    ),
                    const SizedBox(height: AppTheme.spacing8),
                    Text(
                      category['label'] as String,
                      style: AppTheme.body2.copyWith(
                        color: Colors.white,
                        fontWeight: AppTheme.semibold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 功能卡片区域
  Widget _buildFeatureCards() {
    final features = [
      {
        'title': '我的报价',
        'description': '查看报价状态',
        'icon': Icons.local_offer_rounded,
        'route': '/my-offers',
      },
      {
        'title': '我的交易',
        'description': '跟踪订单',
        'icon': Icons.receipt_long_rounded,
        'route': '/transactions',
      },
      {
        'title': '收藏夹',
        'description': '我的收藏',
        'icon': Icons.favorite_rounded,
        'route': '/favorites',
      },
      {
        'title': '附近商品',
        'description': '查找附近',
        'icon': Icons.location_on_rounded,
        'route': '/nearby',
      },
    ];

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('快捷功能', style: AppTheme.heading4),
            const SizedBox(height: AppTheme.spacing12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: AppTheme.spacing12,
                mainAxisSpacing: AppTheme.spacing12,
              ),
              itemCount: features.length,
              itemBuilder: (context, index) {
                final feature = features[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, feature['route'] as String);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppTheme.borderRadiusMedium,
                      boxShadow: AppTheme.elevation1,
                    ),
                    padding: const EdgeInsets.all(AppTheme.spacing16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            feature['icon'] as IconData,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing8),
                        Text(
                          feature['title'] as String,
                          style: AppTheme.body1.copyWith(
                            fontWeight: AppTheme.semibold,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing4),
                        Text(
                          feature['description'] as String,
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.neutral500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 推荐商品区域
  Widget _buildRecommendedListings() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('为你推荐', style: AppTheme.heading4),
                BBXTextButton(
                  text: '查看全部',
                  onPressed: () {
                    Navigator.pushNamed(context, '/marketplace');
                  },
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('listings')
                  .where('status', isEqualTo: 'active')
                  .limit(10)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return BBXEmptyState.noData(
                    description: '加载失败，请重试',
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const BBXListLoading(itemCount: 3);
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return BBXEmptyState.noData(
                    description: '暂无商品',
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final listing = ListingModel.fromDocument(doc);

                    return BBXListingCard(
                      imageUrl: listing.imageUrls.isNotEmpty
                          ? listing.imageUrls.first
                          : '',
                      title: listing.title,
                      category: listing.wasteType,
                      price: listing.pricePerUnit,
                      unit: listing.unit,
                      quantity: '${listing.quantity} ${listing.unit}',
                      sellerName: listing.userEmail,
                      onTap: () {
                        // 导航到商品详情页
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
