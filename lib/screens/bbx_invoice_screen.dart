import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

/// Invoice Details Screen
/// Displays detailed invoice information for subscription payments
class BBXInvoiceScreen extends StatelessWidget {
  final String paymentId;

  const BBXInvoiceScreen({
    super.key,
    required this.paymentId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Invoice'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              _shareInvoice(context);
            },
            tooltip: 'Share Invoice',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              _downloadInvoice(context);
            },
            tooltip: 'Download Invoice',
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('subscription_payments')
            .doc(paymentId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Load failed: ${snapshot.error}'),
                ],
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Invoice not found'),
                ],
              ),
            );
          }

          final payment = snapshot.data!.data() as Map<String, dynamic>;
          return _buildInvoiceContent(context, payment);
        },
      ),
    );
  }

  Widget _buildInvoiceContent(
      BuildContext context, Map<String, dynamic> payment) {
    final planName = payment['planName'] ?? 'Unknown';
    final amount = (payment['amount'] ?? 0).toDouble();
    final paymentMethod = payment['paymentMethod'] ?? 'Unknown';
    final createdAt = payment['createdAt'] as Timestamp?;
    final paidAt = payment['paidAt'] as Timestamp?;
    final userId = payment['userId'] ?? '';
    final userEmail = payment['userEmail'] ?? '';
    final isSimulated = payment['simulatedPayment'] == true;

    // Calculate Fees
    final platformFee = amount * 0.03;
    final paymentGatewayFee = amount * 0.015;
    final subtotal = amount;
    final total = amount + platformFee + paymentGatewayFee;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BBX - Borneo Biomass Exchange',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Subscription Invoice',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                if (isSimulated)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Test Invoice',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),
            const Divider(thickness: 2),
            const SizedBox(height: 24),

            // Invoice details
            _buildInfoRow('Invoice No', paymentId),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Invoice Date',
              createdAt != null ? _formatDate(createdAt.toDate()) : 'N/A',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Payment Date',
              paidAt != null ? _formatDate(paidAt.toDate()) : 'N/A',
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            // Customer info
            const Text(
              'Customer Info',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('User ID', userId),
            const SizedBox(height: 12),
            _buildInfoRow('Email', userEmail),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            // Items
            const Text(
              'Item Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$planName Subscription Plan',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Subscription Period',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'RM ${subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Calculation
            _buildCalculationRow('Subtotal', subtotal, false),
            const SizedBox(height: 8),
            _buildCalculationRow('Platform Fee (3%)', platformFee, false),
            const SizedBox(height: 8),
            _buildCalculationRow('Gateway Fee (1.5%)', paymentGatewayFee, false),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            _buildCalculationRow('Total', total, true),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            // Payment method
            const Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _getPaymentIcon(paymentMethod),
                    color: AppTheme.primary,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _getPaymentMethodName(paymentMethod),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Remarks',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This invoice serves as proof of payment. Contact support for any questions.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                  if (isSimulated) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Note: This is a test invoice generated in a development environment.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildCalculationRow(String label, double amount, bool isTotal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.black : Colors.grey[700],
          ),
        ),
        Text(
          'RM ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isTotal ? 20 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal ? AppTheme.primary : Colors.black87,
          ),
        ),
      ],
    );
  }

  IconData _getPaymentIcon(String method) {
    switch (method) {
      case 'fpx':
        return Icons.account_balance;
      case 'ewallet':
        return Icons.wallet;
      case 'credit_card':
        return Icons.credit_card;
      case 'cash':
        return Icons.money;
      default:
        return Icons.payment;
    }
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'fpx':
        return 'FPX Online Banking';
      case 'ewallet':
        return 'E-Wallet';
      case 'credit_card':
        return 'Credit/Debit Card';
      case 'cash':
        return 'Cash Payment';
      default:
        return method;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _shareInvoice(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share feature coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _downloadInvoice(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF Download feature coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
