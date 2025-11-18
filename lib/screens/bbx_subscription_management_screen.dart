import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

/// 订阅管理页面
/// 显示订阅详情、历史记录、升级/降级选项
class BBXSubscriptionManagementScreen extends StatefulWidget {
  const BBXSubscriptionManagementScreen({Key? key}) : super(key: key);

  @override
  State<BBXSubscriptionManagementScreen> createState() =>
      _BBXSubscriptionManagementScreenState();
}

class _BBXSubscriptionManagementScreenState
    extends State<BBXSubscriptionManagementScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  bool isLoading = true;
  Map<String, dynamic>? subscriptionData;
  List<Map<String, dynamic>> paymentHistory = [];

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
      // 加载用户订阅信息
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get()
          .timeout(const Duration(seconds: 10));

      // 加载支付历史
      final paymentsSnapshot = await FirebaseFirestore.instance
          .collection('subscription_payments')
          .where('userId', isEqualTo: currentUser!.uid)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get()
          .timeout(const Duration(seconds: 10));

      if (mounted) {
        setState(() {
          subscriptionData = userDoc.data();
          paymentHistory = paymentsSnapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ [订阅管理] 加载失败: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载订阅信息失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('订阅管理'),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('请先登录'),
        ),
      );
    }

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('订阅管理'),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final currentPlan = subscriptionData?['subscriptionPlan'] ?? 'free';
    final subscriptionStatus = subscriptionData?['subscriptionStatus'] ?? 'active';

    return Scaffold(
      appBar: AppBar(
        title: const Text('订阅管理'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadSubscriptionData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 当前订阅卡片
              _buildCurrentSubscriptionCard(currentPlan, subscriptionStatus),

              const SizedBox(height: 24),

              // 快速操作按钮
              _buildQuickActions(currentPlan),

              const SizedBox(height: 24),

              // 订阅详情
              _buildSubscriptionDetails(currentPlan),

              const SizedBox(height: 24),

              // 支付历史
              _buildPaymentHistory(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentSubscriptionCard(String plan, String status) {
    final planInfo = _getPlanInfo(plan);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            planInfo['color'] as Color,
            (planInfo['color'] as Color).withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (planInfo['color'] as Color).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '当前订阅',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'active'
                      ? Colors.green
                      : status == 'expired'
                          ? Colors.red
                          : Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status == 'active' ? '有效' : status == 'expired' ? '已过期' : '待激活',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                planInfo['icon'] as IconData,
                size: 40,
                color: Colors.white,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    planInfo['name'] as String,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    planInfo['description'] as String,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (plan != 'free') ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white30),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem('价格', 'RM ${planInfo['price']}/年'),
                _buildInfoItem('续费日期', _getNextBillingDate()),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(String currentPlan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '快速操作',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (currentPlan == 'free' || currentPlan == 'basic')
              Expanded(
                child: _buildActionButton(
                  icon: Icons.upgrade,
                  label: '升级计划',
                  color: AppTheme.primary,
                  onTap: () {
                    Navigator.pushNamed(context, '/subscription');
                  },
                ),
              ),
            if (currentPlan == 'free' || currentPlan == 'basic')
              const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.receipt_long,
                label: '查看发票',
                color: Colors.blue,
                onTap: () {
                  _showInvoicesDialog();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionDetails(String currentPlan) {
    final planInfo = _getPlanInfo(currentPlan);
    final features = planInfo['features'] as List<String>;

    return Container(
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
            '订阅权益',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 20,
                      color: planInfo['color'] as Color,
                    ),
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
        ],
      ),
    );
  }

  Widget _buildPaymentHistory() {
    return Container(
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
            '支付历史',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (paymentHistory.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  '暂无支付记录',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...paymentHistory.map((payment) => _buildPaymentItem(payment)),
        ],
      ),
    );
  }

  Widget _buildPaymentItem(Map<String, dynamic> payment) {
    final paymentId = payment['id'] ?? '';
    final planName = payment['planName'] ?? 'Unknown';
    final amount = payment['amount'] ?? 0;
    final paymentMethod = payment['paymentMethod'] ?? 'Unknown';
    final createdAt = payment['createdAt'] as Timestamp?;
    final isSimulated = payment['simulatedPayment'] == true;

    return InkWell(
      onTap: () {
        if (paymentId.isNotEmpty) {
          Navigator.pushNamed(
            context,
            '/invoice',
            arguments: {'paymentId': paymentId},
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.payment,
              color: AppTheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      planName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isSimulated) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '测试',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  createdAt != null
                      ? _formatDate(createdAt.toDate())
                      : 'Unknown date',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  _getPaymentMethodName(paymentMethod),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            'RM ${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right,
            color: Colors.grey,
            size: 20,
          ),
        ],
      ),
    ),
    );
  }

  void _showInvoicesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('发票功能'),
        content: const Text('发票生成功能即将推出！\n\n您可以在支付历史中查看所有交易记录。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getPlanInfo(String plan) {
    switch (plan.toLowerCase()) {
      case 'basic':
        return {
          'name': 'Basic',
          'description': '适合个人用户',
          'color': Colors.blue,
          'icon': Icons.star,
          'price': 99,
          'features': [
            '无限列表',
            '优先匹配',
            '基础报告',
            '邮件支持',
            '数据导出',
          ],
        };
      case 'professional':
        return {
          'name': 'Professional',
          'description': '适合企业用户',
          'color': AppTheme.primary,
          'icon': Icons.workspace_premium,
          'price': 199,
          'features': [
            'Basic 所有功能',
            'ESG 合规报告',
            '高级数据分析',
            '物流优化',
            '专属客服',
            'API 访问',
          ],
        };
      case 'enterprise':
        return {
          'name': 'Enterprise',
          'description': '适合大型企业',
          'color': Colors.purple,
          'icon': Icons.diamond,
          'price': 499,
          'features': [
            'Professional 所有功能',
            '多用户账号',
            '定制化报告',
            '白标解决方案',
            '专属客户经理',
            '优先技术支持',
            'SLA 保证',
          ],
        };
      default:
        return {
          'name': 'Free',
          'description': '免费试用',
          'color': Colors.grey,
          'icon': Icons.person,
          'price': 0,
          'features': [
            '3天试用（个人）',
            '7天试用（公司）',
            '最多 5 个列表',
            '基础功能',
            '社区支持',
          ],
        };
    }
  }

  String _getNextBillingDate() {
    final expiresAt = subscriptionData?['subscriptionExpiresAt'];
    if (expiresAt is Timestamp) {
      return _formatDate(expiresAt.toDate());
    }
    return '暂无';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
}
