import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../widgets/enhanced/modern_search.dart';
import '../../widgets/enhanced/modern_card.dart';
import '../../widgets/enhanced/shimmer_loading.dart';
import '../../models/listing_model.dart';
import '../search/bbx_new_search_screen.dart';
import '../categories/bbx_category_listings_screen.dart';

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
    super.build(context);
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppTheme.primary500,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildSliverAppBar(),

            _buildSearchSection(),

            _buildQuickCategories(),

            _buildQuickActions(),

            _buildPromotionBanner(),

            _buildRecommendedSection(),

            const SliverToBoxAdapter(
              child: SizedBox(height: AppTheme.spacing24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? 'User';
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

            _buildNotificationButton(),

            const SizedBox(width: AppTheme.spacing8),

            _buildScanButton(),
          ],
        ),
      ),
    );
  }

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
          hintText: 'Search waste types, companies...',
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

  Widget _buildQuickCategories() {
    final categories = [
      {'name': 'Plastic', 'label': 'Plastic', 'icon': '♻️', 'color': AppTheme.plastic},
      {'name': 'Metal', 'label': 'Metal', 'icon': '🔩', 'color': AppTheme.metal},
      {'name': 'Paper', 'label': 'Paper', 'icon': '📄', 'color': AppTheme.paper},
      {'name': 'Glass', 'label': 'Glass', 'icon': '🍾', 'color': AppTheme.glass},
      {'name': 'Electronic', 'label': 'Electronic', 'icon': '💻', 'color': AppTheme.electronic},
      {'name': 'Organic', 'label': 'Organic', 'icon': '🌿', 'color': AppTheme.organic},
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
                const Text('Categories', style: AppTheme.heading4),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/categories');
                  },
                  child: Row(
                    children: [
                      Text(
                        'View All',
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

  Widget _buildQuickActions() {
    final actions = [
      {
        'title': 'My Quotes',
        'subtitle': '5 Pending',
        'icon': Icons.local_offer_rounded,
        'gradient': const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
        ),
        'route': '/my-offers',
      },
      {
        'title': 'My Transactions',
        'subtitle': '2 In Progress',
        'icon': Icons.receipt_long_rounded,
        'gradient': const LinearGradient(
          colors: [Color(0xFF4ECDC4), Color(0xFF44D9C0)],
        ),
        'route': '/transactions',
      },
      {
        'title': 'Nearby',
        'subtitle': 'Based on location',
        'icon': Icons.location_on_rounded,
        'gradient': const LinearGradient(
          colors: [Color(0xFFF7B731), Color(0xFFF7CE66)],
        ),
        'route': '/nearby',
      },
      {
        'title': 'My Favorites',
        'subtitle': '8 Items',
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
            const Text('Quick Actions', style: AppTheme.heading4),
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
                            'Limited Time Offer',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: AppTheme.semibold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Upgrade to Professional\nGet more benefits',
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
                            'Upgrade Now',
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

  Widget _buildRecommendedSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Recommended', style: AppTheme.heading4),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/marketplace');
                  },
                  child: Row(
                    children: [
                      Text(
                        'View All',
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
                heroTag: listing.imageUrls.isNotEmpty ? listing.imageUrls.first : null,
                imageUrl: listing.imageUrls.isNotEmpty
                    ? listing.imageUrls.first
                    : '',
                title: listing.title,
                category: listing.wasteType,
                price: listing.pricePerUnit,
                unit: listing.unit,
                location: (listing.location ?? 'Unknown Location').toString(),
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
                  // TODO: Implement favorite logic
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
          // TODO: Implement QR Scan
        },
        icon: const Icon(
          Icons.qr_code_scanner_rounded,
          color: AppTheme.neutral700,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
      child: Column(
        children: List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacing16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppTheme.borderRadiusLarge,
                border: Border.all(color: AppTheme.neutral200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerLoading.rounded(
                    width: double.infinity,
                    height: 180,
                    shapeBorder: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerLoading.rectangular(height: 20, width: 200),
                        const SizedBox(height: 8),
                        ShimmerLoading.rectangular(height: 14, width: 150),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ShimmerLoading.rectangular(height: 24, width: 100),
                            ShimmerLoading.rectangular(height: 36, width: 80),
                          ],
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
    );
  }

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
            'Failed to load',
            style: AppTheme.heading4.copyWith(
              color: AppTheme.neutral600,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'Please check network connection',
            style: AppTheme.body2.copyWith(
              color: AppTheme.neutral500,
            ),
          ),
        ],
      ),
    );
  }

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
            'No listings found',
            style: AppTheme.heading4.copyWith(
              color: AppTheme.neutral600,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'Check back later',
            style: AppTheme.body2.copyWith(
              color: AppTheme.neutral500,
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning 👋';
    } else if (hour < 18) {
      return 'Good Afternoon ☀️';
    } else {
      return 'Good Evening 🌙';
    }
  }
}
