import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'bbx_chip.dart';
import 'bbx_avatar.dart';

/// BBX 基础卡片组件
class BBXCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? elevation;
  final BorderRadius? borderRadius;

  const BBXCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing8),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: borderRadius ?? AppTheme.borderRadiusMedium,
        boxShadow: elevation != null ? [AppTheme.shadowSmall] : AppTheme.elevation2,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? AppTheme.borderRadiusMedium,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppTheme.spacing16),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// BBX 商品卡片组件
class BBXListingCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String category;
  final double price;
  final String unit;
  final String? quantity;
  final String? sellerName;
  final String? sellerAvatar;
  final double? rating;
  final bool isVerified;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool isFavorited;

  const BBXListingCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.category,
    required this.price,
    required this.unit,
    this.quantity,
    this.sellerName,
    this.sellerAvatar,
    this.rating,
    this.isVerified = false,
    this.onTap,
    this.onFavorite,
    this.isFavorited = false,
  });

  @override
  Widget build(BuildContext context) {
    return BBXCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 商品图片
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radiusMedium),
                  topRight: Radius.circular(AppTheme.radiusMedium),
                ),
                child: Image.network(
                  imageUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 160,
                    color: AppTheme.neutral200,
                    child: const Icon(
                      Icons.image_not_supported_rounded,
                      size: 48,
                      color: AppTheme.neutral400,
                    ),
                  ),
                ),
              ),
              // 分类标签
              Positioned(
                top: AppTheme.spacing8,
                left: AppTheme.spacing8,
                child: BBXCategoryChip(category: category, isSmall: true),
              ),
              // 收藏按钮
              if (onFavorite != null)
                Positioned(
                  top: AppTheme.spacing8,
                  right: AppTheme.spacing8,
                  child: GestureDetector(
                    onTap: onFavorite,
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.spacing8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorited ? Icons.favorite : Icons.favorite_border,
                        color: isFavorited ? AppTheme.error : AppTheme.neutral600,
                        size: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // 商品信息
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacing12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 商品标题
                Text(
                  title,
                  style: AppTheme.heading4,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTheme.spacing8),

                // 卖家信息
                if (sellerName != null)
                  Row(
                    children: [
                      BBXAvatar(
                        imageUrl: sellerAvatar,
                        name: sellerName,
                        size: 16,
                      ),
                      const SizedBox(width: AppTheme.spacing4),
                      Expanded(
                        child: Text(
                          sellerName!,
                          style: AppTheme.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isVerified)
                        const Icon(
                          Icons.verified_rounded,
                          size: 14,
                          color: AppTheme.accent,
                        ),
                      if (rating != null) ...[
                        const SizedBox(width: AppTheme.spacing4),
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
                          ),
                        ),
                      ],
                    ],
                  ),

                const SizedBox(height: AppTheme.spacing8),

                // 数量
                if (quantity != null)
                  Text(
                    quantity!,
                    style: AppTheme.body2.copyWith(
                      color: AppTheme.neutral600,
                    ),
                  ),

                const SizedBox(height: AppTheme.spacing8),

                // 价格和按钮
                Row(
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: AppTheme.heading3.copyWith(
                            color: AppTheme.primary500,
                          ),
                          children: [
                            const TextSpan(text: 'RM '),
                            TextSpan(text: price.toStringAsFixed(2)),
                            TextSpan(
                              text: '/$unit',
                              style: AppTheme.caption.copyWith(
                                color: AppTheme.neutral600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing12,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary500,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                      ),
                      child: const Center(
                        child: Text(
                          '报价',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: AppTheme.semibold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// BBX 报价卡片组件
class BBXOfferCard extends StatelessWidget {
  final String status;
  final String listingTitle;
  final String listingImage;
  final String category;
  final double originalPrice;
  final double offerPrice;
  final String? quantity;
  final String? sellerName;
  final String? sellerAvatar;
  final bool isVerified;
  final String createdAt;
  final VoidCallback? onTap;
  final List<Widget>? actions;

  const BBXOfferCard({
    super.key,
    required this.status,
    required this.listingTitle,
    required this.listingImage,
    required this.category,
    required this.originalPrice,
    required this.offerPrice,
    this.quantity,
    this.sellerName,
    this.sellerAvatar,
    this.isVerified = false,
    required this.createdAt,
    this.onTap,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return BBXCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部：状态和时间
          Row(
            children: [
              BBXStatusChip.status(status, isSmall: true),
              const Spacer(),
              Text(
                createdAt,
                style: AppTheme.caption.copyWith(
                  color: AppTheme.neutral500,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacing12),

          // 商品信息
          Row(
            children: [
              // 商品图片
              ClipRRect(
                borderRadius: AppTheme.borderRadiusMedium,
                child: Image.network(
                  listingImage,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 80,
                    color: AppTheme.neutral200,
                    child: const Icon(Icons.image_not_supported_rounded),
                  ),
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
                    BBXCategoryChip(category: category, isSmall: true),
                    if (quantity != null) ...[
                      const SizedBox(height: AppTheme.spacing4),
                      Text(
                        quantity!,
                        style: AppTheme.body2,
                      ),
                    ],
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

          // 对方信息
          if (sellerName != null) ...[
            const SizedBox(height: AppTheme.spacing12),
            Row(
              children: [
                BBXAvatar(
                  imageUrl: sellerAvatar,
                  name: sellerName,
                  size: 32,
                ),
                const SizedBox(width: AppTheme.spacing8),
                Expanded(
                  child: Text(
                    sellerName!,
                    style: AppTheme.body2,
                  ),
                ),
                if (isVerified)
                  const Icon(
                    Icons.verified_rounded,
                    size: 16,
                    color: AppTheme.accent,
                  ),
              ],
            ),
          ],

          // 操作按钮
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacing12),
            Row(
              children: [
                for (int i = 0; i < actions!.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppTheme.spacing8),
                  Expanded(child: actions![i]),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// BBX 交易卡片组件
class BBXTransactionCard extends StatelessWidget {
  final String transactionId;
  final String status;
  final String listingTitle;
  final String listingImage;
  final double amount;
  final String? quantity;
  final String createdAt;
  final String? estimatedPickupDate;
  final String? otherPartyName;
  final String? otherPartyAvatar;
  final VoidCallback? onTap;
  final List<Widget>? quickActions;

  const BBXTransactionCard({
    super.key,
    required this.transactionId,
    required this.status,
    required this.listingTitle,
    required this.listingImage,
    required this.amount,
    this.quantity,
    required this.createdAt,
    this.estimatedPickupDate,
    this.otherPartyName,
    this.otherPartyAvatar,
    this.onTap,
    this.quickActions,
  });

  @override
  Widget build(BuildContext context) {
    return BBXCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部：交易编号和状态
          Row(
            children: [
              Text(
                '#${transactionId.substring(transactionId.length - 6)}',
                style: AppTheme.body1.copyWith(
                  fontWeight: AppTheme.semibold,
                  color: AppTheme.neutral700,
                ),
              ),
              const Spacer(),
              BBXStatusChip.status(status, isSmall: true),
            ],
          ),

          const SizedBox(height: AppTheme.spacing12),

          // 商品信息
          Row(
            children: [
              ClipRRect(
                borderRadius: AppTheme.borderRadiusMedium,
                child: Image.network(
                  listingImage,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 80,
                    color: AppTheme.neutral200,
                    child: const Icon(Icons.image_not_supported_rounded),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
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
                    if (quantity != null) ...[
                      const SizedBox(height: AppTheme.spacing4),
                      Text(
                        quantity!,
                        style: AppTheme.body2.copyWith(
                          color: AppTheme.neutral600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacing12),

          // 金额
          RichText(
            text: TextSpan(
              style: AppTheme.heading2.copyWith(
                color: AppTheme.primary500,
              ),
              children: [
                const TextSpan(text: 'RM '),
                TextSpan(text: amount.toStringAsFixed(2)),
              ],
            ),
          ),

          // 时间信息
          const SizedBox(height: AppTheme.spacing8),
          Text(
            '创建时间：$createdAt',
            style: AppTheme.caption.copyWith(
              color: AppTheme.neutral500,
            ),
          ),
          if (estimatedPickupDate != null)
            Text(
              '预计取货：$estimatedPickupDate',
              style: AppTheme.caption.copyWith(
                color: AppTheme.neutral700,
                fontWeight: AppTheme.semibold,
              ),
            ),

          // 对方信息
          if (otherPartyName != null) ...[
            const SizedBox(height: AppTheme.spacing12),
            Row(
              children: [
                BBXAvatar(
                  imageUrl: otherPartyAvatar,
                  name: otherPartyName,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.spacing8),
                Text(
                  otherPartyName!,
                  style: AppTheme.body2,
                ),
              ],
            ),
          ],

          // 快捷操作
          if (quickActions != null && quickActions!.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacing12),
            Row(
              children: [
                for (int i = 0; i < quickActions!.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppTheme.spacing8),
                  Expanded(child: quickActions![i]),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
