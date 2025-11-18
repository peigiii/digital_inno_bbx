import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/common/common.dart';
import '../widgets/marketplace/category_chips.dart';
import '../widgets/marketplace/stat_cards.dart';
import '../widgets/marketplace/product_card.dart';
import '../widgets/marketplace/supplier_card.dart';

/// BBX 新版市场首页
/// 现代化设计，参考 Alibaba B2B 和 IndiaMART
class BBXNewMarketplaceScreen extends StatefulWidget {
  const BBXNewMarketplaceScreen({super.key});

  @override
  State<BBXNewMarketplaceScreen> createState() => _BBXNewMarketplaceScreenState();
}

class _BBXNewMarketplaceScreenState extends State<BBXNewMarketplaceScreen> {
  final ScrollController _scrollController = ScrollController();
  String _selectedCategory = 'all';
  String _searchQuery = '';
  bool _isLoadingMore = false;
  DocumentSnapshot? _lastDocument;
  final List<DocumentSnapshot> _products = [];
  static const int _productsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialProducts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
      _loadMoreProducts();
    }
  }

  Future<void> _loadInitialProducts() async {
    try {
      Query query = FirebaseFirestore.instance
          .collection('waste_listings')
          .where('status', isEqualTo: 'available')
          .orderBy('createdAt', descending: true)
          .limit(_productsPerPage);

      if (_selectedCategory != 'all') {
        query = query.where('wasteType', isEqualTo: _selectedCategory);
      }

      final snapshot = await query.get();

      if (mounted) {
        setState(() {
          _products.clear();
          _products.addAll(snapshot.docs);
          _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
        });
      }
    } catch (e) {
      debugPrint('加载商品失败: $e');
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || _lastDocument == null) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      Query query = FirebaseFirestore.instance
          .collection('waste_listings')
          .where('status', isEqualTo: 'available')
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_productsPerPage);

      if (_selectedCategory != 'all') {
        query = query.where('wasteType', isEqualTo: _selectedCategory);
      }

      final snapshot = await query.get();

      if (mounted) {
        setState(() {
          _products.addAll(snapshot.docs);
          _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('加载更多商品失败: $e');
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadInitialProducts();
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      _products.clear();
      _lastDocument = null;
    });
    _loadInitialProducts();
  }

  void _showMakeOfferDialog(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final priceController = TextEditingController();
    final messageController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    DateTime? selectedDate;

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('提交报价'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Listing info
                      Text(
                        '废料: ${data['title']}',
                        style: AppTheme.subtitle1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '数量: ${data['quantity']} ${data['unit']}',
                        style: AppTheme.body2.copyWith(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '原价: RM${data['pricePerUnit']}/${data['unit']}',
                        style: AppTheme.body2.copyWith(color: AppTheme.textSecondary),
                      ),
                      const Divider(height: 24),

                      // Offer price
                      AppInput(
                        controller: priceController,
                        label: '您的报价 (RM)',
                        hint: '输入总价',
                        prefixIcon: Icons.monetization_on,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入报价';
                          }
                          if (double.tryParse(value) == null) {
                            return '请输入有效数字';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Collection date
                      InkWell(
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(const Duration(days: 1)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 90)),
                          );
                          if (pickedDate != null) {
                            setDialogState(() {
                              selectedDate = pickedDate;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: '收集日期',
                            prefixIcon: const Icon(Icons.calendar_today),
                            border: OutlineInputBorder(
                              borderRadius: AppTheme.borderRadiusStandard,
                            ),
                          ),
                          child: Text(
                            selectedDate != null
                                ? DateFormat('yyyy-MM-dd').format(selectedDate!)
                                : '选择收集日期',
                            style: TextStyle(
                              color: selectedDate != null ? AppTheme.textPrimary : AppTheme.textHint,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Message
                      TextAreaInput(
                        controller: messageController,
                        label: '留言（可选）',
                        hint: '说明您的收集计划或其他信息',
                        minLines: 3,
                        maxLines: 5,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                SecondaryButton(
                  text: '取消',
                  onPressed: () => Navigator.pop(dialogContext),
                  width: 100,
                  height: 40,
                ),
                PrimaryButton(
                  text: '提交',
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(dialogContext);
                      await _submitOffer(
                        doc.id,
                        data,
                        double.parse(priceController.text),
                        messageController.text,
                        selectedDate,
                      );
                    }
                  },
                  width: 100,
                  height: 40,
                ),
              ],
            );
          },
        );
      },
    );

    priceController.dispose();
    messageController.dispose();
  }

  Future<void> _submitOffer(
    String listingId,
    Map<String, dynamic> listingData,
    double offerPrice,
    String message,
    DateTime? collectionDate,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('请先登录');
      }

      // Get current user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('用户数据不存在');
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      // Create offer
      final offerData = {
        'listingId': listingId,
        'recyclerId': user.uid,
        'recyclerName': userData['displayName'] ?? user.email,
        'recyclerCompany': userData['companyName'] ?? '',
        'recyclerContact': userData['contact'] ?? '',
        'producerId': listingData['userId'],
        'offerPrice': offerPrice,
        'message': message,
        'collectionDate': collectionDate != null ? Timestamp.fromDate(collectionDate) : null,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('offers')
          .add(offerData)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('提交超时，请检查网络连接');
            },
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('报价提交成功！'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('提交失败: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppTheme.primary,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // AppBar with Search
            _buildAppBar(),

            // Category Chips
            SliverToBoxAdapter(
              child: CategoryChips(
                selectedCategory: _selectedCategory,
                onCategorySelected: _onCategorySelected,
              ),
            ),

            // Banner Carousel
            SliverToBoxAdapter(
              child: _buildBannerCarousel(),
            ),

            // Stats Cards
            SliverToBoxAdapter(
              child: _buildStatsSection(),
            ),

            // Featured Suppliers
            SliverToBoxAdapter(
              child: _buildFeaturedSuppliers(),
            ),

            // Hot Products Header
            SliverToBoxAdapter(
              child: SectionHeader(
                title: '🔥 热门商品',
                actionText: '查看全部',
                onActionTap: () {
                  // Navigate to all products
                },
              ),
            ),

            // Products Grid
            _buildProductsGrid(),

            // Loading More Indicator
            if (_isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spacingLG),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),

            // Bottom Spacing
            const SliverToBoxAdapter(
              child: SizedBox(height: AppTheme.spacingXL),
            ),
          ],
        ),
      ),

      // Floating Action Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/waste-list');
        },
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add),
        label: const Text('发布废料'),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: AppTheme.surface,
      elevation: 0,
      toolbarHeight: 80,
      title: Row(
        children: [
          // Logo/Title
          const Text(
            'BBX 市场',
            style: AppTheme.h3,
          ),
          const SizedBox(width: AppTheme.spacingMD),

          // Search Box
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: AppTheme.borderRadiusStandard,
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: '搜索生物质废料、公司、城市...',
                  hintStyle: AppTheme.body2.copyWith(color: AppTheme.textHint),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.mic, color: AppTheme.textSecondary),
                    onPressed: () {
                      // Voice search
                    },
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          ),

          const SizedBox(width: AppTheme.spacingSM),

          // Filter Button
          AppIconButton(
            icon: Icons.tune,
            onPressed: () {
              // Show filter dialog
            },
            tooltip: '筛选',
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCarousel() {
    return Container(
      height: 200,
      margin: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: AppTheme.borderRadiusLarge,
        boxShadow: AppTheme.shadowMedium,
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.eco,
                  size: 64,
                  color: AppTheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: AppTheme.spacingMD),
                Text(
                  'BBX 生物质交易平台',
                  style: AppTheme.h3.copyWith(color: AppTheme.primaryDark),
                ),
                const SizedBox(height: AppTheme.spacingSM),
                Text(
                  '连接供应商与回收商，共建绿色未来',
                  style: AppTheme.body2.copyWith(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),

          // Indicator Dots (placeholder)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == 0
                        ? AppTheme.primary
                        : AppTheme.divider,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchStats(),
      builder: (context, snapshot) {
        return StatCards(stats: snapshot.data);
      },
    );
  }

  Future<Map<String, dynamic>> _fetchStats() async {
    try {
      // Fetch real stats from Firestore
      final listingsSnapshot = await FirebaseFirestore.instance
          .collection('waste_listings')
          .where('status', isEqualTo: 'available')
          .get();

      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .limit(100)
          .get();

      final offersSnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .where('status', isEqualTo: 'accepted')
          .get();

      // Calculate stats
      int totalTonnage = 0;
      for (var doc in listingsSnapshot.docs) {
        final data = doc.data();
        totalTonnage += (data['quantity'] ?? 0) as int;
      }

      return {
        'totalTonnage': totalTonnage,
        'activeUsers': usersSnapshot.docs.length,
        'completedOrders': offersSnapshot.docs.length,
        'carbonReduced': (totalTonnage * 0.85).round(), // Estimate
      };
    } catch (e) {
      debugPrint('获取统计数据失败: $e');
      return {
        'totalTonnage': 0,
        'activeUsers': 0,
        'completedOrders': 0,
        'carbonReduced': 0,
      };
    }
  }

  Widget _buildFeaturedSuppliers() {
    return Column(
      children: [
        SectionHeader(
          title: '⭐ 优质供应商',
          actionText: '查看全部',
          onActionTap: () {
            // Navigate to all suppliers
          },
        ),
        SizedBox(
          height: 220,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('userType', isEqualTo: 'producer')
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    return const SizedBox(
                      width: 180,
                      child: CardShimmer(),
                    );
                  },
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    '暂无供应商',
                    style: AppTheme.body2.copyWith(color: AppTheme.textSecondary),
                  ),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  return SupplierCard(
                    doc: doc,
                    onTap: () {
                      // Navigate to supplier profile
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductsGrid() {
    if (_products.isEmpty) {
      return SliverFillRemaining(
        child: EmptyStateCard(
          icon: Icons.inventory_2_outlined,
          title: '暂无商品',
          message: '成为第一个发布废料信息的用户',
          action: PrimaryButton(
            text: '发布废料',
            icon: Icons.add,
            onPressed: () {
              Navigator.pushNamed(context, '/waste-list');
            },
          ),
        ),
      );
    }

    // Filter by search query
    final filteredProducts = _products.where((doc) {
      if (_searchQuery.isEmpty) return true;

      final data = doc.data() as Map<String, dynamic>;
      final title = (data['title'] ?? '').toString().toLowerCase();
      final wasteType = (data['wasteType'] ?? '').toString().toLowerCase();
      final city = (data['city'] ?? data['contactInfo'] ?? '').toString().toLowerCase();

      return title.contains(_searchQuery.toLowerCase()) ||
          wasteType.contains(_searchQuery.toLowerCase()) ||
          city.contains(_searchQuery.toLowerCase());
    }).toList();

    if (filteredProducts.isEmpty) {
      return SliverFillRemaining(
        child: EmptyStateCard(
          icon: Icons.search_off,
          title: '未找到匹配的商品',
          message: '请尝试调整搜索条件',
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSM),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 0,
          mainAxisSpacing: 0,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final doc = filteredProducts[index];
            return ProductCard(
              doc: doc,
              onTap: () {
                // Navigate to product detail
              },
              onQuote: () {
                _showMakeOfferDialog(doc);
              },
            );
          },
          childCount: filteredProducts.length,
        ),
      ),
    );
  }
}
