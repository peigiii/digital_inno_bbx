import 'package:cloud_firestore/cloud_firestore.dart';

/// 交易模型
class TransactionModel {
  final String id;
  final String? offerId; // 关联的报价ID
  final String buyerId;
  final String sellerId;
  final String listingId;
  final double amount; // 交易金额
  final double platformFee; // 平台费（3%）
  final double totalAmount; // 总金额 = amount + platformFee
  final String paymentMethod; // cash, bank_transfer, ewallet
  final String paymentStatus; // pending, paid, refunded
  final String? paymentProofUrl; // 支付凭证图片URL
  final String? paymentId; // 支付ID
  final String? receiptUrl; // 收据URL
  final String status; // confirmed, scheduled, inTransit, delivered, completed, disputed, cancelled, refunded
  final String shippingStatus; // pending, picked_up, in_transit, delivered, completed
  final String escrowStatus; // held, released, refunded
  final String? deliveryMethod; // 配送方式：self_collect(自提)/delivery(邮寄)
  final Map<String, dynamic>? shippingInfo; // 快递信息(仅邮寄时使用): courierName, trackingNumber, shippedAt, notes
  final String? trackingNumber; // 快递单号（兼容旧字段）
  final String? logisticsProvider; // 物流供应商（兼容旧字段）
  final DateTime? pickupScheduledDate; // 预定取货日期
  final DateTime? actualPickupDate; // 实际取货日期
  final DateTime? pickupDate; // 取货日期（兼容旧字段）
  final DateTime? deliveryDate; // 送货日期
  final String? notes; // 交易备注
  final String? cancellationReason; // 取消原因
  final List<String> shippingProof;
  final String? complianceDocumentUrl; // 合规文档URL
  final bool buyerReviewed; // 买家是否已评价
  final bool sellerReviewed; // 卖家是否已评价
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
    this.offerId,
    required this.buyerId,
    required this.sellerId,
    required this.listingId,
    required this.amount,
    required this.platformFee,
    required this.totalAmount,
    this.paymentMethod = 'cash',
    this.paymentStatus = 'pending',
    this.paymentProofUrl,
    this.paymentId,
    this.receiptUrl,
    this.status = 'confirmed',
    this.shippingStatus = 'pending',
    this.escrowStatus = 'held',
    this.deliveryMethod,
    this.shippingInfo,
    this.trackingNumber,
    this.logisticsProvider,
    this.pickupScheduledDate,
    this.actualPickupDate,
    this.pickupDate,
    this.deliveryDate,
    this.notes,
    this.cancellationReason,
    this.shippingProof = const [],
    this.complianceDocumentUrl,
    this.buyerReviewed = false,
    this.sellerReviewed = false,
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
      offerId: data['offerId'],
      buyerId: data['buyerId'] ?? '',
      sellerId: data['sellerId'] ?? '',
      listingId: data['listingId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      platformFee: (data['platformFee'] ?? 0).toDouble(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? 'cash',
      paymentStatus: data['paymentStatus'] ?? 'pending',
      paymentProofUrl: data['paymentProofUrl'],
      paymentId: data['paymentId'],
      receiptUrl: data['receiptUrl'],
      status: data['status'] ?? 'confirmed',
      shippingStatus: data['shippingStatus'] ?? 'pending',
      escrowStatus: data['escrowStatus'] ?? 'held',
      deliveryMethod: data['deliveryMethod'],
      shippingInfo: data['shippingInfo'] as Map<String, dynamic>?,
      trackingNumber: data['trackingNumber'],
      logisticsProvider: data['logisticsProvider'],
      pickupScheduledDate: (data['pickupScheduledDate'] as Timestamp?)?.toDate(),
      actualPickupDate: (data['actualPickupDate'] as Timestamp?)?.toDate(),
      pickupDate: (data['pickupDate'] as Timestamp?)?.toDate(),
      deliveryDate: (data['deliveryDate'] as Timestamp?)?.toDate(),
      notes: data['notes'],
      cancellationReason: data['cancellationReason'],
      shippingProof: (data['shippingProof'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      complianceDocumentUrl: data['complianceDocumentUrl'],
      buyerReviewed: data['buyerReviewed'] ?? false,
      sellerReviewed: data['sellerReviewed'] ?? false,
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
      'offerId': offerId,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'listingId': listingId,
      'amount': amount,
      'platformFee': platformFee,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'paymentProofUrl': paymentProofUrl,
      'paymentId': paymentId,
      'receiptUrl': receiptUrl,
      'status': status,
      'shippingStatus': shippingStatus,
      'escrowStatus': escrowStatus,
      'deliveryMethod': deliveryMethod,
      'shippingInfo': shippingInfo,
      'trackingNumber': trackingNumber,
      'logisticsProvider': logisticsProvider,
      'pickupScheduledDate': pickupScheduledDate != null ? Timestamp.fromDate(pickupScheduledDate!) : null,
      'actualPickupDate': actualPickupDate != null ? Timestamp.fromDate(actualPickupDate!) : null,
      'pickupDate': pickupDate != null ? Timestamp.fromDate(pickupDate!) : null,
      'deliveryDate': deliveryDate != null ? Timestamp.fromDate(deliveryDate!) : null,
      'notes': notes,
      'cancellationReason': cancellationReason,
      'shippingProof': shippingProof,
      'complianceDocumentUrl': complianceDocumentUrl,
      'buyerReviewed': buyerReviewed,
      'sellerReviewed': sellerReviewed,
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
    String? paymentStatus,
    String? paymentProofUrl,
    String? paymentId,
    String? receiptUrl,
    String? status,
    String? shippingStatus,
    String? escrowStatus,
    String? deliveryMethod,
    Map<String, dynamic>? shippingInfo,
    String? trackingNumber,
    String? logisticsProvider,
    DateTime? pickupScheduledDate,
    DateTime? actualPickupDate,
    DateTime? pickupDate,
    DateTime? deliveryDate,
    String? notes,
    String? cancellationReason,
    List<String>? shippingProof,
    String? complianceDocumentUrl,
    bool? buyerReviewed,
    bool? sellerReviewed,
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
      offerId: offerId,
      buyerId: buyerId,
      sellerId: sellerId,
      listingId: listingId,
      amount: amount,
      platformFee: platformFee,
      totalAmount: totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentProofUrl: paymentProofUrl ?? this.paymentProofUrl,
      paymentId: paymentId ?? this.paymentId,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      status: status ?? this.status,
      shippingStatus: shippingStatus ?? this.shippingStatus,
      escrowStatus: escrowStatus ?? this.escrowStatus,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      shippingInfo: shippingInfo ?? this.shippingInfo,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      logisticsProvider: logisticsProvider ?? this.logisticsProvider,
      pickupScheduledDate: pickupScheduledDate ?? this.pickupScheduledDate,
      actualPickupDate: actualPickupDate ?? this.actualPickupDate,
      pickupDate: pickupDate ?? this.pickupDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      notes: notes ?? this.notes,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      shippingProof: shippingProof ?? this.shippingProof,
      complianceDocumentUrl: complianceDocumentUrl ?? this.complianceDocumentUrl,
      buyerReviewed: buyerReviewed ?? this.buyerReviewed,
      sellerReviewed: sellerReviewed ?? this.sellerReviewed,
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
  bool get isConfirmed => status == 'confirmed';
  bool get isScheduled => status == 'scheduled';
  bool get isInTransit => status == 'inTransit';
  bool get isDelivered => status == 'delivered';
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
      case 'confirmed':
        return '已确认';
      case 'scheduled':
        return '已安排';
      case 'inTransit':
        return '运输中';
      case 'delivered':
        return '已送达';
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
      case 'cash':
        return '现金支付';
      case 'bank_transfer':
        return '银行转账';
      case 'ewallet':
        return '电子钱包';
      case 'fpx':
        return 'FPX 网银转账';
      case 'credit_card':
        return '信用卡/借记卡';
      default:
        return paymentMethod;
    }
  }

  /// 获取物流状态显示文本
  String get shippingStatusDisplay {
    switch (shippingStatus) {
      case 'pending':
        return '待发货';
      case 'picked_up':
        return '已取货';
      case 'in_transit':
        return '运输中';
      case 'delivered':
        return '已送达';
      case 'completed':
        return '已完成';
      default:
        return shippingStatus;
    }
  }

  /// 获取支付状态显示文本
  String get paymentStatusDisplay {
    switch (paymentStatus) {
      case 'pending':
        return '待支付';
      case 'paid':
        return '已支付';
      case 'refunded':
        return '已退款';
      default:
        return paymentStatus;
    }
  }

  /// 判断是否可以支付（状态为confirmed）
  bool canPayment() {
    return status == 'confirmed' && paymentStatus == 'pending';
  }

  /// 判断是否可以取货（已支付）
  bool canPickup() {
    return paymentStatus == 'paid' && shippingStatus == 'pending';
  }

  /// 判断是否可以确认收货（in_transit状态）
  bool canConfirmDelivery() {
    return shippingStatus == 'in_transit' || shippingStatus == 'picked_up';
  }

  /// 判断是否可以完成交易（已送达）
  bool canComplete() {
    return shippingStatus == 'delivered' && status != 'completed';
  }

  /// 判断是否可以取消（未完成状态）
  bool canCancel() {
    return status != 'completed' && status != 'cancelled' && shippingStatus != 'completed';
  }

  /// 判断交易是否进行中
  bool isActive() {
    return status != 'completed' && status != 'cancelled' && status != 'refunded';
  }

  /// 距离取货还有几天
  int? daysToPickup() {
    if (pickupScheduledDate == null) return null;
    final now = DateTime.now();
    final difference = pickupScheduledDate!.difference(now);
    return difference.inDays;
  }

  @override
  String toString() {
    return 'TransactionModel(id: $id, amount: $amount, status: $status, shippingStatus: $shippingStatus, escrowStatus: $escrowStatus)';
  }
}
