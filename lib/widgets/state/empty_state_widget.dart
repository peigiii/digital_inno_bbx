import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// EmptyStatusShowComponents
/// UseAtShowFriendGood of EmptyDataInfoandGuide user operation
class EmptyStateWidget extends StatelessWidget {
  /// ShowIcon
  final IconData icon;

  /// Title
  final String title;

  /// DescriptionTextWord
  final String message;

  /// Action Button Text
  final String? actionLabel;

  /// Action Button Callback
  final VoidCallback? onAction;

  /// Secondary Action Text
  final String? secondaryActionLabel;

  /// Secondary Action Callback
  final VoidCallback? onSecondaryAction;

  /// IconColor
  final Color? iconColor;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.iconColor,
  });

  /// EmptyListing List Preset
  factory EmptyStateWidget.noListings({
    VoidCallback? onCreateListing,
    VoidCallback? onBrowseAll,
  }) {
    return EmptyStateWidget(
      icon: Icons.inventory_2_outlined,
      title: 'No items yet',
      message: 'Post your first item，StartTransactionBar',
      actionLabel: 'ReleaseItem',
      onAction: onCreateListing,
      secondaryActionLabel: 'BrowseAll',
      onSecondaryAction: onBrowseAll,
    );
  }

  /// EmptyFavoriteColTablePreSet
  factory EmptyStateWidget.noFavorites({
    VoidCallback? onBrowse,
  }) {
    return EmptyStateWidget(
      icon: Icons.favorite_border_rounded,
      title: 'No favorites yet',
      message: 'Favorite items you like，For easier access next time',
      iconColor: AppTheme.error,
      actionLabel: 'Browse',
      onAction: onBrowse,
    );
  }

  /// EmptyTransactionColTablePreSet
  factory EmptyStateWidget.noTransactions({
    VoidCallback? onBrowse,
  }) {
    return EmptyStateWidget(
      icon: Icons.receipt_long_outlined,
      title: 'No transactions yet',
      message: 'Your transaction records will appear here',
      actionLabel: 'Go Shopping',
      onAction: onBrowse,
    );
  }

  /// EmptyQuoteColTablePreSet
  factory EmptyStateWidget.noOffers({
    VoidCallback? onBrowse,
  }) {
    return EmptyStateWidget(
      icon: Icons.local_offer_outlined,
      title: 'ReturnNoneQuote',
      message: 'Browse items and submit yourQuote',
      actionLabel: 'Browse Items',
      onAction: onBrowse,
    );
  }

  /// EmptyMessageColTablePreSet
  factory EmptyStateWidget.noMessages() {
    return EmptyStateWidget(
      icon: Icons.chat_bubble_outline_rounded,
      title: 'No conversations yet',
      message: 'Messages with the seller will appear here',
      iconColor: AppTheme.primary500,
    );
  }

  /// SearchNoneResultPreSet
  factory EmptyStateWidget.noSearchResults({
    String? searchTerm,
    VoidCallback? onClearSearch,
  }) {
    return EmptyStateWidget(
      icon: Icons.search_off_rounded,
      title: 'No items found',
      message: searchTerm != null
          ? 'NoneFindTo"$searchTerm" of MutualOffResult'
          : 'Try searching with other keywords',
      actionLabel: 'ClearSearch',
      onAction: onClearSearch,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // EmptyStatusIcon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (iconColor ?? AppTheme.neutral400).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 80,
                color: iconColor ?? AppTheme.neutral400,
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              title,
              style: AppTheme.heading2.copyWith(
                color: AppTheme.neutral900,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              message,
              style: AppTheme.body2.copyWith(
                color: AppTheme.neutral600,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            // ActionPressButton
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary500,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  ),
                ),
              ),
            ],

            // Secondary Action Button
            if (secondaryActionLabel != null && onSecondaryAction != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onSecondaryAction,
                child: Text(secondaryActionLabel!),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primary500,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
