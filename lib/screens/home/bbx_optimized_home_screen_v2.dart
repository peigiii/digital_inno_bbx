import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';

/// BBX 首页 - 渐进式测试版 v2
/// 逐步添加功能，排查白屏原�?
class BBXOptimizedHomeScreenV2 extends StatefulWidget {
  const BBXOptimizedHomeScreenV2({super.key});

  @override
  State<BBXOptimizedHomeScreenV2> createState() => _BBXOptimizedHomeScreenV2State();
}

class _BBXOptimizedHomeScreenV2State extends State<BBXOptimizedHomeScreenV2> {
  final ScrollController _scrollController = ScrollController();
  bool _showGreeting = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 50 && _showGreeting) {
      setState(() => _showGreeting = false);
    } else if (_scrollController.offset <= 50 && !_showGreeting) {
      setState(() => _showGreeting = true);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '早上�?👋';
    if (hour < 18) return '下午�?☀�?;
    return '晚上�?🌙';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // 顶部�?
          _buildSliverAppBar(),

          // 搜索栏区�?
          _buildSearchSection(),

          // 快捷分类
          _buildQuickCategories(),

          // 快捷功能卡片
          _buildQuickActions(),

          // Banner广告�?
          _buildPromotionBanner(),

          // 商品列表标题
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacing16,
                AppTheme.spacing24,
                AppTheme.spacing16,
                AppTheme.spacing12,
              ),
              child: Row(
                children: [
                  const Text('为你推荐', style: AppTheme.heading3),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    child: Row(
                      children: const [
                        Text('查看全部', style: TextStyle(color: AppTheme.primary500)),
                        Icon(Icons.chevron_right, size: 18, color: AppTheme.primary500),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 商品列表（占位）
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppTheme.borderRadiusLarge,
                  border: Border.all(color: AppTheme.neutral300),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 48, color: AppTheme.neutral500),
                      SizedBox(height: 12),
                      Text('商品列表加载区域', style: TextStyle(color: AppTheme.neutral600)),
                      SizedBox(height: 4),
                      Text('(暂时占位)', style: TextStyle(fontSize: 12, color: AppTheme.neutral500)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppTheme.spacing24)),
        ],
      ),
    );
  }

  /// 顶部 AppBar
  Widget _buildSliverAppBar() {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? '用户';
    final greeting = _getGreeting();

    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(
          AppTheme.spacing16,
          MediaQuery.of(context).padding.top + AppTheme.spacing12,
          AppTheme.spacing16,
          AppTheme.spacing16,
        ),
        child: Row(
          children: [
            // Logo
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary500.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'BBX',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: AppTheme.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),

            // 问候语
            Expanded(
              child: AnimatedOpacity(
                opacity: _showGreeting ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: AppTheme.caption.copyWith(color: AppTheme.neutral600),
                    ),
                    Text(
                      userName,
                      style: AppTheme.heading4.copyWith(height: 1.2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            // 通知按钮
            IconButton(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_outlined, size: 24),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              onPressed: () {},
            ),

            const SizedBox(width: AppTheme.spacing8),

            // 扫码按钮
            IconButton(
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 24),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  /// 搜索区域（简化版，不使用自定义组件）
  Widget _buildSearchSection() {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacing16,
          0,
          AppTheme.spacing16,
          AppTheme.spacing16,
        ),
        child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('搜索功能')),
            );
          },
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: AppTheme.spacing20),
                // 搜索图标（带渐变�?
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                const Expanded(
                  child: Text(
                    '搜索废料类型、商�?..',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.neutral500,
                    ),
                  ),
                ),
                // 筛选按�?
                Container(
                  margin: const EdgeInsets.only(right: AppTheme.spacing8),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primary500, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    size: 20,
                    color: AppTheme.primary500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 快捷分类
  Widget _buildQuickCategories() {
    final categories = [
      {'label': '塑料', 'icon': '♻️', 'color': AppTheme.plastic},
      {'label': '金属', 'icon': '🔩', 'color': AppTheme.metal},
      {'label': '纸类', 'icon': '📄', 'color': AppTheme.paper},
      {'label': '玻璃', 'icon': '🍾', 'color': AppTheme.glass},
      {'label': '电子', 'icon': '💻', 'color': AppTheme.electronic},
      {'label': '有机', 'icon': '🌿', 'color': AppTheme.organic},
    ];

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppTheme.spacing8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
            child: Row(
              children: [
                const Text('废料分类', style: AppTheme.heading4),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: const Row(
                    children: [
                      Text('全部', style: TextStyle(color: AppTheme.primary500)),
                      Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.primary500),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isFirst = index == 0;
                final isLast = index == categories.length - 1;

                return Container(
                  width: 90,
                  margin: EdgeInsets.only(
                    left: isFirst ? 0 : AppTheme.spacing8,
                    right: isLast ? 0 : 0,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              (category['color'] as Color).withOpacity(0.8),
                              (category['color'] as Color),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          boxShadow: [
                            BoxShadow(
                              color: (category['color'] as Color).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              category['icon'] as String,
                              style: const TextStyle(fontSize: 32),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              category['label'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: AppTheme.semibold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 快捷功能卡片
  Widget _buildQuickActions() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('快捷功能', style: AppTheme.heading4),
            const SizedBox(height: AppTheme.spacing12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: AppTheme.spacing12,
              crossAxisSpacing: AppTheme.spacing12,
              childAspectRatio: 1.5,
              children: [
                _buildActionCard(
                  title: '我的报价',
                  subtitle: '待处�?5 �?,
                  icon: Icons.local_offer_outlined,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFEE5A6F)],
                  ),
                  onTap: () {},
                ),
                _buildActionCard(
                  title: '我的交易',
                  subtitle: '进行�?2 �?,
                  icon: Icons.receipt_long_outlined,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                  ),
                  onTap: () {},
                ),
                _buildActionCard(
                  title: '附近商品',
                  subtitle: '查看周边',
                  icon: Icons.location_on_outlined,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFC371), Color(0xFFFF5F6D)],
                  ),
                  onTap: () {},
                ),
                _buildActionCard(
                  title: '我的收藏',
                  subtitle: '已收�?12 �?,
                  icon: Icons.favorite_outline,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEC6EAD), Color(0xFF3494E6)],
                  ),
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTheme.borderRadiusLarge,
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: AppTheme.borderRadiusLarge,
            boxShadow: AppTheme.elevation2,
          ),
          padding: const EdgeInsets.all(AppTheme.spacing16),
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
                      fontSize: 16,
                      fontWeight: AppTheme.semibold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
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

  /// Banner广告�?
  Widget _buildPromotionBanner() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
        height: 120,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
          borderRadius: AppTheme.borderRadiusLarge,
          boxShadow: AppTheme.elevation4,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            borderRadius: AppTheme.borderRadiusLarge,
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '升级专业�?,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: AppTheme.bold,
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
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '立即升级',
                            style: TextStyle(
                              color: Color(0xFF667EEA),
                              fontSize: 14,
                              fontWeight: AppTheme.semibold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.workspace_premium,
                    color: Colors.white,
                    size: 64,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

