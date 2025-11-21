import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../services/escrow_service.dart';

class BBXTransactionDetailScreen extends StatefulWidget {
  final String transactionId;

  const BBXTransactionDetailScreen({
    super.key,
    required this.transactionId,
  });

  @override
  State<BBXTransactionDetailScreen> createState() =>
      _BBXTransactionDetailScreenState();
}

class _BBXTransactionDetailScreenState
    extends State<BBXTransactionDetailScreen> {
  final EscrowService _escrowService = EscrowService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  final TextEditingController _trackingNumberController =
      TextEditingController();
  final TextEditingController _refundReasonController =
      TextEditingController();

  @override
  void dispose() {
    _trackingNumberController.dispose();
    _refundReasonController.dispose();
    super.dispose();
  }

  Future<void> _uploadShippingProof() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) return;

      setState(() => _isLoading = true);

            final userId = _auth.currentUser!.uid;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('shipping_proofs/${widget.transactionId}/$fileName');

      await ref.putFile(File(image.path));
      final url = await ref.getDownloadURL();

            if (!mounted) return;

      final trackingNumber = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('输入物流单号'),
          content: TextField(
            controller: _trackingNumberController,
            decoration: const InputDecoration(
              labelText: '物流单号',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, _trackingNumberController.text);
              },
              child: const Text('确认'),
            ),
          ],
        ),
      );

      if (trackingNumber == null || trackingNumber.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      await _escrowService.uploadShippingProof(
        transactionId: widget.transactionId,
        trackingNumber: trackingNumber,
        proofUrls: [url],
      );

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('发货凭证上传成功')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传失败: $e')),
        );
      }
    }
  }

  Future<void> _confirmReceived() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认收货'),
        content: const Text('确认收到商品并满意吗？确认后资金将释放给卖家?),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认收货'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _isLoading = true);
      await _escrowService.confirmReceived(widget.transactionId);
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Confirmed收?)),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
  }

  Future<void> _requestRefund() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('申请退?),
        content: TextField(
          controller: _refundReasonController,
          decoration: const InputDecoration(
            labelText: '退款原?,
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, _refundReasonController.text);
            },
            child: const Text('提交'),
          ),
        ],
      ),
    );

    if (reason == null || reason.isEmpty) return;

    try {
      setState(() => _isLoading = true);
      await _escrowService.requestRefund(
        transactionId: widget.transactionId,
        reason: reason,
      );
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('退款申请已提交')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('交易详情'),
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _escrowService.getTransactionDetails(widget.transactionId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('错误: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final userId = _auth.currentUser!.uid;
          final isBuyer = data['buyerId'] == userId;
          final isSeller = data['sellerId'] == userId;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                                _buildStatusCard(data),
                const SizedBox(height: 16),

                                _buildTimeline(data),
                const SizedBox(height: 16),

                                _buildTransactionInfo(data),
                const SizedBox(height: 16),

                                if (data['trackingNumber'] != null) ...[
                  _buildShippingInfo(data),
                  const SizedBox(height: 16),
                ],

                                if (!_isLoading) ...[
                  if (isSeller && data['status'] == 'paid')
                    _buildSellerActions(data),
                  if (isBuyer && data['status'] == 'shipped')
                    _buildBuyerActions(data),
                  if (isBuyer &&
                      data['status'] == 'completed' &&
                      _escrowService.canRequestRefund(data))
                    _buildRefundAction(),
                ],

                if (_isLoading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(Map<String, dynamic> data) {
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
      color: statusColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: statusColor, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '订单? ${widget.transactionId.substring(0, 8)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Text(
              'RM ${data['amount'].toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(Map<String, dynamic> data) {
    final steps = <Map<String, dynamic>>[];

    steps.add({
      'title': '订单创建',
      'time': data['createdAt'],
      'completed': true,
    });

    steps.add({
      'title': '买家支付',
      'time': data['paidAt'],
      'completed': data['status'] != 'pending',
    });

    steps.add({
      'title': '卖家发货',
      'time': data['shippedAt'],
      'completed': data['status'] == 'shipped' ||
          data['status'] == 'completed',
    });

    steps.add({
      'title': '交易完成',
      'time': data['completedAt'],
      'completed': data['status'] == 'completed',
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '交易进度',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isLast = index == steps.length - 1;

              return _buildTimelineItem(
                title: step['title'],
                time: step['time'],
                completed: step['completed'],
                isLast: isLast,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required Timestamp? time,
    required bool completed,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: completed ? Colors.green : Colors.grey[300],
              ),
              child: completed
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: completed ? Colors.green : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: completed ? Colors.black : Colors.grey,
                ),
              ),
              if (time != null) ...[
                const SizedBox(height: 2),
                Text(
                  _formatDateTime(time.toDate()),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
              if (!isLast) const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionInfo(Map<String, dynamic> data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '交易信息',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('支付方式', data['paymentMethod'] ?? 'Online Banking'),
            _buildInfoRow('托管状?, EscrowStatus.fromString(data['escrowStatus']).label),
            if (data['refundReason'] != null)
              _buildInfoRow('退款原?, data['refundReason']),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingInfo(Map<String, dynamic> data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '物流信息',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('物流单号', data['trackingNumber'] ?? '-'),
            if (data['shippingProof'] != null &&
                (data['shippingProof'] as List).isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('发货凭证:', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: (data['shippingProof'] as List).length,
                  itemBuilder: (context, index) {
                    final url = (data['shippingProof'] as List)[index];
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(url, fit: BoxFit.cover),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSellerActions(Map<String, dynamic> data) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _uploadShippingProof,
        icon: const Icon(Icons.local_shipping),
        label: const Text('上传发货凭证'),
      ),
    );
  }

  Widget _buildBuyerActions(Map<String, dynamic> data) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _confirmReceived,
        icon: const Icon(Icons.check_circle),
        label: const Text('确认收货'),
      ),
    );
  }

  Widget _buildRefundAction() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _requestRefund,
        icon: const Icon(Icons.money_off),
        label: const Text('申请退?),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
