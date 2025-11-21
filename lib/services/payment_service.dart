import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_constants.dart';

/// Payment Service
/// - STRIPE_PUBLISHABLE_KEY
/// - STRIPE_SECRET_KEY
/// - STRIPE_WEBHOOK_SECRET
class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String stripePublishableKey = 'pk_test_YOUR_KEY_HERE';
  static const String stripeSecretKey = 'sk_test_YOUR_KEY_HERE';

  /// Create Payment Intent
  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String currency,
    required String transactionId,
    String? customerId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      /*
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/create-payment-intent'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'amount': (amount * 100).toInt(),
          'currency': currency.toLowerCase(),
          'transactionId': transactionId,
          'customerId': customerId,
          'metadata': metadata,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create payment intent');
      }
      */

      return {
        'clientSecret': 'pi_test_secret_${DateTime.now().millisecondsSinceEpoch}',
        'paymentIntentId': 'pi_${DateTime.now().millisecondsSinceEpoch}',
        'status': 'requires_payment_method',
      };
    } catch (e) {
      throw Exception('Payment creation failed: $e');
    }
  }

  /// Confirm Payment
  /// - paymentIntentId: Stripe Payment Intent ID
  Future<void> confirmPayment({
    required String transactionId,
    required String paymentIntentId,
    required String paymentMethod,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _firestore
          .collection(CollectionConstants.transactions)
          .doc(transactionId)
          .update({
        'status': TransactionStatusConstants.paid,
        'paidAt': FieldValue.serverTimestamp(),
        'paymentMethod': paymentMethod,
        'paymentIntentId': paymentIntentId,
        'escrowStatus': EscrowStatusConstants.held,
      }).timeout(ApiConstants.defaultTimeout);

    } catch (e) {
      throw Exception('Payment confirmation failed: $e');
    }
  }

  /// Process Refund
  Future<void> processRefund({
    required String transactionId,
    double? amount,
    String? reason,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final transactionDoc = await _firestore
          .collection(CollectionConstants.transactions)
          .doc(transactionId)
          .get();

      if (!transactionDoc.exists) throw Exception('Transaction not found');

      final transactionData = transactionDoc.data()!;
      final paymentIntentId = transactionData['paymentIntentId'];

      if (paymentIntentId == null) throw Exception('Payment record not found');

      /*
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/create-refund'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'paymentIntentId': paymentIntentId,
          'amount': amount != null ? (amount * 100).toInt() : null,
          'reason': reason,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Refund failed');
      }
      */

      await _firestore
          .collection(CollectionConstants.transactions)
          .doc(transactionId)
          .update({
        'status': TransactionStatusConstants.refunded,
        'escrowStatus': EscrowStatusConstants.refunded,
        'refundProcessedAt': FieldValue.serverTimestamp(),
        'refundNote': reason,
      }).timeout(ApiConstants.defaultTimeout);
    } catch (e) {
      throw Exception('Refund processing failed: $e');
    }
  }

  /// Release Escrow
  Future<void> releaseEscrow(String transactionId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final transactionDoc = await _firestore
          .collection(CollectionConstants.transactions)
          .doc(transactionId)
          .get();

      if (!transactionDoc.exists) throw Exception('Transaction not found');

      final transactionData = transactionDoc.data()!;
      final amount = transactionData['amount'];
      // ignore: unused_local_variable
      final sellerId = transactionData['sellerId'];

      final platformFee = _calculatePlatformFee(amount);
      final sellerAmount = amount - platformFee;

      /*
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/transfer-to-seller'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'sellerId': sellerId,
          'amount': (sellerAmount * 100).toInt(),
          'transactionId': transactionId,
          'platformFee': (platformFee * 100).toInt(),
        }),
      );
      */

      await _firestore
          .collection(CollectionConstants.transactions)
          .doc(transactionId)
          .update({
        'escrowStatus': EscrowStatusConstants.released,
        'platformFee': platformFee,
        'sellerAmount': sellerAmount,
        'completedAt': FieldValue.serverTimestamp(),
      }).timeout(ApiConstants.defaultTimeout);
    } catch (e) {
      throw Exception('Fund release failed: $e');
    }
  }

  double _calculatePlatformFee(double amount) {
    double fee = amount * (FeeConstants.platformFeePercent / 100);

    if (fee < FeeConstants.minPlatformFee) {
      fee = FeeConstants.minPlatformFee;
    } else if (fee > FeeConstants.maxPlatformFee) {
      fee = FeeConstants.maxPlatformFee;
    }

    return double.parse(fee.toStringAsFixed(2));
  }

  double calculatePaymentGatewayFee(double amount) {
    double fee = amount * (FeeConstants.paymentGatewayFeePercent / 100);

    if (fee < FeeConstants.minPaymentGatewayFee) {
      fee = FeeConstants.minPaymentGatewayFee;
    }

    return double.parse(fee.toStringAsFixed(2));
  }

  Map<String, double> calculateFees(double amount) {
    final platformFee = _calculatePlatformFee(amount);
    final paymentFee = calculatePaymentGatewayFee(amount);
    final totalFees = platformFee + paymentFee;
    final buyerPays = amount + totalFees;
    final sellerReceives = amount - platformFee;

    return {
      'amount': amount,
      'platformFee': platformFee,
      'paymentGatewayFee': paymentFee,
      'totalFees': totalFees,
      'buyerPays': buyerPays,
      'sellerReceives': sellerReceives,
    };
  }

  List<Map<String, dynamic>> getPaymentMethods() {
    return [
      {
        'id': PaymentMethodConstants.fpx,
        'name': 'FPX Online Banking',
        'icon': 'fpx',
        'enabled': true,
        'description': 'Malaysian Online Banking',
      },
      {
        'id': PaymentMethodConstants.ewallet,
        'name': 'E-Wallet',
        'icon': 'ewallet',
        'enabled': true,
        'description': 'Touch \'n Go / GrabPay',
      },
      {
        'id': PaymentMethodConstants.creditCard,
        'name': 'Credit/Debit Card',
        'icon': 'credit_card',
        'enabled': true,
        'description': 'Visa / Mastercard / Amex',
      },
      {
        'id': PaymentMethodConstants.cash,
        'name': 'Cash Payment',
        'icon': 'cash',
        'enabled': true,
        'description': 'Cash on Delivery',
      },
    ];
  }

  /// Simulate Payment
  Future<bool> simulatePayment({
    required String userId,
    required String planName,
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      // ignore: avoid_print
      print('🔄 [Payment Service] Starting simulated payment...');
      // ignore: avoid_print
      print('👤 User: $userId');
      // ignore: avoid_print
      print('📋 Plan: $planName');
      // ignore: avoid_print
      print('💰 Amount: RM $amount');
      // ignore: avoid_print
      print('💳 Method: $paymentMethod');

      await Future.delayed(const Duration(seconds: 2));

      await _firestore.collection(CollectionConstants.users).doc(userId).update({
        'subscriptionPlan': planName.toLowerCase().replaceAll(' ', '_'),
        'subscriptionUpdatedAt': FieldValue.serverTimestamp(),
        'subscriptionStatus': 'active',
        'subscriptionExpiresAt': FieldValue.serverTimestamp(),
      }).timeout(ApiConstants.defaultTimeout);

      await _firestore.collection('subscription_payments').add({
        'userId': userId,
        'planName': planName,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'status': TransactionStatusConstants.paid,
        'paidAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'simulatedPayment': true,
      }).timeout(ApiConstants.defaultTimeout);

      // ignore: avoid_print
      print('✅ [Payment Service] Payment simulation successful');
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('❌ [Payment Service] Payment simulation failed: $e');
      return false;
    }
  }

  /// Handle Webhook
  /// - payment_intent.succeeded
  /// - payment_intent.payment_failed
  /// - charge.refunded
  /// - transfer.created
  Future<void> handleWebhook(Map<String, dynamic> event) async {
    final eventType = event['type'];
    final data = event['data']['object'];

    switch (eventType) {
      case 'payment_intent.succeeded':
        await _handlePaymentSuccess(data);
        break;
      case 'payment_intent.payment_failed':
        await _handlePaymentFailed(data);
        break;
      case 'charge.refunded':
        await _handleRefundSuccess(data);
        break;
      default:
        // ignore: avoid_print
        print('Unhandled webhook event: $eventType');
    }
  }

  Future<void> _handlePaymentSuccess(Map<String, dynamic> paymentIntent) async {
    final transactionId = paymentIntent['metadata']['transactionId'];
    if (transactionId != null) {
      await _firestore
          .collection(CollectionConstants.transactions)
          .doc(transactionId)
          .update({
        'status': TransactionStatusConstants.paid,
        'paidAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _handlePaymentFailed(Map<String, dynamic> paymentIntent) async {
    final transactionId = paymentIntent['metadata']['transactionId'];
    if (transactionId != null) {
      await _firestore
          .collection(CollectionConstants.transactions)
          .doc(transactionId)
          .update({
        'status': TransactionStatusConstants.cancelled,
        'cancelReason': 'payment_failed',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _handleRefundSuccess(Map<String, dynamic> charge) async {
    // ignore: avoid_print
    print('Refund successful: ${charge['id']}');
  }
}
