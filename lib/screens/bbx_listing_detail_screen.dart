import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/common/shimmer_loading.dart';
import '../widgets/marketplace/product_card.dart';
import '../widgets/state/error_state_widget.dart';
import '../services/chat_service.dart';
import '../services/favorite_service.dart';
import 'chat/bbx_chat_screen.dart';

class BBXListingDetailScreen extends StatefulWidget {
  final String listingId;

  const BBXListingDetailScreen({
    Key? key,
    required this.listingId,
  }) : super(key: key);

  @override
  State<BBXListingDetailScreen> createState() => _BBXListingDetailScreenState();
}

class _BBXListingDetailScreenState extends State<BBXListingDetailScreen> {
  int _currentImageIndex = 0;
  bool _isDescriptionExpanded = false;
  GoogleMapController? _mapController;
  final PageController _imagePageController = PageController();
  final ChatService _chatService = ChatService();
  final FavoriteService _favoriteService = FavoriteService();
  bool _isStartingChat = false;

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  void _shareListing(Map<String, dynamic> data) {
    final price = _getPrice(data);
    final unit = _getUnitLabel(data);
    final quantity = _getQuantity(data);
    Share.share(
      'Check out this listing: ${data['wasteType']}\n'
      'Price: RM ${price.toStringAsFixed(2)}/$unit\n'
      'Quantity: $quantity $unit',
      subject: data['wasteType'],
    );
  }

