import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bbx_avatar.dart';
import '../../widgets/bbx_button.dart';

class BBXNewProfileScreen extends StatelessWidget {
  const BBXNewProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
                    _buildProfileHeader(user),

                    _buildStatsCard(),

                    _buildMenuSections(context),
        ],
      ),
    );
  }

    Widget _buildProfileHeader(User? user) {
    return SliverToBoxAdapter(
      child: Container(
        height: 240,
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                            Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: BBXAvatar(
                  imageUrl: user?.photoURL,
                  name: user?.displayName ?? '用户',
                  size: 100,
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),

                            Text(
                user?.displayName ?? '未登?,
                style: AppTheme.heading2.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppTheme.spacing8),

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
                  '认证卖家',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: AppTheme.semibold,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),

                            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ...List.generate(
                    5,
                    (index) => Icon(
                      Icons.star_rounded,
                      color: Colors.amber[300],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '4.8',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: AppTheme.semibold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing16),

                            OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppTheme.borderRadiusLarge,
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

    Widget _buildStatsCard() {
    return SliverToBoxAdapter(
      child: Transform.translate(
        offset: const Offset(0, -20),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
          padding: const EdgeInsets.all(AppTheme.spacing16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppTheme.borderRadiusLarge,
            boxShadow: AppTheme.elevation4,
          ),
          child: Row(
            children: [
              _buildStatItem('交易?, '128'),
              _buildStatItem('Quote?, '45'),
              _buildStatItem('收藏?, '23'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
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
    );
  }

    Widget _buildMenuSections(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                        const Text('我的活动', style: AppTheme.heading4),
            const SizedBox(height: AppTheme.spacing12),
            _buildMenuGroup([
              _MenuItem(Icons.inventory_2_rounded, '我的商品', AppTheme.primary500, '/my-listings', badge: 12),
              _MenuItem(Icons.local_offer_rounded, '我的Quote', AppTheme.secondary500, '/my-offers', badge: 5),
              _MenuItem(Icons.receipt_long_rounded, '我的交易', AppTheme.info, '/transactions', badge: 3),
              _MenuItem(Icons.favorite_rounded, '我的收藏', AppTheme.error, '/favorites', badge: 23),
            ]),

            const SizedBox(height: AppTheme.spacing24),

                        const Text('设置', style: AppTheme.heading4),
            const SizedBox(height: AppTheme.spacing12),
            _buildMenuGroup([
              _MenuItem(Icons.person_outline_rounded, 'Account Settings', null, '/account-settings'),
              _MenuItem(Icons.notifications_outlined, 'Notification Settings', null, '/notification-settings'),
              _MenuItem(Icons.lock_outline_rounded, '隐私设置', null, '/privacy-settings'),
              _MenuItem(Icons.language_rounded, 'Language', null, '/language-settings', trailing: 'English'),
            ]),

            const SizedBox(height: AppTheme.spacing24),

                        const Text('其他', style: AppTheme.heading4),
            const SizedBox(height: AppTheme.spacing12),
            _buildMenuGroup([
              _MenuItem(Icons.help_outline_rounded, '帮助中心', null, '/help'),
              _MenuItem(Icons.info_outline_rounded, '关于我们', null, '/about'),
              _MenuItem(Icons.logout_rounded, '退出登?, AppTheme.error, null, isLogout: true),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuGroup(List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.borderRadiusMedium,
        boxShadow: AppTheme.elevation1,
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              ListTile(
                leading: Icon(item.icon, color: item.color ?? AppTheme.neutral700),
                title: Text(
                  item.title,
                  style: AppTheme.body1.copyWith(
                    color: item.isLogout ? AppTheme.error : AppTheme.neutral900,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: const BoxDecoration(
                          color: AppTheme.error,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          item.badge.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: AppTheme.bold,
                          ),
                        ),
                      ),
                    if (item.trailing != null)
                      Text(
                        item.trailing!,
                        style: AppTheme.body2.copyWith(
                          color: AppTheme.neutral600,
                        ),
                      ),
                    if (!item.isLogout)
                      const Icon(Icons.chevron_right_rounded),
                  ],
                ),
                onTap: () {
                  if (item.isLogout) {
                    _handleLogout();
                  } else if (item.route != null) {
                    // Navigator.pushNamed(context, item.route!);
                  }
                },
              ),
              if (index < items.length - 1)
                const Divider(height: 1, indent: 56),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _handleLogout() async {
    await FirebaseAuth.instance.signOut();
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final Color? color;
  final String? route;
  final int? badge;
  final String? trailing;
  final bool isLogout;

  _MenuItem(
    this.icon,
    this.title,
    this.color,
    this.route, {
    this.badge,
    this.trailing,
    this.isLogout = false,
  });
}
