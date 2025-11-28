import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import 'bbx_my_listings_standalone_screen.dart';
import 'offers/bbx_my_offers_screen.dart';
import 'bbx_favorites_standalone_screen.dart';
import 'bbx_history_standalone_screen.dart';

class BBXProfileCardsScreen extends StatefulWidget {
  const BBXProfileCardsScreen({Key? key}) : super(key: key);

  @override
  State<BBXProfileCardsScreen> createState() => _BBXProfileCardsScreenState();
}

class _BBXProfileCardsScreenState extends State<BBXProfileCardsScreen> {
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
          final userData = snapshot.data?.data() as Map<String, dynamic>?;

          return CustomScrollView(
            slivers: [
              // User header card
              SliverToBoxAdapter(
                child: _buildUserHeaderCard(userData),
              ),

              // Orders card
              SliverToBoxAdapter(
                child: _buildOrdersCard(),
              ),

              // Function grid (2 columns)
              SliverToBoxAdapter(
                child: _buildFunctionGrid(),
              ),

              // Services list card
              SliverToBoxAdapter(
                child: _buildServicesCard(),
              ),

              // Logout button
              SliverToBoxAdapter(
                child: _buildLogoutButton(),
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

  Widget _buildUserHeaderCard(Map<String, dynamic>? userData) {
    final userName = userData?['displayName'] ?? user?.email ?? 'User';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF9C27B0),
            Color(0xFFBA68C8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9C27B0).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white.withOpacity(0.3),
              child: Text(
                userName[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Name
          Text(
            userName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 8),

          // Member badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.diamond, size: 16, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  'Gold Member',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Points', '1,250'),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildStatItem('Coupons', '3'),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Edit profile button
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.edit, size: 16, color: Colors.white),
            label: const Text(
              'Edit Profile',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersCard() {
    final orders = [
      {'icon': Icons.payment, 'label': 'To Pay', 'badge': '2'},
      {'icon': Icons.inventory_2, 'label': 'To Ship', 'badge': null},
      {'icon': Icons.local_shipping, 'label': 'Shipped', 'badge': '1'},
      {'icon': Icons.rate_review, 'label': 'Review', 'badge': null},
      {'icon': Icons.assignment_return, 'label': 'Return', 'badge': null},
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Orders',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: _buildOrderItem(
                    icon: order['icon'] as IconData,
                    label: order['label'] as String,
                    badge: order['badge'] as String?,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem({
    required IconData icon,
    required String label,
    String? badge,
  }) {
    return InkWell(
      onTap: () {},
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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

  Widget _buildFunctionGrid() {
    final functions = [
      {
        'icon': Icons.post_add,
        'label': 'My Listings',
        'gradient': const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
        ),
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BBXMyListingsStandaloneScreen(),
              ),
            ),
      },
      {
        'icon': Icons.request_quote,
        'label': 'My Quotes',
        'gradient': const LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
        ),
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BBXMyOffersScreen(),
              ),
            ),
      },
      {
        'icon': Icons.favorite,
        'label': 'Favorites',
        'gradient': const LinearGradient(
          colors: [Color(0xFFF44336), Color(0xFFE57373)],
        ),
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BBXFavoritesStandaloneScreen(),
              ),
            ),
      },
      {
        'icon': Icons.history,
        'label': 'History',
        'gradient': const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
        ),
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BBXHistoryStandaloneScreen(),
              ),
            ),
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
        children: functions.map((func) {
          return InkWell(
            onTap: func['onTap'] as VoidCallback,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                gradient: func['gradient'] as Gradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    func['icon'] as IconData,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    func['label'] as String,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildServicesCard() {
    final services = [
      {'icon': Icons.location_on, 'label': 'Address Management'},
      {'icon': Icons.credit_card, 'label': 'Payment Methods'},
      {'icon': Icons.manage_accounts, 'label': 'Account Settings'},
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'My Services',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...services.map(
            (service) => ListTile(
              leading: Icon(
                service['icon'] as IconData,
                color: AppTheme.primary,
              ),
              title: Text(service['label'] as String),
              trailing: const Icon(
                Icons.chevron_right,
                color: AppTheme.textLight,
              ),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: OutlinedButton.icon(
        onPressed: _handleLogout,
        icon: const Icon(Icons.logout),
        label: const Text('Logout'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: AppTheme.error),
          foregroundColor: AppTheme.error,
          minimumSize: const Size(double.infinity, 50),
        ),
      ),
    );
  }
}