  void _showPurchaseDialog(Map<String, dynamic> data) {
    debugPrint('🛒 [ListingDetail] Opening purchase dialog...');

    final TextEditingController quantityController = TextEditingController();
    final price = _getPrice(data);
    final unit = _getUnitLabel(data);
    final availableQty = _getQuantity(data);

    double calculatedTotal = 0.0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Calculate total whenever quantity changes
          final quantity = double.tryParse(quantityController.text) ?? 0;
          calculatedTotal = quantity * price;
          final platformFee = calculatedTotal * 0.03; // 3% platform fee
          final grandTotal = calculatedTotal + platformFee;

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.shopping_cart, color: AppTheme.primary),
                SizedBox(width: 8),
                Text('Purchase Product'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundGrey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['wasteType'] ?? 'Product',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Price: RM ${price.toStringAsFixed(2)} per $unit',
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                        Text(
                          'Available: $availableQty $unit',
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quantity input
                  TextField(
                    controller: quantityController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Quantity ($unit)',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.production_quantity_limits),
                      hintText: 'Enter quantity to purchase',
                    ),
                    onChanged: (value) {
                      setState(() {}); // Rebuild to update total
                    },
                  ),
                  const SizedBox(height: 16),

                  // Price breakdown
                  if (quantity > 0) ...[
                    const Divider(),
                    _buildPriceRow('Subtotal', calculatedTotal),
                    _buildPriceRow('Platform Fee (3%)', platformFee),
                    const Divider(),
                    _buildPriceRow(
                      'Total',
                      grandTotal,
                      isTotal: true,
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Important note
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Seller will be notified and will contact you to arrange payment and delivery.',
                            style: TextStyle(fontSize: 12, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  debugPrint('❌ [ListingDetail] Purchase cancelled');
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: quantity > 0 && quantity <= availableQty
                    ? () => _submitPurchaseRequest(data, quantity, grandTotal)
                    : null,
                icon: const Icon(Icons.check_circle),
                label: const Text('Submit Request'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black : AppTheme.textSecondary,
            ),
          ),
          Text(
            'RM ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? AppTheme.primary : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitPurchaseRequest(
    Map<String, dynamic> data,
    double quantity,
    double totalAmount,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('⚠️ [ListingDetail] User not logged in for purchase');
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to make a purchase')),
      );
      Navigator.pushNamed(context, '/login');
      return;
    }

    debugPrint('💳 [ListingDetail] Submitting purchase request...');
    debugPrint('   - Quantity: $quantity');
    debugPrint('   - Total Amount: RM ${totalAmount.toStringAsFixed(2)}');

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Create transaction in Firestore
      final transactionRef = await FirebaseFirestore.instance.collection('transactions').add({
        'listingId': widget.listingId,
        'buyerId': user.uid,
        'sellerId': data['userId'],
        'quantity': quantity,
        'pricePerUnit': _getPrice(data),
        'amount': totalAmount - (totalAmount * 0.03), // Subtotal
        'platformFee': totalAmount * 0.03,
        'totalAmount': totalAmount,
        'unit': _getUnitLabel(data),
        'status': 'pending',
        'paymentStatus': 'pending',
        'shippingStatus': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ [ListingDetail] Purchase request created: ${transactionRef.id}');

      // Close loading dialog
      Navigator.pop(context);
      // Close purchase dialog
      Navigator.pop(context);

      // Show success message
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppTheme.success, size: 32),
              SizedBox(width: 12),
              Text('Order Placed!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your purchase request has been submitted successfully!',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                'What happens next:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildStepItem('1', 'Seller will review your request'),
              _buildStepItem('2', 'You will be contacted for payment details'),
              _buildStepItem('3', 'After payment, seller will arrange delivery'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt, color: AppTheme.success),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Transaction ID: ${transactionRef.id.substring(0, 8)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/transactions');
              },
              icon: const Icon(Icons.list_alt),
              label: const Text('View Orders'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);

      debugPrint('❌ [ListingDetail] Error submitting purchase: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit purchase: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Widget _buildStepItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    print('');
    print('═══════════════════════════════════════════════════');
    print('🚀 [ListingDetail] initState - 商品详情页初始化');
    print('📦 接收到的商品ID: ${widget.listingId}');
    print('📝 商品ID类型: ${widget.listingId.runtimeType}');
    print('📏 商品ID长度: ${widget.listingId.length}');
    print('═══════════════════════════════════════════════════');
    print('');
  }

  @override
  Widget build(BuildContext context) {
    print('');
    print('─────────────────────────────────────────────────');
    print('🔍 [ListingDetail] build() 方法被调用');
    print('📦 商品ID: ${widget.listingId}');
    print('─────────────────────────────────────────────────');
    print('');

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('listings')
            .doc(widget.listingId)
            .snapshots(),
        builder: (context, snapshot) {
          print('');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          print('📡 [StreamBuilder] 状态回调');
          print('🔗 connectionState: ${snapshot.connectionState}');
          print('✅ hasData: ${snapshot.hasData}');
          print('❌ hasError: ${snapshot.hasError}');
          if (snapshot.hasError) {
            print('💥 错误详情: ${snapshot.error}');
            print('📚 错误堆栈: ${snapshot.stackTrace}');
          }
          if (snapshot.hasData) {
            print('📦 snapshot.data 类型: ${snapshot.data.runtimeType}');
            print('📄 snapshot.data 是否为null: ${snapshot.data == null}');
            if (snapshot.data != null) {
              print('📋 document exists: ${snapshot.data!.exists}');
              print('📝 document id: ${snapshot.data!.id}');
              final rawData = snapshot.data!.data();
              print('🗂️ data() 返回类型: ${rawData.runtimeType}');
              print('🗂️ data() 是否为null: ${rawData == null}');
              if (rawData != null) {
                print('🔑 数据字段: ${(rawData as Map).keys.toList()}');
              }
            }
          }
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          print('');

          if (snapshot.hasError) {
            print('❌ [ListingDetail] 进入错误处理分支');
            return Scaffold(
              appBar: AppBar(
                title: const Text('Product Details'),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: ErrorStateWidget.network(
                onRetry: () {
                  debugPrint('🔄 [ListingDetail] Retry button pressed');
                  setState(() {});
                },
                onBack: () {
                  debugPrint('⬅️ [ListingDetail] Back button pressed from error');
                  Navigator.pop(context);
                },
              ),
            );
          }

          if (!snapshot.hasData || snapshot.connectionState == ConnectionState.waiting) {
            print('⏳ [ListingDetail] 数据加载中...');
            print('   - hasData: ${snapshot.hasData}');
            print('   - connectionState: ${snapshot.connectionState}');
            return Scaffold(
              appBar: AppBar(
                title: const Text('Product Details'),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading product details...'),
                  ],
                ),
              ),
            );
          }

          print('');
          print('🔍 准备提取数据...');
          print('   snapshot.data 是否为 null: ${snapshot.data == null}');

          if (snapshot.data == null) {
            print('💥 CRITICAL: snapshot.data 是 null!');
            return Scaffold(
              appBar: AppBar(
                title: const Text('Product Details'),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: ErrorStateWidget.notFound(
                title: 'Data Error',
                message: 'snapshot.data is null',
                onBack: () => Navigator.pop(context),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;

          print('📊 数据提取结果:');
          print('   - data 是否为 null: ${data == null}');
          if (data != null) {
            print('   - data 类型: ${data.runtimeType}');
            print('   - data 字段数量: ${data.length}');
            print('   - data 所有字段: ${data.keys.toList()}');
            print('   - wasteType: ${data['wasteType']}');
            print('   - status: ${data['status']}');
            print('   - userId: ${data['userId']}');
          }
          print('');

          if (data == null) {
            print('⚠️ [ListingDetail] Document exists but data is null');
            return Scaffold(
              appBar: AppBar(
                title: const Text('Product Details'),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: ErrorStateWidget.notFound(
                title: 'Product Not Found',
                message: 'This product may have been deleted or is no longer available',
                onBack: () {
                  debugPrint('⬅️ [ListingDetail] Back button pressed from not found');
                  Navigator.pop(context);
                },
              ),
            );
          }

          print('');
          print('✅✅✅ [成功] 数据加载成功! ✅✅✅');
          print('📋 商品信息:');
          print('   - 标题(wasteType): ${data['wasteType'] ?? 'N/A'}');
          print('   - 价格(pricePerUnit): ${data['pricePerUnit']}');
          print('   - 价格(pricePerTon): ${data['pricePerTon']}');
          print('   - 价格(price): ${data['price']}');
          print('   - 状态(status): ${data['status'] ?? 'N/A'}');
          print('   - 卖家ID(userId): ${data['userId']}');
          print('   - 数量(quantity): ${data['quantity']}');
          print('   - 单位(unit): ${data['unit']}');
          final description = data['description']?.toString() ?? '';
          final descPreview = description.length > 50 ? '${description.substring(0, 50)}...' : description;
          print('   - 描述(description): ${descPreview.isEmpty ? 'N/A' : descPreview}');
          print('');

          print('🖼️ 处理图片数据...');
          print('   - imageUrls 字段类型: ${data['imageUrls'].runtimeType}');
          print('   - imageUrls 内容: ${data['imageUrls']}');
          print('   - imageUrl (单数) 字段: ${data['imageUrl']}');

          List<String> images =
              (data['imageUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

          // Fix for single image url field
          final singleImage = data['imageUrl'];
          if (images.isEmpty && singleImage is String && singleImage.isNotEmpty) {
            print('   ✅ 找到单个 imageUrl 字段: $singleImage');
            images = [singleImage];
          }

          final hasImages = images.isNotEmpty;
          print('   📸 图片总数: ${images.length}');
          if (images.isEmpty) {
            print('   ⚠️ 该商品没有图片');
          } else {
            print('   📸 图片URL列表: $images');
          }
          print('');

          print('');
          print('🎨🎨🎨 开始构建UI界面 🎨🎨🎨');
          print('   - hasImages: $hasImages');
          print('   - images.length: ${images.length}');
          print('');

          try {
            return Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    // Image carousel AppBar
                    SliverAppBar(
                    expandedHeight: 400,
                    pinned: true,
                    backgroundColor: AppTheme.primary,
                    leading: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    actions: [
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.share, color: Colors.white),
                        ),
                        onPressed: () => _shareListing(data),
                      ),
                      StreamBuilder<bool>(
                        stream: _favoriteService.isFavoriteStream(widget.listingId),
                        builder: (context, snapshot) {
                          final isFavorite = snapshot.data ?? false;
                          return IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: isFavorite ? Colors.red : Colors.white,
                              ),
                            ),
                            onPressed: () => _favoriteService.toggleFavorite(widget.listingId, context),
                          );
                        },
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: hasImages
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
                                    // Debug: Log image URL being loaded
                                    debugPrint('🖼️ [ListingDetail] Loading image $index: ${images[index]}');

                                    return CachedNetworkImage(
                                      imageUrl: images[index],
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) {
                                        debugPrint('⏳ [ListingDetail] Image $index loading...');
                                        return Container(
                                          width: double.infinity,
                                          height: 400,
                                          color: AppTheme.backgroundGrey,
                                          child: const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      },
                                      errorWidget: (context, url, error) {
                                        debugPrint('❌ [ListingDetail] Failed to load image $index: $error');
                                        return Container(
                                          color: AppTheme.backgroundGrey,
                                          child: const Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.broken_image, size: 80, color: AppTheme.textLight),
                                                SizedBox(height: 8),
                                                Text('Failed to load image', style: TextStyle(color: AppTheme.textLight)),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                                // Image indicator
                                if (images.length > 1)
                                  Positioned(
                                    bottom: 16,
                                    left: 0,
                                    right: 0,
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          '${_currentImageIndex + 1} / ${images.length}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
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
                    ),
                  ),

                  // Content
                  SliverToBoxAdapter(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Price and title section
                        _buildPriceSection(data),

                        const Divider(height: 1),

                        // Supplier info card
                        _buildSupplierCard(data),

                        const Divider(height: 1),

                        // Product specifications
                        _buildSpecifications(data),

                        const Divider(height: 1),

                        // Description
                        _buildDescription(data),

                        const Divider(height: 1),

                        // Location with map
                        _buildLocation(data),

                        const Divider(height: 1),

                        // Similar products
                        _buildSimilarProducts(data),

                        const SizedBox(height: 80), // Space for bottom bar
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomActionBar(data),
              ),
            ],
          );
          } catch (e, stackTrace) {
            print('');
            print('💥💥💥 UI构建过程中发生异常! 💥💥💥');
            print('❌ 异常类型: ${e.runtimeType}');
            print('💥 异常信息: $e');
            print('📚 堆栈跟踪:');
            print(stackTrace);
            print('💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥');
            print('');

            return Scaffold(
              appBar: AppBar(
                title: const Text('Product Details'),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'UI构建错误',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('$e', textAlign: TextAlign.center),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('返回'),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildPriceSection(Map<String, dynamic> data) {
    final price = _getPrice(data);
    final unit = _getUnitLabel(data);
    final quantity = _getQuantity(data);
    final status = (data['status'] ?? 'available').toString();

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RM ${price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    Text(
                      'per $unit',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: status == 'available'
                      ? AppTheme.success.withOpacity(0.1)
                      : AppTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status == 'available' ? 'Available' : 'Sold Out',
                  style: TextStyle(
                    color: status == 'available'
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
              const Icon(Icons.inventory_2_outlined, size: 16, color: AppTheme.textLight),
              const SizedBox(width: 4),
              Text(
                'Available: $quantity $unit',
                style: const TextStyle(
                  color: AppTheme.textLight,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.access_time, size: 16, color: AppTheme.textLight),
              const SizedBox(width: 4),
              Text(
                _formatDate(data['createdAt']),
                style: const TextStyle(
                  color: AppTheme.textLight,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[100] ?? Colors.blue),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_shipping, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Delivery Method',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[900],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.check_circle, size: 14, color: Colors.green[700]),
                    const SizedBox(width: 6),
                    const Text(
                      'Pickup Available',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.check_circle, size: 14, color: Colors.green[700]),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Shipping Available (Negotiable)',
                        style: TextStyle(fontSize: 13),
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

  Widget _buildSupplierCard(Map<String, dynamic> data) {
    // Add null check for userId
    final userId = data['userId'];
    if (userId == null) {
      debugPrint('⚠️ [ListingDetail] No userId found in listing data');
      return Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundGrey,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.textLight),
              SizedBox(width: 12),
              Text('Supplier information unavailable', style: TextStyle(color: AppTheme.textSecondary)),
            ],
          ),
        ),
      );
    }

    debugPrint('👤 [ListingDetail] Loading supplier info for userId: $userId');

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          debugPrint('⏳ [ListingDetail] Loading supplier data...');
          return Container(
            padding: const EdgeInsets.all(AppTheme.spacingLG),
            color: Colors.white,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          debugPrint('❌ [ListingDetail] Error loading supplier: ${snapshot.error}');
          // Show minimal supplier info on error
          return Container(
            padding: const EdgeInsets.all(AppTheme.spacingLG),
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Supplier Information',
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
                      child: const Icon(Icons.person, color: AppTheme.primary),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Supplier information unavailable',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        // Fallback for deleted users
        final displayName = userData?['displayName'] ?? 'Unknown User';
        final isVerified = userData?['isVerified'] == true;

        debugPrint('✅ [ListingDetail] Supplier loaded: $displayName (verified: $isVerified)');

        return Container(
          padding: const EdgeInsets.all(AppTheme.spacingLG),
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Supplier Information',
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
                      displayName[0].toUpperCase(),
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
                            Flexible(
                              child: Text(
                                displayName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (isVerified)
                              const Icon(
                                Icons.verified,
                                size: 20,
                                color: AppTheme.primary,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 16, color: Colors.amber),
                            const SizedBox(width: 4),
                            const Text(
                              '4.8',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '(125 reviews)',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textLight,
                              ),
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
                      onPressed: () {
                        // Navigate to supplier profile
                      },
                      icon: const Icon(Icons.store, size: 18),
                      label: const Text('View Shop'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isStartingChat
                          ? null
                          : () => _startChatWithSeller(data),
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: const Text('Chat'),
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
          ),
        );
      },
    );
  }

  Widget _buildSpecifications(Map<String, dynamic> data) {
    final price = _getPrice(data);
    final unit = _getUnitLabel(data);
    final quantity = _getQuantity(data);

    final specs = [
      {'label': 'Waste Type', 'value': data['wasteType'] ?? '-'},
      {'label': 'Quantity', 'value': '$quantity $unit'},
      {'label': 'Price', 'value': 'RM ${price.toStringAsFixed(2)}/$unit'},
      {'label': 'Moisture Content', 'value': data['moistureContent'] ?? '-'},
      {'label': 'Collection Date', 'value': _formatDate(data['collectionDate'])},
      {'label': 'Location', 'value': _getLocationDisplay(data['location'])},
    ];

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Product Specifications',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...specs.map((spec) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 140,
                      child: Text(
                        spec['label']!,
                        style: const TextStyle(
                          color: AppTheme.textLight,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        spec['value']!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildDescription(Map<String, dynamic> data) {
    final description = data['description'] ?? 'No description available.';
    final shouldShowExpandButton = description.length > 200;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Product Description',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          AnimatedCrossFade(
            firstChild: Text(
              description,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: AppTheme.textSecondary,
              ),
            ),
            secondChild: Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: AppTheme.textSecondary,
              ),
            ),
            crossFadeState: _isDescriptionExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
          if (shouldShowExpandButton)
            TextButton(
              onPressed: () {
                setState(() {
                  _isDescriptionExpanded = !_isDescriptionExpanded;
                });
              },
              child: Text(
                _isDescriptionExpanded ? 'Show Less' : 'Show More',
                style: const TextStyle(color: AppTheme.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocation(Map<String, dynamic> data) {
    final latLng = _getLatLng(data);

    // Debug: Log location rendering
    debugPrint('📍 [ListingDetail] Rendering location map');

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Location',
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
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            child: SizedBox(
              height: 200,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: latLng,
                  zoom: 14,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('listing_location'),
                    position: latLng,
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
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Similar Products',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to category
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 240,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('listings')
                  .where('wasteType', isEqualTo: data['wasteType'])
                  .where('status', isEqualTo: 'available')
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    itemBuilder: (context, index) => const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: ShimmerBox(width: 160, height: 240),
                    ),
                  );
                }

                if (snapshot.hasError || snapshot.data == null) {
                  debugPrint('❌ [ListingDetail] Error loading similar products: ${snapshot.error}');
                  return const Center(
                    child: Text('Unable to load similar products'),
                  );
                }

                final products = snapshot.data!.docs
                    .where((doc) => doc.id != widget.listingId)
                    .toList();

                if (products.isEmpty) {
                  return const Center(
                    child: Text('No similar products found'),
                  );
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: SizedBox(
                        width: 160,
                        child: ProductCard(
                          doc: product,
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BBXListingDetailScreen(
                                  listingId: product.id,
                                ),
                              ),
                            );
                          },
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

  Widget _buildBottomActionBar(Map<String, dynamic> data) {
    final sellerId = data['userId'] as String?;
    final isOwnListing = sellerId != null && sellerId == FirebaseAuth.instance.currentUser?.uid;
    final isAvailable = data['status'] == 'available';

    debugPrint('🎨 [ListingDetail] Building bottom action bar');
    debugPrint('   - Is own listing: $isOwnListing');
    debugPrint('   - Is available: $isAvailable');
    debugPrint('   - Seller ID: $sellerId');

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Favorite button
            StreamBuilder<bool>(
              stream: _favoriteService.isFavoriteStream(widget.listingId),
              builder: (context, snapshot) {
                final isFavorite = snapshot.data ?? false;
                return IconButton(
                  onPressed: () {
                    debugPrint('❤️ [ListingDetail] Favorite button pressed');
                    _favoriteService.toggleFavorite(widget.listingId, context);
                  },
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : AppTheme.textSecondary,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.backgroundGrey,
                    padding: const EdgeInsets.all(12),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            // Contact button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isStartingChat || isOwnListing
                    ? null
                    : () {
                        debugPrint('💬 [ListingDetail] Contact button pressed');
                        _startChatWithSeller(data);
                      },
                icon: const Icon(Icons.chat_bubble_outline, size: 20),
                label: const Text('Contact'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppTheme.primary),
                  foregroundColor: AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Buy Now button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isAvailable && !isOwnListing
                    ? () {
                        debugPrint('🛒 [ListingDetail] Buy Now button pressed');
                        _showPurchaseDialog(data);
                      }
                    : null,
                icon: const Icon(Icons.request_quote, size: 20),
                label: const Text('Get Quote'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppTheme.dividerLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startChatWithSeller(Map<String, dynamic> data) async {
    debugPrint('💬 [ListingDetail] Starting chat with seller...');

    final sellerId = data['userId'] as String?;
    final currentUser = FirebaseAuth.instance.currentUser;

    if (sellerId == null || sellerId.isEmpty) {
      debugPrint('⚠️ [ListingDetail] No seller ID available');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seller information not available')),
      );
      return;
    }

    if (currentUser == null) {
      debugPrint('⚠️ [ListingDetail] User not logged in');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to start a chat')),
      );
      Navigator.pushNamed(context, '/login');
      return;
    }

    if (sellerId == currentUser.uid) {
      debugPrint('⚠️ [ListingDetail] Cannot chat with own listing');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This is your own listing')),
      );
      return;
    }

    if (_isStartingChat) {
      debugPrint('⚠️ [ListingDetail] Chat already starting...');
      return;
    }

    setState(() {
      _isStartingChat = true;
    });

    try {
      debugPrint('📱 [ListingDetail] Creating/getting conversation...');
      final conversationId = await _chatService.getOrCreateConversation(sellerId);
      debugPrint('✅ [ListingDetail] Conversation ID: $conversationId');

      final sellerDoc =
          await FirebaseFirestore.instance.collection('users').doc(sellerId).get();
      final sellerData = sellerDoc.data() ?? {};
      final sellerName = (sellerData['displayName'] ??
              sellerData['companyName'] ??
              sellerData['email'] ??
              'Seller')
          .toString();
      final sellerAvatar = sellerData['photoURL'] as String?;

      debugPrint('👤 [ListingDetail] Seller name: $sellerName');

      if (!mounted) return;

      debugPrint('🚀 [ListingDetail] Navigating to chat screen...');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BBXChatScreen(
            conversationId: conversationId,
            otherUserId: sellerId,
            otherUserName: sellerName.isEmpty ? 'Seller' : sellerName,
            otherUserAvatar: sellerAvatar,
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ [ListingDetail] Error starting chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to start chat: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isStartingChat = false;
        });
      }
    }
  }

  double _getPrice(Map<String, dynamic> data) {
    final raw = data['pricePerUnit'] ?? data['pricePerTon'] ?? data['price'] ?? 0;
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw) ?? 0;
    return 0;
  }

  double _getQuantity(Map<String, dynamic> data) {
    final raw = data['quantity'] ?? 0;
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw) ?? 0;
    return 0;
  }

  String _getUnitLabel(Map<String, dynamic> data) {
    final unit = data['unit'];
    if (unit is String && unit.isNotEmpty) return unit;
    if (data['pricePerTon'] != null) return 'ton';
    return 'unit';
  }

  String _getLocationDisplay(dynamic location) {
    if (location == null) return 'Location not specified';

    if (location is Map<String, dynamic>) {
      final lat = (location['latitude'] as num?)?.toDouble();
      final lng = (location['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
      }
      if (location['address'] != null) {
        return location['address'].toString();
      }
    }

    if (location is GeoPoint) {
      return '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';
    }

    if (location is String && location.isNotEmpty) {
      return location;
    }

    return 'Location not specified';
  }

  LatLng _getLatLng(Map<String, dynamic> data) {
    final location = data['location'];
    double? latitude;
    double? longitude;

    if (location is Map<String, dynamic>) {
      latitude = (location['latitude'] as num?)?.toDouble();
      longitude = (location['longitude'] as num?)?.toDouble();
    } else if (location is GeoPoint) {
      latitude = location.latitude;
      longitude = location.longitude;
    }

    latitude ??= (data['latitude'] as num?)?.toDouble();
    longitude ??= (data['longitude'] as num?)?.toDouble();

    return LatLng(latitude ?? 5.9804, longitude ?? 116.0735);
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '-';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }
    return '-';
  }
}
