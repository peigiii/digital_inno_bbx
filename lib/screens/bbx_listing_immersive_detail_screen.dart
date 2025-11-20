import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/common/shimmer_loading.dart';

class BBXListingImmersiveDetailScreen extends StatefulWidget {
  final String listingId;

  const BBXListingImmersiveDetailScreen({
    Key? key,
    required this.listingId,
  }) : super(key: key);

  @override
  State<BBXListingImmersiveDetailScreen> createState() =>
      _BBXListingImmersiveDetailScreenState();
}

class _BBXListingImmersiveDetailScreenState
    extends State<BBXListingImmersiveDetailScreen> {
  int _currentImageIndex = 0;
  bool _isFavorite = false;
  final PageController _imagePageController = PageController();
  late GoogleMapController _mapController;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  Future<void> _checkIfFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final favDoc = await FirebaseFirestore.instance
        .collection('user_favorites')
        .doc(user.uid)
        .collection('listings')
        .doc(widget.listingId)
        .get();

    setState(() {
      _isFavorite = favDoc.exists;
    });
  }

  Future<void> _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to add favorites')),
      );
      return;
    }

    final favRef = FirebaseFirestore.instance
        .collection('user_favorites')
        .doc(user.uid)
        .collection('listings')
        .doc(widget.listingId);

    if (_isFavorite) {
      await favRef.delete();
    } else {
      await favRef.set({
        'listingId': widget.listingId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('waste_listings')
            .doc(widget.listingId)
            .snapshots(),
        builder: (context, snapshot) {
          // 处理加载状态
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 处理错误
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('加载失败: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('返回'),
                  ),
                ],
              ),
            );
          }

          // 检查数据是否存在
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('数据不存在'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('商品不存在或已被删除'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('返回'),
                  ),
                ],
              ),
            );
          }

          final images =
              (data['imageUrls'] as List<dynamic>?)?.cast<String>() ?? [];
          final hasImages = images.isNotEmpty;

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // Full screen image carousel
                  SliverToBoxAdapter(
                    child: _buildImageCarousel(images, hasImages),
                  ),

                  // Price section (floating card)
                  SliverToBoxAdapter(
                    child: _buildPriceCard(data),
                  ),

                  // Supplier card
                  SliverToBoxAdapter(
                    child: _buildSupplierCard(data),
                  ),

                  // Specifications card
                  SliverToBoxAdapter(
                    child: _buildSpecsCard(data),
                  ),

                  // Description card
                  SliverToBoxAdapter(
                    child: _buildDescriptionCard(data),
                  ),

                  // Location card
                  SliverToBoxAdapter(
                    child: _buildLocationCard(data),
                  ),

                  // Similar products
                  SliverToBoxAdapter(
                    child: _buildSimilarProducts(data),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),

              // Floating top buttons
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopBar(data),
              ),

              // Bottom action bar (glass effect)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomBar(data),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildImageCarousel(List<String> images, bool hasImages) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5,
      child: hasImages
          ? Stack(
              children: [
                PageView.builder(
                  controller: _imagePageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return CachedNetworkImage(
                      imageUrl: images[index],
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const ShimmerBox(width: double.infinity, height: 400),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error, size: 80),
                    );
                  },
                ),
                // Indicator
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
            )
          : Container(
              color: AppTheme.backgroundGrey,
              child: const Icon(
                Icons.image_not_supported,
                size: 100,
                color: AppTheme.textLight,
              ),
            ),
    );
  }

  Widget _buildTopBar(Map<String, dynamic> data) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildFloatingButton(
              icon: Icons.arrow_back,
              onPressed: () => Navigator.pop(context),
            ),
            Row(
              children: [
                _buildFloatingButton(
                  icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
                  onPressed: _toggleFavorite,
                  color: _isFavorite ? Colors.red : null,
                ),
                const SizedBox(width: 8),
                _buildFloatingButton(
                  icon: Icons.share,
                  onPressed: () => _shareListing(data),
                ),
                const SizedBox(width: 8),
                _buildFloatingButton(
                  icon: Icons.more_vert,
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: color ?? Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceCard(Map<String, dynamic> data) {
    return Transform.translate(
      offset: const Offset(0, -30),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RM ${data['pricePerUnit'] ?? 0}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    Text(
                      'per ${data['unit'] ?? 'ton'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    data['status'] == 'available' ? 'Available' : 'Sold Out',
                    style: TextStyle(
                      color: data['status'] == 'available'
                          ? AppTheme.success
                          : AppTheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              data['wasteType'] ?? 'Unknown',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, size: 16, color: Colors.amber),
                const Icon(Icons.star, size: 16, color: Colors.amber),
                const Icon(Icons.star, size: 16, color: Colors.amber),
                const Icon(Icons.star, size: 16, color: Colors.amber),
                const Icon(Icons.star_half, size: 16, color: Colors.amber),
                const SizedBox(width: 8),
                const Text(
                  '4.8',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                Text(
                  '(125 reviews)',
                  style: TextStyle(color: AppTheme.textLight),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplierCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(data['userId'])
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ShimmerBox(width: double.infinity, height: 80);
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const SizedBox.shrink();
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          if (userData == null) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Supplier',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    child: Text(
                      (userData['displayName'] ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              userData['displayName'] ?? 'Unknown',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (userData['isVerified'] == true)
                              const Icon(
                                Icons.verified,
                                size: 20,
                                color: AppTheme.primary,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Row(
                          children: [
                            Icon(Icons.star, size: 14, color: Colors.amber),
                            SizedBox(width: 4),
                            Text(
                              '4.8',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: const Text('Chat'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.store, size: 18),
                      label: const Text('View Shop'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSpecsCard(Map<String, dynamic> data) {
    final specs = [
      {'label': 'Type', 'value': data['wasteType'] ?? '-'},
      {'label': 'Quantity', 'value': '${data['quantity']} ${data['unit'] ?? 'tons'}'},
      {'label': 'Unit', 'value': data['unit'] ?? '-'},
      {'label': 'Location', 'value': _getLocationDisplay(data['location'])},
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📋 Specifications',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...specs.map(
            (spec) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    spec['label']!,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    spec['value']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📝 Description',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            data['description'] ?? 'No description available.',
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(Map<String, dynamic> data) {
    final locationData = data['location'] as Map<String, dynamic>?;
    final latitude = (locationData?['latitude'] as num?)?.toDouble() ?? 5.9804;
    final longitude = (locationData?['longitude'] as num?)?.toDouble() ?? 116.0735;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📍 Location',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getLocationDisplay(data['location']),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 200,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(latitude, longitude),
                  zoom: 14,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('listing_location'),
                    position: LatLng(latitude, longitude),
                  ),
                },
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                onMapCreated: (controller) {
                  _mapController = controller;
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarProducts(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💡 Similar Products',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('waste_listings')
                  .where('wasteType', isEqualTo: data['wasteType'])
                  .where('status', isEqualTo: 'available')
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                }

                if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                  return const SizedBox.shrink();
                }

                final products = snapshot.data!.docs
                    .where((doc) => doc.id != widget.listingId)
                    .toList();

                if (products.isEmpty) {
                  return const Center(child: Text('No similar products'));
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final productData =
                        product.data() as Map<String, dynamic>;
                    final images = (productData['imageUrls'] as List<dynamic>?)
                            ?.cast<String>() ??
                        [];

                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: InkWell(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  BBXListingImmersiveDetailScreen(
                                listingId: product.id,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 140,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.divider),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12)),
                                child: images.isNotEmpty
                                    ? Image.network(
                                        images[0],
                                        height: 100,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        height: 100,
                                        color: AppTheme.backgroundGrey,
                                      ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      productData['wasteType'] ?? 'Unknown',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'RM ${productData['pricePerTon']}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(Map<String, dynamic> data) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            border: Border(
              top: BorderSide(color: AppTheme.divider.withOpacity(0.5)),
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  onPressed: _toggleFavorite,
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : AppTheme.textSecondary,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.backgroundGrey,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.chat_bubble_outline, size: 20),
                    label: const Text('Contact'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: data['status'] == 'available'
                        ? () => _showQuoteDialog(data)
                        : null,
                    icon: const Icon(Icons.request_quote, size: 20),
                    label: const Text('Quote'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _shareListing(Map<String, dynamic> data) {
    Share.share(
      'Check out this listing: ${data['wasteType']}\n'
      'Price: RM ${data['pricePerUnit']}/${data['unit'] ?? 'ton'}\n'
      'Quantity: ${data['quantity']} ${data['unit'] ?? 'tons'}',
      subject: data['wasteType'],
    );
  }

  String _getLocationDisplay(dynamic location) {
    if (location == null) return 'Location not specified';

    // 如果是字符串，直接返回
    if (location is String) return location;

    // 如果是Map（包含latitude和longitude）
    if (location is Map<String, dynamic>) {
      final lat = location['latitude'];
      final lng = location['longitude'];
      if (lat != null && lng != null) {
        return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
      }
      // 如果有address字段，返回address
      if (location['address'] != null) {
        return location['address'].toString();
      }
    }

    // 如果是GeoPoint类型
    if (location is GeoPoint) {
      return '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';
    }

    return 'Location not specified';
  }

  void _showQuoteDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Quote'),
        content: const Text('Quote dialog will be implemented'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
