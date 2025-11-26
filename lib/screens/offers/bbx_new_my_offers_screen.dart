import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bbx_card.dart';
import '../../widgets/bbx_chip.dart';
import '../../widgets/bbx_button.dart';
import '../../widgets/bbx_empty_state.dart';
import '../../widgets/bbx_loading.dart';
import '../../widgets/state/error_state_widget.dart';
import '../../widgets/state/empty_state_widget.dart';
import '../../models/offer_model.dart';

/// BBX MineQuotePage（Complete Refactor）
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
    'all': 'All',
    'pending': 'WaitPlace�?,
    'negotiating': 'DiscussPrice�?,
    'accepted': 'AlreadyConnect�?,
    'rejected': 'AlreadyRefuse�?,
    'expired': 'AlreadyPass�?,
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
        title: const Text('MineQuote', style: AppTheme.heading2),
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
                      const Text('ISendOut of '),
                      const SizedBox(width: 4),
                      _buildBadge(5),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('IReceived of '),
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
          // StatusFilterBar
          _buildFilterBar(),

          // ContentArea
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

  /// AngleMark
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

  /// FilterBar
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

  /// ISendOut of QuoteColTable
  Widget _buildSentOffersList() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return ErrorStateWidget.permissionDenied(
        message: 'Please login to view yourQuote',
        onBack: () => Navigator.pop(context),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _getOffersStream(user.uid, isSent: true),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorStateWidget.network(
            onRetry: () => setState(() {}),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const BBXListLoading(itemCount: 5);
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return EmptyStateWidget.noOffers(
            onBrowse: () => Navigator.pushNamed(context, '/home'),
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

  /// IReceived of QuoteColTable
  Widget _buildReceivedOffersList() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return ErrorStateWidget.permissionDenied(
        message: 'Please login to view receivedQuote',
        onBack: () => Navigator.pop(context),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _getOffersStream(user.uid, isSent: false),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorStateWidget.network(
            onRetry: () => setState(() {}),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const BBXListLoading(itemCount: 5);
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.inbox_outlined,
            title: 'TempNoneReceived of Quote',
            message: 'When a buyer submits to your itemQuoteTime\nWillShowAtThisIn',
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

  /// GetQuote�?
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

  /// QuoteCard
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
          // Top：StatusandTime
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

          // Item Info（SimpleizeVersion�?
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
                      'Item Title',
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

          // QuoteInfo
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
                        'Original Price',
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
                        'Quote',
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

          // ReturnPriceInfo（IfHave）
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
                      const Text('Seller Counter Offer', style: AppTheme.caption),
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

          // PairSquareInfo
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
                child: Text('SellerName', style: AppTheme.body2),
              ),
              const Icon(
                Icons.verified_rounded,
                size: 16,
                color: AppTheme.accent,
              ),
            ],
          ),

          // ActionPressButton
          const SizedBox(height: AppTheme.spacing12),
          _buildActionButtons(status, isSent: isSent),
        ],
      ),
    );
  }

  /// ActionPressButton
  Widget _buildActionButtons(String status, {required bool isSent}) {
    if (isSent) {
      // ISendOut of Quote
      switch (status) {
        case 'pending':
          return Row(
            children: [
              Expanded(
                child: BBXSecondaryButton(
                  text: 'CancelQuote',
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
                  text: 'RejectReturnPrice',
                  onPressed: () {},
                  height: 40,
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                flex: 2,
                child: BBXPrimaryButton(
                  text: 'AcceptReturnPrice',
                  onPressed: () {},
                  height: 40,
                ),
              ),
            ],
          );
        case 'accepted':
          return BBXPrimaryButton(
            text: 'View Transaction',
            onPressed: () {},
            height: 40,
          );
        case 'rejected':
        case 'expired':
          return BBXPrimaryButton(
            text: 'RetryQuote',
            onPressed: () {},
            height: 40,
          );
        default:
          return const SizedBox.shrink();
      }
    } else {
      // IReceived of Quote
      switch (status) {
        case 'pending':
          return Row(
            children: [
              Expanded(
                child: BBXSecondaryButton(
                  text: 'Reject',
                  onPressed: () {},
                  height: 40,
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                child: BBXSecondaryButton(
                  text: 'ReturnPrice',
                  onPressed: () {},
                  height: 40,
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                flex: 2,
                child: BBXPrimaryButton(
                  text: 'Accept',
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
                  text: 'Counter Offer Again',
                  onPressed: () {},
                  height: 40,
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                flex: 2,
                child: BBXPrimaryButton(
                  text: 'AcceptCurrent�?,
                  onPressed: () {},
                  height: 40,
                ),
              ),
            ],
          );
        case 'accepted':
          return BBXPrimaryButton(
            text: 'View Transaction',
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
      return '${difference.inDays}DayFront';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}Hours�?;
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}Minutes�?;
    } else {
      return 'Just now';
    }
  }
}
