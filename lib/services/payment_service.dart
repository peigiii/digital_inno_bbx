import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_constants.dart';

/// 支付服务
/// 集成 Stripe、PayPal 等支付网关
///
/// TODO: 需要配置以下环境变量:
/// - STRIPE_PUBLISHABLE_KEY
/// - STRIPE_SECRET_KEY
/// - STRIPE_WEBHOOK_SECRET
class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stripe 配置（需要从环境变量或 Firebase Remote Config 读取）
  static const String stripePublishableKey = 'pk_test_YOUR_KEY_HERE';
  static const String stripeSecretKey = 'sk_test_YOUR_KEY_HERE';

  /// 创建支付意图（Stripe Payment Intent）
  ///
  /// 流程：
  /// 1. 在后端创建 Payment Intent
  /// 2. 返回 client_secret 给客户端
  /// 3. 客户端使用 client_secret 完成支付
  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String currency,
    required String transactionId,
    String? customerId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // TODO: 调用 Firebase Cloud Function 创建 Payment Intent
      // 因为 Stripe Secret Key 不应该暴露在客户端

      // 示例结构（实际需要 Cloud Function）:
      /*
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/create-payment-intent'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'amount': (amount * 100).toInt(), // Stripe 使用 cents
          'currency': currency.toLowerCase(),
          'transactionId': transactionId,
          'customerId': customerId,
          'metadata': metadata,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('创建支付意图失败');
      }
      */

      // 暂时返回模拟数据
      return {
        'clientSecret': 'pi_test_secret_${DateTime.now().millisecondsSinceEpoch}',
        'paymentIntentId': 'pi_${DateTime.now().millisecondsSinceEpoch}',
        'status': 'requires_payment_method',
      };
    } catch (e) {
      throw Exception('创建支付失败: $e');
    }
  }

  /// 确认支付
  ///
  /// 参数：
  /// - transactionId: 交易ID
  /// - paymentIntentId: Stripe Payment Intent ID
  /// - paymentMethod: 支付方式
  Future<void> confirmPayment({
    required String transactionId,
    required String paymentIntentId,
    required String paymentMethod,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('用户未登录');

      // 更新交易状态
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

      // TODO: 在实际场景中，支付确认应该通过 Webhook 处理
      // 而不是客户端直接更新
    } catch (e) {
      throw Exception('确认支付失败: $e');
    }
  }

  /// 处理退款
  ///
  /// 参数：
  /// - transactionId: 交易ID
  /// - amount: 退款金额（可选，默认全额退款）
  /// - reason: 退款原因
  Future<void> processRefund({
    required String transactionId,
    double? amount,
    String? reason,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('用户未登录');

      // 获取交易信息
      final transactionDoc = await _firestore
          .collection(CollectionConstants.transactions)
          .doc(transactionId)
          .get();

      if (!transactionDoc.exists) throw Exception('交易不存在');

      final transactionData = transactionDoc.data()!;
      final paymentIntentId = transactionData['paymentIntentId'];

      if (paymentIntentId == null) throw Exception('未找到支付记录');

      // TODO: 调用 Stripe API 或 Cloud Function 处理退款
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
        throw Exception('退款失败');
      }
      */

      // 更新交易状态
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
      throw Exception('处理退款失败: $e');
    }
  }

  /// 释放托管资金给卖家
  ///
  /// 在买家确认收货后调用
  Future<void> releaseEscrow(String transactionId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('用户未登录');

      // 获取交易信息
      final transactionDoc = await _firestore
          .collection(CollectionConstants.transactions)
          .doc(transactionId)
          .get();

      if (!transactionDoc.exists) throw Exception('交易不存在');

      final transactionData = transactionDoc.data()!;
      final amount = transactionData['amount'];
      final sellerId = transactionData['sellerId'];

      // 计算平台费用
      final platformFee = _calculatePlatformFee(amount);
      final sellerAmount = amount - platformFee;

      // TODO: 调用支付网关转账给卖家
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

      // 更新交易状态
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
      throw Exception('释放资金失败: $e');
    }
  }

  /// 计算平台费用
  double _calculatePlatformFee(double amount) {
    double fee = amount * (FeeConstants.platformFeePercent / 100);

    // 应用最小和最大费用限制
    if (fee < FeeConstants.minPlatformFee) {
      fee = FeeConstants.minPlatformFee;
    } else if (fee > FeeConstants.maxPlatformFee) {
      fee = FeeConstants.maxPlatformFee;
    }

    return double.parse(fee.toStringAsFixed(2));
  }

  /// 计算支付网关费用
  double calculatePaymentGatewayFee(double amount) {
    double fee = amount * (FeeConstants.paymentGatewayFeePercent / 100);

    if (fee < FeeConstants.minPaymentGatewayFee) {
      fee = FeeConstants.minPaymentGatewayFee;
    }

    return double.parse(fee.toStringAsFixed(2));
  }

  /// 计算总费用
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

  /// 获取支付方式列表
  List<Map<String, dynamic>> getPaymentMethods() {
    return [
      {
        'id': PaymentMethodConstants.fpx,
        'name': 'FPX 网银转账',
        'icon': 'fpx',
        'enabled': true,
        'description': '马来西亚银行在线转账',
      },
      {
        'id': PaymentMethodConstants.ewallet,
        'name': '电子钱包',
        'icon': 'ewallet',
        'enabled': true,
        'description': 'Touch \'n Go / GrabPay',
      },
      {
        'id': PaymentMethodConstants.creditCard,
        'name': '信用卡/借记卡',
        'icon': 'credit_card',
        'enabled': true,
        'description': 'Visa / Mastercard / Amex',
      },
      {
        'id': PaymentMethodConstants.cash,
        'name': '现金支付',
        'icon': 'cash',
        'enabled': true,
        'description': '当面交易现金支付',
      },
    ];
  }

  /// Webhook 处理（应该在 Cloud Function 中实现）
  ///
  /// 用于处理 Stripe 的支付状态更新
  ///
  /// 事件类型：
  /// - payment_intent.succeeded
  /// - payment_intent.payment_failed
  /// - charge.refunded
  /// - transfer.created
  Future<void> handleWebhook(Map<String, dynamic> event) async {
    final eventType = event['type'];
    final data = event['data']['object'];

    switch (eventType) {
      case 'payment_intent.succeeded':
        // 支付成功
        await _handlePaymentSuccess(data);
        break;
      case 'payment_intent.payment_failed':
        // 支付失败
        await _handlePaymentFailed(data);
        break;
      case 'charge.refunded':
        // 退款成功
        await _handleRefundSuccess(data);
        break;
      default:
        print('未处理的 webhook 事件: $eventType');
    }
  }

  Future<void> _handlePaymentSuccess(Map<String, dynamic> paymentIntent) async {
    // 根据 metadata 中的 transactionId 更新交易状态
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
    // 处理退款成功通知
    print('退款成功: ${charge['id']}');
  }
}
