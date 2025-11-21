import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

/// 发票查看页面
/// 显示订阅支付的详细发票信�?
class BBXInvoiceScreen extends StatelessWidget {
  final String paymentId;

  const BBXInvoiceScreen({
    Key? key,
    required this.paymentId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('支付发票'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              _shareInvoice(context);
            },
            tooltip: '分享发票',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              _downloadInvoice(context);
            },
            tooltip: '下载发票',
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
                  Text('加载失败: ${snapshot.error}'),
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
                  Text('发票不存�?),
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

    // 计算费用
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
                      '订阅支付发票',
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
                      '测试发票',
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
            _buildInfoRow('发票编号', paymentId),
            const SizedBox(height: 12),
            _buildInfoRow(
              '开票日�?,
              createdAt != null ? _formatDate(createdAt.toDate()) : 'N/A',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              '支付日期',
              paidAt != null ? _formatDate(paidAt.toDate()) : 'N/A',
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            // Customer info
            const Text(
              '客户信息',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('用户 ID', userId),
            const SizedBox(height: 12),
            _buildInfoRow('邮箱', userEmail),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            // Items
            const Text(
              '项目明细',
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
                              '$planName 订阅计划',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '订阅周期�?�?,
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
            _buildCalculationRow('小计', subtotal, false),
            const SizedBox(height: 8),
            _buildCalculationRow('平台服务�?(3%)', platformFee, false),
            const SizedBox(height: 8),
            _buildCalculationRow('支付网关�?(1.5%)', paymentGatewayFee, false),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            _buildCalculationRow('总计', total, true),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            // Payment method
            const Text(
              '支付方式',
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
                    '备注',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '此发票为订阅服务支付凭证。如有任何疑问，请联系客服�?,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                  if (isSimulated) ...[
                    const SizedBox(height: 8),
                    Text(
                      '注意：此为测试环境生成的发票，仅供开发测试使用�?,
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
        return 'FPX 网银转账';
      case 'ewallet':
        return '电子钱包';
      case 'credit_card':
        return '信用�?借记�?;
      case 'cash':
        return '现金支付';
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
        content: Text('分享功能即将推出'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _downloadInvoice(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF 下载功能即将推出'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
