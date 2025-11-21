import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bbx_button.dart';
import '../../widgets/bbx_chip.dart';
import '../../widgets/bbx_avatar.dart';
import '../../widgets/bbx_loading.dart';
import '../../widgets/bbx_notification.dart';
import '../../models/listing_model.dart';
import '../offers/bbx_new_make_offer_screen.dart';
import '../../utils/page_transitions.dart';

class BBXNewListingDetailScreen extends StatefulWidget {
  final String listingId;

  const BBXNewListingDetailScreen({
    super.key,
    required this.listingId,
  });

  @override
  State<BBXNewListingDetailScreen> createState() => _BBXNewListingDetailScreenState();
}

class _BBXNewListingDetailScreenState extends State<BBXNewListingDetailScreen> {
  final PageController _imagePageController = PageController();
  int _currentImageIndex = 0;
  bool _isFavorited = false;
  bool _showFullDescription = false;

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('listings')
            .doc(widget.listingId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('加载失败?{snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const BBXFullScreenLoading(message: '加载?..');
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('商品不存?));
          }

          final listing = ListingModel.fromDocument(snapshot.data!);

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                                    _buildImageCarousel(listing.images),

                                    _buildListingInfoCard(listing),

                                    _buildBasicInfo(listing),

                                    _buildSellerCard(listing),

                                    _buildDescription(listing),

                                    _buildLocationInfo(listing),

                                    _buildSimilarListings(listing.category),

                                    const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),

                            _buildBottomActionBar(listing),
            ],
          );
        },
      ),
    );
  }

    Widget _buildImageCarousel(List<String> images) {
    final displayImages = images.isNotEmpty ? images : [''];

    return SliverAppBar(
      expandedHeight: MediaQuery.of(context).size.height * 0.4,
      pinned: false,
      backgroundColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.share_rounded, color: Colors.white),
              onPressed: () {},
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                _isFavorited ? Icons.favorite : Icons.favorite_border,
                color: _isFavorited ? AppTheme.error : Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _isFavorited = !_isFavorited;
                });
                BBXNotification.showSuccess(
                  context,
                  _isFavorited ? '已添加到收藏' : 'Cancelled收?,
                );
              },
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            PageView.builder(
              controller: _imagePageController,
              onPageChanged: (index) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
              itemCount: displayImages.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                                      },
                  child: displayImages[index].isNotEmpty
                      ? Image.network(
                          displayImages[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: AppTheme.neutral200,
                            child: const Icon(
                              Icons.image_not_supported_rounded,
                              size: 64,
                              color: AppTheme.neutral400,
                            ),
                          ),
                        )
                      : Container(
                          color: AppTheme.neutral200,
                          child: const Icon(
                            Icons.image_not_supported_rounded,
                            size: 64,
                            color: AppTheme.neutral400,
                          ),
                        ),
                );
              },
            ),
                        if (displayImages.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    displayImages.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentImageIndex == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

    Widget _buildListingInfoCard(Listing listing) {
    return SliverToBoxAdapter(
      child: Transform.translate(
        offset: const Offset(0, -20),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
          padding: const EdgeInsets.all(AppTheme.spacing24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppTheme.radiusXLarge),
              topRight: Radius.circular(AppTheme.radiusXLarge),
            ),
            boxShadow: AppTheme.elevation4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                            BBXCategoryChip(category: listing.category),
              const SizedBox(height: AppTheme.spacing12),

                            Text(
                listing.title,
                style: AppTheme.heading2,
              ),
              const SizedBox(height: AppTheme.spacing12),

                            Row(
                children: [
                  RichText(
                    text: TextSpan(
                      style: AppTheme.heading1.copyWith(
                        color: AppTheme.primary500,
                      ),
                      children: [
                        const TextSpan(text: 'RM '),
                        TextSpan(
                          text: listing.pricePerUnit.toStringAsFixed(2),
                        ),
                        TextSpan(
                          text: '/${listing.unit}',
                          style: AppTheme.body1.copyWith(
                            color: AppTheme.neutral600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing8),

                            Text(
                '发布?${listing.createdAt != null ? _formatDate(listing.createdAt!) : '未知时间'}',
                style: AppTheme.caption.copyWith(
                  color: AppTheme.neutral500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

    Widget _buildBasicInfo(Listing listing) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(AppTheme.spacing16),
        padding: const EdgeInsets.all(AppTheme.spacing12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppTheme.borderRadiusMedium,
          boxShadow: AppTheme.elevation1,
        ),
        child: Column(
          children: [
            Row(
              children: [
                _buildInfoItem(
                  Icons.inventory_2_outlined,
                  '总数?,
                  '${listing.quantity} ${listing.unit}',
                ),
                const SizedBox(width: AppTheme.spacing8),
                _buildInfoItem(
                  Icons.shopping_cart_outlined,
                  '数量',
                  '${listing.quantity} ${listing.unit}',
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing12),
            Row(
              children: [
                _buildInfoItem(
                  Icons.check_circle_outline,
                  '可用数量',
                  '${listing.quantity} ${listing.unit}',
                ),
                const SizedBox(width: AppTheme.spacing8),
                _buildInfoItem(
                  Icons.location_on_outlined,
                  '所在地',
                  listing.location != null && listing.location!['address'] != null
                      ? listing.location!['address'].toString().split(',').first
                      : listing.contactInfo,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.primary500, size: 20),
          const SizedBox(width: AppTheme.spacing4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.neutral700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTheme.body2.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

    Widget _buildSellerCard(Listing listing) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(AppTheme.spacing16),
        padding: const EdgeInsets.all(AppTheme.spacing12),
        decoration: BoxDecoration(
          color: AppTheme.neutral50,
          borderRadius: AppTheme.borderRadiusMedium,
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              BBXAvatarVerified(
                imageUrl: null,
                name: listing.sellerName,
                size: 48,
                isVerified: true,
              ),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      listing.sellerName,
                      style: AppTheme.heading4,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, size: 14, color: Colors.amber[700]),
                        const SizedBox(width: 4),
                        const Text('4.8', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        const Text('·', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        const Flexible(
                          child: Text(
                            '128笔交?,
                            style: TextStyle(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BBXIconButton(
                    icon: Icons.message_rounded,
                    onPressed: () {},
                    color: AppTheme.primary500,
                    size: 36,
                  ),
                  const SizedBox(height: 4),
                  BBXIconButton(
                    icon: Icons.phone_rounded,
                    onPressed: () {},
                    color: AppTheme.primary500,
                    size: 36,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

    Widget _buildDescription(Listing listing) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(AppTheme.spacing16),
        padding: const EdgeInsets.all(AppTheme.spacing16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppTheme.borderRadiusMedium,
          boxShadow: AppTheme.elevation1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('商品描述', style: AppTheme.heading3),
            const SizedBox(height: AppTheme.spacing12),
            Text(
              listing.description,
              style: AppTheme.body1,
              maxLines: _showFullDescription ? null : 5,
              overflow: _showFullDescription ? null : TextOverflow.ellipsis,
            ),
            if (listing.description.length > 200)
              TextButton(
                onPressed: () {
                  setState(() {
                    _showFullDescription = !_showFullDescription;
                  });
                },
                child: Text(_showFullDescription ? '收起' : '展开'),
              ),
          ],
        ),
      ),
    );
  }

    Widget _buildLocationInfo(Listing listing) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(AppTheme.spacing16),
        padding: const EdgeInsets.all(AppTheme.spacing16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppTheme.borderRadiusMedium,
          boxShadow: AppTheme.elevation1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('取货地址', style: AppTheme.heading3),
            const SizedBox(height: AppTheme.spacing12),
                        Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppTheme.neutral200,
                borderRadius: AppTheme.borderRadiusMedium,
              ),
              child: const Center(
                child: Icon(
                  Icons.map_rounded,
                  size: 64,
                  color: AppTheme.neutral400,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing12),
            Text(
              listing.location != null && listing.location!['address'] != null
                  ? listing.location!['address'].toString()
                  : listing.contactInfo,
              style: AppTheme.body1,
            ),
            const SizedBox(height: AppTheme.spacing12),
            BBXSecondaryButton(
              text: '查看地图',
              onPressed: () {},
              icon: Icons.directions_rounded,
            ),
          ],
        ),
      ),
    );
  }

    Widget _buildSimilarListings(String category) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('相似商品', style: AppTheme.heading3),
            const SizedBox(height: AppTheme.spacing12),
            SizedBox(
              height: 240,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('listings')
                    .where('category', isEqualTo: category)
                    .where('status', isEqualTo: 'active')
                    .limit(5)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('暂无相似商品'));
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final listing = ListingModel.fromDocument(doc);

                      return Container(
                        width: 160,
                        margin: const EdgeInsets.only(right: AppTheme.spacing12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: AppTheme.borderRadiusMedium,
                          boxShadow: AppTheme.elevation1,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(AppTheme.radiusMedium),
                                topRight: Radius.circular(AppTheme.radiusMedium),
                              ),
                              child: Image.network(
                                listing.images.isNotEmpty ? listing.images.first : '',
                                height: 120,
                                width: 160,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  height: 120,
                                  color: AppTheme.neutral200,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(AppTheme.spacing8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    listing.title,
                                    style: AppTheme.body2,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'RM ${listing.pricePerUnit.toStringAsFixed(2)}',
                                    style: AppTheme.heading4.copyWith(
                                      color: AppTheme.primary500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

    Widget _buildBottomActionBar(Listing listing) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing12,
          vertical: AppTheme.spacing12,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: AppTheme.shadowMedium,
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              BBXIconButton(
                icon: _isFavorited ? Icons.favorite : Icons.favorite_border,
                onPressed: () {
                  setState(() {
                    _isFavorited = !_isFavorited;
                  });
                },
                color: _isFavorited ? AppTheme.error : AppTheme.neutral600,
                size: 44,
              ),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                child: BBXSecondaryButton(
                  text: '联系',
                  onPressed: () {},
                  icon: Icons.message_rounded,
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                flex: 2,
                child: BBXPrimaryButton(
                  text: '提交Quote',
                  onPressed: () {
                    PageTransitions.navigateToSlideUp(
                      context,
                      BBXNewMakeOfferScreen(listing: listing),
                    );
                  },
                  icon: Icons.local_offer_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return '${date.year}-${date.month}-${date.day}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}
