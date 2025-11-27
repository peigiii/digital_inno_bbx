import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../theme/app_theme.dart';
import 'bbx_listing_detail_screen.dart';
import 'bbx_advanced_filter_screen.dart';

class BBXMarketBrowseScreen extends StatefulWidget {
  const BBXMarketBrowseScreen({Key? key}) : super(key: key);

  @override
  State<BBXMarketBrowseScreen> createState() => _BBXMarketBrowseScreenState();
}

class _BBXMarketBrowseScreenState extends State<BBXMarketBrowseScreen> {
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _favorites = {};

  final List<Map<String, String>> _categories = [
    {'id': 'all', 'label': 'All'},
    {'id': 'Wood Waste', 'label': 'Wood'},
    {'id': 'EFB (Empty Fruit Bunches)', 'label': 'Palm'},
    {'id': 'Rice Husks', 'label': 'Rice'},
    {'id': 'Sugarcane Bagasse', 'label': 'Sugarcane'},
    {'id': 'Bamboo Waste', 'label': 'Bamboo'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: SafeArea(
        child: Column(
          children: [
            // Search and filter bar
            _buildSearchBar(),

            // Category chips
            _buildCategoryChips(),

            // Products grid
            Expanded(
              child: _buildProductsGrid(),
            ),
          ],
        ),
      ),

      // Floating action button for posting
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/waste-list');
        },
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundGrey,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search products...',
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: AppTheme.textLight),
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BBXAdvancedFilterScreen(),
                ),
              );
            },
            icon: const Icon(Icons.tune),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category['id'] ||
              (_selectedCategory == null && category['id'] == 'all');

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category['label']!),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = selected ? category['id'] : null;
                });
              },
              backgroundColor: Colors.white,
              selectedColor: AppTheme.primary.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? AppTheme.primary : AppTheme.divider,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: _buildQuery().snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = snapshot.data!.docs;

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 80,
                  color: AppTheme.textLight,
                ),
                const SizedBox(height: 16),
                Text(
                  'No products found',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return MasonryGridView.count(
          crossAxisCount: 2,
          padding: const EdgeInsets.all(16),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final data = product.data() as Map<String, dynamic>;
            return _buildProductCard(product.id, data);
          },
        );
      },
    );
  }

  Query _buildQuery() {
    Query query = FirebaseFirestore.instance
        .collection('listings')
        .where('status', isEqualTo: 'available');

    if (_selectedCategory != null && _selectedCategory != 'all') {
      query = query.where('wasteType', isEqualTo: _selectedCategory);
    }

    return query.limit(20);
  }

  Widget _buildProductCard(String id, Map<String, dynamic> data) {
    final images = (data['imageUrls'] as List<dynamic>?)?.cast<String>() ?? [];
    final imageUrl = images.isNotEmpty ? images[0] : null;
    final isFavorite = _favorites.contains(id);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BBXListingDetailScreen(listingId: id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with favorite button
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderImage();
                          },
                        )
                      : _buildPlaceholderImage(),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 4,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (isFavorite) {
                            _favorites.remove(id);
                          } else {
                            _favorites.add(id);
                          }
                        });
                      },
                      customBorder: const CircleBorder(),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : AppTheme.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    data['wasteType'] ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Price
                  Text(
                    'RM ${data['pricePerTon']}/ton',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Quantity
                  Row(
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 14,
                        color: AppTheme.textLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${data['quantity']} tons',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppTheme.textLight,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          data['location'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Rating
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const Icon(Icons.star_half, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      const Text(
                        '4.5',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 150,
      width: double.infinity,
      color: AppTheme.backgroundGrey,
      child: const Icon(
        Icons.image_outlined,
        size: 48,
        color: AppTheme.textLight,
      ),
    );
  }
}
