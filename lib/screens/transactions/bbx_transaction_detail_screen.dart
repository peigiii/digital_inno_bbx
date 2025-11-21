import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/transaction_model.dart';
import '../../models/listing_model.dart';
import '../../models/user_model.dart';
import '../../models/logistics_update_model.dart';
import '../../services/transaction_service.dart';
import '../../services/listing_service.dart';
import '../../services/user_service.dart';
import '../../utils/delivery_config.dart';
import 'bbx_upload_payment_screen.dart';
import 'bbx_update_logistics_screen.dart';

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
        title: const Text('Transaction Details'),
      ),
      body: StreamBuilder<TransactionModel>(
        stream: _transactionService.getTransactionDetailsStream(widget.transactionId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Load failed: ${snapshot.error}'));
          }

          final transaction = snapshot.data;
          if (transaction == null) {
            return const Center(child: Text('Transaction not found'));
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
                                            _buildProgressIndicator(transaction),
                      const SizedBox(height: 24),

                                            _buildTransactionInfoCard(transaction),
                      const SizedBox(height: 16),

                                            _buildProductInfoCard(transaction),
                      const SizedBox(height: 16),

                                            _buildAmountCard(transaction),
                      const SizedBox(height: 16),

                                            _buildUserInfoCard(transaction.buyerId, 'Buyer Info'),
                      const SizedBox(height: 16),

                                            _buildUserInfoCard(transaction.sellerId, 'Seller Info'),
                      const SizedBox(height: 16),

                                            _buildLogisticsInfoCard(transaction),
                      const SizedBox(height: 16),

                                            if (transaction.paymentProofUrl != null) ...[
                        _buildPaymentProofCard(transaction),
                        const SizedBox(height: 16),
                      ],

                                            _buildLogisticsTimeline(transaction),
                      const SizedBox(height: 80),                     ],
                  ),
                ),
              ),

                            _buildActionButtons(transaction, isBuyer),
            ],
          );
        },
      ),
    );
  }

    Widget _buildProgressIndicator(TransactionModel transaction) {
    final steps = ['Order', 'Pay', 'Pickup', 'Transit', 'Delivered', 'Done'];
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

    Widget _buildTransactionInfoCard(TransactionModel transaction) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transaction Info',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildInfoRow('ID', transaction.id, copyable: true),
            _buildInfoRow('Created At', _formatDateTime(transaction.createdAt)),
            _buildInfoRow('Current Status', transaction.shippingStatusDisplay),
            _buildInfoRow('Payment Method', transaction.paymentMethodDisplay),
            _buildInfoRow('Payment Status', transaction.paymentStatusDisplay),
          ],
        ),
      ),
    );
  }

    Widget _buildProductInfoCard(TransactionModel transaction) {
    return FutureBuilder<ListingModel?>(
      future: _listingService.getListing(transaction.listingId),
      builder: (context, snapshot) {
        final listing = snapshot.data;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Product Info',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                if (listing != null) ...[
                  Row(
                    children: [
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
                                listing.wasteType,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Qty: ${listing.quantity} ${listing.unit}',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            Text(
                              'Price: RM ${listing.pricePerUnit.toStringAsFixed(2)}/${listing.unit}',
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

    Widget _buildAmountCard(TransactionModel transaction) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Amount Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Product Amount'),
                Text('RM ${transaction.amount.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Platform Fee (3%)'),
                Text('RM ${transaction.platformFee.toStringAsFixed(2)}'),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount',
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
                        backgroundImage: user.photoURL != null
                            ? NetworkImage(user.photoURL!)
                            : null,
                        child: user.photoURL == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName ?? 'Unknown User',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                              ),
                            ),
                            if (user.contact != null)
                              InkWell(
                                onTap: () => _makePhoneCall(user.contact!),
                                child: Row(
                                  children: [
                                    const Icon(Icons.phone, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      user.contact!,
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

    Widget _buildLogisticsInfoCard(TransactionModel transaction) {
    final deliveryMethod = transaction.deliveryMethod;
    final shippingInfo = transaction.shippingInfo;
    final isSelfCollect = DeliveryConfig.isSelfCollect(deliveryMethod);
    final isDelivery = DeliveryConfig.isDelivery(deliveryMethod);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                        Row(
              children: [
                Icon(
                  isSelfCollect ? Icons.store : Icons.local_shipping,
                  color: isSelfCollect ? Colors.green : Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isSelfCollect ? 'Method: Self Collect' : 'Method: Delivery',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),

                        if (isSelfCollect) ...[
              _buildInfoRow('Pickup Address', 'Please contact seller'),
              if (transaction.pickupScheduledDate != null)
                _buildInfoRow('Scheduled Date', _formatDateTime(transaction.pickupScheduledDate)),
              if (transaction.actualPickupDate != null)
                _buildInfoRow('Actual Pickup', _formatDateTime(transaction.actualPickupDate)),
              const SizedBox(height: 12),
                            Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.green[700], size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Please contact seller to arrange pickup',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

                        if (isDelivery && shippingInfo == null) ...[
              DeliveryConfig.buildShippingFeeNote(),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Waiting for seller to ship',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],

                        if (isDelivery && shippingInfo != null) ...[
                            Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                                        Row(
                      children: [
                        const Icon(Icons.local_shipping, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          shippingInfo['courierName'] ?? 'Unknown Courier',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                                        Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tracking Number',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                shippingInfo['trackingNumber'] ?? '',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                                                IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: shippingInfo['trackingNumber'] ?? ''),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Copied to clipboard')),
                            );
                          },
                          tooltip: 'Copy Tracking Number',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

                            if (shippingInfo['shippedAt'] != null) ...[
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Shipped At',
                  _formatDateTime((shippingInfo['shippedAt'] as Timestamp).toDate()),
                ),
              ],

                            if (shippingInfo['notes'] != null && shippingInfo['notes'].toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seller Notes',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        shippingInfo['notes'] ?? '',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],

                            const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        ' Please track on courier website',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

                        if (deliveryMethod == null) ...[
              if (transaction.pickupScheduledDate != null)
                _buildInfoRow('Scheduled Pickup', _formatDateTime(transaction.pickupScheduledDate)),
              if (transaction.actualPickupDate != null)
                _buildInfoRow('Actual Pickup', _formatDateTime(transaction.actualPickupDate)),
              if (transaction.deliveryDate != null)
                _buildInfoRow('Delivered At', _formatDateTime(transaction.deliveryDate)),
              if (transaction.trackingNumber != null)
                _buildInfoRow('Tracking No.', transaction.trackingNumber!),
            ],
          ],
        ),
      ),
    );
  }

    Widget _buildPaymentProofCard(TransactionModel transaction) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Proof',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            GestureDetector(
              onTap: () {
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

    Widget _buildLogisticsTimeline(TransactionModel transaction) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Timeline',
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
                  return const Text('No updates yet');
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
                                    'Location: ${update.location}',
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

    Widget _buildActionButtons(TransactionModel transaction, bool isBuyer) {
    List<Widget> buttons = [];

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
            child: const Text('Upload Payment'),
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
            child: const Text('Cancel Order'),
          ),
        ),
      );
    }

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
            child: const Text('Mark Picked Up'),
          ),
        ),
      );
    }

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
            child: const Text('Update Logistics'),
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
            child: const Text('Confirm Receipt'),
          ),
        ),
      );
    }

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
            child: const Text('Complete Order'),
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
                        const SnackBar(content: Text('Copied to clipboard')),
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
          const SnackBar(content: Text('Marked as Picked Up')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action failed: $e')),
        );
      }
    }
  }

  Future<void> _confirmDelivery(TransactionModel transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Receipt'),
        content: const Text('Are you sure you received the goods?\nThis cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _transactionService.confirmDelivery(transaction.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Receipt Confirmed')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Action failed: $e')),
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
          const SnackBar(content: Text('Transaction Completed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action failed: $e')),
        );
      }
    }
  }

  Future<void> _cancelTransaction(TransactionModel transaction) async {
    final TextEditingController reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please enter cancellation reason:'),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Reason...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Back'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true && reasonController.text.isNotEmpty) {
      try {
        await _transactionService.cancelTransaction(transaction.id, reasonController.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction Cancelled')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Action failed: $e')),
          );
        }
      }
    }
  }
}
