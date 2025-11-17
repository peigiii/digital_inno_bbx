import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'bbx_users_screen.dart';
import 'digital_inno_marketplace_screen.dart';
import 'bbx_recyclers_screen.dart';
import 'bbx_offers_screen.dart';
import 'bbx_messages_screen.dart';
import 'bbx_admin_screen.dart';
import '../widgets/bbx_bottom_nav.dart';

class BBXHomeScreen extends StatefulWidget {
  const BBXHomeScreen({super.key});

  @override
  State<BBXHomeScreen> createState() => _BBXHomeScreenState();
}

class _BBXHomeScreenState extends State<BBXHomeScreen> {
  int _currentIndex = 1; // Start with Listings (Marketplace) screen

  final List<Widget> _screens = const [
    BBXUsersScreen(),
    DigitalInnoMarketplaceScreen(),
    BBXRecyclersScreen(),
    BBXOffersScreen(),
    BBXMessagesScreen(),
    BBXAdminScreen(),
  ];

  final List<String> _titles = const [
    'Users',
    'Marketplace',
    'Recyclers',
    'Offers',
    'Messages',
    'Admin',
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('您确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF44336),
              foregroundColor: Colors.white,
            ),
            child: const Text('退出'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      try {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('退出失败: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent going back to login screen
        return false;
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: BBXBottomNav(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
        ),
        drawer: _buildDrawer(),
      ),
    );
  }

  Widget _buildDrawer() {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: Column(
        children: [
          // Drawer Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 40,
                    child: Text(
                      (user?.email?[0] ?? 'U').toUpperCase(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.email ?? 'Guest',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'BBX Member',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.people,
                  title: 'Users',
                  index: 0,
                ),
                _buildDrawerItem(
                  icon: Icons.list,
                  title: 'Marketplace',
                  index: 1,
                ),
                _buildDrawerItem(
                  icon: Icons.recycling,
                  title: 'Recyclers',
                  index: 2,
                ),
                _buildDrawerItem(
                  icon: Icons.local_offer,
                  title: 'Offers',
                  index: 3,
                ),
                _buildDrawerItem(
                  icon: Icons.message,
                  title: 'Messages',
                  index: 4,
                ),
                _buildDrawerItem(
                  icon: Icons.admin_panel_settings,
                  title: 'Admin',
                  index: 5,
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.settings, color: Color(0xFF4CAF50)),
                  title: const Text('Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Settings feature coming soon'),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.help, color: Color(0xFF4CAF50)),
                  title: const Text('Help & Support'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Help & Support feature coming soon'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Logout Button
          Container(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF44336),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          // App Version
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'BBX v1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final isSelected = _currentIndex == index;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[700],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: const Color(0xFF4CAF50).withOpacity(0.1),
      onTap: () {
        Navigator.pop(context); // Close drawer
        _onTabTapped(index);
      },
    );
  }
}
