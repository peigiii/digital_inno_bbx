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
    print('🔍 [订阅页面] 开始加载订阅数�?);

    if (currentUser == null) {
      print('�?[订阅页面] 用户未登�?);
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      return;
    }

    print('�?[订阅页面] 用户已登�? ${currentUser!.email}');
    print('🔄 [订阅页面] 查询 Firestore 用户文档...');

    try {
      // 添加 10 秒超�?
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('⏱️ [订阅页面] Firestore 查询超时�?0秒）');
              throw Exception('查询超时，请检查网络连�?);
            },
          );

      print('📄 [订阅页面] 文档查询完成，存�? ${userDoc.exists}');

      if (!mounted) {
        print('⚠️ [订阅页面] Widget 已销毁，停止更新');
        return;
      }

      if (userDoc.exists) {
        final plan = userDoc.data()?['subscriptionPlan'] ?? 'free';
        print('�?[订阅页面] 当前计划: $plan');
        setState(() {
          currentPlan = plan;
          isLoading = false;
        });
      } else {
        print('⚠️ [订阅页面] 用户文档不存在，使用默认计划');
        setState(() {
          currentPlan = 'free';
          isLoading = false;
        });
      }
    } catch (e) {
      print('�?[订阅页面] 加载失败: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        // 显示错误提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载订阅信息失败: $e'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _selectPlan(String planName, int price) async {
    print('🎯 [订阅页面] 用户选择计划: $planName (RM $price)');

    if (currentUser == null) {
      print('�?[订阅页面] 用户未登�?);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('请先登录'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // 免费计划直接更新，无需支付
    if (price == 0) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认选择免费计划'),
          content: const Text('您将使用免费计划，可随时升级到付费计划�?),
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

      if (confirm != true) {
        print('�?[订阅页面] 用户取消选择');
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

        print('�?[订阅页面] 免费计划已激�?);

        if (mounted) {
          setState(() {
            currentPlan = 'free';
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已选择免费计划'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('�?[订阅页面] 更新失败: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('选择计划失败: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      return;
    }

    // 付费计划：导航到支付页面
    print('💳 [订阅页面] 导航到支付页�?..');

    if (mounted) {
      Navigator.pushNamed(
        context,
        '/payment',
        arguments: {
          'planName': planName,
          'planPrice': price,
          'planPeriod': '1�?,
        },
      );
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
              '/�?,
              [
                '3天试用（个人�?,
                '7天试用（公司�?,
                '最�?5 个列�?,
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
              '/�?,
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
              '/�?,
              [
                'Basic 所有功�?,
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
              '/�?,
              [
                'Professional 所有功�?,
                '多用户账�?,
                '定制化报�?,
                '白标解决方案',
                '专属客户经理',
                '优先技术支�?,
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
                    '�?选择计划后，请联系管理员完成支付\n'
                    '�?支持银行转账、支付宝等方式\n'
                    '�?付款�?24 小时内激活\n'
                    '�?可随时升级或降级计划',
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
        return 'Basic (RM 99/�?';
      case 'professional':
        return 'Professional (RM 199/�?';
      case 'enterprise':
        return 'Enterprise (RM 499/�?';
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
