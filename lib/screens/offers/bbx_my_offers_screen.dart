import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/offer_model.dart';
import '../../services/offer_service.dart';
import '../../utils/delivery_config.dart';

/// 我的报价页面
class BBXMyOffersScreen extends StatefulWidget {
  const BBXMyOffersScreen({super.key});

  @override
  State<BBXMyOffersScreen> createState() => _BBXMyOffersScreenState();
}

class _BBXMyOffersScreenState extends State<BBXMyOffersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _offerService = OfferService();

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
        title: const Text('我的报价'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '我发出的'),
            Tab(text: '我收到的'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyOffersTab(),
          _buildReceivedOffersTab(),
        ],
      ),
    );
  }

  /// 我发出的报价标签�?
  Widget _buildMyOffersTab() {
    return StreamBuilder<List<OfferModel>>(
      stream: _offerService.getMyOffers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('加载失败�?{snapshot.error}'));
        }

        final offers = snapshot.data ?? [];

        if (offers.isEmpty) {
          return _buildEmptyState('暂无报价', '您还没有发出过报�?);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: offers.length,
          itemBuilder: (context, index) {
            return _buildOfferCard(offers[index], isBuyer: true);
          },
        );
      },
    );
  }

  /// 我收到的报价标签�?
  Widget _buildReceivedOffersTab() {
    return StreamBuilder<List<OfferModel>>(
      stream: _offerService.getReceivedOffers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('加载失败�?{snapshot.error}'));
        }

        final offers = snapshot.data ?? [];

        if (offers.isEmpty) {
          return _buildEmptyState('暂无报价', '还没有人向您发出报价');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: offers.length,
          itemBuilder: (context, index) {
            return _buildOfferCard(offers[index], isBuyer: false);
          },
        );
      },
    );
  }

  /// 空状�?
  Widget _buildEmptyState(String title, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  /// 报价卡片
  Widget _buildOfferCard(OfferModel offer, {required bool isBuyer}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 状态标�?
            Row(
              children: [
                _buildStatusBadge(offer.status),
                const Spacer(),
                Text(
                  _formatDate(offer.createdAt),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 报价金额
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'RM ${offer.offerPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                if (offer.originalPrice > 0) ...[
                  Text(
                    'RM ${offer.originalPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (offer.discountPercentage > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '-${offer.discountPercentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // 买家/卖家信息
            Text(
              isBuyer ? '卖家�?{offer.sellerId}' : '买家�?{offer.recyclerName}',
              style: const TextStyle(fontSize: 14),
            ),

            // 配送方式标�?
            if (offer.deliveryMethod != null) ...[
              const SizedBox(height: 8),
              DeliveryConfig.buildMethodChip(offer.deliveryMethod!, small: true),
            ],

            // 留言
            if (offer.message.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  offer.message,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            // 还价信息
            if (offer.status == 'negotiating' && offer.counterOfferPrice != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.sync_alt, size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          '卖家还价',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'RM ${offer.counterOfferPrice!.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    if (offer.sellerResponse != null && offer.sellerResponse!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        offer.sellerResponse!,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // 操作按钮
            if (offer.canAccept || offer.status == 'negotiating') ...[
              const SizedBox(height: 16),
              _buildActionButtons(offer, isBuyer),
            ],
          ],
        ),
      ),
    );
  }

  /// 状态标�?
  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'negotiating':
        color = Colors.blue;
        break;
      case 'accepted':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      case 'expired':
      case 'cancelled':
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
      ),
      child: Text(
        _getStatusText(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 获取状态文�?
  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return '待处�?;
      case 'negotiating':
        return '议价�?;
      case 'accepted':
        return '已接�?;
      case 'rejected':
        return '已拒�?;
      case 'expired':
        return '已过�?;
      case 'cancelled':
        return '已取�?;
      default:
        return status;
    }
  }

  /// 操作按钮
  Widget _buildActionButtons(OfferModel offer, bool isBuyer) {
    if (isBuyer && offer.status == 'negotiating') {
      // 买家接受还价
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _acceptCounterOffer(offer),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            '接受还价',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      );
    }

    if (!isBuyer && offer.canAccept) {
      // 卖家操作：接受、拒绝、还�?
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _rejectOffer(offer),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('拒绝'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _acceptOffer(offer),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '接受',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _counterOffer(offer),
            icon: const Icon(Icons.sync_alt),
            tooltip: '还价',
            color: Colors.blue,
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  /// 接受报价
  Future<void> _acceptOffer(OfferModel offer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认接受'),
        content: Text('确定接受该报价：RM ${offer.offerPrice.toStringAsFixed(2)}�?),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _offerService.acceptOffer(offer.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已接受报�?),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败�?e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 拒绝报价
  Future<void> _rejectOffer(OfferModel offer) async {
    final reasonController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('拒绝报价'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('请说明拒绝原因：'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: '输入原因...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _offerService.rejectOffer(offer.id, reasonController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已拒绝报�?),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败�?e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 还价
  Future<void> _counterOffer(OfferModel offer) async {
    final priceController = TextEditingController();
    final messageController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('还价'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '还价金额',
                prefixText: 'RM ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: '说明',
                hintText: '告诉买家您的理由...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final price = double.tryParse(priceController.text);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入有效的金额'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _offerService.counterOffer(offer.id, price, messageController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('还价已发�?),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败�?e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 接受还价
  Future<void> _acceptCounterOffer(OfferModel offer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认接受还价'),
        content: Text('确定接受卖家还价：RM ${offer.counterOfferPrice!.toStringAsFixed(2)}�?),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _offerService.acceptCounterOffer(offer.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已接受还�?),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败�?e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 格式化日�?
  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }
}
