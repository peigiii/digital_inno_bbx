import 'package:flutter/material.dart';

class BBXBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isAdmin;

  const BBXBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    // 根据是否是管理员决定显示哪些导航�?
    final items = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.people),
        label: 'Users',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.list),
        label: 'Listings',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.recycling),
        label: 'Recyclers',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.local_offer),
        label: 'Offers',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.message),
        label: 'Messages',
      ),
      if (isAdmin)
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
    ];

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF4CAF50),
      unselectedItemColor: Colors.grey,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: items,
    );
  }
}
