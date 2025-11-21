import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/common.dart';

class SupplierCard extends StatelessWidget {
  final DocumentSnapshot doc;
  final VoidCallback? onTap;

  const SupplierCard({
    super.key,
    required this.doc,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final displayName = data['displayName'] ?? data['email']?.split('@').first ?? 'Supplier';
    final companyName = data['companyName'] ?? displayName;
    final city = data['city'] ?? data['address'] ?? 'Unknown Location';
    final avatarUrl = data['avatarUrl'];
    final isVerified = data['isVerified'] ?? false;
    final rating = data['rating'] ?? 4.5;
    final photoURL = data['photoURL'];

        final imageUrl = photoURL ?? avatarUrl;

    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: AppTheme.spacingMD),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        margin: EdgeInsets.zero,
        child: Column(
          children: [
                        Stack(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppTheme.primaryLight,
                  backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                  child: imageUrl == null
                      ? Text(
                          displayName.isNotEmpty ? displayName[0].toUpperCase() : 'S',
                          style: AppTheme.h2.copyWith(
                            color: AppTheme.primary,
                          ),
                        )
                      : null,
                  onBackgroundImageError: (exception, stackTrace) {
                    // Handle image load error
                  },
                ),

                                if (isVerified)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.shadowLight,
                      ),
                      child: const Icon(
                        Icons.verified,
                        size: 16,
                        color: AppTheme.accent,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingMD),

                        Text(
              companyName,
              style: AppTheme.subtitle1.copyWith(fontSize: 14),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: AppTheme.spacingSM),

                        Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.star,
                  size: 16,
                  color: AppTheme.warning,
                ),
                const SizedBox(width: 4),
                Text(
                  rating.toStringAsFixed(1),
                  style: AppTheme.body2.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingSM),

                        Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    city,
                    style: AppTheme.caption,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingMD),

                        SmallButton(
              text: 'View Shop',
              onPressed: onTap,
              outlined: true,
              color: AppTheme.accent,
            ),
          ],
        ),
      ),
    );
  }
}
