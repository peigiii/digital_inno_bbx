import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import 'package:lottie/lottie.dart';

/// 支付确认页面
/// 显示支付结果（成功或失败）
class BBXPaymentConfirmationScreen extends StatefulWidget {
  final String planName;
  final int planPrice;
  final String paymentMethod;
  final bool success;

  const BBXPaymentConfirmationScreen({
    Key? key,
    required this.planName,
    required this.planPrice,
    required this.paymentMethod,
    required this.success,
  }) : super(key: key);

  @override
  State<BBXPaymentConfirmationScreen> createState() =>
      _BBXPaymentConfirmationScreenState();
}

class _BBXPaymentConfirmationScreenState
    extends State<BBXPaymentConfirmationScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  bool isUpdatingSubscription = false;

  @override
  void initState() {
    super.initState();
    if (widget.success) {
      _updateSubscription();
    }
  }

  Future<void> _updateSubscription() async {
    if (currentUser == null) return;

    setState(() {
      isUpdatingSubscription = true;
    });

    try {
      print('🔄 [确认页面] 更新订阅状态...');

      // 更新用户订阅信息
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update({
        'subscriptionPlan': widget.planName.toLowerCase().replaceAll(' ', '_'),
        'subscriptionUpdatedAt': FieldValue.serverTimestamp(),
        'subscriptionStatus': 'active',
        'subscriptionExpiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 365)), // 1年
        ),
      }).timeout(const Duration(seconds: 10));

      // 记录支付交易
      await FirebaseFirestore.instance.collection('subscription_payments').add({
        'userId': currentUser!.uid,
        'userEmail': currentUser!.email,
        'planName': widget.planName,
        'amount': widget.planPrice,
        'paymentMethod': widget.paymentMethod,
        'status': 'completed',
        'paidAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));

      print('✅ [确认页面] 订阅更新成功');
    } catch (e) {
      print('❌ [确认页面] 更新订阅失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新订阅失败: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isUpdatingSubscription = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // 禁用返回按钮
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: isUpdatingSubscription
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        '正在激活订阅...',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const SizedBox(height: 40),

                            // Success/failure animation
                            if (widget.success)
                              Icon(
                                Icons.check_circle,
                                size: 120,
                                color: AppTheme.success,
                              )
                            else
                              Icon(
                                Icons.error,
                                size: 120,
                                color: AppTheme.error,
                              ),

                            const SizedBox(height: 32),

                            // Title
                            Text(
                              widget.success ? '支付成功！' : '支付失败',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: widget.success
                                    ? AppTheme.success
                                    : AppTheme.error,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Subtitle
                            Text(
                              widget.success
                                  ? '恭喜！您已成功订阅 ${widget.planName} 计划'
                                  : '支付未能完成，请重试',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),

                            const SizedBox(height: 40),

                            // Payment details card
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Column(
                                children: [
                                  _buildDetailRow(
                                    '订阅计划',
                                    widget.planName,
                                    Icons.workspace_premium,
                                  ),
                                  const Divider(height: 24),
                                  _buildDetailRow(
                                    '支付金额',
                                    'RM ${widget.planPrice.toStringAsFixed(2)}',
                                    Icons.attach_money,
                                  ),
                                  const Divider(height: 24),
                                  _buildDetailRow(
                                    '支付方式',
                                    _getPaymentMethodName(widget.paymentMethod),
                                    Icons.payment,
                                  ),
                                  const Divider(height: 24),
                                  _buildDetailRow(
                                    '交易时间',
                                    _formatDateTime(DateTime.now()),
                                    Icons.access_time,
                                  ),
                                  if (widget.success) ...[
                                    const Divider(height: 24),
                                    _buildDetailRow(
                                      '有效期',
                                      '${_formatDate(DateTime.now())} - ${_formatDate(DateTime.now().add(const Duration(days: 365)))}',
                                      Icons.calendar_today,
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            if (widget.success) ...[
                              const SizedBox(height: 32),

                              // Benefits reminder
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.lightbulb,
                                          color: AppTheme.primary,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          '订阅权益已激活',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '您现在可以享受 ${widget.planName} 计划的所有功能和权益。',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Action buttons
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          if (widget.success) ...[
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    '/profile',
                                    (route) => false,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  '返回个人中心',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    '/home',
                                    (route) => false,
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primary,
                                  side: const BorderSide(color: AppTheme.primary),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  '返回首页',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  '重试支付',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    '/home',
                                    (route) => false,
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey[600],
                                  side: BorderSide(color: Colors.grey[400]!),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  '稍后再说',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'fpx':
        return 'FPX 网银转账';
      case 'ewallet':
        return '电子钱包';
      case 'credit_card':
        return '信用卡/借记卡';
      case 'cash':
        return '现金支付';
      default:
        return method;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
