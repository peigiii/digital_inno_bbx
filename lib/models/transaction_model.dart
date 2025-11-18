import 'package:cloud_firestore/cloud_firestore.dart';

/// 交易模型
class TransactionModel {
  final String id;
  final String buyerId;
  final String sellerId;
  final String listingId;
  final double amount;
  final String paymentMethod; // fpx, ewallet, credit_card, cash
  final String status; // pending, paid, shipped, completed, cancelled, refund_requested, refunded, refund_rejected, disputed
  final String escrowStatus; // held, released, refunded
  final String? trackingNumber;
  final List<String> shippingProof;
  final DateTime? createdAt;
  final DateTime? paidAt;
  final DateTime? shippedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? refundReason;
  final DateTime? refundRequestedAt;
  final DateTime? refundProcessedAt;
  final String? refundNote;
  final Map<String, dynamic>? metadata;

  TransactionModel({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.listingId,
    required this.amount,
    this.paymentMethod = 'fpx',
    this.status = 'pending',
    this.escrowStatus = 'held',
    this.trackingNumber,
    this.shippingProof = const [],
    this.createdAt,
    this.paidAt,
    this.shippedAt,
    this.completedAt,
    this.cancelledAt,
    this.refundReason,
    this.refundRequestedAt,
    this.refundProcessedAt,
    this.refundNote,
    this.metadata,
  });

  /// 从 Firestore 文档创建
  factory TransactionModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel.fromMap(doc.id, data);
  }

  /// 从 Map 创建
  factory TransactionModel.fromMap(String id, Map<String, dynamic> data) {
    return TransactionModel(
      id: id,
      buyerId: data['buyerId'] ?? '',
      sellerId: data['sellerId'] ?? '',
      listingId: data['listingId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? 'fpx',
      status: data['status'] ?? 'pending',
      escrowStatus: data['escrowStatus'] ?? 'held',
      trackingNumber: data['trackingNumber'],
      shippingProof: (data['shippingProof'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      paidAt: (data['paidAt'] as Timestamp?)?.toDate(),
      shippedAt: (data['shippedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      cancelledAt: (data['cancelledAt'] as Timestamp?)?.toDate(),
      refundReason: data['refundReason'],
      refundRequestedAt: (data['refundRequestedAt'] as Timestamp?)?.toDate(),
      refundProcessedAt: (data['refundProcessedAt'] as Timestamp?)?.toDate(),
      refundNote: data['refundNote'],
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// 转换为 Map（用于Firestore）
  Map<String, dynamic> toMap() {
    return {
      'buyerId': buyerId,
      'sellerId': sellerId,
      'listingId': listingId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'status': status,
      'escrowStatus': escrowStatus,
      'trackingNumber': trackingNumber,
      'shippingProof': shippingProof,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'shippedAt': shippedAt != null ? Timestamp.fromDate(shippedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'refundReason': refundReason,
      'refundRequestedAt': refundRequestedAt != null ? Timestamp.fromDate(refundRequestedAt!) : null,
      'refundProcessedAt': refundProcessedAt != null ? Timestamp.fromDate(refundProcessedAt!) : null,
      'refundNote': refundNote,
      'metadata': metadata,
    };
  }

  /// 复制并修改部分字段
  TransactionModel copyWith({
    String? paymentMethod,
    String? status,
    String? escrowStatus,
    String? trackingNumber,
    List<String>? shippingProof,
    DateTime? paidAt,
    DateTime? shippedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    String? refundReason,
    DateTime? refundRequestedAt,
    DateTime? refundProcessedAt,
    String? refundNote,
    Map<String, dynamic>? metadata,
  }) {
    return TransactionModel(
      id: id,
      buyerId: buyerId,
      sellerId: sellerId,
      listingId: listingId,
      amount: amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      escrowStatus: escrowStatus ?? this.escrowStatus,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      shippingProof: shippingProof ?? this.shippingProof,
      createdAt: createdAt,
      paidAt: paidAt ?? this.paidAt,
      shippedAt: shippedAt ?? this.shippedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      refundReason: refundReason ?? this.refundReason,
      refundRequestedAt: refundRequestedAt ?? this.refundRequestedAt,
      refundProcessedAt: refundProcessedAt ?? this.refundProcessedAt,
      refundNote: refundNote ?? this.refundNote,
      metadata: metadata ?? this.metadata,
    );
  }

  /// 状态判断
  bool get isPending => status == 'pending';
  bool get isPaid => status == 'paid';
  bool get isShipped => status == 'shipped';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isRefundRequested => status == 'refund_requested';
  bool get isRefunded => status == 'refunded';
  bool get isDisputed => status == 'disputed';

  /// 托管状态判断
  bool get isEscrowHeld => escrowStatus == 'held';
  bool get isEscrowReleased => escrowStatus == 'released';
  bool get isEscrowRefunded => escrowStatus == 'refunded';

  /// 获取状态显示文本
  String get statusDisplay {
    switch (status) {
      case 'pending':
        return '待支付';
      case 'paid':
        return '已支付';
      case 'shipped':
        return '已发货';
      case 'completed':
        return '已完成';
      case 'cancelled':
        return '已取消';
      case 'refund_requested':
        return '退款申请中';
      case 'refunded':
        return '已退款';
      case 'refund_rejected':
        return '退款被拒';
      case 'disputed':
        return '争议中';
      default:
        return status;
    }
  }

  /// 获取支付方式显示文本
  String get paymentMethodDisplay {
    switch (paymentMethod) {
      case 'fpx':
        return 'FPX 网银转账';
      case 'ewallet':
        return '电子钱包';
      case 'credit_card':
        return '信用卡/借记卡';
      case 'cash':
        return '现金支付';
      default:
        return paymentMethod;
    }
  }

  @override
  String toString() {
    return 'TransactionModel(id: $id, amount: $amount, status: $status, escrowStatus: $escrowStatus)';
  }
}
