import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bbx_card.dart';
import '../../widgets/bbx_chip.dart';
import '../../widgets/bbx_empty_state.dart';
import '../../widgets/bbx_loading.dart';
import '../../models/listing_model.dart';

/// BBX 分类商品列表页
class BBXCategoryListingsScreen extends StatefulWidget {
  final String category;
  final String categoryLabel;

  const BBXCategoryListingsScreen({
    super.key,
    required this.category,
    required this.categoryLabel,
  });

  @override
  State<BBXCategoryListingsScreen> createState() =>
      _BBXCategoryListingsScreenState();
}

class _BBXCategoryListingsScreenState extends State<BBXCategoryListingsScreen> {
  String _sortBy = 'latest';
  final List<String> _filters = [];

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getCategoryColor(widget.category);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // 顶部AppBar（渐变色）
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: color,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.categoryLabel,
                style: AppTheme.heading2.copyWith(
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),

          // 统计信息栏
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Row(
                children: [
                  const Text('共 0 个商品', style: AppTheme.body2),
                  const Spacer(),
                  DropdownButton<String>(
                    value: _sortBy,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'latest', child: Text('最新发布')),
                      DropdownMenuItem(value: 'price_asc', child: Text('价格从低到高')),
                      DropdownMenuItem(value: 'price_desc', child: Text('价格从高到低')),
                      DropdownMenuItem(value: 'quantity', child: Text('数量从多到少')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _sortBy = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          // 快捷筛选
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing16,
                vertical: AppTheme.spacing8,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    BBXFilterChip(
                      label: '全部',
                      isSelected: _filters.isEmpty,
                      onTap: () {
                        setState(() {
                          _filters.clear();
                        });
                      },
                    ),
                    const SizedBox(width: AppTheme.spacing8),
                    BBXFilterChip(
                      label: '已认证',
                      isSelected: _filters.contains('verified'),
                      onTap: () {
                        setState(() {
                          if (_filters.contains('verified')) {
                            _filters.remove('verified');
                          } else {
                            _filters.add('verified');
                          }
                        });
                      },
                    ),
                    const SizedBox(width: AppTheme.spacing8),
                    BBXFilterChip(
                      label: '附近5km',
                      isSelected: _filters.contains('nearby5'),
                      onTap: () {
                        setState(() {
                          if (_filters.contains('nearby5')) {
                            _filters.remove('nearby5');
                          } else {
                            _filters.add('nearby5');
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 商品列表
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('listings')
                .where('category', isEqualTo: widget.category)
                .where('status', isEqualTo: 'active')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return SliverToBoxAdapter(
                  child: BBXEmptyState.noData(
                    description: '加载失败，请重试',
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: BBXListLoading(itemCount: 5),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SliverToBoxAdapter(
                  child: BBXEmptyState.noData(
                    description: '暂无该分类商品',
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final listing = Listing.fromFirestore(doc);

                    return BBXListingCard(
                      imageUrl: listing.images.isNotEmpty
                          ? listing.images.first
                          : '',
                      title: listing.title,
                      category: listing.category,
                      price: listing.pricePerUnit,
                      unit: listing.unit,
                      quantity: '${listing.quantity} ${listing.unit}',
                      sellerName: listing.sellerName,
                      onTap: () {
                        // 导航到商品详情页
                      },
                    );
                  },
                  childCount: snapshot.data!.docs.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
