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
    if (currentUser == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (userDoc.exists && mounted) {
        setState(() {
          currentPlan = userDoc.data()?['subscriptionPlan'] ?? 'free';
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading subscription: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _selectPlan(String planName, int price) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('确认选择 $planName'),
        content: Text(
          price > 0
              ? '您将订阅 $planName 计划，价格为 RM $price/年。\n\n请联系管理员完成支付。'
              : '您将使用免费计划。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
            ),
            child: const Text('确认'),
          ),
        ],
      ),
    );

    if (confirm == true && currentUser != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .update({
          'subscriptionPlan': planName.toLowerCase().replaceAll(' ', '_'),
          'subscriptionUpdatedAt': FieldValue.serverTimestamp(),
        });

        setState(() {
          currentPlan = planName.toLowerCase().replaceAll(' ', '_');
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已选择 $planName 计划'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('选择计划失败: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('订阅计划'),
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
        title: const Text('订阅计划'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '选择适合您的计划',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '当前计划: ${_getPlanDisplayName(currentPlan)}',
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
              '/月',
              [
                '3天试用（个人）',
                '7天试用（公司）',
                '最多 5 个列表',
                '基础功能',
                '社区支持',
              ],
              currentPlan == 'free',
              Colors.grey,
              0,
            ),

            // Basic Plan
            _buildPlanCard(
              'Basic',
              'RM 99',
              '/年',
              [
                '无限列表',
                '优先匹配',
                '基础报告',
                '邮件支持',
                '数据导出',
              ],
              currentPlan == 'basic',
              Colors.blue,
              99,
            ),

            // Professional Plan
            _buildPlanCard(
              'Professional',
              'RM 199',
              '/年',
              [
                'Basic 所有功能',
                'ESG 合规报告',
                '高级数据分析',
                '物流优化',
                '专属客服',
                'API 访问',
              ],
              currentPlan == 'professional',
              const Color(0xFF4CAF50),
              199,
            ),

            // Enterprise Plan
            _buildPlanCard(
              'Enterprise',
              'RM 499',
              '/年',
              [
                'Professional 所有功能',
                '多用户账号',
                '定制化报告',
                '白标解决方案',
                '专属客户经理',
                '优先技术支持',
                'SLA 保证',
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
                        '支付说明',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• 选择计划后，请联系管理员完成支付\n'
                    '• 支持银行转账、支付宝等方式\n'
                    '• 付款后 24 小时内激活\n'
                    '• 可随时升级或降级计划',
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
        return 'Basic (RM 99/年)';
      case 'professional':
        return 'Professional (RM 199/年)';
      case 'enterprise':
        return 'Enterprise (RM 499/年)';
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
                      '当前计划',
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
                  isCurrentPlan ? '当前计划' : '选择计划',
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
