import 'package:flutter/material.dart';

class BBXHomeProgressive extends StatelessWidget {
  const BBXHomeProgressive({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top),
            
            _buildTopBar(context),
            
            _buildSearchBar(context),

            _buildSectionTitle(context, 'Waste Categories'),

            _buildCategories(context),

            _buildSectionTitle(context, 'Quick Actions'),

            _buildQuickActions(context),

            // Banner
            _buildBanner(context),

            _buildSectionTitle(context, 'Recommended'),

            _buildProductsPlaceholder(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Logo
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'BBX',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good Morning 👋',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF757575),
                  ),
                ),
                Text(
                  'BBX User',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No new notifications'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('QR Code Scanner coming soon...'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, '/search');
        },
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 20),
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Search waste types, items...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/advanced-search');
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF2E7D32),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    size: 20,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              if (title == 'Waste Categories') {
                Navigator.pushNamed(context, '/categories');
              } else if (title == 'Quick Actions') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('More features coming soon...'),
                    duration: Duration(seconds: 2),
                  ),
                );
              } else if (title == 'Recommended') {
                Navigator.pushNamed(context, '/marketplace');
              }
            },
            child: Row(
              children: const [
                Text(
                  'All',
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 14,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Color(0xFF2E7D32),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildCategoryCard(context, '♻️', 'Plastic', const Color(0xFF2196F3)),
          const SizedBox(width: 8),
          _buildCategoryCard(context, '🔩', 'Metal', const Color(0xFFFF9800)),
          const SizedBox(width: 8),
          _buildCategoryCard(context, '📄', 'Paper', const Color(0xFF8BC34A)),
          const SizedBox(width: 8),
          _buildCategoryCard(context, '🍾', 'Glass', const Color(0xFF00BCD4)),
          const SizedBox(width: 8),
          _buildCategoryCard(context, '💻', 'E-Waste', const Color(0xFF9C27B0)),
          const SizedBox(width: 8),
          _buildCategoryCard(context, '🌿', 'Organic', const Color(0xFF795548)),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, String emoji, String label, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/category-listings',
          arguments: {'category': label},
        );
      },
      child: Container(
        width: 90,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  context,
                  'My Quote',
                  'Pending: 5',
                  Icons.local_offer_outlined,
                  const Color(0xFFFF6B6B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  context,
                  'My Transactions',
                  'Ongoing: 2',
                  Icons.receipt_long_outlined,
                  const Color(0xFF4ECDC4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  context,
                  'Nearby Items',
                  'Explore Nearby',
                  Icons.location_on_outlined,
                  const Color(0xFFFFC371),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  context,
                  'My Favorites',
                  'Saved: 12',
                  Icons.favorite_outline,
                  const Color(0xFFEC6EAD),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return GestureDetector(
      onTap: () {
        if (title == 'My Quote') {
          Navigator.pushNamed(context, '/my-offers');
        } else if (title == 'My Transactions') {
          Navigator.pushNamed(context, '/transactions');
        } else if (title == 'Nearby Items') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Nearby Items feature coming soon...'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.orange.shade700,
            ),
          );
        } else if (title == 'My Favorites') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('My Favorites feature coming soon...'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.pink.shade700,
            ),
          );
        }
      },
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white,
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

  Widget _buildBanner(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/subscription');
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFF667EEA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Upgrade to Pro',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Enjoy more privileges and features',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.workspace_premium,
                color: Colors.white,
                size: 64,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductsPlaceholder() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: Color(0xFF9E9E9E),
            ),
            SizedBox(height: 12),
            Text(
              'Product List Loading Area',
              style: TextStyle(color: Color(0xFF757575)),
            ),
          ],
        ),
      ),
    );
  }
}
