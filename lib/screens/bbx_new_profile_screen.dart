import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../widgets/common/shimmer_loading.dart';

class BBXNewProfileScreen extends StatefulWidget {
  const BBXNewProfileScreen({Key? key}) : super(key: key);

  @override
  State<BBXNewProfileScreen> createState() => _BBXNewProfileScreenState();
}

class _BBXNewProfileScreenState extends State<BBXNewProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      // Navigate to login screen
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_off, size: 80, color: AppTheme.textLight),
              const SizedBox(height: 16),
              const Text(
                'Please login to access your profile',
                style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>?;

          return CustomScrollView(
            slivers: [
              // User header card
              SliverToBoxAdapter(
                child: _buildUserHeader(userData),
              ),

              // Orders section
              SliverToBoxAdapter(
                child: _buildOrdersSection(),
              ),

              // My transactions section
              SliverToBoxAdapter(
                child: _buildTransactionsSection(),
              ),

              // My services section
              SliverToBoxAdapter(
                child: _buildServicesSection(),
              ),

              // Help & support section
              SliverToBoxAdapter(
                child: _buildHelpSection(),
              ),

              // Logout button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingLG),
                  child: OutlinedButton(
                    onPressed: _handleLogout,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppTheme.error),
                      foregroundColor: AppTheme.error,
                    ),
                    child: const Text(
                      'Logout',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserHeader(Map<String, dynamic>? userData) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary,
            AppTheme.primaryDark,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLG),
          child: Column(
            children: [
              // Avatar and user info
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 38,
                      backgroundColor: AppTheme.primary.withOpacity(0.3),
                      child: Text(
                        (userData?['displayName'] ?? user!.email ?? 'U')[0]
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                userData?['displayName'] ?? user!.email ?? 'User',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (userData?['isVerified'] == true)
                              const Icon(
                                Icons.verified,
                                size: 20,
                                color: Colors.white,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.diamond,
                                size: 14,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Gold Member',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // Navigate to settings
                    },
                    icon: const Icon(
                      Icons.settings,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Stats cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.stars,
                      label: 'Points',
                      value: '1,250',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.card_giftcard,
                      label: 'Coupons',
                      value: '3',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.account_balance_wallet,
                      label: 'Balance',
                      value: 'RM 0',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersSection() {
    return Container(
      margin: const EdgeInsets.only(top: AppTheme.spacingMD),
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Orders',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to all orders
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOrderItem(
                icon: Icons.payment,
                label: 'To Pay',
                badge: '2',
                onTap: () {},
              ),
              _buildOrderItem(
                icon: Icons.inventory_2,
                label: 'To Ship',
                badge: null,
                onTap: () {},
              ),
              _buildOrderItem(
                icon: Icons.local_shipping,
                label: 'Shipped',
                badge: '1',
                onTap: () {},
              ),
              _buildOrderItem(
                icon: Icons.rate_review,
                label: 'Review',
                badge: null,
                onTap: () {},
              ),
              _buildOrderItem(
                icon: Icons.assignment_return,
                label: 'Return',
                badge: null,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem({
    required IconData icon,
    required String label,
    String? badge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 60,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 32, color: AppTheme.primary),
                if (badge != null)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsSection() {
    final items = [
      {'icon': Icons.post_add, 'label': 'My Listings', 'route': '/my-listings'},
      {'icon': Icons.request_quote, 'label': 'My Quotes', 'route': '/my-quotes'},
      {'icon': Icons.favorite, 'label': 'Favorites', 'route': '/favorites'},
      {'icon': Icons.history, 'label': 'History', 'route': '/history'},
      {'icon': Icons.star_rate, 'label': 'Reviews', 'route': '/reviews'},
      {'icon': Icons.analytics, 'label': 'Analytics', 'route': '/analytics'},
    ];

    return Container(
      margin: const EdgeInsets.only(top: AppTheme.spacingMD),
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Transactions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: items.map((item) {
              return InkWell(
                onTap: () {
                  // Navigator.pushNamed(context, item['route'] as String);
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      size: 32,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['label'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection() {
    final items = [
      {'icon': Icons.location_on, 'label': 'Address Management', 'route': '/addresses'},
      {'icon': Icons.credit_card, 'label': 'Payment Methods', 'route': '/payment-methods'},
      {'icon': Icons.description, 'label': 'Contracts', 'route': '/contracts'},
      {'icon': Icons.receipt_long, 'label': 'Invoices', 'route': '/invoices'},
      {'icon': Icons.notifications, 'label': 'Notifications', 'route': '/notifications'},
      {'icon': Icons.manage_accounts, 'label': 'Account Settings', 'route': '/account-settings'},
    ];

    return Container(
      margin: const EdgeInsets.only(top: AppTheme.spacingMD),
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSM),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingLG),
            child: Text(
              'My Services',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => _buildListTile(
                icon: item['icon'] as IconData,
                label: item['label'] as String,
                onTap: () {
                  // Navigator.pushNamed(context, item['route'] as String);
                },
              )),
        ],
      ),
    );
  }

  Widget _buildHelpSection() {
    final items = [
      {'icon': Icons.support_agent, 'label': 'Customer Service', 'route': '/customer-service'},
      {'icon': Icons.contact_support, 'label': 'Contact Us', 'route': '/contact'},
      {'icon': Icons.help_center, 'label': 'Help Center', 'route': '/help'},
      {'icon': Icons.video_library, 'label': 'Tutorials', 'route': '/tutorials'},
      {'icon': Icons.info, 'label': 'About BBX', 'route': '/about'},
    ];

    return Container(
      margin: const EdgeInsets.only(top: AppTheme.spacingMD),
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSM),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingLG),
            child: Text(
              'Help & Support',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => _buildListTile(
                icon: item['icon'] as IconData,
                label: item['label'] as String,
                onTap: () {
                  // Navigator.pushNamed(context, item['route'] as String);
                },
              )),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textLight),
      onTap: onTap,
    );
  }
}
