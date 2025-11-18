import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/payment_service.dart';
import '../theme/app_theme.dart';

/// 支付页面
/// 用户选择订阅计划后进入此页面完成支付
class BBXPaymentScreen extends StatefulWidget {
  final String planName;
  final int planPrice;
  final String planPeriod;

  const BBXPaymentScreen({
    Key? key,
    required this.planName,
    required this.planPrice,
    required this.planPeriod,
  }) : super(key: key);

  @override
  State<BBXPaymentScreen> createState() => _BBXPaymentScreenState();
}

class _BBXPaymentScreenState extends State<BBXPaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  String? selectedPaymentMethod;
  bool isProcessing = false;
  bool agreedToTerms = false;

  @override
  Widget build(BuildContext context) {
    final fees = _paymentService.calculateFees(widget.planPrice.toDouble());

    return Scaffold(
      appBar: AppBar(
        title: const Text('支付订单'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Order summary card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '订单摘要',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryRow(
                    '订阅计划',
                    widget.planName,
                    isTitle: true,
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    '订阅周期',
                    widget.planPeriod,
                  ),
                  const Divider(height: 24),
                  _buildSummaryRow(
                    '订阅费用',
                    'RM ${widget.planPrice.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    '平台费 (${fees['platformFee']! / widget.planPrice * 100}%)',
                    'RM ${fees['platformFee']!.toStringAsFixed(2)}',
                    isSmall: true,
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    '支付网关费',
                    'RM ${fees['paymentGatewayFee']!.toStringAsFixed(2)}',
                    isSmall: true,
                  ),
                  const Divider(height: 24),
                  _buildSummaryRow(
                    '总计',
                    'RM ${fees['buyerPays']!.toStringAsFixed(2)}',
                    isTotal: true,
                  ),
                ],
              ),
            ),

            // Payment methods
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '选择支付方式',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._paymentService.getPaymentMethods().map((method) {
                    if (!method['enabled']) return const SizedBox.shrink();

                    return _buildPaymentMethodOption(
                      id: method['id'],
                      name: method['name'],
                      description: method['description'],
                      icon: _getPaymentIcon(method['icon']),
                    );
                  }).toList(),
                ],
              ),
            ),

            // Terms agreement
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: agreedToTerms,
                    onChanged: (value) {
                      setState(() {
                        agreedToTerms = value ?? false;
                      });
                    },
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          agreedToTerms = !agreedToTerms;
                        });
                      },
                      child: const Text(
                        '我已阅读并同意订阅服务条款和隐私政策',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Pay button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isProcessing ||
                          selectedPaymentMethod == null ||
                          !agreedToTerms
                      ? null
                      : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          '立即支付 RM ${fees['buyerPays']!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isTitle = false,
    bool isSmall = false,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal
                ? 18
                : isSmall
                    ? 13
                    : 15,
            fontWeight: isTotal || isTitle ? FontWeight.bold : FontWeight.normal,
            color: isSmall ? Colors.grey[600] : Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal
                ? 18
                : isSmall
                    ? 13
                    : 15,
            fontWeight: isTotal || isTitle ? FontWeight.bold : FontWeight.normal,
            color: isTotal
                ? AppTheme.primary
                : isSmall
                    ? Colors.grey[600]
                    : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodOption({
    required String id,
    required String name,
    required String description,
    required IconData icon,
  }) {
    final isSelected = selectedPaymentMethod == id;

    return InkWell(
      onTap: () {
        setState(() {
          selectedPaymentMethod = id;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? AppTheme.primary.withOpacity(0.05) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? AppTheme.primary : Colors.grey[600],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppTheme.primary : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  IconData _getPaymentIcon(String iconName) {
    switch (iconName) {
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

  Future<void> _processPayment() async {
    if (currentUser == null) {
      _showError('请先登录');
      return;
    }

    if (selectedPaymentMethod == null) {
      _showError('请选择支付方式');
      return;
    }

    if (!agreedToTerms) {
      _showError('请同意服务条款');
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      print('🔄 [支付页面] 开始处理支付...');
      print('📋 计划: ${widget.planName}');
      print('💰 金额: RM ${widget.planPrice}');
      print('💳 支付方式: $selectedPaymentMethod');

      // 模拟支付处理（实际应调用 PaymentService）
      await Future.delayed(const Duration(seconds: 2));

      // TODO: 实际支付集成
      // final result = await _paymentService.createPaymentIntent(
      //   amount: widget.planPrice.toDouble(),
      //   currency: 'myr',
      //   transactionId: 'subscription_${DateTime.now().millisecondsSinceEpoch}',
      // );

      print('✅ [支付页面] 支付成功');

      if (mounted) {
        // 导航到确认页面
        Navigator.pushReplacementNamed(
          context,
          '/payment-confirmation',
          arguments: {
            'planName': widget.planName,
            'planPrice': widget.planPrice,
            'paymentMethod': selectedPaymentMethod,
            'success': true,
          },
        );
      }
    } catch (e) {
      print('❌ [支付页面] 支付失败: $e');
      _showError('支付失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
