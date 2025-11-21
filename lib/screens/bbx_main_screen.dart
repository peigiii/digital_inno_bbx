import 'package:flutter/material.dart';
import '../widgets/navigation/bbx_bottom_navigation.dart';
import 'home/bbx_home_progressive.dart'; import 'marketplace/bbx_optimized_marketplace_screen.dart'; import 'digital_inno_list_waste_screen.dart';
import 'chat/bbx_conversations_screen.dart';
import 'profile/bbx_optimized_profile_screen.dart'; 
class BBXMainScreen extends StatefulWidget {
  final int initialIndex;
  const BBXMainScreen({super.key, this.initialIndex = 0});

  @override
  State<BBXMainScreen> createState() => _BBXMainScreenState();
}

class _BBXMainScreenState extends State<BBXMainScreen> {
  late int _currentIndex;
  int _unreadMessageCount = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pages = [
      const BBXHomeProgressive(),                       const BBXOptimizedMarketplaceScreen(),            const BBXListWasteScreen(),                       const BBXConversationsScreen(),                   const BBXOptimizedProfileScreen(),              ];
    _loadUnreadMessageCount();
  }

    Future<void> _loadUnreadMessageCount() async {
            setState(() {
      _unreadMessageCount = 0;
    });
  }

    void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

        if (index == 3) {
      _loadUnreadMessageCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BBXBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        unreadMessageCount: _unreadMessageCount,
      ),
    );
  }
}
