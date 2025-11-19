import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/transaction_model.dart';
import '../../models/listing_model.dart';
import '../../models/user_model.dart';
import '../../models/logistics_update_model.dart';
import '../../services/transaction_service.dart';
import '../../services/listing_service.dart';
import '../../services/user_service.dart';
import 'bbx_upload_payment_screen.dart';
import 'bbx_update_logistics_screen.dart';

/// 交易详情页面
class BBXTransactionDetailScreen extends StatefulWidget {
  final String transactionId;

  const BBXTransactionDetailScreen({
    Key? key,
    required this.transactionId,
  }) : super(key: key);

  @override
  State<BBXTransactionDetailScreen> createState() => _BBXTransactionDetailScreenState();
}

class _BBXTransactionDetailScreenState extends State<BBXTransactionDetailScreen> {
  final TransactionService _transactionService = TransactionService();
  final ListingService _listingService = ListingService();
  final UserService _userService = UserService();

  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('交易详情'),
      ),
      body: StreamBuilder<TransactionModel>(
        stream: _transactionService.getTransactionDetailsStream(widget.transactionId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('加载失败: ${snapshot.error}'));
          }

          final transaction = snapshot.data;
          if (transaction == null) {
            return const Center(child: Text('交易不存在'));
          }

          final bool isBuyer = transaction.buyerId == _currentUserId;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. 状态进度条
                      _buildProgressIndicator(transaction),
                      const SizedBox(height: 24),

                      // 2. 交易信息卡片
                      _buildTransactionInfoCard(transaction),
                      const SizedBox(height: 16),

                      // 3. 商品信息卡片
                      _buildProductInfoCard(transaction),
                      const SizedBox(height: 16),

                      // 4. 金额明细卡片
                      _buildAmountCard(transaction),
                      const SizedBox(height: 16),

                      // 5. 买家信息卡片
                      _buildUserInfoCard(transaction.buyerId, '买家信息'),
                      const SizedBox(height: 16),

                      // 6. 卖家信息卡片
                      _buildUserInfoCard(transaction.sellerId, '卖家信息'),
                      const SizedBox(height: 16),

                      // 7. 物流信息卡片
                      _buildLogisticsInfoCard(transaction),
                      const SizedBox(height: 16),

                      // 8. 支付凭证卡片（如已上传）
                      if (transaction.paymentProofUrl != null) ...[
                        _buildPaymentProofCard(transaction),
                        const SizedBox(height: 16),
                      ],

                      // 9. 物流时间线
                      _buildLogisticsTimeline(transaction),
                      const SizedBox(height: 80), // 底部按钮区域的空间
                    ],
                  ),
                ),
              ),

              // 10. 操作按钮区域（底部固定）
              _buildActionButtons(transaction, isBuyer),
            ],
          );
        },
      ),
    );
  }

  /// 1. 状态进度条
  Widget _buildProgressIndicator(TransactionModel transaction) {
    final steps = ['确认订单', '支付', '取货', '运输', '送达', '完成'];
    int currentStep = 0;

    switch (transaction.shippingStatus) {
      case 'pending':
        currentStep = transaction.paymentStatus == 'paid' ? 2 : 1;
        break;
      case 'picked_up':
        currentStep = 2;
        break;
      case 'in_transit':
        currentStep = 3;
        break;
      case 'delivered':
        currentStep = 4;
        break;
      case 'completed':
        currentStep = 5;
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(steps.length, (index) {
                final isCompleted = index <= currentStep;
                final isCurrent = index == currentStep;

                return Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted ? Colors.green : Colors.grey[300],
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check, color: Colors.white, size: 18)
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        steps[index],
                        style: TextStyle(
                          fontSize: 10,
                          color: isCurrent ? Colors.green : Colors.grey[600],
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// 2. 交易信息卡片
  Widget _buildTransactionInfoCard(TransactionModel transaction) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '交易信息',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildInfoRow('交易编号', transaction.id, copyable: true),
            _buildInfoRow('创建时间', _formatDateTime(transaction.createdAt)),
            _buildInfoRow('当前状态', transaction.shippingStatusDisplay),
            _buildInfoRow('支付方式', transaction.paymentMethodDisplay),
            _buildInfoRow('支付状态', transaction.paymentStatusDisplay),
          ],
        ),
      ),
    );
  }

  /// 3. 商品信息卡片
  Widget _buildProductInfoCard(TransactionModel transaction) {
    return FutureBuilder<ListingModel?>(
      future: _listingService.getListingById(transaction.listingId),
      builder: (context, snapshot) {
        final listing = snapshot.data;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '商品信息',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                if (listing != null) ...[
                  Row(
                    children: [
                      // 商品图片
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: listing.imageUrls.isNotEmpty
                            ? Image.network(
                                listing.imageUrls.first,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[300],
                                child: const Icon(Icons.recycling),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              listing.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                listing.scrapType,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '数量: ${listing.quantity} ${listing.unit}',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            Text(
                              '单价: RM ${listing.expectedPrice.toStringAsFixed(2)}/${listing.unit}',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 4. 金额明细卡片
  Widget _buildAmountCard(TransactionModel transaction) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '金额明细',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('商品金额'),
                Text('RM ${transaction.amount.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('平台费 (3%)'),
                Text('RM ${transaction.platformFee.toStringAsFixed(2)}'),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '总金额',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'RM ${transaction.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 5. & 6. 用户信息卡片
  Widget _buildUserInfoCard(String userId, String title) {
    return FutureBuilder<UserModel?>(
      future: _userService.getUserById(userId),
      builder: (context, snapshot) {
        final user = snapshot.data;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                if (user != null) ...[
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: user.photoUrl != null
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        child: user.photoUrl == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName ?? '未知用户',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                              ),
                            ),
                            if (user.phone != null)
                              InkWell(
                                onTap: () => _makePhoneCall(user.phone!),
                                child: Row(
                                  children: [
                                    const Icon(Icons.phone, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      user.phone!,
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 7. 物流信息卡片
  Widget _buildLogisticsInfoCard(TransactionModel transaction) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '物流信息',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            if (transaction.pickupScheduledDate != null)
              _buildInfoRow('预定取货日期', _formatDateTime(transaction.pickupScheduledDate)),
            if (transaction.actualPickupDate != null)
              _buildInfoRow('实际取货日期', _formatDateTime(transaction.actualPickupDate)),
            if (transaction.deliveryDate != null)
              _buildInfoRow('送达日期', _formatDateTime(transaction.deliveryDate)),
            if (transaction.trackingNumber != null)
              _buildInfoRow('物流追踪号', transaction.trackingNumber!),
          ],
        ),
      ),
    );
  }

  /// 8. 支付凭证卡片
  Widget _buildPaymentProofCard(TransactionModel transaction) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '支付凭证',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            GestureDetector(
              onTap: () {
                // 查看大图
                _showImageDialog(transaction.paymentProofUrl!);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  transaction.paymentProofUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 9. 物流时间线
  Widget _buildLogisticsTimeline(TransactionModel transaction) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '物流时间线',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            StreamBuilder<List<LogisticsUpdateModel>>(
              stream: _transactionService.getLogisticsUpdates(widget.transactionId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final updates = snapshot.data ?? [];

                if (updates.isEmpty) {
                  return const Text('暂无物流更新');
                }

                return Column(
                  children: updates.map((update) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.green,
                                ),
                              ),
                              if (updates.last != update)
                                Container(
                                  width: 2,
                                  height: 40,
                                  color: Colors.grey[300],
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  update.statusDisplay,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _formatDateTime(update.createdAt),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (update.location != null)
                                  Text(
                                    '位置: ${update.location}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Text(update.description),
                                if (update.imageUrl != null) ...[
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () => _showImageDialog(update.imageUrl!),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        update.imageUrl!,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 10. 操作按钮区域
  Widget _buildActionButtons(TransactionModel transaction, bool isBuyer) {
    List<Widget> buttons = [];

    // confirmed状态
    if (transaction.canPayment() && isBuyer) {
      buttons.add(
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BBXUploadPaymentScreen(transactionId: transaction.id),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('上传支付凭证'),
          ),
        ),
      );

      buttons.add(const SizedBox(width: 8));

      buttons.add(
        Expanded(
          child: OutlinedButton(
            onPressed: () => _cancelTransaction(transaction),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('取消交易'),
          ),
        ),
      );
    }

    // paid状态
    if (transaction.canPickup() && !isBuyer) {
      buttons.add(
        Expanded(
          child: ElevatedButton(
            onPressed: () => _markAsPickedUp(transaction),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('标记已取货'),
          ),
        ),
      );
    }

    // picked_up/in_transit状态
    if ((transaction.shippingStatus == 'picked_up' || transaction.shippingStatus == 'in_transit') && !isBuyer) {
      buttons.add(
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BBXUpdateLogisticsScreen(transactionId: transaction.id),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('更新物流信息'),
          ),
        ),
      );
    }

    if (transaction.canConfirmDelivery() && isBuyer) {
      if (buttons.isNotEmpty) {
        buttons.add(const SizedBox(width: 8));
      }
      buttons.add(
        Expanded(
          child: ElevatedButton(
            onPressed: () => _confirmDelivery(transaction),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('确认收货'),
          ),
        ),
      );
    }

    // delivered状态
    if (transaction.canComplete()) {
      buttons.add(
        Expanded(
          child: ElevatedButton(
            onPressed: () => _completeTransaction(transaction),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('完成交易'),
          ),
        ),
      );
    }

    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: buttons,
        ),
      ),
    );
  }

  // ==================== 辅助方法 ====================

  Widget _buildInfoRow(String label, String? value, {bool copyable = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[700]),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value ?? '--',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    textAlign: TextAlign.right,
                  ),
                ),
                if (copyable && value != null)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已复制到剪贴板')),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '--';
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Stack(
          children: [
            Image.network(imageUrl),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _markAsPickedUp(TransactionModel transaction) async {
    try {
      await _transactionService.markAsPickedUp(transaction.id, null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已标记为已取货')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
  }

  Future<void> _confirmDelivery(TransactionModel transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认收货'),
        content: const Text('请确认您已收到货物\n确认后将无法撤销'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('确认收货'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _transactionService.confirmDelivery(transaction.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已确认收货')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('操作失败: $e')),
          );
        }
      }
    }
  }

  Future<void> _completeTransaction(TransactionModel transaction) async {
    try {
      await _transactionService.completeTransaction(transaction.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('交易已完成')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
  }

  Future<void> _cancelTransaction(TransactionModel transaction) async {
    final TextEditingController reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('取消交易'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('请输入取消原因：'),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '请输入取消原因',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('返回'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('确认取消'),
          ),
        ],
      ),
    );

    if (confirmed == true && reasonController.text.isNotEmpty) {
      try {
        await _transactionService.cancelTransaction(transaction.id, reasonController.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('交易已取消')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('操作失败: $e')),
          );
        }
      }
    }
  }
}
