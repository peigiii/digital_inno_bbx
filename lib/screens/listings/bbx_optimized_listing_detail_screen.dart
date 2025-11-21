import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_theme.dart';
import '../../models/listing_model.dart';
import '../offers/bbx_optimized_make_offer_bottom_sheet.dart';

/// BBX 商品详情�?- 完全优化�?
/// 适配 Pixel 5 (393 x 851 dp)
/// Material Design 3 风格
class BBXOptimizedListingDetailScreen extends StatefulWidget {
  final String listingId;

  const BBXOptimizedListingDetailScreen({
    super.key,
    required this.listingId,
  });

  @override
  State<BBXOptimizedListingDetailScreen> createState() =>
      _BBXOptimizedListingDetailScreenState();
}

class _BBXOptimizedListingDetailScreenState
    extends State<BBXOptimizedListingDetailScreen> {
  final PageController _imagePageController = PageController();
  final ScrollController _scrollController = ScrollController();
  
  int _currentImageIndex = 0;
  bool _isFavorited = false;
  double _appBarOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _checkIfFavorited();
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // 根据滚动位置控制 AppBar 透明�?
    final offset = _scrollController.offset;
    setState(() {
      _appBarOpacity = (offset / 200).clamp(0.0, 1.0);
    });
  }

  Future<void> _checkIfFavorited() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final favDoc = await FirebaseFirestore.instance
        .collection('user_favorites')
        .doc(user.uid)
        .collection('listings')
        .doc(widget.listingId)
        .get();

    if (mounted) {
      setState(() {
        _isFavorited = favDoc.exists;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('请先登录');
      return;
    }

    final favRef = FirebaseFirestore.instance
        .collection('user_favorites')
        .doc(user.uid)
        .collection('listings')
        .doc(widget.listingId);

    try {
      if (_isFavorited) {
        await favRef.delete();
        _showMessage('已取消收�?);
      } else {
        await favRef.set({
          'listingId': widget.listingId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        _showMessage('已添加到收藏');
      }

      setState(() {
        _isFavorited = !_isFavorited;
      });
    } catch (e) {
      _showMessage('操作失败，请重试');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('listings')
          .doc(widget.listingId)
          .snapshots(),
      builder: (context, snapshot) {
        // 获取数据
        Map<String, dynamic>? data;
        if (snapshot.hasData) {
          data = snapshot.data!.data() as Map<String, dynamic>?;
        }

        return Scaffold(
          backgroundColor: AppTheme.background,
          extendBodyBehindAppBar: true,
          appBar: _buildAppBar(),
          body: Builder(
            builder: (context) {
              if (snapshot.hasError) {
                return _buildErrorState();
              }

              if (!snapshot.hasData) {
                return _buildLoadingState();
              }

              if (data == null) {
                return _buildNotFoundState();
              }

              return _buildContent(data);
            },
          ),
          bottomNavigationBar: data != null ? _buildBottomActionBar(data) : null,
        );
      },
    );
  }

  /// 顶部 AppBar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white.withOpacity(_appBarOpacity),
      elevation: _appBarOpacity > 0.5 ? 2 : 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _appBarOpacity < 0.5
              ? Colors.black.withOpacity(0.3)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: _appBarOpacity < 0.5 ? Colors.white : AppTheme.neutral900,
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _appBarOpacity < 0.5
                ? Colors.black.withOpacity(0.3)
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () {
              // 分享功能
              Share.share('查看这个商品');
            },
            icon: Icon(
              Icons.share_rounded,
              color: _appBarOpacity < 0.5 ? Colors.white : AppTheme.neutral900,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: _appBarOpacity < 0.5
                ? Colors.black.withOpacity(0.3)
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(
              _isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isFavorited
                  ? AppTheme.error
                  : (_appBarOpacity < 0.5 ? Colors.white : AppTheme.neutral900),
            ),
          ),
        ),
      ],
    );
  }

  /// 主内容区�?
  Widget _buildContent(Map<String, dynamic> data) {
    final images = (data['imageUrls'] as List<dynamic>?)?.cast<String>() ?? [];

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // 图片轮播区域
        SliverToBoxAdapter(
          child: _buildImageCarousel(images),
        ),

        // 价格和标题卡片（浮动设计�?
        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -24),
            child: _buildPriceCard(data),
          ),
        ),

        // 商品详情
        SliverToBoxAdapter(
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
                // 卖家信息卡片
                _buildSellerCard(data),
                const SizedBox(height: AppTheme.spacing16),

                // 商品规格
                _buildSpecificationsCard(data),
                const SizedBox(height: AppTheme.spacing16),

                // 商品描述
                _buildDescriptionCard(data),
                const SizedBox(height: AppTheme.spacing16),

                // 位置信息
                _buildLocationCard(data),
                const SizedBox(height: AppTheme.spacing16),

                // 相似商品
                _buildSimilarProductsSection(data),
                
                // 底部间距
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 图片轮播
  Widget _buildImageCarousel(List<String> images) {
    if (images.isEmpty) {
      return Container(
        height: 400,
        color: AppTheme.neutral100,
        child: const Center(
          child: Icon(
            Icons.image_not_supported_rounded,
            size: 80,
            color: AppTheme.neutral400,
          ),
        ),
      );
    }

    return SizedBox(
      height: 400,
      child: Stack(
        children: [
          // 图片轮播
          PageView.builder(
            controller: _imagePageController,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemCount: images.length,
            itemBuilder: (context, index) {
              final imageWidget = Image.network(
                images[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppTheme.neutral100,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image_rounded,
                        size: 80,
                        color: AppTheme.neutral400,
                      ),
                    ),
                  );
                },
              );

              // 只对第一张图片使�?Hero 动画，且 URL 不为�?
              if (index == 0 && images[index].isNotEmpty) {
                return Hero(
                  tag: images[index],
                  child: imageWidget,
                );
              }
              return imageWidget;
            },
          ),

          // 渐变遮罩（底部）
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                  ],
                ),
              ),
            ),
          ),

          // 图片指示�?
          if (images.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentImageIndex == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentImageIndex == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 价格和标题卡�?
  Widget _buildPriceCard(Map<String, dynamic> data) {
    final price = (data['pricePerUnit'] ?? 0).toDouble();
    final unit = data['unit'] ?? 'kg';
    final title = data['title'] ?? '未知商品';
    final category = data['wasteType'] ?? 'Other';
    final quantity = data['quantity'] ?? 0;
    final status = data['status'] ?? 'available';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.borderRadiusLarge,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 分类标签
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing8,
              vertical: AppTheme.spacing4,
            ),
            decoration: BoxDecoration(
              color: AppTheme.getCategoryColor(category).withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Text(
              category,
              style: TextStyle(
                color: AppTheme.getCategoryColor(category),
                fontSize: 12,
                fontWeight: AppTheme.semibold,
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spacing12),

          // 标题
          Text(
            title,
            style: AppTheme.heading2.copyWith(height: 1.3),
          ),

          const SizedBox(height: AppTheme.spacing12),

          // 可用数量
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primary50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  size: 16,
                  color: AppTheme.primary500,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '可用�?quantity $unit',
                style: AppTheme.body1.copyWith(
                  fontWeight: AppTheme.medium,
                ),
              ),
              const Spacer(),
              // 状态标�?
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing12,
                  vertical: AppTheme.spacing4,
                ),
                decoration: BoxDecoration(
                  color: status == 'available'
                      ? AppTheme.success.withOpacity(0.1)
                      : AppTheme.neutral200,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: status == 'available'
                            ? AppTheme.success
                            : AppTheme.neutral500,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      status == 'available' ? '可购�? : '已售�?,
                      style: TextStyle(
                        color: status == 'available'
                            ? AppTheme.success
                            : AppTheme.neutral600,
                        fontSize: 12,
                        fontWeight: AppTheme.semibold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacing16),
          const Divider(height: 1),
          const SizedBox(height: AppTheme.spacing16),

          // 价格
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '价格',
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.neutral600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: AppTheme.bold,
                        color: AppTheme.primary600,
                        height: 1.0,
                      ),
                      children: [
                        const TextSpan(text: 'RM '),
                        TextSpan(text: price.toStringAsFixed(2)),
                      ],
                    ),
                  ),
                  Text(
                    '/$unit',
                    style: AppTheme.body2.copyWith(
                      color: AppTheme.neutral600,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // 总价估算
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing12),
                decoration: BoxDecoration(
                  color: AppTheme.primary50,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '全部购买',
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.primary700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'RM ${(price * quantity).toStringAsFixed(2)}',
                      style: AppTheme.heading4.copyWith(
                        color: AppTheme.primary700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 卖家信息卡片
  Widget _buildSellerCard(Map<String, dynamic> data) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(data['userId'])
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppTheme.borderRadiusLarge,
            ),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        if (userData == null) return const SizedBox.shrink();

        final displayName = userData['displayName'] ?? '未知卖家';
        final isVerified = userData['isVerified'] ?? false;

        return Container(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppTheme.borderRadiusLarge,
            border: Border.all(color: AppTheme.neutral200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '卖家信息',
                style: AppTheme.heading4.copyWith(
                  color: AppTheme.neutral700,
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),
              Row(
                children: [
                  // 头像
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        displayName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: AppTheme.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing12),

                  // 卖家信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              displayName,
                              style: AppTheme.heading4,
                            ),
                            if (isVerified) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.verified_rounded,
                                size: 18,
                                color: AppTheme.info,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            ...List.generate(
                              5,
                              (index) => Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: index < 4
                                    ? Colors.amber[700]
                                    : AppTheme.neutral300,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '4.8 (125)',
                              style: AppTheme.caption.copyWith(
                                color: AppTheme.neutral600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 聊天按钮
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primary500,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      onPressed: () {
                        // 打开聊天
                      },
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.chat_bubble_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// 商品规格卡片
  Widget _buildSpecificationsCard(Map<String, dynamic> data) {
    final specs = [
      {
        'icon': Icons.category_rounded,
        'label': '废料类型',
        'value': data['wasteType'] ?? '-'
      },
      {
        'icon': Icons.scale_rounded,
        'label': '重量',
        'value': '${data['quantity']} ${data['unit'] ?? 'kg'}'
      },
      {
        'icon': Icons.water_drop_rounded,
        'label': '含水�?,
        'value': data['moistureContent'] ?? '-'
      },
      {
        'icon': Icons.calendar_today_rounded,
        'label': '收集日期',
        'value': _formatDate(data['collectionDate'])
      },
    ];

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.borderRadiusLarge,
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '商品规格',
            style: AppTheme.heading4.copyWith(
              color: AppTheme.neutral700,
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          ...specs.map((spec) => Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.primary50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        spec['icon'] as IconData,
                        size: 18,
                        color: AppTheme.primary500,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            spec['label'] as String,
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.neutral600,
                            ),
                          ),
                          Text(
                            spec['value'] as String,
                            style: AppTheme.body1.copyWith(
                              fontWeight: AppTheme.medium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  /// 商品描述卡片
  Widget _buildDescriptionCard(Map<String, dynamic> data) {
    final description = data['description'] ?? '暂无描述';

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.borderRadiusLarge,
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '商品描述',
            style: AppTheme.heading4.copyWith(
              color: AppTheme.neutral700,
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          Text(
            description,
            style: AppTheme.body1.copyWith(
              color: AppTheme.neutral700,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  /// 位置信息卡片
  Widget _buildLocationCard(Map<String, dynamic> data) {
    final location = data['location'] ?? '未知位置';

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.borderRadiusLarge,
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '位置信息',
            style: AppTheme.heading4.copyWith(
              color: AppTheme.neutral700,
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppTheme.error,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Text(
                  location.toString(),
                  style: AppTheme.body1.copyWith(
                    fontWeight: AppTheme.medium,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  // 打开地图
                },
                icon: const Icon(
                  Icons.map_rounded,
                  color: AppTheme.primary500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 相似商品区域
  Widget _buildSimilarProductsSection(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('相似商品', style: AppTheme.heading4),
            const Spacer(),
            TextButton(
              onPressed: () {},
              child: Text(
                '查看全部',
                style: AppTheme.body2.copyWith(
                  color: AppTheme.primary500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing12),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            itemBuilder: (context, index) {
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: AppTheme.spacing12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppTheme.borderRadiusMedium,
                  border: Border.all(color: AppTheme.neutral200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppTheme.neutral100,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(AppTheme.radiusMedium),
                          topRight: Radius.circular(AppTheme.radiusMedium),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '商品标题',
                            style: AppTheme.body2.copyWith(
                              fontWeight: AppTheme.semibold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'RM 50.00/kg',
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.primary500,
                              fontWeight: AppTheme.semibold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 底部操作�?
  Widget _buildBottomActionBar(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // 收藏按钮
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.neutral200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: _toggleFavorite,
                icon: Icon(
                  _isFavorited
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: _isFavorited ? AppTheme.error : AppTheme.neutral600,
                ),
              ),
            ),

            const SizedBox(width: AppTheme.spacing12),

            // 联系卖家按钮
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.primary500, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('聊天功能即将上线')),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: AppTheme.primary500,
                            size: 20,
                          ),
                          SizedBox(width: 6),
                          Text(
                            '联系卖家',
                            style: TextStyle(
                              color: AppTheme.primary500,
                              fontSize: 16,
                              fontWeight: AppTheme.semibold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: AppTheme.spacing12),

            // 立即报价按钮
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary500.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // 打开现代化报价弹�?
                      try {
                        final listing = ListingModel.fromMap(widget.listingId, data);
                        BBXOptimizedMakeOfferBottomSheet.show(context, listing);
                      } catch (e) {
                        debugPrint('Error creating ListingModel: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('无法打开报价页面，数据格式错�?)),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: const Center(
                      child: Text(
                        '立即报价',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: AppTheme.bold,
                        ),
                      ),
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

  /// 加载状�?
  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  /// 错误状�?
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: AppTheme.neutral400,
          ),
          const SizedBox(height: AppTheme.spacing16),
          Text(
            '加载失败',
            style: AppTheme.heading4.copyWith(
              color: AppTheme.neutral600,
            ),
          ),
        ],
      ),
    );
  }

  /// 未找到状�?
  Widget _buildNotFoundState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 64,
            color: AppTheme.neutral400,
          ),
          const SizedBox(height: AppTheme.spacing16),
          Text(
            '商品不存�?,
            style: AppTheme.heading4.copyWith(
              color: AppTheme.neutral600,
            ),
          ),
        ],
      ),
    );
  }

  /// 格式化日�?
  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '-';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.year}/${date.month}/${date.day}';
    }
    return '-';
  }
}

