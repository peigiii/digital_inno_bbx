import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/listing_model.dart';
import '../services/favorite_service.dart';
import '../widgets/enhanced/shimmer_loading.dart';
import '../widgets/state/error_state_widget.dart';
import '../widgets/state/empty_state_widget.dart';

class BBXFavoritesStandaloneScreen extends StatefulWidget {
  const BBXFavoritesStandaloneScreen({Key? key}) : super(key: key);

  @override
  State<BBXFavoritesStandaloneScreen> createState() =>
      _BBXFavoritesStandaloneScreenState();
}

class _BBXFavoritesStandaloneScreenState
    extends State<BBXFavoritesStandaloneScreen> {
  final FavoriteService _favoriteService = FavoriteService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('My Favorites'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<ListingModel>>(
        stream: _favoriteService.getFavoriteListings(),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          // Error state
          if (snapshot.hasError) {
            return ErrorStateWidget(
              error: snapshot.error.toString(),
              onRetry: () => setState(() {}),
            );
          }

          // Empty state
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.favorite_border,
              title: 'No Favorites Yet',
              message: 'Start adding items to your favorites to see them here',
              actionText: 'Browse Marketplace',
              onAction: () {
                Navigator.pushNamed(context, '/marketplace');
              },
            );
          }

          // Display favorites
          final listings = snapshot.data!;
          return _buildFavoritesList(listings);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ShimmerLoading(
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFavoritesList(List<ListingModel> listings) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: listings.length,
        itemBuilder: (context, index) {
          final listing = listings[index];
          return _buildFavoriteCard(listing);
        },
      ),
    );
  }

  Widget _buildFavoriteCard(ListingModel listing) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/listing-detail',
              arguments: {'listingId': listing.id},
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                _buildListingImage(listing),
                const SizedBox(width: 12),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        listing.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Category
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          listing.wasteType,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Quantity and Price
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${listing.quantity} ${listing.unit}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'RM ${listing.pricePerUnit.toStringAsFixed(2)}/${listing.unit}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Favorite button
                _buildFavoriteButton(listing),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListingImage(ListingModel listing) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 100,
        height: 100,
        color: Colors.grey.shade200,
        child: listing.imageUrls.isNotEmpty
            ? Image.network(
                listing.imageUrls.first,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildImagePlaceholder();
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                    ),
                  );
                },
              )
            : _buildImagePlaceholder(),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Center(
      child: Icon(
        Icons.inventory_2_outlined,
        size: 40,
        color: Colors.grey.shade400,
      ),
    );
  }

  Widget _buildFavoriteButton(ListingModel listing) {
    return StreamBuilder<bool>(
      stream: _favoriteService.isFavoriteStream(listing.id),
      builder: (context, snapshot) {
        final isFavorite = snapshot.data ?? true;

        return IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? Colors.red : Colors.grey,
          ),
          onPressed: () async {
            await _favoriteService.toggleFavorite(listing.id, context);
          },
          tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
        );
      },
    );
  }
}
