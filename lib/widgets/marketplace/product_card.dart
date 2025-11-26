import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/common.dart';
import '../../services/favorite_service.dart';

class ProductCard extends StatelessWidget {
  final DocumentSnapshot doc;
  final VoidCallback? onTap;
  final VoidCallback? onQuote;
  final bool showFavoriteButton;

  const ProductCard({
    super.key,
    required this.doc,
    this.onTap,
    this.onQuote,
    this.showFavoriteButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final title = data['title'] ?? 'Unknown Title';
    final wasteType = data['wasteType'] ?? 'Unknown Type';
    final quantity = data['quantity'] ?? 0;
    final unit = data['unit'] ?? 'tons';
    final pricePerUnit = data['pricePerUnit'] ?? 0;
    final city = data['city'] ?? data['contactInfo'] ?? 'Unknown Location';
    final userEmail = data['userEmail'] ?? '';
    final imageUrl = data['imageUrl'];

    // Extract company name from email
    String supplierName = 'Supplier';
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
                    Stack(
            children: [
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

              // Favorite button
              if (showFavoriteButton)
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildFavoriteButton(context),
                ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingSM),

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

                    Text(
            title,
            style: AppTheme.subtitle1,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: AppTheme.spacingSM),

                    Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
                    '个unit',
                    style: AppTheme.caption,
                  ),
                ],
              ),

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

                    Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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

                            SmallButton(
                text: 'Quote',
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
            'No Image',
            style: AppTheme.caption.copyWith(
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteButton(BuildContext context) {
    final favoriteService = FavoriteService();
    final listingId = doc.id;

    return StreamBuilder<bool>(
      stream: favoriteService.isFavoriteStream(listingId),
      builder: (context, snapshot) {
        final isFavorite = snapshot.data ?? false;

        return Container(
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
          child: IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : Colors.grey.shade600,
              size: 20,
            ),
            iconSize: 20,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
            onPressed: () async {
              await favoriteService.toggleFavorite(listingId, context);
            },
            tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
          ),
        );
      },
    );
  }
}
