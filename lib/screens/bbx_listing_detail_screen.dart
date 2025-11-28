import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/chat_service.dart';
import 'chat/bbx_chat_screen.dart';

/// 商品详情页 - 简化可靠版本 - 修复类型错误
/// 修复问题：
/// 1. 页面空白
/// 2. 底部按钮错误（isOwnListing 判断错误）
/// 3. 收藏按钮不见
/// 4. Map<String, dynamic> 类型错误
class BBXListingDetailScreen extends StatefulWidget {
  final String listingId;

  const BBXListingDetailScreen({
    super.key,
    required this.listingId,
  });

  @override
  State<BBXListingDetailScreen> createState() => _BBXListingDetailScreenState();
}

class _BBXListingDetailScreenState extends State<BBXListingDetailScreen> {
  bool _isFavorite = false;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    debugPrint('🚀 [ListingDetail] initState - listingId: ${widget.listingId}');
    _checkFavoriteStatus();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkFavoriteStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('favorites')
          .where('userId', isEqualTo: user.uid)
          .where('listingId', isEqualTo: widget.listingId)
          .limit(1)
          .get();

      if (mounted) {
        setState(() => _isFavorite = doc.docs.isNotEmpty);
      }
    } catch (e) {
      debugPrint('❌ [Favorite] Error checking: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('listings')
            .doc(widget.listingId)
            .snapshots(),
        builder: (context, snapshot) {
          // ========== 调试日志 ==========
          debugPrint('═══════════════════════════════════════');
          debugPrint('🔍 [DEBUG] connectionState: ${snapshot.connectionState}');
          debugPrint('🔍 [DEBUG] hasData: ${snapshot.hasData}');
          debugPrint('🔍 [DEBUG] hasError: ${snapshot.hasError}');

          if (snapshot.hasError) {
            debugPrint('❌ [DEBUG] Error: ${snapshot.error}');
          }

          if (snapshot.hasData && snapshot.data != null) {
            debugPrint('📄 [DEBUG] Document exists: ${snapshot.data!.exists}');
            if (snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>?;
              debugPrint('👤 [DEBUG] sellerId (userId): ${data?['userId']}');
              debugPrint('👤 [DEBUG] currentUser.uid: ${FirebaseAuth.instance.currentUser?.uid}');
              debugPrint('🏷️ [DEBUG] title: ${data?['title']}');
              debugPrint('📝 [DEBUG] description: ${data?['description']}');
              debugPrint('🖼️ [DEBUG] imageUrl: ${data?['imageUrl']}');
              debugPrint('🖼️ [DEBUG] imageUrls: ${data?['imageUrls']}');
            }
          }
          debugPrint('═══════════════════════════════════════');
          // ========== 调试日志结束 ==========

          // Loading 状态
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
            );
          }

          // 错误状态
          if (snapshot.hasError) {
            return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          // 文档不存在
          if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('Listing not found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          // 获取数据
          final data = snapshot.data!.data() as Map<String, dynamic>;
          debugPrint('📦 [ListingDetail] Data loaded successfully');
          debugPrint('📦 [DEBUG] All data keys: ${data.keys.toList()}');
          debugPrint('📦 [DEBUG] location field type: ${data['location'].runtimeType}');
          debugPrint('📦 [DEBUG] location field value: ${data['location']}');

          return Stack(
                children: [
              // 主要内容
                  CustomScrollView(
                    slivers: [
                  // 图片区域
                  SliverToBoxAdapter(child: _buildImageSection(data)),

                  // 商品信息卡片
                  SliverToBoxAdapter(child: _buildInfoCard(data)),

                  // 卖家信息
                  SliverToBoxAdapter(child: _buildSellerCard(data)),

                  // 底部间距
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),

              // 返回按钮
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                ),
              ),

              // 收藏按钮
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 8,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.red : Colors.white,
                            ),
                    onPressed: () => _toggleFavorite(data),
                  ),
                ),
              ),

              // 底部操作栏
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomBar(data),
              ),
            ],
                          );
                        },
                      ),
    );
  }

  // ========== 图片区域 ==========
  Widget _buildImageSection(Map<String, dynamic> data) {
    final images = _getImageList(data);

    if (images.isEmpty) {
      return Container(
        height: 280,
        color: Colors.grey[300],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, size: 64, color: Colors.grey[500]),
              const SizedBox(height: 8),
              Text('No image available', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: Stack(
                              children: [
                                PageView.builder(
            controller: _pageController,
            itemCount: images.length,
                                  onPageChanged: (index) {
              setState(() => _currentImageIndex = index);
                                  },
                                  itemBuilder: (context, index) {
                                    return CachedNetworkImage(
                                      imageUrl: images[index],
                                      fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                      Icon(Icons.broken_image, size: 48, color: Colors.grey[500]),
                      const SizedBox(height: 8),
                      Text('Failed to load', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                              ],
                                            ),
                                          ),
                                    );
                                  },
                                ),
          // 图片指示器
                                if (images.length > 1)
                                  Positioned(
                                    bottom: 16,
                                    left: 0,
                                    right: 0,
                                    child: Center(
                                      child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                    color: Colors.black54,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          '${_currentImageIndex + 1} / ${images.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
      ),
    );
  }

  List<String> _getImageList(Map<String, dynamic> data) {
    List<String> images = [];

    // imageUrls (List)
    if (data['imageUrls'] != null && data['imageUrls'] is List) {
      for (var url in data['imageUrls']) {
        if (url != null && url.toString().isNotEmpty) {
          images.add(url.toString());
        }
      }
    }

    // images (备用字段名)
    if (images.isEmpty && data['images'] != null && data['images'] is List) {
      for (var url in data['images']) {
        if (url != null && url.toString().isNotEmpty) {
          images.add(url.toString());
        }
      }
    }

    // imageUrl (String)
    if (images.isEmpty && data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty) {
      images.add(data['imageUrl'].toString());
    }

    debugPrint('🖼️ [Images] Found ${images.length} images');
    return images;
  }

  // ========== 商品信息卡片 ==========
  Widget _buildInfoCard(Map<String, dynamic> data) {
    debugPrint('🏗️ [_buildInfoCard] Starting to build info card');
    try {
      final price = _getPrice(data);
      debugPrint('🏗️ [_buildInfoCard] Price: $price');
      
      final unit = data['unit'] ?? 'kg';
      debugPrint('🏗️ [_buildInfoCard] Unit: $unit');
      
      final quantity = data['quantity'] ?? 0;
      debugPrint('🏗️ [_buildInfoCard] Quantity: $quantity');

    return Container(
      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和状态
          Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              Expanded(
                child: Text(
                  (data['title'] ?? data['wasteType'] ?? 'Untitled').toString(),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              _buildStatusBadge((data['status'] ?? 'open').toString()),
            ],
          ),
          const SizedBox(height: 16),

          // 价格
          Text(
            'RM ${price.toStringAsFixed(2)} / $unit',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
          ),
          ),
          const SizedBox(height: 16),

          const Divider(),

          // 详细信息
          _buildInfoRow(Icons.category, 'Waste Type', (data['wasteType'] ?? '-').toString()),
          _buildInfoRow(Icons.inventory, 'Quantity', '$quantity $unit'),
          _buildInfoRow(Icons.location_on, 'Location', _getLocationString(data)),

          // 描述
          if (data['description'] != null && data['description'].toString().isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
              Text(
              data['description'].toString(),
              style: TextStyle(color: Colors.grey[700], height: 1.5),
                ),
          ],

          // 联系方式
          if (data['contactInfo'] != null && data['contactInfo'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(Icons.phone, 'Contact', data['contactInfo'].toString()),
          ],
        ],
      ),
    );
    } catch (e, stackTrace) {
      debugPrint('❌ [_buildInfoCard] Error: $e');
      debugPrint('❌ [_buildInfoCard] Stack: $stackTrace');
      // 返回错误提示卡片
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red[200]!),
            ),
            child: Column(
              children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 8),
            const Text('Error loading product info', style: TextStyle(color: Colors.red)),
                const SizedBox(height: 4),
            Text('$e', style: const TextStyle(fontSize: 12, color: Colors.red)),
        ],
      ),
    );
  }
  }

  double _getPrice(Map<String, dynamic> data) {
    final raw = data['pricePerUnit'] ?? data['pricePerTon'] ?? data['price'] ?? 0;
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw) ?? 0;
    return 0;
  }

  String _getLocationString(Map<String, dynamic> data) {
    // 优先使用 pickupCity
    if (data['pickupCity'] != null && data['pickupCity'].toString().isNotEmpty) {
      return data['pickupCity'].toString();
    }

    // 如果有 pickupAddress，使用它
    if (data['pickupAddress'] != null && data['pickupAddress'].toString().isNotEmpty) {
      return data['pickupAddress'].toString();
    }

    // 处理 location 字段（可能是 Map 或 String）
    final location = data['location'];
    if (location != null) {
      if (location is String && location.isNotEmpty) {
        return location;
      } else if (location is Map<String, dynamic>) {
        // 如果是 Map，尝试获取地址或坐标
        if (location['address'] != null && location['address'].toString().isNotEmpty) {
          return location['address'].toString();
        }
        // 如果有坐标，显示坐标信息
        if (location['latitude'] != null && location['longitude'] != null) {
          final lat = location['latitude'].toString();
          final lng = location['longitude'].toString();
          return 'GPS: $lat, $lng';
        }
      }
    }

    return 'Location not specified';
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
      return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
            children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: Colors.grey[600])),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
            ],
        ),
      );
    }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String displayText;

    switch (status.toLowerCase()) {
      case 'open':
      case 'available':
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        displayText = 'Available';
        break;
      case 'pending':
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFE65100);
        displayText = 'Pending';
        break;
      case 'sold':
      case 'closed':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC62828);
        displayText = 'Sold';
        break;
      default:
        bgColor = Colors.grey[200]!;
        textColor = Colors.grey[700]!;
        displayText = status;
    }

          return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
                      child: Text(
        displayText,
        style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          );
        }

  // ========== 卖家信息卡片 ==========
  Widget _buildSellerCard(Map<String, dynamic> data) {
        return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2)),
        ],
              ),
      child: Row(
                children: [
                  CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFE8F5E9),
            child: const Icon(Icons.person, color: Color(0xFF2E7D32)),
                  ),
          const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                Text('Seller', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Text(
                  (data['userEmail'] ?? 'Unknown Seller').toString(),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
              ],
                              ),
                            ),
                          ],
                        ),
    );
  }

  // ========== 底部操作栏 ==========
  Widget _buildBottomBar(Map<String, dynamic> data) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final sellerId = data['userId']?.toString();

    // 🔐 关键判断逻辑 - 详细日志
    debugPrint('🔐 ═══════════════════════════════════════');
    debugPrint('🔐 [BottomBar] currentUser: ${currentUser?.uid ?? "NULL"}');
    debugPrint('🔐 [BottomBar] sellerId: ${sellerId ?? "NULL"}');

    // 必须两个都不为空且相等才是自己的商品
    final bool isOwnListing = currentUser != null &&
        currentUser.uid.isNotEmpty &&
        sellerId != null &&
        sellerId.isNotEmpty &&
        currentUser.uid == sellerId;

    debugPrint('🔐 [BottomBar] isOwnListing: $isOwnListing');
    debugPrint('🔐 ═══════════════════════════════════════');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: isOwnListing ? _buildOwnerButtons(data) : _buildBuyerButtons(data),
      ),
    );
  }

  // 卖家看到的按钮（自己的商品）
  Widget _buildOwnerButtons(Map<String, dynamic> data) {
    return Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
            onPressed: () => _editListing(),
            icon: const Icon(Icons.edit),
            label: const Text('Edit Listing'),
                      style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF5C6BC0),
              side: const BorderSide(color: Color(0xFF5C6BC0)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
            onPressed: () => _deleteListing(),
            icon: const Icon(Icons.delete),
            label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
        );
  }

  // 买家看到的按钮（别人的商品）
  Widget _buildBuyerButtons(Map<String, dynamic> data) {
    return Row(
        children: [
        // Contact 按钮
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _handleContact(data),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Contact'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2E7D32),
              side: const BorderSide(color: Color(0xFF2E7D32)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Quote 按钮
                    Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _handleQuote(data),
            icon: const Icon(Icons.request_quote),
            label: const Text('Get Quote'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
    );
  }

  // ========== 功能方法 ==========

  Future<void> _toggleFavorite(Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first'), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      final favRef = FirebaseFirestore.instance.collection('favorites');

      if (_isFavorite) {
        // 取消收藏
        final docs = await favRef
            .where('userId', isEqualTo: user.uid)
            .where('listingId', isEqualTo: widget.listingId)
            .get();

        for (var doc in docs.docs) {
          await doc.reference.delete();
        }
      } else {
        // 添加收藏
        await favRef.add({
          'userId': user.uid,
          'listingId': widget.listingId,
          'title': data['title'] ?? data['wasteType'],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      setState(() => _isFavorite = !_isFavorite);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFavorite ? 'Added to favorites' : 'Removed from favorites'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
      ),
    );
  }
    } catch (e) {
      debugPrint('❌ [Favorite] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleContact(Map<String, dynamic> data) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first'), backgroundColor: Colors.orange),
      );
      return;
    }

    final sellerId = data['userId']?.toString();
    if (sellerId == null || sellerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seller info not available'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      // 获取或创建对话
      final chatService = ChatService();
      final conversationId = await chatService.getOrCreateConversation(sellerId);
      
      // 获取卖家信息
      final sellerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(sellerId)
          .get();
      
      final sellerName = sellerDoc.data()?['displayName'] ?? 
                        data['userEmail']?.toString().split('@')[0] ?? 
                        'Seller';
      final sellerAvatar = sellerDoc.data()?['photoURL'];

      if (mounted) {
        // 导航到聊天页面
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BBXChatScreen(
              conversationId: conversationId,
              otherUserId: sellerId,
              otherUserName: sellerName,
              otherUserAvatar: sellerAvatar,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleQuote(Map<String, dynamic> data) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first'), backgroundColor: Colors.orange),
      );
      return;
    }

    _showQuoteDialog(data);
  }

  void _showQuoteDialog(Map<String, dynamic> data) {
    final priceController = TextEditingController();
    final quantityController = TextEditingController();
    final messageController = TextEditingController();
    final unit = data['unit'] ?? 'kg';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        decoration: const BoxDecoration(
        color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text('Send Quote', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'For: ${data['title'] ?? data['wasteType'] ?? 'Item'}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Your Price (RM)',
                  prefixText: 'RM ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
              const SizedBox(height: 16),

              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  suffixText: unit,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: messageController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Message (Optional)',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _submitQuote(
                    data,
                    priceController.text,
                    quantityController.text,
                    messageController.text,
                  ),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Send Quote',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitQuote(
    Map<String, dynamic> data,
    String price,
    String quantity,
    String message,
  ) async {
    if (price.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a price'), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser!;

      await FirebaseFirestore.instance.collection('offers').add({
        'listingId': widget.listingId,
        'listingTitle': data['title'] ?? data['wasteType'],
        'sellerId': data['userId'],
        'sellerEmail': data['userEmail'],
        'buyerId': user.uid,
        'buyerEmail': user.email,
        'offeredPrice': double.tryParse(price) ?? 0,
        'quantity': double.tryParse(quantity) ?? 0,
        'unit': data['unit'] ?? 'kg',
        'message': message,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context); // 关闭弹窗

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quote sent successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      debugPrint('❌ [Quote] Error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _editListing() {
    Navigator.pushNamed(context, '/edit-listing', arguments: widget.listingId);
  }

  Future<void> _deleteListing() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Listing'),
        content: const Text('Are you sure? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('listings').doc(widget.listingId).delete();

      if (!mounted) return;
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing deleted'), backgroundColor: Colors.green),
      );
    } catch (e) {
        debugPrint('❌ [Delete] Error: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
