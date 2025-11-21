import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/escrow_service.dart';
import 'transactions/bbx_optimized_transaction_detail_screen.dart';

/// 我的交易页面
/// 显示用户的购买和销售记�?
class BBXMyTransactionsScreen extends StatefulWidget {
  const BBXMyTransactionsScreen({super.key});

  @override
  State<BBXMyTransactionsScreen> createState() =>
      _BBXMyTransactionsScreenState();
}

class _BBXMyTransactionsScreenState extends State<BBXMyTransactionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final EscrowService _escrowService = EscrowService();

  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的交易'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '我的购买'),
            Tab(text: '我的销�?),
          ],
        ),
      ),
      body: Column(
        children: [
          // 筛选器
          _buildFilterBar(),
          // 交易列表
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPurchasesList(),
                _buildSalesList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[100],
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('all', '全部'),
            const SizedBox(width: 8),
            _buildFilterChip('pending', '待支�?),
            const SizedBox(width: 8),
            _buildFilterChip('paid', '已支�?),
            const SizedBox(width: 8),
            _buildFilterChip('shipped', '已发�?),
            const SizedBox(width: 8),
            _buildFilterChip('completed', '已完�?),
            const SizedBox(width: 8),
            _buildFilterChip('cancelled', '已取�?),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
    );
  }

  Widget _buildPurchasesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _escrowService.getUserPurchases(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('错误: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var transactions = snapshot.data!.docs;

        // 应用筛�?
        if (_selectedFilter != 'all') {
          transactions = transactions.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] == _selectedFilter;
          }).toList();
        }

        if (transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_outlined,
                    size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  '暂无购买记录',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final doc = transactions[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildTransactionCard(doc.id, data, true);
          },
        );
      },
    );
  }

  Widget _buildSalesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _escrowService.getUserSales(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('错误: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var transactions = snapshot.data!.docs;

        // 应用筛�?
        if (_selectedFilter != 'all') {
          transactions = transactions.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] == _selectedFilter;
          }).toList();
        }

        if (transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sell_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  '暂无销售记�?,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final doc = transactions[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildTransactionCard(doc.id, data, false);
          },
        );
      },
    );
  }

  Widget _buildTransactionCard(
    String transactionId,
    Map<String, dynamic> data,
    bool isPurchase,
  ) {
    final status = TransactionStatus.fromString(data['status']);
    Color statusColor;

    switch (status) {
      case TransactionStatus.completed:
        statusColor = Colors.green;
        break;
      case TransactionStatus.cancelled:
      case TransactionStatus.refunded:
        statusColor = Colors.red;
        break;
      case TransactionStatus.disputed:
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BBXOptimizedTransactionDetailScreen(
                transactionId: transactionId,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部信息
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '订单�? ${transactionId.substring(0, 8)}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      status.label,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 商品信息（简化显示）
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('listings')
                    .doc(data['listingId'])
                    .get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Text('商品信息加载�?..');
                  }

                  final listingData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  return Row(
                    children: [
                      // 商品图片
                      if (listingData['images'] != null &&
                          (listingData['images'] as List).isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            (listingData['images'] as List).first,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(width: 12),
                      // 商品信息
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              listingData['title'] ?? '未知商品',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${listingData['quantity'] ?? 0} ${listingData['unit'] ?? ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),

              // 底部信息
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isPurchase ? Icons.shopping_cart : Icons.sell,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPurchase ? '购买' : '销�?,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(data['createdAt']),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'RM ${data['amount'].toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),

              // 物流信息（如果有�?
              if (data['trackingNumber'] != null) ...[
                const Divider(height: 24),
                Row(
                  children: [
                    const Icon(Icons.local_shipping, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '物流单号: ${data['trackingNumber']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '-';
    final date = timestamp.toDate();
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
