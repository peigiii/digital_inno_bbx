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

/// My Transactions Screen
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
        title: const Text('My Transactions'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: _currentUserId == null
          ? const Center(child: Text('Please login first'))
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

  /// Build Transaction List
  Widget _buildTransactionList(String filterType) {
    return StreamBuilder<List<TransactionModel>>(
      stream: _getTransactionsStream(filterType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Load failed: ${snapshot.error}'));
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

  /// Get Transactions Stream
  Stream<List<TransactionModel>> _getTransactionsStream(String filterType) {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    // Merge Buyer and Seller Transactions
    final buyerStream = _transactionService.getMyBuyerTransactions(_currentUserId!);
    final sellerStream = _transactionService.getMySellerTransactions(_currentUserId!);

    // Merge Streams and Filter
    return buyerStream.asyncMap((buyerTransactions) async {
      final sellerTransactions = await sellerStream.first;
      final allTransactions = [...buyerTransactions, ...sellerTransactions];

      // Filter by Type
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

      // Sort by Time
      filtered.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));

      return filtered;
    });
  }

  /// Build Transaction Card
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
              // Top: Transaction ID + Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ID: ${transaction.id.substring(transaction.id.length - 6)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  _buildStatusChip(transaction.shippingStatus),
                ],
              ),
              const SizedBox(height: 12),

              // Listing Info
              FutureBuilder<ListingModel?>(
                future: _listingService.getListing(transaction.listingId),
                builder: (context, snapshot) {
                  final listing = snapshot.data;
                  return Row(
                    children: [
                      // Image
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

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              listing?.title ?? 'Loading...',
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

              // Amount Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amount',
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
                        'Fee',
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
                        'Total',
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

              // Time Info
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Created: ${_formatDate(transaction.createdAt)}',
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
                      'Pickup: ${_formatDate(transaction.pickupScheduledDate)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 12),

              // Counterparty Info
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
                        '${isBuyer ? 'Seller' : 'Buyer'}: ${otherUser?.displayName ?? 'Loading...'}',
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

              // Action Buttons
              _buildActionButtons(transaction, isBuyer),
            ],
          ),
        ),
      ),
    );
  }

  /// Build Status Chip
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

  /// Build Action Buttons
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
          label: const Text('Upload Payment'),
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
          child: const Text('View Details'),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: buttons,
    );
  }

  /// Format Date
  String _formatDate(DateTime? date) {
    if (date == null) return '--';
    return DateFormat('MM-dd HH:mm').format(date);
  }

  /// Get Status Text
  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'picked_up':
        return 'Picked Up';
      case 'in_transit':
        return 'In Transit';
      case 'delivered':
        return 'Delivered';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }

  /// Get Empty Message
  String _getEmptyMessage(String filterType) {
    switch (filterType) {
      case 'active':
        return 'No active transactions';
      case 'completed':
        return 'No completed transactions';
      case 'cancelled':
        return 'No cancelled transactions';
      default:
        return 'No transactions';
    }
  }
}
