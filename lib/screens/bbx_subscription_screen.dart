import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BBXSubscriptionScreen extends StatefulWidget {
  const BBXSubscriptionScreen({super.key});

  @override
  State<BBXSubscriptionScreen> createState() => _BBXSubscriptionScreenState();
}

class _BBXSubscriptionScreenState extends State<BBXSubscriptionScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String currentPlan = 'free';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
  }

  Future<void> _loadSubscriptionData() async {
    print('🔍 [Subscription Page] Starting to load subscription data...');

    if (currentUser == null) {
      print('❌ [Subscription Page] User not logged in');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      return;
    }

    print('👤 [Subscription Page] User logged in: ${currentUser!.email}');
    print('🔄 [Subscription Page] Querying Firestore user document...');

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('⏱️ [Subscription Page] Firestore query timed out (10s)');
              throw Exception('Query timed out, please check network connection');
            },
          );

      print('📄 [Subscription Page] Document query completed, exists: ${userDoc.exists}');

      if (!mounted) {
        print('⚠️ [Subscription Page] Widget disposed, stopping update');
        return;
      }

      if (userDoc.exists) {
        final plan = userDoc.data()?['subscriptionPlan'] ?? 'free';
        print('📋 [Subscription Page] Current plan: $plan');
        setState(() {
          currentPlan = plan;
          isLoading = false;
        });
      } else {
        print('⚠️ [Subscription Page] User document does not exist, using default plan');
        setState(() {
          currentPlan = 'free';
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ [Subscription Page] Load failed: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load subscription info: $e'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _selectPlan(String planName, int price) async {
    print('🎯 [Subscription Page] User selected plan: $planName (RM $price)');

    if (currentUser == null) {
      print('❌ [Subscription Page] User not logged in');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login first'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (price == 0) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Free Plan'),
          content: const Text('You will use the Free plan. You can upgrade anytime.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );

      if (confirm != true) {
        print('🚫 [Subscription Page] User cancelled selection');
        return;
      }

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .update({
          'subscriptionPlan': 'free',
          'subscriptionUpdatedAt': FieldValue.serverTimestamp(),
          'subscriptionStatus': 'active',
        }).timeout(const Duration(seconds: 10));

        print('✅ [Subscription Page] Free plan activated');

        if (mounted) {
          setState(() {
            currentPlan = 'free';
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Selected Free plan'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('❌ [Subscription Page] Update failed: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to select plan: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      return;
    }

    print('💳 [Subscription Page] Navigating to payment page...');

    if (mounted) {
      Navigator.pushNamed(
        context,
        '/payment',
        arguments: {
          'planName': planName,
          'planPrice': price,
          'planPeriod': '/mo',
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Subscription Plan'),
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Plan'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose the plan that fits you',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Current Plan: ${_getPlanDisplayName(currentPlan)}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Free Plan
            _buildPlanCard(
              'Free',
              'RM 0',
              '/mo',
              [
                '3-day trial (Personal)',
                '7-day trial (Company)',
                'Max 5 listings',
                'Basic features',
                'Community Support',
              ],
              currentPlan == 'free',
              Colors.grey,
              0,
            ),

            // Basic Plan
            _buildPlanCard(
              'Basic',
              'RM 99',
              '/mo',
              [
                'Unlimited listings',
                'Priority matching',
                'Basic reports',
                'Email support',
                'Data export',
              ],
              currentPlan == 'basic',
              Colors.blue,
              99,
            ),

            // Professional Plan
            _buildPlanCard(
              'Professional',
              'RM 199',
              '/mo',
              [
                'All Basic features',
                'ESG Compliance Report',
                'Advanced Analytics',
                'Logistics Optimization',
                'Dedicated Support',
                'API Access',
              ],
              currentPlan == 'professional',
              const Color(0xFF4CAF50),
              199,
            ),

            // Enterprise Plan
            _buildPlanCard(
              'Enterprise',
              'RM 499',
              '/mo',
              [
                'All Professional features',
                'Multi-user account',
                'Custom Reports',
                'White-label Solution',
                'Dedicated Account Manager',
                'Priority Tech Support',
                'SLA Guarantee',
              ],
              currentPlan == 'enterprise',
              Colors.purple,
              499,
            ),

            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Payment Instructions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• After selecting a plan, please contact admin to complete payment\n'
                    '• Supports Bank Transfer, E-Wallet, etc.\n'
                    '• Activation within 24 hours of payment\n'
                    '• Upgrade or downgrade anytime',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPlanDisplayName(String plan) {
    switch (plan.toLowerCase()) {
      case 'free':
        return 'Free';
      case 'basic':
        return 'Basic (RM 99/mo)';
      case 'professional':
        return 'Professional (RM 199/mo)';
      case 'enterprise':
        return 'Enterprise (RM 499/mo)';
      default:
        return 'Free';
    }
  }

  Widget _buildPlanCard(
    String name,
    String price,
    String period,
    List<String> features,
    bool isCurrentPlan,
    Color color,
    int priceValue,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isCurrentPlan ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrentPlan
            ? BorderSide(color: color, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          price,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          period,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (isCurrentPlan)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Current Plan',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            ...features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: color, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          feature,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isCurrentPlan
                    ? null
                    : () => _selectPlan(name, priceValue),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCurrentPlan ? Colors.grey : color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isCurrentPlan ? 'Current Plan' : 'Select Plan',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
