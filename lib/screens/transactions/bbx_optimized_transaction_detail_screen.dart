import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
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

/// BBX Transaction Detail - Optimized
/// Material Design 3 style
class BBXOptimizedTransactionDetailScreen extends StatefulWidget {
  final String transactionId;

  const BBXOptimizedTransactionDetailScreen({
    super.key,
    required this.transactionId,
  });

  @override
  State<BBXOptimizedTransactionDetailScreen> createState() =>
      _BBXOptimizedTransactionDetailScreenState();
}

class _BBXOptimizedTransactionDetailScreenState
    extends State<BBXOptimizedTransactionDetailScreen> {
  final TransactionService _transactionService = TransactionService();
  final ListingService _listingService = ListingService();
  final UserService _userService = UserService();

  String? _currentUserId;
  double _appBarOpacity = 0.0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _appBarOpacity = (_scrollController.offset / 100).clamp(0.0, 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: StreamBuilder<TransactionModel>(
        stream: _transactionService
            .getTransactionDetailsStream(widget.transactionId),
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

          return Stack(
            children: [
              CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // 1. Top Status Header
                  _buildStatusHeader(transaction),

                  // Content List
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // 2. Progress Indicator
                        _buildModernProgressIndicator(transaction),
                        const SizedBox(height: 16),

                        // 3. Transaction Info
                        _buildSectionTitle('Transaction Info'),
                        _buildTransactionInfoCard(transaction),
                        const SizedBox(height: 24),

                        // 4. Product Info
                        _buildSectionTitle('Product Details'),
                        _buildProductInfoCard(transaction),
                        const SizedBox(height: 24),

                        // 5. Amount Details
                        _buildSectionTitle('Amount Details'),
                        _buildAmountCard(transaction),
                        const SizedBox(height: 24),

                        // 6. Counterparty Info
                        _buildSectionTitle(isBuyer ? 'Seller Info' : 'Buyer Info'),
                        _buildUserInfoCard(
                          isBuyer ? transaction.sellerId : transaction.buyerId,
                        ),
                        const SizedBox(height: 24),

                        // 7. Logistics Info
                        _buildSectionTitle('Logistics Info'),
                        _buildLogisticsInfoCard(transaction),
                        const SizedBox(height: 24),

                        // 8. Payment Proof
                        if (transaction.paymentProofUrl != null) ...[
                          _buildSectionTitle('Payment Proof'),
                          _buildPaymentProofCard(transaction),
                          const SizedBox(height: 24),
                        ],

                        // 9. Logistics Timeline
                        _buildSectionTitle('Logistics Updates'),
                        _buildLogisticsTimeline(transaction),
                        
                        // Bottom Padding
                        const SizedBox(height: 100),
                      ]),
                    ),
                  ),
                ],
              ),

              // Custom AppBar
              _buildCustomAppBar(),

              // 10. Bottom Action Bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomActionBar(transaction, isBuyer),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.white.withOpacity(_appBarOpacity),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: _appBarOpacity > 0.5 ? Colors.black : Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    'Transaction Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black.withOpacity(_appBarOpacity),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48), // Placeholder for centering
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHeader(TransactionModel transaction) {
    Color statusColor = AppTheme.getStatusColor(transaction.shippingStatus);
    String statusText = transaction.shippingStatusDisplay;
    IconData statusIcon = Icons.info_outline;

    switch (transaction.shippingStatus) {
      case 'pending':
        statusIcon = Icons.pending_outlined;
        break;
      case 'picked_up':
      case 'in_transit':
        statusIcon = Icons.local_shipping_outlined;
        break;
      case 'delivered':
      case 'completed':
        statusIcon = Icons.check_circle_outline;
        break;
      case 'cancelled':
        statusIcon = Icons.cancel_outlined;
        break;
    }

    return SliverToBoxAdapter(
      child: Container(
        height: 240,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              statusColor,
              Color.lerp(statusColor, Colors.black, 0.2)!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, size: 48, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                statusText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ID: ${transaction.id.substring(0, 8)}...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernProgressIndicator(TransactionModel transaction) {
    final steps = ['Confirmed', 'Paid', 'Shipped', 'Delivered', 'Done'];
    int currentStep = 0;

    if (transaction.shippingStatus == 'cancelled') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade100),
        ),
        child: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 12),
            Text(
              'Transaction Cancelled',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    switch (transaction.shippingStatus) {
      case 'pending':
        currentStep = transaction.paymentStatus == 'paid' ? 1 : 0;
        break;
      case 'picked_up':
      case 'in_transit':
        currentStep = 2;
        break;
      case 'delivered':
        currentStep = 3;
        break;
      case 'completed':
        currentStep = 4;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (index) {
          final isCompleted = index <= currentStep;
          final isCurrent = index == currentStep;
          
          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 2,
                        color: index == 0 
                          ? Colors.transparent 
                          : (index <= currentStep ? AppTheme.primary500 : AppTheme.neutral200),
                      ),
                    ),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isCompleted ? AppTheme.primary500 : Colors.white,
                        border: Border.all(
                          color: isCompleted ? AppTheme.primary500 : AppTheme.neutral300,
                          width: 2,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: isCompleted
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : null,
                    ),
                    Expanded(
                      child: Container(
                        height: 2,
                        color: index == steps.length - 1 
                          ? Colors.transparent 
                          : (index < currentStep ? AppTheme.primary500 : AppTheme.neutral200),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  steps[index],
                  style: TextStyle(
                    fontSize: 11,
                    color: isCurrent 
                      ? AppTheme.primary700 
                      : (isCompleted ? AppTheme.neutral700 : AppTheme.neutral400),
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.neutral800,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInfoRow(String label, String value, {bool copyable = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.neutral600,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: valueColor ?? AppTheme.neutral900,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (copyable) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard')),
                      );
                    },
                    child: const Icon(Icons.copy, size: 16, color: AppTheme.primary500),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionInfoCard(TransactionModel transaction) {
    return _buildCard(
      child: Column(
        children: [
          _buildInfoRow('ID', transaction.id, copyable: true),
          _buildInfoRow('Created At', _formatDateTime(transaction.createdAt)),
          _buildInfoRow(
            'Payment Status', 
            transaction.paymentStatusDisplay,
            valueColor: transaction.paymentStatus == 'paid' ? AppTheme.success : AppTheme.warning,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: _buildInfoRow('Payment Method', transaction.paymentMethodDisplay),
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfoCard(TransactionModel transaction) {
    return FutureBuilder<ListingModel?>(
      future: _listingService.getListing(transaction.listingId),
      builder: (context, snapshot) {
        final listing = snapshot.data;
        if (listing == null) {
          return _buildCard(child: const Center(child: CircularProgressIndicator()));
        }

        return _buildCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  listing.imageUrls.isNotEmpty ? listing.imageUrls.first : '',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 80,
                    color: AppTheme.neutral100,
                    child: const Icon(Icons.image_not_supported, color: AppTheme.neutral400),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.getCategoryColor(listing.wasteType).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        listing.wasteType,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.getCategoryColor(listing.wasteType),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'RM ${listing.pricePerUnit}/${listing.unit} x ${listing.quantity}',
                      style: const TextStyle(
                        color: AppTheme.neutral600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAmountCard(TransactionModel transaction) {
    return _buildCard(
      child: Column(
        children: [
          _buildInfoRow('Product Amount', 'RM ${transaction.amount.toStringAsFixed(2)}'),
          _buildInfoRow('Platform Fee (3%)', 'RM ${transaction.platformFee.toStringAsFixed(2)}'),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'RM ${transaction.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard(String userId) {
    return FutureBuilder<UserModel?>(
      future: _userService.getUserById(userId),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) {
          return _buildCard(child: const SizedBox(height: 60)); // Placeholder
        }

        return _buildCard(
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.neutral200),
                ),
                child: ClipOval(
                  child: user.photoURL != null
                      ? Image.network(user.photoURL!, fit: BoxFit.cover)
                      : const Icon(Icons.person, color: AppTheme.neutral400),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName ?? 'User',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '4.8 (Excellent)',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.neutral600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: user.contact != null
                    ? () => _makePhoneCall(user.contact!)
                    : null,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone, color: AppTheme.primary600),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  // TODO: Navigate to chat
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chat coming soon')),
                  );
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE3F2FD),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chat_bubble, color: Colors.blue),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogisticsInfoCard(TransactionModel transaction) {
    final bool isSelfCollect = DeliveryConfig.isSelfCollect(transaction.deliveryMethod);
    
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSelfCollect ? Icons.store_mall_directory : Icons.local_shipping,
                color: isSelfCollect ? AppTheme.primary600 : Colors.blue,
              ),
              const SizedBox(width: 12),
              Text(
                isSelfCollect ? 'Self Collect' : 'Delivery',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isSelfCollect) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppTheme.primary700),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please contact seller for pickup address and arrange time.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.primary800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            if (transaction.shippingInfo != null)
               _buildInfoRow('Tracking No.', transaction.shippingInfo!['trackingNumber'] ?? '--', copyable: true),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      transaction.shippingInfo != null 
                          ? 'Shipped, please track.'
                          : 'Waiting for seller to ship.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentProofCard(TransactionModel transaction) {
    return GestureDetector(
      onTap: () => _showImageDialog(transaction.paymentProofUrl!),
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            transaction.paymentProofUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLogisticsTimeline(TransactionModel transaction) {
    return StreamBuilder<List<LogisticsUpdateModel>>(
      stream: _transactionService.getLogisticsUpdates(widget.transactionId),
      builder: (context, snapshot) {
        final updates = snapshot.data ?? [];
        if (updates.isEmpty) {
          return _buildCard(
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text('No updates yet', style: TextStyle(color: Colors.grey))),
            ),
          );
        }

        return _buildCard(
          child: Column(
            children: updates.asMap().entries.map((entry) {
              final index = entry.key;
              final update = entry.value;
              final isLast = index == updates.length - 1;
              final isFirst = index == 0;

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isFirst ? AppTheme.primary500 : AppTheme.neutral300,
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: AppTheme.neutral200,
                              ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              update.statusDisplay,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isFirst ? AppTheme.neutral900 : AppTheme.neutral600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDateTime(update.createdAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.neutral500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              update.description,
                              style: const TextStyle(
                                color: AppTheme.neutral700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildBottomActionBar(TransactionModel transaction, bool isBuyer) {
    List<Widget> buttons = [];

    if (transaction.canPayment() && isBuyer) {
      buttons.add(_buildActionButton(
        'Upload Proof',
        Colors.green,
        () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BBXUploadPaymentScreen(transactionId: transaction.id),
          ),
        ),
      ));
      buttons.add(const SizedBox(width: 12));
      buttons.add(_buildActionButton(
        'Cancel',
        Colors.red,
        () => _cancelTransaction(transaction),
        isOutlined: true,
      ));
    } else if (transaction.canPickup() && !isBuyer) {
      buttons.add(_buildActionButton(
        'Mark Picked Up',
        Colors.orange,
        () => _markAsPickedUp(transaction),
      ));
    } else if ((transaction.shippingStatus == 'picked_up' || transaction.shippingStatus == 'in_transit') && !isBuyer) {
      buttons.add(_buildActionButton(
        'Update Logistics',
        Colors.blue,
        () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BBXUpdateLogisticsScreen(transactionId: transaction.id),
          ),
        ),
      ));
    } else if (transaction.canConfirmDelivery() && isBuyer) {
      buttons.add(_buildActionButton(
        'Confirm Receipt',
        Colors.green,
        () => _confirmDelivery(transaction),
      ));
    } else if (transaction.canComplete()) {
      buttons.add(_buildActionButton(
        'Complete Order',
        Colors.green,
        () => _completeTransaction(transaction),
      ));
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(children: buttons.map((e) => e is SizedBox ? e : Expanded(child: e)).toList()),
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onPressed, {bool isOutlined = false}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isOutlined ? Colors.white : color,
        foregroundColor: isOutlined ? color : Colors.white,
        elevation: isOutlined ? 0 : 4,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isOutlined ? BorderSide(color: color) : BorderSide.none,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Helper functions
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
              top: 0, right: 0,
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
    if (await canLaunchUrl(phoneUri)) await launchUrl(phoneUri);
  }

  Future<void> _markAsPickedUp(TransactionModel transaction) async {
    try {
      await _transactionService.markAsPickedUp(transaction.id, null);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as Picked Up')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _confirmDelivery(TransactionModel transaction) async {
    try {
      await _transactionService.confirmDelivery(transaction.id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Confirmed Receipt')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _completeTransaction(TransactionModel transaction) async {
      try {
      await _transactionService.completeTransaction(transaction.id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completed')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _cancelTransaction(TransactionModel transaction) async {
     try {
        await _transactionService.cancelTransaction(transaction.id, "User cancelled");
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cancelled')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
  }
}
