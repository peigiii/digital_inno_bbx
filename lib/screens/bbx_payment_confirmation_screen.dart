import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import 'package:lottie/lottie.dart';

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
    debugPrint('🎬 [Page] initState - success: ${widget.success}');
    if (widget.success) {
      _updateSubscription();
    }
  }

  Future<void> _updateSubscription() async {
    if (currentUser == null) {
      debugPrint('?[Page] User not logged in');
      return;
    }

    debugPrint('👤 [Page] Current user: ${currentUser!.email} (${currentUser!.uid})');

    setState(() {
      isUpdatingSubscription = true;
    });

    try {
      debugPrint('🔄 [Page] Updating subscription status...');
      debugPrint('📋 Plan: ${widget.planName}');
      debugPrint('💰 Amount: ${widget.planPrice}');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update({
        'subscriptionPlan': widget.planName.toLowerCase().replaceAll(' ', '_'),
        'subscriptionUpdatedAt': FieldValue.serverTimestamp(),
        'subscriptionStatus': 'active',
        'subscriptionExpiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 365)),
        ),
      }).timeout(const Duration(seconds: 10));

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

      debugPrint('?[Page] Subscription updated successfully');
      debugPrint('?[Page] Payment record saved to subscription_payments collection');
    } catch (e) {
      debugPrint('?[Page] Update failed: $e');
      debugPrint('?[Page] Error details: ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update failed: $e'),
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
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async => false,
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
                        'Activating subscription...',
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
                              widget.success ? 'Payment Successful' : 'Payment Failed',
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
                                  ? 'Congratulations! You have subscribed to ${widget.planName} plan'
                                  : 'Payment incomplete, please try again',
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
                                    'Subscription Plan',
                                    widget.planName,
                                    Icons.workspace_premium,
                                  ),
                                  const Divider(height: 24),
                                  _buildDetailRow(
                                    'Payment Amount',
                                    'RM ${widget.planPrice.toStringAsFixed(2)}',
                                    Icons.attach_money,
                                  ),
                                  const Divider(height: 24),
                                  _buildDetailRow(
                                    'Payment Method',
                                    _getPaymentMethodName(widget.paymentMethod),
                                    Icons.payment,
                                  ),
                                  const Divider(height: 24),
                                  _buildDetailRow(
                                    'Transaction Time',
                                    _formatDateTime(DateTime.now()),
                                    Icons.access_time,
                                  ),
                                  if (widget.success) ...[
                                    const Divider(height: 24),
                                    _buildDetailRow(
                                      'Valid until',
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
                                          'Subscription benefits activated',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'You can now enjoy all features of ${widget.planName} plan',
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
                                  debugPrint('🏠 [Page] Navigating to Profile');
                                  Navigator.of(context).popUntil((route) => route.isFirst);
                                  Navigator.of(context).pushReplacementNamed('/profile');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Back to Profile',
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
                                  debugPrint('🏠 [Page] Navigating to Home');
                                  Navigator.of(context).popUntil((route) => route.isFirst);
                                  Navigator.of(context).pushReplacementNamed('/home');
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primary,
                                  side: const BorderSide(color: AppTheme.primary),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Back to Home',
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
                                  debugPrint('🔄 [Page] Retrying payment');
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
                                  'Retry Payment',
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
                                  debugPrint('🏠 [Page] Later, returning to Home');
                                  Navigator.of(context).popUntil((route) => route.isFirst);
                                  Navigator.of(context).pushReplacementNamed('/home');
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey[600],
                                  side: BorderSide(color: Colors.grey[400]!),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Later',
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
