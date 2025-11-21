import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/transaction_model.dart';
import '../../models/listing_model.dart';
import '../../models/user_model.dart';
import '../../services/transaction_service.dart';
import '../../services/listing_service.dart';
import '../../services/user_service.dart';
import 'bbx_optimized_transaction_detail_screen.dart';
import 'bbx_upload_payment_screen.dart';

/// 我的交易列表页面
class BBXTransactionsScreen extends StatefulWidget {
  const BBXTransactionsScreen({Key? key}) : super(key: key);

  @override
  State<BBXTransactionsScreen> createState() => _BBXTransactionsScreenState();
}

class _BBXTransactionsScreenState extends State<BBXTransactionsScreen> with SingleTickerProviderStateMixin {
  final TransactionService _transactionService = TransactionService();
  final ListingService _listingService = ListingService();
  final UserService _userService = UserService();

  late TabController _tabController;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '进行�?),
            Tab(text: '已完�?),
            Tab(text: '已取�?),
          ],
        ),
      ),
      body: _currentUserId == null
          ? const Center(child: Text('请先登录'))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTransactionList('active'),
                _buildTransactionList('completed'),
                _buildTransactionList('cancelled'),
              ],
            ),
    );
  }

  /// 构建交易列表
  Widget _buildTransactionList(String filterType) {
    return StreamBuilder<List<TransactionModel>>(
      stream: _getTransactionsStream(filterType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('加载失败: ${snapshot.error}'));
        }

        final transactions = snapshot.data ?? [];

        if (transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  _getEmptyMessage(filterType),
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
            return _buildTransactionCard(transactions[index]);
          },
        );
      },
    );
  }

  /// 获取交易�?
  Stream<List<TransactionModel>> _getTransactionsStream(String filterType) {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    // 合并买家和卖家的交易
    final buyerStream = _transactionService.getMyBuyerTransactions(_currentUserId!);
    final sellerStream = _transactionService.getMySellerTransactions(_currentUserId!);

    // 合并流并过滤
    return buyerStream.asyncMap((buyerTransactions) async {
      final sellerTransactions = await sellerStream.first;
      final allTransactions = [...buyerTransactions, ...sellerTransactions];

      // 根据类型过滤
      List<TransactionModel> filtered;
      switch (filterType) {
        case 'active':
          filtered = allTransactions.where((t) => t.isActive()).toList();
          break;
        case 'completed':
          filtered = allTransactions.where((t) => t.shippingStatus == 'completed').toList();
          break;
        case 'cancelled':
          filtered = allTransactions.where((t) => t.status == 'cancelled').toList();
          break;
        default:
          filtered = allTransactions;
      }

      // 按时间排�?
      filtered.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));

      return filtered;
    });
  }

  /// 构建交易卡片
  Widget _buildTransactionCard(TransactionModel transaction) {
    final bool isBuyer = transaction.buyerId == _currentUserId;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BBXOptimizedTransactionDetailScreen(transactionId: transaction.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部：交易编�?+ 状态标�?
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '交易编号: ${transaction.id.substring(transaction.id.length - 6)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  _buildStatusChip(transaction.shippingStatus),
                ],
              ),
              const SizedBox(height: 12),

              // 商品信息
              FutureBuilder<ListingModel?>(
                future: _listingService.getListing(transaction.listingId),
                builder: (context, snapshot) {
                  final listing = snapshot.data;
                  return Row(
                    children: [
                      // 商品图片
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: listing?.imageUrls.isNotEmpty == true
                            ? Image.network(
                                listing!.imageUrls.first,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image_not_supported),
                                  );
                                },
                              )
                            : Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[300],
                                child: const Icon(Icons.recycling),
                              ),
                      ),
                      const SizedBox(width: 12),

                      // 商品信息
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              listing?.title ?? '加载�?..',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            if (listing != null)
                              Text(
                                '${listing.quantity} ${listing.unit}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),

              const Divider(height: 24),

              // 金额信息
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '交易金额',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'RM ${transaction.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '平台�?,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'RM ${transaction.platformFee.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '总金�?,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'RM ${transaction.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 时间信息
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '创建: ${_formatDate(transaction.createdAt)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  if (transaction.pickupScheduledDate != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.local_shipping, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '取货: ${_formatDate(transaction.pickupScheduledDate)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 12),

              // 对方信息
              FutureBuilder<UserModel?>(
                future: _userService.getUserById(isBuyer ? transaction.sellerId : transaction.buyerId),
                builder: (context, snapshot) {
                  final otherUser = snapshot.data;
                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: otherUser?.photoURL != null
                            ? NetworkImage(otherUser!.photoURL!)
                            : null,
                        child: otherUser?.photoURL == null
                            ? const Icon(Icons.person, size: 16)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${isBuyer ? '卖家' : '买家'}: ${otherUser?.displayName ?? '加载�?..'}',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 12),

              // 操作按钮
              _buildActionButtons(transaction, isBuyer),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建状态标�?
  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'pending':
        color = Colors.blue;
        break;
      case 'picked_up':
        color = Colors.orange;
        break;
      case 'in_transit':
        color = Colors.cyan;
        break;
      case 'delivered':
        color = Colors.green;
        break;
      case 'completed':
        color = Colors.grey;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        _getStatusText(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons(TransactionModel transaction, bool isBuyer) {
    List<Widget> buttons = [];

    if (transaction.canPayment() && isBuyer) {
      buttons.add(
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BBXUploadPaymentScreen(transactionId: transaction.id),
              ),
            );
          },
          icon: const Icon(Icons.upload, size: 18),
          label: const Text('上传支付凭证'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      );
    }

    if (buttons.isEmpty) {
      buttons.add(
        OutlinedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BBXOptimizedTransactionDetailScreen(transactionId: transaction.id),
              ),
            );
          },
          child: const Text('查看详情'),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: buttons,
    );
  }

  /// 格式化日�?
  String _formatDate(DateTime? date) {
    if (date == null) return '--';
    return DateFormat('MM-dd HH:mm').format(date);
  }

  /// 获取状态文�?
  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return '待发�?;
      case 'picked_up':
        return '已取�?;
      case 'in_transit':
        return '运输�?;
      case 'delivered':
        return '已送达';
      case 'completed':
        return '已完�?;
      default:
        return status;
    }
  }

  /// 获取空列表提�?
  String _getEmptyMessage(String filterType) {
    switch (filterType) {
      case 'active':
        return '暂无进行中的交易';
      case 'completed':
        return '暂无已完成的交易';
      case 'cancelled':
        return '暂无已取消的交易';
      default:
        return '暂无交易';
    }
  }
}
