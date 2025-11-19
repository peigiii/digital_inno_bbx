import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// 现代化商品卡片组件 - 优化版
/// 适配 Pixel 5 (393 x 851 dp)
class ModernListingCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String category;
  final double price;
  final String unit;
  final String? location;
  final String? sellerName;
  final String? sellerAvatar;
  final double? rating;
  final int? reviewCount;
  final bool isVerified;
  final bool isFavorited;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;

  const ModernListingCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.category,
    required this.price,
    required this.unit,
    this.location,
    this.sellerName,
    this.sellerAvatar,
    this.rating,
    this.reviewCount,
    this.isVerified = false,
    this.isFavorited = false,
    this.onTap,
    this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing8,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: AppTheme.borderRadiusLarge,
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppTheme.borderRadiusLarge,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppTheme.borderRadiusLarge,
              border: Border.all(color: AppTheme.neutral200, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 图片区域 (16:9 比例)
                _buildImageSection(),
                
                // 信息区域
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacing12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 商品标题
                      Text(
                        title,
                        style: AppTheme.heading4.copyWith(height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppTheme.spacing4),

                      // 位置信息
                      if (location != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: AppTheme.neutral500,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location!,
                                style: AppTheme.caption.copyWith(
                                  color: AppTheme.neutral600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: AppTheme.spacing8),

                      // 价格和操作按钮
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: AppTheme.bold,
                                      color: AppTheme.primary500,
                                      height: 1.2,
                                    ),
                                    children: [
                                      const TextSpan(text: 'RM '),
                                      TextSpan(text: price.toStringAsFixed(2)),
                                    ],
                                  ),
                                ),
                                Text(
                                  '/$unit',
                                  style: AppTheme.caption.copyWith(
                                    color: AppTheme.neutral600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // 报价按钮
                          Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacing16,
                            ),
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
                                '立即报价',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: AppTheme.semibold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // 卖家信息
                      if (sellerName != null) ...[
                        const SizedBox(height: AppTheme.spacing8),
                        const Divider(height: 1),
                        const SizedBox(height: AppTheme.spacing8),
                        Row(
                          children: [
                            // 头像
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: AppTheme.primary100,
                              backgroundImage: sellerAvatar != null
                                  ? NetworkImage(sellerAvatar!)
                                  : null,
                              child: sellerAvatar == null
                                  ? Text(
                                      sellerName![0].toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.primary500,
                                        fontWeight: AppTheme.semibold,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            
                            // 卖家名和认证
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      sellerName!,
                                      style: AppTheme.caption.copyWith(
                                        color: AppTheme.neutral700,
                                        fontWeight: AppTheme.medium,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isVerified) ...[
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.verified_rounded,
                                      size: 14,
                                      color: AppTheme.info,
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // 评分
                            if (rating != null) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: Colors.amber[700],
                              ),
                              const SizedBox(width: 2),
                              Text(
                                rating!.toStringAsFixed(1),
                                style: AppTheme.caption.copyWith(
                                  color: AppTheme.neutral700,
                                  fontWeight: AppTheme.semibold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建图片区域
  Widget _buildImageSection() {
    return Stack(
      children: [
        // 主图片 (16:9 比例，最大高度 200dp)
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppTheme.radiusLarge),
              topRight: Radius.circular(AppTheme.radiusLarge),
            ),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppTheme.neutral100,
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported_rounded,
                      size: 48,
                      color: AppTheme.neutral400,
                    ),
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: AppTheme.neutral100,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.primary500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // 分类标签（左上角）
        Positioned(
          top: AppTheme.spacing8,
          left: AppTheme.spacing8,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing8,
              vertical: AppTheme.spacing4,
            ),
            decoration: BoxDecoration(
              color: AppTheme.getCategoryColor(category).withOpacity(0.9),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Text(
              category,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: AppTheme.semibold,
              ),
            ),
          ),
        ),

        // 收藏按钮（右上角）
        if (onFavorite != null)
          Positioned(
            top: AppTheme.spacing8,
            right: AppTheme.spacing8,
            child: GestureDetector(
              onTap: onFavorite,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    isFavorited
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isFavorited ? AppTheme.error : AppTheme.neutral600,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 现代化报价卡片组件
class ModernOfferCard extends StatelessWidget {
  final String status;
  final String statusLabel;
  final String listingTitle;
  final String listingImage;
  final String category;
  final double originalPrice;
  final double offerPrice;
  final String unit;
  final String? sellerName;
  final bool isVerified;
  final String createdAt;
  final VoidCallback? onTap;
  final Widget? actions;

  const ModernOfferCard({
    super.key,
    required this.status,
    required this.statusLabel,
    required this.listingTitle,
    required this.listingImage,
    required this.category,
    required this.originalPrice,
    required this.offerPrice,
    required this.unit,
    this.sellerName,
    this.isVerified = false,
    required this.createdAt,
    this.onTap,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final discountPercent = ((1 - offerPrice / originalPrice) * 100);
    final statusColor = AppTheme.getStatusColor(status);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing8,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: AppTheme.borderRadiusLarge,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppTheme.borderRadiusLarge,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppTheme.borderRadiusLarge,
              border: Border.all(color: AppTheme.neutral200, width: 1),
              // 左侧状态条
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.2),
                  blurRadius: 0,
                  spreadRadius: 0,
                  offset: const Offset(-4, 0),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 顶部：状态和时间
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacing12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing8,
                          vertical: AppTheme.spacing4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: AppTheme.semibold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: AppTheme.neutral500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        createdAt,
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.neutral500,
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // 商品信息
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacing12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 商品图片
                      ClipRRect(
                        borderRadius: AppTheme.borderRadiusMedium,
                        child: Image.network(
                          listingImage,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 80,
                              height: 80,
                              color: AppTheme.neutral100,
                              child: const Icon(
                                Icons.image_not_supported_rounded,
                                color: AppTheme.neutral400,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacing12),

                      // 商品详情
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              listingTitle,
                              style: AppTheme.heading4,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppTheme.spacing4),
                            
                            // 分类标签
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacing8,
                                vertical: AppTheme.spacing4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.getCategoryColor(category)
                                    .withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusSmall),
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  color: AppTheme.getCategoryColor(category),
                                  fontSize: 11,
                                  fontWeight: AppTheme.semibold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 报价信息
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacing12),
                  padding: const EdgeInsets.all(AppTheme.spacing12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary50,
                        AppTheme.primary50.withOpacity(0.5),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: AppTheme.borderRadiusMedium,
                  ),
                  child: Row(
                    children: [
                      // 原价
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
                            const SizedBox(height: 2),
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

                      // 报价
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '我的报价',
                              style: AppTheme.caption.copyWith(
                                color: AppTheme.neutral600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'RM ${offerPrice.toStringAsFixed(2)}',
                              style: AppTheme.heading4.copyWith(
                                color: AppTheme.primary700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 折扣标签
                      if (discountPercent > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacing8,
                            vertical: AppTheme.spacing4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.success,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                          child: Text(
                            '-${discountPercent.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: AppTheme.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // 卖家信息
                if (sellerName != null) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spacing12,
                      AppTheme.spacing8,
                      AppTheme.spacing12,
                      AppTheme.spacing8,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.primary100,
                          child: Text(
                            sellerName![0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.primary500,
                              fontWeight: AppTheme.semibold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sellerName!,
                            style: AppTheme.body2.copyWith(
                              fontWeight: AppTheme.medium,
                            ),
                          ),
                        ),
                        if (isVerified)
                          const Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: AppTheme.info,
                          ),
                      ],
                    ),
                  ),
                ],

                // 操作按钮
                if (actions != null) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.spacing12),
                    child: actions,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

