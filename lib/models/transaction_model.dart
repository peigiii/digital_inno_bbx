import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String? offerId;   final String buyerId;
  final String sellerId;
  final String listingId;
  final double amount;   final double platformFee;   final double totalAmount;   final String paymentMethod; // cash, bank_transfer, ewallet
  final String paymentStatus; // pending, paid, refunded
  final String? paymentProofUrl;   final String? paymentId;   final String? receiptUrl;   final String status; // confirmed, scheduled, inTransit, delivered, completed, disputed, cancelled, refunded
  final String shippingStatus; // pending, picked_up, in_transit, delivered, completed
  final String escrowStatus; // held, released, refunded
  final String? deliveryMethod;   final Map<String, dynamic>? shippingInfo;   final String? trackingNumber;   final String? logisticsProvider;   final DateTime? pickupScheduledDate;   final DateTime? actualPickupDate;   final DateTime? pickupDate;   final DateTime? deliveryDate;   final String? notes;   final String? cancellationReason;   final List<String> shippingProof;
  final String? complianceDocumentUrl;   final bool buyerReviewed;   final bool sellerReviewed;   final DateTime? createdAt;
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

    factory TransactionModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel.fromMap(doc.id, data);
  }

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

    bool get isEscrowHeld => escrowStatus == 'held';
  bool get isEscrowReleased => escrowStatus == 'released';
  bool get isEscrowRefunded => escrowStatus == 'refunded';

    String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending Payment';
      case 'confirmed':
        return 'Confirmed';
      case 'scheduled':
        return 'Scheduled';
      case 'inTransit':
        return 'In Transit';
      case 'delivered':
        return 'Delivered';
      case 'paid':
        return 'Paid';
      case 'shipped':
        return 'Shipped';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'refund_requested':
        return 'Refund Requested';
      case 'refunded':
        return 'Refunded';
      case 'refund_rejected':
        return 'Refund Rejected';
      case 'disputed':
        return 'Disputed';
      default:
        return status;
    }
  }

    String get paymentMethodDisplay {
    switch (paymentMethod) {
      case 'cash':
        return 'NowGoldPay';
      case 'bank_transfer':
        return 'BankTurnAccount';
      case 'ewallet':
        return 'ElectronicWallet';
      case 'fpx':
        return 'FPX NetSilverTurnAccount';
      case 'credit_card':
        return 'Credit/Debit Card';
      default:
        return paymentMethod;
    }
  }

    String get shippingStatusDisplay {
    switch (shippingStatus) {
      case 'pending':
        return 'Pending Shipment';
      case 'picked_up':
        return 'Picked Up';
      case 'in_transit':
        return 'In Transit';
      case 'delivered':
        return 'Delivered';
      case 'completed':
        return 'Completed';
      default:
        return shippingStatus;
    }
  }

    String get paymentStatusDisplay {
    switch (paymentStatus) {
      case 'pending':
        return 'Pending Payment';
      case 'paid':
        return 'Paid';
      case 'refunded':
        return 'Refunded';
      default:
        return paymentStatus;
    }
  }

    bool canPayment() {
    return status == 'confirmed' && paymentStatus == 'pending';
  }

    bool canPickup() {
    return paymentStatus == 'paid' && shippingStatus == 'pending';
  }

    bool canConfirmDelivery() {
    return shippingStatus == 'in_transit' || shippingStatus == 'picked_up';
  }

    bool canComplete() {
    return shippingStatus == 'delivered' && status != 'completed';
  }

    bool canCancel() {
    return status != 'completed' && status != 'cancelled' && shippingStatus != 'completed';
  }

    bool isActive() {
    return status != 'completed' && status != 'cancelled' && status != 'refunded';
  }

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
