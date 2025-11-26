import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../models/listing_model.dart';
import '../../widgets/enhanced/modern_card.dart';
import '../../widgets/enhanced/shimmer_loading.dart';
import '../../widgets/state/error_state_widget.dart';
import '../../widgets/state/empty_state_widget.dart';

/// BBX ItemColTable - Optimize�?
/// Material Design 3 Style，FitMatch Pixel 5
class BBXOptimizedMarketplaceScreen extends StatefulWidget {
  const BBXOptimizedMarketplaceScreen({super.key});

  @override
  State<BBXOptimizedMarketplaceScreen> createState() =>
      _BBXOptimizedMarketplaceScreenState();
}

class _BBXOptimizedMarketplaceScreenState
    extends State<BBXOptimizedMarketplaceScreen> {
  String _selectedCategory = 'all';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _categories = [
    {'id': 'all', 'label': '📦 All', 'color': Color(0xFF43A047)},
    {'id': 'EFB (Empty Fruit Bunches)', 'label': '🌴 EFB', 'color': Color(0xFFFF9800)},
    {'id': 'Palm Shell', 'label': '🥥 Palm Shell', 'color': Color(0xFF8BC34A)},
    {'id': 'Wood Chips', 'label': '🪵 Wood Chips', 'color': Color(0xFF795548)},
    {'id': 'Plastic', 'label': '♻️ Plastic', 'color': Color(0xFF2196F3)},
    {'id': 'Metal', 'label': '🔩 Metal', 'color': Color(0xFF607D8B)},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // TopSearch�?
            _buildTopBar(),

            // CategoryFilter�?
            _buildCategoryChips(),

            // ItemColTable
            Expanded(
              child: _buildProductList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BBX Market',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // Search�?
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search biomass waste...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.primary500),
              suffixIcon: IconButton(
                icon: const Icon(Icons.tune),
                onPressed: () {
                  // AdvancedFilter�?
                },
              ),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Container(
      height: 50,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category['id'];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category['label']),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category['id'];
                });
              },
              backgroundColor: Colors.white,
              selectedColor: (category['color'] as Color).withOpacity(0.2),
              checkmarkColor: category['color'],
              labelStyle: TextStyle(
                color: isSelected ? category['color'] : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? category['color'] : Colors.grey.shade300,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _buildQuery().snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState();
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 16, bottom: 80),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            try {
              final doc = snapshot.data!.docs[index];
              final listing = ListingModel.fromDocument(doc);

              return ModernListingCard(
                heroTag: listing.imageUrls.isNotEmpty ? listing.imageUrls.first : null,
                imageUrl: listing.imageUrls.isNotEmpty ? listing.imageUrls.first : '',
                title: listing.title,
                category: listing.wasteType,
                price: listing.pricePerUnit,
                unit: listing.unit,
                location: listing.location != null ? listing.location.toString() : 'UnknownLocation',
                sellerName: listing.userEmail.split('@').first,
                rating: 4.5,
                isVerified: true,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/listing-detail',
                    arguments: {'listingId': listing.id},
                  );
                },
                onFavorite: () {
                  // TODO: FavoriteFunction
                },
              );
            } catch (e) {
              debugPrint('Error parsing listing: $e');
              return const SizedBox.shrink();
            }
          },
        );
      },
    );
  }

  Query _buildQuery() {
    Query query = FirebaseFirestore.instance
        .collection('listings')
        .where('status', isEqualTo: 'available')
        .orderBy('createdAt', descending: true)
        .limit(50);

    if (_selectedCategory != 'all') {
      query = query.where('wasteType', isEqualTo: _selectedCategory);
    }

    return query;
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoading.rounded(
                  width: double.infinity,
                  height: 180,
                  shapeBorder: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerLoading.rectangular(height: 20, width: 200),
                      const SizedBox(height: 8),
                      ShimmerLoading.rectangular(height: 14, width: 150),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ShimmerLoading.rectangular(height: 24, width: 100),
                          ShimmerLoading.rectangular(height: 36, width: 80),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return ErrorStateWidget.network(
      onRetry: () => setState(() {}),
    );
  }

  Widget _buildEmptyState() {
    if (_selectedCategory == 'all') {
      return EmptyStateWidget.noListings(
        onCreateListing: () {
          // NavigationToReleaseItemPage
          Navigator.pushNamed(context, '/create-listing');
        },
        onBrowseAll: () {
          // CutChangeToAllCategory
          setState(() {
            _selectedCategory = 'all';
          });
        },
      );
    } else {
      return EmptyStateWidget(
        icon: Icons.category_outlined,
        title: 'ThatCategoryTempNoneItem',
        message: 'Try browsing other categories or view all items',
        actionLabel: 'View All',
        onAction: () {
          setState(() {
            _selectedCategory = 'all';
          });
        },
      );
    }
  }
}

