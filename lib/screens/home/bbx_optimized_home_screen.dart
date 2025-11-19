import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../widgets/enhanced/modern_search.dart';
import '../../widgets/enhanced/modern_card.dart';
import '../../models/listing_model.dart';
import '../search/bbx_new_search_screen.dart';
import '../categories/bbx_category_listings_screen.dart';
import '../../utils/page_transitions.dart';

/// BBX 首页 - 完全优化版
/// 适配 Pixel 5 (393 x 851 dp)
/// Material Design 3 风格，现代化设计
class BBXOptimizedHomeScreen extends StatefulWidget {
  const BBXOptimizedHomeScreen({super.key});

  @override
  State<BBXOptimizedHomeScreen> createState() => _BBXOptimizedHomeScreenState();
}

class _BBXOptimizedHomeScreenState extends State<BBXOptimizedHomeScreen>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  bool _showGreeting = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // 滚动时隐藏问候语
    if (_scrollController.offset > 50 && _showGreeting) {
      setState(() => _showGreeting = false);
    } else if (_scrollController.offset <= 50 && !_showGreeting) {
      setState(() => _showGreeting = true);
    }
  }

  Future<void> _onRefresh() async {
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用，因为使用了 AutomaticKeepAliveClientMixin
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppTheme.primary500,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 顶部栏
            _buildSliverAppBar(),

            // 搜索栏区域
            _buildSearchSection(),

            // 快捷分类（横向滚动）
            _buildQuickCategories(),

            // 快捷功能卡片
            _buildQuickActions(),

            // Banner广告位（可选）
            _buildPromotionBanner(),

            // 为你推荐 - 商品列表
            _buildRecommendedSection(),

            // 底部间距
            const SliverToBoxAdapter(
              child: SizedBox(height: AppTheme.spacing24),
            ),
          ],
        ),
      ),
    );
  }

  /// 顶部 AppBar
  Widget _buildSliverAppBar() {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? '用户';
    final greeting = _getGreeting();

    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(
          AppTheme.spacing16,
          MediaQuery.of(context).padding.top + AppTheme.spacing12,
          AppTheme.spacing16,
          AppTheme.spacing16,
        ),
        child: Row(
          children: [
            // Logo 和标题
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary500.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
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

            // 问候语
            Expanded(
              child: AnimatedOpacity(
                opacity: _showGreeting ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.neutral600,
                      ),
                    ),
                    Text(
                      userName,
                      style: AppTheme.heading4.copyWith(height: 1.2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            // 通知按钮
            _buildNotificationButton(),

            const SizedBox(width: AppTheme.spacing8),

            // 扫码按钮
            _buildScanButton(),
          ],
        ),
      ),
    );
  }

  /// 搜索区域
  Widget _buildSearchSection() {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacing16,
          0,
          AppTheme.spacing16,
          AppTheme.spacing16,
        ),
        child: ModernSearchBar(
          hintText: '搜索废料类型、商品...',
          showFilter: true,
          showVoiceSearch: false,
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const BBXNewSearchScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
            );
          },
          onFilter: () {
            Navigator.pushNamed(context, '/advanced-search');
          },
        ),
      ),
    );
  }

  /// 快捷分类（横向滚动）
  Widget _buildQuickCategories() {
    final categories = [
      {'name': 'Plastic', 'label': '塑料', 'icon': '♻️', 'color': AppTheme.plastic},
      {'name': 'Metal', 'label': '金属', 'icon': '🔩', 'color': AppTheme.metal},
      {'name': 'Paper', 'label': '纸类', 'icon': '📄', 'color': AppTheme.paper},
      {'name': 'Glass', 'label': '玻璃', 'icon': '🍾', 'color': AppTheme.glass},
      {'name': 'Electronic', 'label': '电子', 'icon': '💻', 'color': AppTheme.electronic},
      {'name': 'Organic', 'label': '有机', 'icon': '🌿', 'color': AppTheme.organic},
    ];

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppTheme.spacing8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
            child: Row(
              children: [
                const Text('废料分类', style: AppTheme.heading4),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/categories');
                  },
                  child: Row(
                    children: [
                      Text(
                        '全部',
                        style: AppTheme.body2.copyWith(
                          color: AppTheme.primary500,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: AppTheme.primary500,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return _buildCategoryCard(
                  name: category['name'] as String,
                  label: category['label'] as String,
                  emoji: category['icon'] as String,
                  color: category['color'] as Color,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BBXCategoryListingsScreen(
                          category: category['name'] as String,
                          categoryLabel: category['label'] as String,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 快捷功能
  Widget _buildQuickActions() {
    final actions = [
      {
        'title': '我的报价',
        'subtitle': '5 条待处理',
        'icon': Icons.local_offer_rounded,
        'gradient': const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
        ),
        'route': '/my-offers',
      },
      {
        'title': '我的交易',
        'subtitle': '2 笔进行中',
        'icon': Icons.receipt_long_rounded,
        'gradient': const LinearGradient(
          colors: [Color(0xFF4ECDC4), Color(0xFF44D9C0)],
        ),
        'route': '/transactions',
      },
      {
        'title': '附近商品',
        'subtitle': '基于位置',
        'icon': Icons.location_on_rounded,
        'gradient': const LinearGradient(
          colors: [Color(0xFFF7B731), Color(0xFFF7CE66)],
        ),
        'route': '/nearby',
      },
      {
        'title': '我的收藏',
        'subtitle': '8 个商品',
        'icon': Icons.favorite_rounded,
        'gradient': const LinearGradient(
          colors: [Color(0xFFEE5A6F), Color(0xFFF082A5)],
        ),
        'route': '/favorites',
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
                childAspectRatio: 1.6,
                crossAxisSpacing: AppTheme.spacing12,
                mainAxisSpacing: AppTheme.spacing12,
              ),
              itemCount: actions.length,
              itemBuilder: (context, index) {
                final action = actions[index];
                return _buildActionCard(
                  title: action['title'] as String,
                  subtitle: action['subtitle'] as String,
                  icon: action['icon'] as IconData,
                  gradient: action['gradient'] as LinearGradient,
                  onTap: () {
                    Navigator.pushNamed(context, action['route'] as String);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Banner 推广位
  Widget _buildPromotionBanner() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          AppTheme.spacing16,
          0,
          AppTheme.spacing16,
          AppTheme.spacing16,
        ),
        height: 140,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppTheme.borderRadiusLarge,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667EEA).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 背景装饰
            Positioned(
              right: -20,
              bottom: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 40,
              top: -30,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // 内容
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacing20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '限时优惠',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: AppTheme.semibold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '升级专业版\n享受更多特权',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: AppTheme.bold,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/subscription');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF667EEA),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            '立即升级',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: AppTheme.semibold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.workspace_premium_rounded,
                    color: Colors.white,
                    size: 60,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 推荐商品区域
  Widget _buildRecommendedSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('为你推荐', style: AppTheme.heading4),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/marketplace');
                  },
                  child: Row(
                    children: [
                      Text(
                        '查看全部',
                        style: AppTheme.body2.copyWith(
                          color: AppTheme.primary500,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: AppTheme.primary500,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing8),
            _buildListingList(),
          ],
        ),
      ),
    );
  }

  /// 商品列表
  Widget _buildListingList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('listings')
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState();
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            try {
              final listing = ListingModel.fromDocument(doc);
              return ModernListingCard(
                imageUrl: listing.imageUrls.isNotEmpty
                    ? listing.imageUrls.first
                    : '',
                title: listing.title,
                category: listing.wasteType,
                price: listing.pricePerUnit,
                unit: listing.unit,
                location: (listing.location ?? '未知位置').toString(),
                sellerName: listing.userEmail,
                rating: 4.8,
                reviewCount: 125,
                isVerified: true,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/listing-detail',
                    arguments: {'listingId': listing.id},
                  );
                },
                onFavorite: () {
                  // 处理收藏逻辑
                },
              );
            } catch (e) {
              debugPrint('Error parsing listing: $e');
              return const SizedBox.shrink();
            }
          },
        );
      },
    );
  }

  /// 分类卡片
  Widget _buildCategoryCard({
    required String name,
    required String label,
    required String emoji,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: AppTheme.spacing12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppTheme.borderRadiusLarge,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: AppTheme.semibold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 功能卡片
  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: AppTheme.borderRadiusLarge,
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: AppTheme.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 通知按钮
  Widget _buildNotificationButton() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.neutral50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
            icon: const Icon(
              Icons.notifications_rounded,
              color: AppTheme.neutral700,
              size: 22,
            ),
          ),
        ),
        // 红点提示
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppTheme.error,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  /// 扫码按钮
  Widget _buildScanButton() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.neutral50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: () {
          // 打开扫码页面
        },
        icon: const Icon(
          Icons.qr_code_scanner_rounded,
          color: AppTheme.neutral700,
          size: 22,
        ),
      ),
    );
  }

  /// 加载状态
  Widget _buildLoadingState() {
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing16,
            vertical: AppTheme.spacing8,
          ),
          height: 280,
          decoration: BoxDecoration(
            color: AppTheme.neutral100,
            borderRadius: AppTheme.borderRadiusLarge,
          ),
        ),
      ),
    );
  }

  /// 错误状态
  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing32),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: AppTheme.neutral400,
          ),
          const SizedBox(height: AppTheme.spacing16),
          Text(
            '加载失败',
            style: AppTheme.heading4.copyWith(
              color: AppTheme.neutral600,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            '请检查网络连接后重试',
            style: AppTheme.body2.copyWith(
              color: AppTheme.neutral500,
            ),
          ),
        ],
      ),
    );
  }

  /// 空状态
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing32),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: AppTheme.neutral400,
          ),
          const SizedBox(height: AppTheme.spacing16),
          Text(
            '暂无商品',
            style: AppTheme.heading4.copyWith(
              color: AppTheme.neutral600,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            '稍后再来看看吧',
            style: AppTheme.body2.copyWith(
              color: AppTheme.neutral500,
            ),
          ),
        ],
      ),
    );
  }

  /// 获取问候语
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return '早上好 👋';
    } else if (hour < 18) {
      return '下午好 ☀️';
    } else {
      return '晚上好 🌙';
    }
  }
}

