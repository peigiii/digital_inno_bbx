import 'package:flutter/material.dart';
import '../widgets/navigation/bbx_bottom_navigation.dart';
import 'home/bbx_optimized_home_screen.dart'; // 优化后的首页
import 'bbx_new_marketplace_screen.dart';
import 'digital_inno_list_waste_screen.dart';
import 'chat/bbx_conversations_screen.dart';
import 'profile/bbx_profile_screen.dart';

/// BBX 主页面 - 管理底部导航的5个Tab页面
class BBXMainScreen extends StatefulWidget {
  const BBXMainScreen({super.key});

  @override
  State<BBXMainScreen> createState() => _BBXMainScreenState();
}

class _BBXMainScreenState extends State<BBXMainScreen> {
  int _currentIndex = 0; // 默认首页
  int _unreadMessageCount = 0;

  // 5个Tab对应的页面
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const BBXOptimizedHomeScreen(),  // 0: 首页 ← 已更新为优化版本！
      const BBXNewMarketplaceScreen(), // 1: 商品列表
      const BBXListWasteScreen(),      // 2: 发布（创建商品）
      const BBXConversationsScreen(),  // 3: 消息
      const BBXProfileScreen(),        // 4: 个人中心
    ];
    _loadUnreadMessageCount();
  }

  /// 加载未读消息数量
  Future<void> _loadUnreadMessageCount() async {
    // TODO: 实现从 Firestore 加载未读消息数量
    // 临时使用0
    setState(() {
      _unreadMessageCount = 0;
    });
  }

  /// 处理底部导航点击
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    // 如果点击消息Tab，刷新未读数量
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
