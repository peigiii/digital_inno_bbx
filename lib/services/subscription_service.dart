import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/subscription_model.dart';

/// 订阅服务
class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 获取当前用户的订阅信息
  Future<SubscriptionModel?> getCurrentSubscription() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      final doc = await _firestore
          .collection('subscriptions')
          .doc(userId)
          .get();

      if (!doc.exists) {
        // 如果没有订阅记录，创建免费订阅
        return await _createFreeSubscription(userId);
      }

      return SubscriptionModel.fromFirestore(doc);
    } catch (e) {
      print('获取订阅信息失败: $e');
      return null;
    }
  }

  /// 创建免费订阅
  Future<SubscriptionModel> _createFreeSubscription(String userId) async {
    final now = DateTime.now();
    final subscription = SubscriptionModel(
      id: userId,
      userId: userId,
      planType: SubscriptionPlanType.free,
      status: SubscriptionStatus.active,
      startDate: now,
      endDate: null,
      price: 0,
      period: '永久',
      features: [
        '发布 5 个商品',
        '基础搜索功能',
        '查看报价',
        '社区支持',
      ],
      createdAt: now,
      updatedAt: now,
    );

    await _firestore
        .collection('subscriptions')
        .doc(userId)
        .set(subscription.toMap());

    return subscription;
  }

  /// 订阅计划
  Future<bool> subscribe(
    SubscriptionPlanType planType,
    String period,
  ) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('用户未登录');

      final planDetails = _getPlanDetails(planType, period);
      final now = DateTime.now();
      final endDate = _calculateEndDate(now, period);

      final subscription = SubscriptionModel(
        id: userId,
        userId: userId,
        planType: planType,
        status: SubscriptionStatus.active,
        startDate: now,
        endDate: endDate,
        price: planDetails['price'],
        period: period,
        features: planDetails['features'],
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection('subscriptions')
          .doc(userId)
          .set(subscription.toMap());

      // 更新用户文档中的订阅计划
      await _firestore.collection('users').doc(userId).update({
        'subscriptionPlan': planType.toString().split('.').last,
        'subscriptionStatus': 'active',
        'subscriptionUpdatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('订阅失败: $e');
      return false;
    }
  }

  /// 取消订阅
  Future<bool> cancelSubscription() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('用户未登录');

      await _firestore.collection('subscriptions').doc(userId).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('users').doc(userId).update({
        'subscriptionStatus': 'cancelled',
        'subscriptionUpdatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('取消订阅失败: $e');
      return false;
    }
  }

  /// 获取所有可用计划
  List<Map<String, dynamic>> getAvailablePlans() {
    return [
      {
        'type': SubscriptionPlanType.free,
        'name': 'Free',
        'priceMonthly': 0,
        'priceYearly': 0,
        'features': [
          '发布 5 个商品',
          '基础搜索功能',
          '查看报价',
          '社区支持',
        ],
      },
      {
        'type': SubscriptionPlanType.basic,
        'name': 'Basic',
        'priceMonthly': 29,
        'priceYearly': 99,
        'features': [
          '发布 50 个商品',
          '高级搜索',
          '优先展示',
          '数据分析',
          '客服支持',
        ],
      },
      {
        'type': SubscriptionPlanType.professional,
        'name': 'Professional',
        'priceMonthly': 59,
        'priceYearly': 199,
        'features': [
          '无限发布',
          'ESG 合规报告',
          '高级数据分析',
          '物流优化',
          '专属客服',
          'API 访问',
        ],
      },
      {
        'type': SubscriptionPlanType.enterprise,
        'name': 'Enterprise',
        'priceMonthly': 149,
        'priceYearly': 499,
        'features': [
          'Professional 所有功能',
          '多用户账号',
          '定制化报告',
          '白标解决方案',
          '专属客户经理',
          '优先技术支持',
          'SLA 保证',
        ],
      },
    ];
  }

  /// 获取计划详情
  Map<String, dynamic> _getPlanDetails(
    SubscriptionPlanType planType,
    String period,
  ) {
    final plans = getAvailablePlans();
    final plan = plans.firstWhere(
      (p) => p['type'] == planType,
      orElse: () => plans[0],
    );

    final price = period == '1年' ? plan['priceYearly'] : plan['priceMonthly'];

    return {
      'price': price.toDouble(),
      'features': List<String>.from(plan['features']),
    };
  }

  /// 计算结束日期
  DateTime _calculateEndDate(DateTime startDate, String period) {
    if (period == '1个月') {
      return startDate.add(const Duration(days: 30));
    } else if (period == '1年') {
      return DateTime(
        startDate.year + 1,
        startDate.month,
        startDate.day,
      );
    }
    return startDate.add(const Duration(days: 30));
  }

  /// 检查订阅是否过期
  Future<void> checkAndUpdateExpiredSubscriptions() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final doc = await _firestore
          .collection('subscriptions')
          .doc(userId)
          .get();

      if (!doc.exists) return;

      final subscription = SubscriptionModel.fromFirestore(doc);

      if (subscription.isExpired && subscription.status == SubscriptionStatus.active) {
        await _firestore.collection('subscriptions').doc(userId).update({
          'status': 'expired',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        await _firestore.collection('users').doc(userId).update({
          'subscriptionStatus': 'expired',
          'subscriptionUpdatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('检查订阅状态失败: $e');
    }
  }
}
