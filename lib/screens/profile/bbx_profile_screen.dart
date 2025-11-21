import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bbx_avatar.dart';
import '../../widgets/bbx_button.dart';
import '../../widgets/bbx_loading.dart';

/// BBX 个人中心页面（完全重构）
class BBXProfileScreen extends StatefulWidget {
  const BBXProfileScreen({super.key});

  @override
  State<BBXProfileScreen> createState() => _BBXProfileScreenState();
}

class _BBXProfileScreenState extends State<BBXProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool isLoading = true;

  // 用户数据
  int transactionCount = 0;
  int offerCount = 0;
  int favoriteCount = 0;
  double walletBalance = 0.0;
  String membershipTier = 'Free';
  int rewardPoints = 0;
  int availableCoupons = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      // 加载用户数据
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        setState(() {
          membershipTier = data['subscriptionPlan'] ?? 'free';
          walletBalance = (data['walletBalance'] ?? 0).toDouble();
        });
      }

      // 加载奖励积分
      final rewardsDoc = await FirebaseFirestore.instance
          .collection('rewards')
          .doc(user!.uid)
          .get();

      if (rewardsDoc.exists) {
        setState(() {
          rewardPoints = rewardsDoc.data()?['points'] ?? 0;
        });
      }

      // TODO: 加载交易、报价、收藏数�?
      setState(() {
        transactionCount = 12;
        offerCount = 5;
        favoriteCount = 8;
        availableCoupons = 3;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('加载用户数据失败: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: BBXFullScreenLoading()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // 顶部个人信息卡片（渐变背景）
          _buildProfileHeader(),

          // 统计卡片（浮动）
          _buildStatsCard(),

          // 账户管理区域
          _buildAccountSection(),

          // 我的服务区域
          _buildMyServicesSection(),

          // 会员专区
          _buildMembershipSection(),

          // 设置区域
          _buildSettingsSection(),

          // 帮助与支�?
          _buildHelpSection(),

          // 退出登�?
          _buildLogoutButton(),

          // 底部间距
          const SliverToBoxAdapter(
            child: SizedBox(height: AppTheme.spacing32),
          ),
        ],
      ),
    );
  }

  /// 个人信息头部
  Widget _buildProfileHeader() {
    return SliverToBoxAdapter(
      child: Container(
        height: 220,
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(AppTheme.radiusXLarge),
            bottomRight: Radius.circular(AppTheme.radiusXLarge),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 头像
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: BBXAvatar(
                  imageUrl: user?.photoURL,
                  name: user?.displayName ?? '用户',
                  size: 80,
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),

              // 用户�?
              Text(
                user?.displayName ?? '未登�?,
                style: AppTheme.heading2.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppTheme.spacing4),

              // 用户角色标签
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing12,
                  vertical: AppTheme.spacing4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: const Text(
                  '认证用户',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: AppTheme.semibold,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),

              // 评分
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ...List.generate(
                    5,
                    (index) => Icon(
                      Icons.star_rounded,
                      color: Colors.amber[300],
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '4.8',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: AppTheme.semibold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing12),

              // 编辑资料按钮
              OutlinedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/edit-profile');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppTheme.borderRadiusLarge,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing24,
                    vertical: AppTheme.spacing8,
                  ),
                ),
                child: const Text('编辑资料'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 统计卡片
  Widget _buildStatsCard() {
    return SliverToBoxAdapter(
      child: Transform.translate(
        offset: const Offset(0, -30),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
          padding: const EdgeInsets.all(AppTheme.spacing16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppTheme.borderRadiusLarge,
            boxShadow: AppTheme.shadowLarge,
          ),
          child: Row(
            children: [
              _buildStatItem('交易�?, transactionCount.toString(), () {
                Navigator.pushNamed(context, '/transactions');
              }),
              Container(
                width: 1,
                height: 40,
                color: AppTheme.neutral300,
              ),
              _buildStatItem('报价�?, offerCount.toString(), () {
                Navigator.pushNamed(context, '/my-offers');
              }),
              Container(
                width: 1,
                height: 40,
                color: AppTheme.neutral300,
              ),
              _buildStatItem('收藏�?, favoriteCount.toString(), () {
                Navigator.pushNamed(context, '/favorites');
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Text(
              value,
              style: AppTheme.heading2.copyWith(
                color: AppTheme.primary500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTheme.caption.copyWith(
                color: AppTheme.neutral600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 账户管理区域
  Widget _buildAccountSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacing16,
          0,
          AppTheme.spacing16,
          AppTheme.spacing16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('账户管理', style: AppTheme.heading3),
            const SizedBox(height: AppTheme.spacing12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppTheme.borderRadiusMedium,
                boxShadow: AppTheme.shadowSmall,
              ),
              child: Column(
                children: [
                  _buildAccountItem(
                    icon: Icons.account_balance_wallet_rounded,
                    iconColor: const Color(0xFFFFD700),
                    title: '钱包余额',
                    trailing: 'RM ${walletBalance.toStringAsFixed(2)}',
                    onTap: () => Navigator.pushNamed(context, '/wallet'),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildAccountItem(
                    icon: Icons.workspace_premium_rounded,
                    iconColor: const Color(0xFFFFA500),
                    title: '会员等级',
                    trailing: _getMembershipDisplayName(membershipTier),
                    onTap: () => Navigator.pushNamed(context, '/subscription'),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildAccountItem(
                    icon: Icons.card_giftcard_rounded,
                    iconColor: AppTheme.error,
                    title: '积分奖励',
                    trailing: '$rewardPoints �?,
                    onTap: () => Navigator.pushNamed(context, '/rewards'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 我的服务区域
  Widget _buildMyServicesSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('我的服务', style: AppTheme.heading3),
            const SizedBox(height: AppTheme.spacing12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppTheme.borderRadiusMedium,
                boxShadow: AppTheme.shadowSmall,
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.inventory_2_rounded,
                    title: '我的商品',
                    subtitle: '已发�?12 �?,
                    onTap: () => Navigator.pushNamed(context, '/my-listings'),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildMenuItem(
                    icon: Icons.local_offer_rounded,
                    title: '我的报价',
                    subtitle: '待处�?5 �?,
                    badge: 5,
                    onTap: () => Navigator.pushNamed(context, '/my-offers'),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildMenuItem(
                    icon: Icons.receipt_long_rounded,
                    title: '我的交易',
                    subtitle: '进行�?2 �?,
                    onTap: () => Navigator.pushNamed(context, '/transactions'),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildMenuItem(
                    icon: Icons.favorite_rounded,
                    title: '我的收藏',
                    subtitle: '已收�?8 �?,
                    onTap: () => Navigator.pushNamed(context, '/favorites'),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildMenuItem(
                    icon: Icons.location_on_rounded,
                    title: '附近商品',
                    subtitle: '基于位置筛�?,
                    onTap: () => Navigator.pushNamed(context, '/nearby'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 会员专区
  Widget _buildMembershipSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('会员专区', style: AppTheme.heading3),
            const SizedBox(height: AppTheme.spacing12),

            // 2x2 网格
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: AppTheme.spacing12,
              crossAxisSpacing: AppTheme.spacing12,
              childAspectRatio: 1.5,
              children: [
                _buildMembershipCard(
                  icon: Icons.workspace_premium_rounded,
                  title: '订阅计划',
                  subtitle: '升级享更多权�?,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  onTap: () => Navigator.pushNamed(context, '/subscription'),
                ),
                _buildMembershipCard(
                  icon: Icons.card_giftcard_rounded,
                  title: '奖励中心',
                  subtitle: '赚取 $rewardPoints 积分',
                  gradient: const LinearGradient(
                    colors: [AppTheme.error, Color(0xFFE91E63)],
                  ),
                  onTap: () => Navigator.pushNamed(context, '/rewards'),
                ),
                _buildMembershipCard(
                  icon: Icons.confirmation_number_rounded,
                  title: '优惠�?,
                  subtitle: '$availableCoupons 张可�?,
                  gradient: const LinearGradient(
                    colors: [AppTheme.accent, Color(0xFF64B5F6)],
                  ),
                  badge: availableCoupons,
                  onTap: () => Navigator.pushNamed(context, '/coupons'),
                ),
                _buildMembershipCard(
                  icon: Icons.analytics_rounded,
                  title: '我的统计',
                  subtitle: '查看交易数据',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
                  ),
                  onTap: () => Navigator.pushNamed(context, '/statistics'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 设置区域
  Widget _buildSettingsSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('设置', style: AppTheme.heading3),
            const SizedBox(height: AppTheme.spacing12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppTheme.borderRadiusMedium,
                boxShadow: AppTheme.shadowSmall,
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.settings_rounded,
                    title: '账户设置',
                    onTap: () => Navigator.pushNamed(context, '/account-settings'),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildMenuItem(
                    icon: Icons.notifications_rounded,
                    title: '通知设置',
                    onTap: () => Navigator.pushNamed(context, '/notification-settings'),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildMenuItem(
                    icon: Icons.security_rounded,
                    title: '隐私设置',
                    onTap: () => Navigator.pushNamed(context, '/privacy-settings'),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildMenuItem(
                    icon: Icons.language_rounded,
                    title: '语言设置',
                    trailing: Text(
                      '中文',
                      style: AppTheme.body2.copyWith(
                        color: AppTheme.neutral600,
                      ),
                    ),
                    onTap: () => Navigator.pushNamed(context, '/language-settings'),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildMenuItem(
                    icon: Icons.dark_mode_rounded,
                    title: '深色模式',
                    trailing: Switch(
                      value: false,
                      onChanged: (value) {
                        // TODO: 实现深色模式切换
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 帮助与支�?
  Widget _buildHelpSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('帮助与支�?, style: AppTheme.heading3),
            const SizedBox(height: AppTheme.spacing12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppTheme.borderRadiusMedium,
                boxShadow: AppTheme.shadowSmall,
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.help_outline_rounded,
                    title: '帮助中心',
                    onTap: () => Navigator.pushNamed(context, '/help'),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildMenuItem(
                    icon: Icons.support_agent_rounded,
                    title: '联系客服',
                    onTap: () => Navigator.pushNamed(context, '/support'),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildMenuItem(
                    icon: Icons.star_border_rounded,
                    title: '给我们评�?,
                    onTap: () {
                      // TODO: 打开应用商店评分
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildMenuItem(
                    icon: Icons.info_outline_rounded,
                    title: '关于BBX',
                    trailing: Text(
                      'v1.0.0',
                      style: AppTheme.body2.copyWith(
                        color: AppTheme.neutral600,
                      ),
                    ),
                    onTap: () => Navigator.pushNamed(context, '/about'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 退出登录按�?
  Widget _buildLogoutButton() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppTheme.borderRadiusMedium,
            boxShadow: AppTheme.shadowSmall,
          ),
          child: ListTile(
            leading: const Icon(
              Icons.logout_rounded,
              color: AppTheme.error,
            ),
            title: const Text(
              '退出登�?,
              style: TextStyle(
                color: AppTheme.error,
                fontWeight: AppTheme.semibold,
              ),
            ),
            onTap: () => _showLogoutConfirmation(),
          ),
        ),
      ),
    );
  }

  /// 账户�?
  Widget _buildAccountItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [iconColor, iconColor.withOpacity(0.7)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
      title: Text(title, style: AppTheme.body1),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            trailing,
            style: AppTheme.heading4.copyWith(
              color: AppTheme.primary500,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
      onTap: onTap,
    );
  }

  /// 菜单�?
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    int? badge,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.neutral700),
      title: Text(title, style: AppTheme.body1),
      subtitle: subtitle != null
          ? Text(subtitle, style: AppTheme.caption)
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppTheme.error,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: AppTheme.bold,
                ),
              ),
            ),
          if (trailing != null)
            trailing
          else
            const Icon(Icons.chevron_right_rounded),
        ],
      ),
      onTap: onTap,
    );
  }

  /// 会员卡片
  Widget _buildMembershipCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required LinearGradient gradient,
    int? badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: AppTheme.borderRadiusMedium,
          boxShadow: AppTheme.shadowMedium,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacing12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: Colors.white, size: 32),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: AppTheme.semibold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (badge != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badge.toString(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: AppTheme.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getMembershipDisplayName(String tier) {
    switch (tier.toLowerCase()) {
      case 'free':
        return 'Free';
      case 'basic':
        return 'Basic';
      case 'professional':
        return 'Professional';
      case 'enterprise':
        return 'Enterprise';
      default:
        return 'Free';
    }
  }

  void _showLogoutConfirmation() {
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
          BBXPrimaryButton(
            text: '确定',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
            height: 40,
          ),
        ],
      ),
    );
  }
}
