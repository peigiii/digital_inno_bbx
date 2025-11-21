import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/common.dart';

/// 商品卡片组件
class ProductCard extends StatelessWidget {
  final DocumentSnapshot doc;
  final VoidCallback? onTap;
  final VoidCallback? onQuote;

  const ProductCard({
    super.key,
    required this.doc,
    this.onTap,
    this.onQuote,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final title = data['title'] ?? '未知标题';
    final wasteType = data['wasteType'] ?? '未知类型';
    final quantity = data['quantity'] ?? 0;
    final unit = data['unit'] ?? '�?;
    final pricePerUnit = data['pricePerUnit'] ?? 0;
    final city = data['city'] ?? data['contactInfo'] ?? '未知地区';
    final userEmail = data['userEmail'] ?? '';
    final imageUrl = data['imageUrl'];

    // Extract company name from email
    String supplierName = '供应�?;
    if (userEmail.isNotEmpty) {
      supplierName = userEmail.split('@').first;
    }

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSM,
        vertical: AppTheme.spacingSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图片
          if (imageUrl != null)
            ClipRRect(
              borderRadius: AppTheme.borderRadiusStandard,
              child: Image.network(
                imageUrl,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholderImage();
                },
              ),
            )
          else
            _buildPlaceholderImage(),

          const SizedBox(height: AppTheme.spacingSM),

          // 废料类型（标签）
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingSM,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: const BorderRadius.all(Radius.circular(4)),
            ),
            child: Text(
              wasteType,
              style: AppTheme.caption.copyWith(
                color: AppTheme.primaryDark,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: AppTheme.spacingSM),

          // 标题
          Text(
            title,
            style: AppTheme.subtitle1,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: AppTheme.spacingSM),

          // 价格和数�?
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 价格
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RM $pricePerUnit',
                    style: AppTheme.h3.copyWith(
                      color: AppTheme.primary,
                    ),
                  ),
                  Text(
                    '�?unit',
                    style: AppTheme.caption,
                  ),
                ],
              ),

              // 数量
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMD,
                  vertical: AppTheme.spacingSM,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: AppTheme.borderRadiusStandard,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$quantity $unit',
                      style: AppTheme.body2.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingSM),

          const Divider(height: 1),
          const SizedBox(height: AppTheme.spacingSM),

          // 底部信息
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 城市和供应商
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            city,
                            style: AppTheme.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.store_outlined,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            supplierName,
                            style: AppTheme.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 立即报价按钮
              SmallButton(
                text: '报价',
                icon: Icons.local_offer,
                onPressed: onQuote,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: AppTheme.borderRadiusStandard,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 48,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          Text(
            '暂无图片',
            style: AppTheme.caption.copyWith(
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}
