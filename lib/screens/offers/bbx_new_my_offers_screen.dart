import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bbx_card.dart';
import '../../widgets/bbx_chip.dart';
import '../../widgets/bbx_button.dart';
import '../../widgets/bbx_empty_state.dart';
import '../../widgets/bbx_loading.dart';
import '../../models/offer_model.dart';

/// BBX 我的报价页面（完全重构）
class BBXNewMyOffersScreen extends StatefulWidget {
  const BBXNewMyOffersScreen({super.key});

  @override
  State<BBXNewMyOffersScreen> createState() => _BBXNewMyOffersScreenState();
}

class _BBXNewMyOffersScreenState extends State<BBXNewMyOffersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'all';

  final List<String> _filters = [
    'all',
    'pending',
    'negotiating',
    'accepted',
    'rejected',
    'expired',
  ];

  final Map<String, String> _filterLabels = {
    'all': '全部',
    'pending': '待处�?,
    'negotiating': '议价�?,
    'accepted': '已接�?,
    'rejected': '已拒�?,
    'expired': '已过�?,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('我的报价', style: AppTheme.heading2),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.neutral300,
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppTheme.primary500,
                borderRadius: AppTheme.borderRadiusLarge,
              ),
              indicatorPadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing24,
                vertical: AppTheme.spacing8,
              ),
              labelColor: Colors.white,
              labelStyle: AppTheme.body1.copyWith(
                fontWeight: AppTheme.semibold,
              ),
              unselectedLabelColor: AppTheme.neutral700,
              unselectedLabelStyle: AppTheme.body1.copyWith(
                fontWeight: AppTheme.regular,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('我发出的'),
                      const SizedBox(width: 4),
                      _buildBadge(5),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('我收到的'),
                      const SizedBox(width: 4),
                      _buildBadge(3),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // 状态筛选栏
          _buildFilterBar(),

          // 内容区域
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSentOffersList(),
                _buildReceivedOffersList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 角标
  Widget _buildBadge(int count) {
    if (count == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppTheme.error,
        borderRadius: BorderRadius.circular(10),
      ),
      constraints: const BoxConstraints(
        minWidth: 20,
        minHeight: 20,
      ),
      child: Text(
        count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: AppTheme.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// 筛选栏
  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing8,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacing8),
              child: BBXFilterChip(
                label: _filterLabels[filter]!,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 我发出的报价列表
  Widget _buildSentOffersList() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return BBXEmptyState.noData(description: '请先登录');
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _getOffersStream(user.uid, isSent: true),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return BBXEmptyState.noData(description: '加载失败');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const BBXListLoading(itemCount: 5);
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return BBXEmptyState.noData(
            description: '暂无报价记录',
            action: BBXPrimaryButton(
              text: '去逛�?,
              onPressed: () {
                Navigator.pushNamed(context, '/home');
              },
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            return _buildOfferCard(doc, isSent: true);
          },
        );
      },
    );
  }

  /// 我收到的报价列表
  Widget _buildReceivedOffersList() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return BBXEmptyState.noData(description: '请先登录');
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _getOffersStream(user.uid, isSent: false),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return BBXEmptyState.noData(description: '加载失败');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const BBXListLoading(itemCount: 5);
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return BBXEmptyState.noData(
            description: '暂无收到的报�?,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            return _buildOfferCard(doc, isSent: false);
          },
        );
      },
    );
  }

  /// 获取报价�?
  Stream<QuerySnapshot> _getOffersStream(String userId, {required bool isSent}) {
    var query = FirebaseFirestore.instance
        .collection('offers')
        .where(isSent ? 'buyerId' : 'sellerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true);

    if (_selectedFilter != 'all') {
      query = query.where('status', isEqualTo: _selectedFilter);
    }

    return query.snapshots();
  }

  /// 报价卡片
  Widget _buildOfferCard(DocumentSnapshot doc, {required bool isSent}) {
    final data = doc.data() as Map<String, dynamic>;
    final status = data['status'] ?? 'pending';
    final offerPrice = (data['offerPrice'] ?? 0.0).toDouble();
    final originalPrice = (data['originalPrice'] ?? 0.0).toDouble();
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final counterPrice = data['counterPrice'] != null
        ? (data['counterPrice'] as num).toDouble()
        : null;
    final sellerMessage = data['sellerMessage'] as String?;

    return BBXCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部：状态和时间
          Row(
            children: [
              BBXStatusChip.status(status, isSmall: true),
              const Spacer(),
              Text(
                _formatDate(createdAt),
                style: AppTheme.caption.copyWith(
                  color: AppTheme.neutral500,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacing12),

          // 商品信息（简化版�?
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.neutral200,
                  borderRadius: AppTheme.borderRadiusMedium,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '商品标题',
                      style: AppTheme.heading4,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    BBXCategoryChip(category: 'Plastic', isSmall: true),
                    const SizedBox(height: 4),
                    const Text(
                      '100 kg',
                      style: AppTheme.body2,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacing12),

          // 报价信息
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing12),
            decoration: BoxDecoration(
              color: AppTheme.neutral50,
              borderRadius: AppTheme.borderRadiusMedium,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '原价',
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.neutral600,
                        ),
                      ),
                      Text(
                        'RM ${originalPrice.toStringAsFixed(2)}',
                        style: AppTheme.body2.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: AppTheme.neutral500,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '报价',
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.neutral600,
                        ),
                      ),
                      Text(
                        'RM ${offerPrice.toStringAsFixed(2)}',
                        style: AppTheme.heading4.copyWith(
                          color: AppTheme.primary500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing8,
                    vertical: AppTheme.spacing4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    '-${((1 - offerPrice / originalPrice) * 100).toStringAsFixed(0)}%',
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.success,
                      fontWeight: AppTheme.semibold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 还价信息（如有）
          if (counterPrice != null && sellerMessage != null) ...[
            const SizedBox(height: AppTheme.spacing12),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing12),
              decoration: BoxDecoration(
                color: AppTheme.info.withOpacity(0.05),
                border: Border.all(color: AppTheme.info, width: 1),
                borderRadius: AppTheme.borderRadiusMedium,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_rounded, color: AppTheme.info, size: 16),
                      const SizedBox(width: 4),
                      const Text('卖家还价', style: AppTheme.caption),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'RM ${counterPrice.toStringAsFixed(2)}',
                    style: AppTheme.heading4.copyWith(color: AppTheme.info),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sellerMessage,
                    style: AppTheme.body2,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],

          // 对方信息
          const SizedBox(height: AppTheme.spacing12),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppTheme.neutral300,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              const Expanded(
                child: Text('卖家姓名', style: AppTheme.body2),
              ),
              const Icon(
                Icons.verified_rounded,
                size: 16,
                color: AppTheme.accent,
              ),
            ],
          ),

          // 操作按钮
          const SizedBox(height: AppTheme.spacing12),
          _buildActionButtons(status, isSent: isSent),
        ],
      ),
    );
  }

  /// 操作按钮
  Widget _buildActionButtons(String status, {required bool isSent}) {
    if (isSent) {
      // 我发出的报价
      switch (status) {
        case 'pending':
          return Row(
            children: [
              Expanded(
                child: BBXSecondaryButton(
                  text: '取消报价',
                  onPressed: () {},
                  height: 40,
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              BBXIconButton(
                icon: Icons.message_rounded,
                onPressed: () {},
                size: 40,
              ),
            ],
          );
        case 'negotiating':
          return Row(
            children: [
              Expanded(
                child: BBXSecondaryButton(
                  text: '拒绝还价',
                  onPressed: () {},
                  height: 40,
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                flex: 2,
                child: BBXPrimaryButton(
                  text: '接受还价',
                  onPressed: () {},
                  height: 40,
                ),
              ),
            ],
          );
        case 'accepted':
          return BBXPrimaryButton(
            text: '查看交易',
            onPressed: () {},
            height: 40,
          );
        case 'rejected':
        case 'expired':
          return BBXPrimaryButton(
            text: '重新报价',
            onPressed: () {},
            height: 40,
          );
        default:
          return const SizedBox.shrink();
      }
    } else {
      // 我收到的报价
      switch (status) {
        case 'pending':
          return Row(
            children: [
              Expanded(
                child: BBXSecondaryButton(
                  text: '拒绝',
                  onPressed: () {},
                  height: 40,
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                child: BBXSecondaryButton(
                  text: '还价',
                  onPressed: () {},
                  height: 40,
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                flex: 2,
                child: BBXPrimaryButton(
                  text: '接受',
                  onPressed: () {},
                  height: 40,
                ),
              ),
            ],
          );
        case 'negotiating':
          return Row(
            children: [
              Expanded(
                child: BBXSecondaryButton(
                  text: '再次还价',
                  onPressed: () {},
                  height: 40,
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                flex: 2,
                child: BBXPrimaryButton(
                  text: '接受当前�?,
                  onPressed: () {},
                  height: 40,
                ),
              ),
            ],
          );
        case 'accepted':
          return BBXPrimaryButton(
            text: '查看交易',
            onPressed: () {},
            height: 40,
          );
        default:
          return const SizedBox.shrink();
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时�?;
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟�?;
    } else {
      return '刚刚';
    }
  }
}
