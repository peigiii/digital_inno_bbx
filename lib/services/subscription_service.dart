import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/subscription_model.dart';

class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

    Future<SubscriptionModel?> getCurrentSubscription() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      final doc = await _firestore
          .collection('subscriptions')
          .doc(userId)
          .get();

      if (!doc.exists) {
                return await _createFreeSubscription(userId);
      }

      return SubscriptionModel.fromFirestore(doc);
    } catch (e) {
      print('Failed to get subscription info: $e');
      return null;
    }
  }

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
        'Post 5 items',
        'Basic search',
        'View Quote',
        'Community Support',
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

    Future<bool> subscribe(
    SubscriptionPlanType planType,
    String period,
  ) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

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

            await _firestore.collection('users').doc(userId).update({
        'subscriptionPlan': planType.toString().split('.').last,
        'subscriptionStatus': 'active',
        'subscriptionUpdatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Subscription failed: $e');
      return false;
    }
  }

    Future<bool> cancelSubscription() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

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
      print('Failed to cancel subscription: $e');
      return false;
    }
  }

    List<Map<String, dynamic>> getAvailablePlans() {
    return [
      {
        'type': SubscriptionPlanType.free,
        'name': 'Free',
        'priceMonthly': 0,
        'priceYearly': 0,
        'features': [
          'Post 5 items',
          'Basic search',
          'View Quote',
          'Community Support',
        ],
      },
      {
        'type': SubscriptionPlanType.basic,
        'name': 'Basic',
        'priceMonthly': 29,
        'priceYearly': 99,
        'features': [
          'Post 50 items',
          'Advanced Search',
          'Priority Listing',
          'Data Analytics',
          'Customer Support',
        ],
      },
      {
        'type': SubscriptionPlanType.professional,
        'name': 'Professional',
        'priceMonthly': 59,
        'priceYearly': 199,
        'features': [
          'Unlimited Posting',
          'ESG Compliance Report',
          'Advanced Analytics',
          'Logistics Optimization',
          'Dedicated Support',
          'API Access',
        ],
      },
      {
        'type': SubscriptionPlanType.enterprise,
        'name': 'Enterprise',
        'priceMonthly': 149,
        'priceYearly': 499,
        'features': [
          'All Professional features',
          'Multi-user account',
          'Custom Reports',
          'White-label Solution',
          'Dedicated Account Manager',
          'Priority Tech Support',
          'SLA Guarantee',
        ],
      },
    ];
  }

    Map<String, dynamic> _getPlanDetails(
    SubscriptionPlanType planType,
    String period,
  ) {
    final plans = getAvailablePlans();
    final plan = plans.firstWhere(
      (p) => p['type'] == planType,
      orElse: () => plans[0],
    );

    final price = period == '1? ? plan['priceYearly'] : plan['priceMonthly'];

    return {
      'price': price.toDouble(),
      'features': List<String>.from(plan['features']),
    };
  }

    DateTime _calculateEndDate(DateTime startDate, String period) {
    if (period == '1个月') {
      return startDate.add(const Duration(days: 30));
    } else if (period == '1?) {
      return DateTime(
        startDate.year + 1,
        startDate.month,
        startDate.day,
      );
    }
    return startDate.add(const Duration(days: 30));
  }

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
      print('Failed to check subscription: $e');
    }
  }
}
