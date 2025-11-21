import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// BBX 个人中心 - 完全优化�?
/// Material Design 3 风格，适配 Pixel 5
class BBXOptimizedProfileScreen extends StatefulWidget {
  const BBXOptimizedProfileScreen({super.key});

  @override
  State<BBXOptimizedProfileScreen> createState() => _BBXOptimizedProfileScreenState();
}

class _BBXOptimizedProfileScreenState extends State<BBXOptimizedProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool isLoading = true;

  // 用户数据（开发模式默认值）
  int transactionCount = 12;
  int offerCount = 5;
  int favoriteCount = 8;
  double walletBalance = 1250.50;
  String membershipTier = 'Free';
  int rewardPoints = 350;
  int availableCoupons = 3;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // 模拟加载
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          // 顶部渐变卡片
          _buildGradientHeader(),

          // 统计卡片（浮动设计，负margin�?
          _buildFloatingStatsCard(),

          // 账户管理小卡�?
          _buildAccountCards(),

          // 会员专区（金色渐变）
          _buildMembershipSection(),

          // 我的服务菜单
          _buildMyServicesSection(),

          // 设置菜单
          _buildSettingsSection(),

          // 退出登�?
          _buildLogoutButton(),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  /// 顶部渐变背景卡片
  Widget _buildGradientHeader() {
    return SliverToBoxAdapter(
      child: Container(
        height: 200,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 头像
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    color: Colors.white,
                  ),
                  child: const Icon(Icons.person, size: 40, color: Color(0xFF2E7D32)),
                ),
                const SizedBox(height: 12),
                // 用户�?
                Text(
                  user?.displayName ?? '用户',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                // 邮箱
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 浮动统计卡片（负margin设计�?
  Widget _buildFloatingStatsCard() {
    return SliverToBoxAdapter(
      child: Transform.translate(
        offset: const Offset(0, -32), // 负margin效果
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('交易�?, '$transactionCount', Icons.receipt_long),
              _buildDivider(),
              _buildStatItem('报价�?, '$offerCount', Icons.local_offer),
              _buildDivider(),
              _buildStatItem('收藏�?, '$favoriteCount', Icons.favorite),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF2E7D32), size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF212121),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF757575),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: const Color(0xFFE0E0E0),
    );
  }

  /// 账户管理彩色卡片�?x2网格�?
  Widget _buildAccountCards() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '账户管理',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.8,
              children: [
                _buildAccountCard(
                  '钱包余额',
                  'RM ${walletBalance.toStringAsFixed(2)}',
                  Icons.account_balance_wallet,
                  const LinearGradient(colors: [Color(0xFFFFC371), Color(0xFFFF5F6D)]),
                  () => Navigator.pushNamed(context, '/wallet'),
                ),
                _buildAccountCard(
                  '会员等级',
                  membershipTier == 'free' ? 'Free' : 'Premium',
                  Icons.workspace_premium,
                  const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                  () => Navigator.pushNamed(context, '/subscription'),
                ),
                _buildAccountCard(
                  '积分奖励',
                  '$rewardPoints �?,
                  Icons.stars,
                  const LinearGradient(colors: [Color(0xFFEC6EAD), Color(0xFF3494E6)]),
                  () => Navigator.pushNamed(context, '/rewards'),
                ),
                _buildAccountCard(
                  '优惠�?,
                  '$availableCoupons 张可�?,
                  Icons.confirmation_number,
                  const LinearGradient(colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)]),
                  () => Navigator.pushNamed(context, '/coupons'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(
    String title,
    String value,
    IconData icon,
    Gradient gradient,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
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
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 会员专区（金色渐变）
  Widget _buildMembershipSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33FFA500),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium, color: Colors.white, size: 48),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '升级专业�?,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '享受更多特权和功�?,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '立即升级',
                style: TextStyle(
                  color: Color(0xFFFFA500),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 我的服务菜单
  Widget _buildMyServicesSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '我的服务',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildMenuItem(Icons.inventory_2_outlined, '我的商品', '已发�?12 �?, '/marketplace'),
            const Divider(height: 1, indent: 56),
            _buildMenuItem(Icons.local_offer_outlined, '我的报价', '待处�?5 �?, '/my-offers'),
            const Divider(height: 1, indent: 56),
            _buildMenuItem(Icons.receipt_long_outlined, '我的交易', '进行�?2 �?, '/transactions'),
            const Divider(height: 1, indent: 56),
            _buildMenuItem(Icons.chat_bubble_outline, '消息通知', '3 条未�?, '/messages'),
            const Divider(height: 1, indent: 56),
            _buildMenuItem(Icons.bar_chart_outlined, '我的统计', '查看交易数据', '/statistics'),
          ],
        ),
      ),
    );
  }

  /// 设置菜单
  Widget _buildSettingsSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '设置',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildMenuItem(Icons.settings_outlined, '账户设置', '个人信息、安�?, '/account-settings'),
            const Divider(height: 1, indent: 56),
            _buildMenuItem(Icons.notifications_outlined, '通知设置', '推送、消息提�?, '/notification-settings'),
            const Divider(height: 1, indent: 56),
            _buildMenuItem(Icons.language_outlined, '语言设置', '中文', null),
            const Divider(height: 1, indent: 56),
            _buildMenuItem(Icons.help_outline, '帮助中心', '常见问题', null),
            const Divider(height: 1, indent: 56),
            _buildMenuItem(Icons.info_outline, '关于我们', 'BBX v1.0.0', null),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle, String? route) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (route != null) {
            Navigator.pushNamed(context, route);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$title 功能开发中...'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF2E7D32), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF212121),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF9E9E9E),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 退出登录按钮（单独区域，红色）
  Widget _buildLogoutButton() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showLogoutDialog(),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.logout, color: Color(0xFFF44336), size: 22),
                  SizedBox(width: 8),
                  Text(
                    '退出登�?,
                    style: TextStyle(
                      color: Color(0xFFF44336),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登�?),
        content: const Text('确定要退出登录吗�?),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            child: const Text(
              '确定',
              style: TextStyle(color: Color(0xFFF44336)),
            ),
          ),
        ],
      ),
    );
  }
}

