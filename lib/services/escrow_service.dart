import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 交易保护系统（托管支付服务）
///
/// 交易流程：
/// 1. 买家下单 → 资金托管到平台
/// 2. 卖家发货 → 上传物流凭证
/// 3. 买家确认收货 → 资金释放给卖家
/// 4. 争议期（7天）→ 可申请退款
class EscrowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 创建交易并托管资金
  Future<String> createTransaction({
    required String sellerId,
    required String listingId,
    required double amount,
    required String paymentMethod,
    Map<String, dynamic>? metadata,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('用户未登录');

    final transaction = await _firestore.collection('transactions').add({
      'buyerId': userId,
      'sellerId': sellerId,
      'listingId': listingId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'status': 'pending',
      'escrowStatus': 'held',
      'trackingNumber': null,
      'shippingProof': [],
      'completedAt': null,
      'createdAt': FieldValue.serverTimestamp(),
      'metadata': metadata ?? {},
    });

    return transaction.id;
  }

  /// 买家支付订单（托管资金）
  Future<void> payTransaction(String transactionId) async {
    await _firestore.collection('transactions').doc(transactionId).update({
      'status': 'paid',
      'paidAt': FieldValue.serverTimestamp(),
    });
  }

  /// 卖家上传发货凭证
  Future<void> uploadShippingProof({
    required String transactionId,
    required String trackingNumber,
    required List<String> proofUrls,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('用户未登录');

    // 验证是否为卖家
    final doc = await _firestore
        .collection('transactions')
        .doc(transactionId)
        .get();

    if (!doc.exists) throw Exception('交易不存在');

    final data = doc.data()!;
    if (data['sellerId'] != userId) {
      throw Exception('无权操作此交易');
    }

    await _firestore.collection('transactions').doc(transactionId).update({
      'status': 'shipped',
      'trackingNumber': trackingNumber,
      'shippingProof': proofUrls,
      'shippedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 买家确认收货（释放资金）
  Future<void> confirmReceived(String transactionId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('用户未登录');

    // 验证是否为买家
    final doc = await _firestore
        .collection('transactions')
        .doc(transactionId)
        .get();

    if (!doc.exists) throw Exception('交易不存在');

    final data = doc.data()!;
    if (data['buyerId'] != userId) {
      throw Exception('无权操作此交易');
    }

    await _firestore.collection('transactions').doc(transactionId).update({
      'status': 'completed',
      'escrowStatus': 'released',
      'completedAt': FieldValue.serverTimestamp(),
    });

    // TODO: 实际释放资金给卖家的逻辑
    // 这里需要集成真实的支付网关
  }

  /// 申请退款
  Future<void> requestRefund({
    required String transactionId,
    required String reason,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('用户未登录');

    // 验证是否为买家
    final doc = await _firestore
        .collection('transactions')
        .doc(transactionId)
        .get();

    if (!doc.exists) throw Exception('交易不存在');

    final data = doc.data()!;
    if (data['buyerId'] != userId) {
      throw Exception('无权操作此交易');
    }

    await _firestore.collection('transactions').doc(transactionId).update({
      'status': 'refund_requested',
      'refundReason': reason,
      'refundRequestedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 处理退款（管理员操作）
  Future<void> processRefund({
    required String transactionId,
    required bool approved,
    String? note,
  }) async {
    final status = approved ? 'refunded' : 'refund_rejected';
    final escrowStatus = approved ? 'refunded' : 'released';

    await _firestore.collection('transactions').doc(transactionId).update({
      'status': status,
      'escrowStatus': escrowStatus,
      'refundProcessedAt': FieldValue.serverTimestamp(),
      'refundNote': note,
    });

    // TODO: 实际退款逻辑
  }

  /// 获取用户的购买交易
  Stream<QuerySnapshot> getUserPurchases() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('用户未登录');

    return _firestore
        .collection('transactions')
        .where('buyerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// 获取用户的销售交易
  Stream<QuerySnapshot> getUserSales() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('用户未登录');

    return _firestore
        .collection('transactions')
        .where('sellerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// 获取交易详情
  Stream<DocumentSnapshot> getTransactionDetails(String transactionId) {
    return _firestore
        .collection('transactions')
        .doc(transactionId)
        .snapshots();
  }

  /// 取消交易
  Future<void> cancelTransaction(String transactionId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('用户未登录');

    final doc = await _firestore
        .collection('transactions')
        .doc(transactionId)
        .get();

    if (!doc.exists) throw Exception('交易不存在');

    final data = doc.data()!;

    // 只有买家可以取消未支付的订单
    if (data['buyerId'] != userId) {
      throw Exception('无权操作此交易');
    }

    if (data['status'] != 'pending') {
      throw Exception('该状态下无法取消订单');
    }

    await _firestore.collection('transactions').doc(transactionId).update({
      'status': 'cancelled',
      'cancelledAt': FieldValue.serverTimestamp(),
    });
  }

  /// 检查交易是否可以申请退款（7天争议期）
  bool canRequestRefund(Map<String, dynamic> transaction) {
    if (transaction['status'] != 'completed') return false;

    final completedAt = (transaction['completedAt'] as Timestamp?)?.toDate();
    if (completedAt == null) return false;

    final daysSinceCompletion = DateTime.now().difference(completedAt).inDays;
    return daysSinceCompletion <= 7;
  }

  /// 获取交易统计
  Future<Map<String, dynamic>> getTransactionStats(String userId) async {
    final purchases = await _firestore
        .collection('transactions')
        .where('buyerId', isEqualTo: userId)
        .get();

    final sales = await _firestore
        .collection('transactions')
        .where('sellerId', isEqualTo: userId)
        .get();

    int completedPurchases = 0;
    int completedSales = 0;
    double totalSpent = 0;
    double totalEarned = 0;

    for (var doc in purchases.docs) {
      final data = doc.data();
      if (data['status'] == 'completed') {
        completedPurchases++;
        totalSpent += (data['amount'] as num).toDouble();
      }
    }

    for (var doc in sales.docs) {
      final data = doc.data();
      if (data['status'] == 'completed') {
        completedSales++;
        totalEarned += (data['amount'] as num).toDouble();
      }
    }

    return {
      'totalPurchases': purchases.size,
      'totalSales': sales.size,
      'completedPurchases': completedPurchases,
      'completedSales': completedSales,
      'totalSpent': totalSpent,
      'totalEarned': totalEarned,
      'completionRate': sales.size > 0
          ? (completedSales / sales.size * 100).toStringAsFixed(1)
          : '0',
    };
  }
}

/// 交易状态枚举
enum TransactionStatus {
  pending('pending', '待支付'),
  paid('paid', '已支付'),
  shipped('shipped', '已发货'),
  completed('completed', '已完成'),
  cancelled('cancelled', '已取消'),
  refundRequested('refund_requested', '申请退款'),
  refunded('refunded', '已退款'),
  refundRejected('refund_rejected', '退款被拒'),
  disputed('disputed', '有争议');

  final String value;
  final String label;
  const TransactionStatus(this.value, this.label);

  static TransactionStatus fromString(String value) {
    return TransactionStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TransactionStatus.pending,
    );
  }
}

/// 托管状态枚举
enum EscrowStatus {
  held('held', '资金托管中'),
  released('released', '资金已释放'),
  refunded('refunded', '已退款');

  final String value;
  final String label;
  const EscrowStatus(this.value, this.label);

  static EscrowStatus fromString(String value) {
    return EscrowStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => EscrowStatus.held,
    );
  }
}
