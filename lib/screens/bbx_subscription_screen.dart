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
  String currentPlan = 'Free';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
  }

  Future<void> _loadSubscriptionData() async {
    if (currentUser == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          currentPlan = doc.data()?['subscriptionPlan'] ?? 'Free';
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _upgradePlan(String plan, double price) async {
    if (currentUser == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认升级'),
        content: Text('确定要升级到 $plan 计划吗？\n价格：RM $price/月'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .update({'subscriptionPlan': plan});

        setState(() {
          currentPlan = plan;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('成功升级到 $plan 计划'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('升级失败: $e'),
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
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
            Text(
              '当前计划: $currentPlan',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildPlanCard(
              'Free',
              0,
              [
                '基础匹配功能',
                '每月 5 次报价',
                '标准客服支持',
                '基础分析报告',
              ],
              Colors.grey,
              isCurrentPlan: currentPlan == 'Free',
            ),
            _buildPlanCard(
              'Basic',
              99,
              [
                'Free 的所有功能',
                '每月 20 次报价',
                '优先匹配',
                '高级分析报告',
                '邮件支持',
              ],
              Colors.blue,
              isCurrentPlan: currentPlan == 'Basic',
            ),
            _buildPlanCard(
              'Professional',
              199,
              [
                'Basic 的所有功能',
                '无限报价',
                '实时价格预测',
                'API 访问',
                '专属客户经理',
                '优先技术支持',
              ],
              Colors.purple,
              isCurrentPlan: currentPlan == 'Professional',
            ),
            _buildPlanCard(
              'Enterprise',
              499,
              [
                'Professional 的所有功能',
                '自定义集成',
                '批量折扣',
                '白标方案',
                '专属服务器',
                '24/7 电话支持',
                '定制培训',
              ],
              Colors.orange,
              isCurrentPlan: currentPlan == 'Enterprise',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    String planName,
    double price,
    List<String> features,
    Color color, {
    bool isCurrentPlan = false,
  }) {
    return Card(
      elevation: isCurrentPlan ? 8 : 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrentPlan
            ? BorderSide(color: color, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  planName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
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
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  price == 0 ? '免费' : 'RM ${price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (price > 0)
                  const Padding(
                    padding: EdgeInsets.only(left: 4, top: 8),
                    child: Text(
                      '/月',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ...features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: color,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(feature),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            if (!isCurrentPlan)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _upgradePlan(planName, price),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(price == 0 ? '降级到此计划' : '升级到此计划'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
