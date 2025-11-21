import 'package:flutter/material.dart';
import '../widgets/navigation/bbx_bottom_navigation.dart';
import 'home/bbx_home_progressive.dart'; // 渐进式首�?
import 'marketplace/bbx_optimized_marketplace_screen.dart'; // 优化后的商品列表
import 'digital_inno_list_waste_screen.dart';
import 'chat/bbx_conversations_screen.dart';
import 'profile/bbx_optimized_profile_screen.dart'; // 优化后的个人中心

/// BBX 主页�?- 管理底部导航�?个Tab页面
class BBXMainScreen extends StatefulWidget {
  const BBXMainScreen({super.key});

  @override
  State<BBXMainScreen> createState() => _BBXMainScreenState();
}

class _BBXMainScreenState extends State<BBXMainScreen> {
  int _currentIndex = 0; // 默认首页
  int _unreadMessageCount = 0;

  // 5个Tab对应的页�?
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const BBXHomeProgressive(),                 // 0: 首页 �?渐进式首�?
      const BBXOptimizedMarketplaceScreen(),      // 1: 商品列表 �?优化�?
      const BBXListWasteScreen(),                 // 2: 发布（创建商品）
      const BBXConversationsScreen(),             // 3: 消息
      const BBXOptimizedProfileScreen(),          // 4: 个人中心 �?优化�?
    ];
    _loadUnreadMessageCount();
  }

  /// 加载未读消息数量
  Future<void> _loadUnreadMessageCount() async {
    // TODO: 实现�?Firestore 加载未读消息数量
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

    // 如果点击消息Tab，刷新未读数�?
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
