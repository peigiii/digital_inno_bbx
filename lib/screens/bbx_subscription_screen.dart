import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class BBXSubscriptionScreen extends StatefulWidget {
  const BBXSubscriptionScreen({super.key});

  @override
  State<BBXSubscriptionScreen> createState() => _BBXSubscriptionScreenState();
}

class _BBXSubscriptionScreenState extends State<BBXSubscriptionScreen> {
  String? _currentPlan;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentPlan();
  }

  Future<void> _loadCurrentPlan() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (mounted && userDoc.exists) {
          setState(() {
            _currentPlan = (userDoc.data() as Map<String, dynamic>)['subscriptionPlan'] ?? SubscriptionPlans.free;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentPlan = SubscriptionPlans.free;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _upgradePlan(String planName) async {
    // Show coming soon dialog for now
    // In production, this would integrate with Stripe/Razorpay
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('支付功能'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('您选择了：$planName'),
            const SizedBox(height: 16),
            const Text('支付集成功能即将推出！'),
            const SizedBox(height: 8),
            const Text(
              '正式版本将支持：\n• Stripe 支付\n• 信用卡/借记卡\n• 在线银行转账\n• 电子钱包',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF4CAF50),
          ),
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            const Icon(
              Icons.workspace_premium,
              size: 64,
              color: Color(0xFF4CAF50),
            ),
            const SizedBox(height: 16),
            const Text(
              '选择适合您的计划',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              '升级以解锁更多功能',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Free Plan
            _buildPlanCard(
              planName: SubscriptionPlans.free,
              title: 'Free',
              subtitle: '个人用户试用',
              price: 'RM 0',
              period: '永久免费',
              features: const [
                '3天试用（个人）',
                '7天试用（公司）',
                '最多 5 个废料列表',
                '基础功能',
                '标准支持',
              ],
              isPopular: false,
              isCurrent: _currentPlan == SubscriptionPlans.free,
            ),

            const SizedBox(height: 16),

            // Pro Plan
            _buildPlanCard(
              planName: SubscriptionPlans.pro,
              title: 'Pro',
              subtitle: '专业用户',
              price: 'RM 199',
              period: '/年',
              features: const [
                '✓ Free 所有功能',
                '✓ 无限废料列表',
                '✓ 优先匹配推荐',
                '✓ ESG 环保报告',
                '✓ 数据分析仪表板',
                '✓ 优先客服支持',
              ],
              isPopular: true,
              isCurrent: _currentPlan == SubscriptionPlans.pro,
            ),

            const SizedBox(height: 16),

            // Business A Plan
            _buildPlanCard(
              planName: SubscriptionPlans.businessA,
              title: 'Business A',
              subtitle: '中小企业',
              price: 'RM 299',
              period: '/年',
              features: const [
                '✓ Pro 所有功能',
                '✓ 物流路线优化',
                '✓ 专属客户经理',
                '✓ 批量操作功能',
                '✓ 高级数据导出',
                '✓ 定制化报表',
              ],
              isPopular: false,
              isCurrent: _currentPlan == SubscriptionPlans.businessA,
            ),

            const SizedBox(height: 16),

            // Business B Plan
            _buildPlanCard(
              planName: SubscriptionPlans.businessB,
              title: 'Business B',
              subtitle: '大型企业',
              price: 'RM 399',
              period: '/年',
              features: const [
                '✓ Business A 所有功能',
                '✓ API 接口访问',
                '✓ 多用户账号管理',
                '✓ 定制功能开发',
                '✓ SLA 服务保障',
                '✓ 专属技术支持',
              ],
              isPopular: false,
              isCurrent: _currentPlan == SubscriptionPlans.businessB,
            ),

            const SizedBox(height: 32),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.security,
                    color: Color(0xFF4CAF50),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '安全支付保障',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '我们使用加密技术保护您的支付信息\n支持 30 天无理由退款',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String planName,
    required String title,
    required String subtitle,
    required String price,
    required String period,
    required List<String> features,
    required bool isPopular,
    required bool isCurrent,
  }) {
    return Card(
      elevation: isPopular ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isPopular
            ? const BorderSide(color: Color(0xFF4CAF50), width: 2)
            : BorderSide.none,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '最受欢迎',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (isPopular) const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),
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
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),
                ...features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF4CAF50),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              feature,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isCurrent ? null : () => _upgradePlan(planName),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPopular
                          ? const Color(0xFF4CAF50)
                          : Colors.grey[300],
                      foregroundColor: isPopular ? Colors.white : Colors.grey[700],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      isCurrent ? '当前计划' : '选择此计划',
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
          if (isCurrent)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '当前',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
