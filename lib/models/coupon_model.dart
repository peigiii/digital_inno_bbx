import 'package:cloud_firestore/cloud_firestore.dart';

/// 优惠券状�?
enum CouponStatus {
  available,
  used,
  expired,
}

/// 优惠券类�?
enum CouponType {
  fixed, // 固定金额
  percentage, // 百分比折�?
}

/// 优惠券模�?
class CouponModel {
  final String id;
  final String userId;
  final String code;
  final String title;
  final String description;
  final CouponType discountType;
  final int discount; // 折扣值（如果是fixed则是金额，如果是percentage则是百分比）
  final double minAmount; // 最小使用金�?
  final CouponStatus status;
  final DateTime expiryDate;
  final DateTime? usedAt;
  final String? usedInTransactionId;
  final DateTime createdAt;
  final DateTime updatedAt;

  CouponModel({
    required this.id,
    required this.userId,
    required this.code,
    required this.title,
    required this.description,
    required this.discountType,
    required this.discount,
    required this.minAmount,
    required this.status,
    required this.expiryDate,
    this.usedAt,
    this.usedInTransactionId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CouponModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return CouponModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      code: data['code'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      discountType: data['discountType'] == 'percentage'
          ? CouponType.percentage
          : CouponType.fixed,
      discount: data['discount'] ?? 0,
      minAmount: (data['minAmount'] ?? 0).toDouble(),
      status: _parseStatus(data['status']),
      expiryDate: (data['expiryDate'] as Timestamp?)?.toDate() ??
          DateTime.now().add(Duration(days: 30)),
      usedAt:
          data['usedAt'] != null ? (data['usedAt'] as Timestamp).toDate() : null,
      usedInTransactionId: data['usedInTransactionId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory CouponModel.fromMap(Map<String, dynamic> data) {
    return CouponModel(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      code: data['code'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      discountType: data['discountType'] == 'percentage'
          ? CouponType.percentage
          : CouponType.fixed,
      discount: data['discount'] ?? 0,
      minAmount: (data['minAmount'] ?? 0).toDouble(),
      status: _parseStatus(data['status']),
      expiryDate: data['expiryDate'] is Timestamp
          ? (data['expiryDate'] as Timestamp).toDate()
          : DateTime.parse(data['expiryDate']),
      usedAt: data['usedAt'] != null
          ? (data['usedAt'] is Timestamp
              ? (data['usedAt'] as Timestamp).toDate()
              : DateTime.parse(data['usedAt']))
          : null,
      usedInTransactionId: data['usedInTransactionId'],
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.parse(data['createdAt']),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'code': code,
      'title': title,
      'description': description,
      'discountType':
          discountType == CouponType.percentage ? 'percentage' : 'fixed',
      'discount': discount,
      'minAmount': minAmount,
      'status': status.toString().split('.').last,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'usedAt': usedAt != null ? Timestamp.fromDate(usedAt!) : null,
      'usedInTransactionId': usedInTransactionId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// 是否可用
  bool get isAvailable =>
      status == CouponStatus.available && !isExpired;

  /// 是否已过�?
  bool get isExpired => DateTime.now().isAfter(expiryDate);

  /// 是否已使�?
  bool get isUsed => status == CouponStatus.used;

  /// 计算折扣金额
  double calculateDiscount(double amount) {
    if (!isAvailable || amount < minAmount) {
      return 0.0;
    }

    if (discountType == CouponType.fixed) {
      return discount.toDouble();
    } else {
      // percentage
      return amount * (discount / 100);
    }
  }

  /// 计算最终金�?
  double calculateFinalAmount(double amount) {
    final discountAmount = calculateDiscount(amount);
    final finalAmount = amount - discountAmount;
    return finalAmount < 0 ? 0 : finalAmount;
  }

  /// 获取折扣显示文本
  String get discountDisplayText {
    if (discountType == CouponType.fixed) {
      return 'RM $discount';
    } else {
      return '$discount%';
    }
  }

  /// 获取状态显示名�?
  String get statusDisplayName {
    switch (status) {
      case CouponStatus.available:
        return '可用';
      case CouponStatus.used:
        return '已使�?;
      case CouponStatus.expired:
        return '已过�?;
    }
  }

  static CouponStatus _parseStatus(String? value) {
    switch (value?.toLowerCase()) {
      case 'used':
        return CouponStatus.used;
      case 'expired':
        return CouponStatus.expired;
      default:
        return CouponStatus.available;
    }
  }

  /// 标记为已使用
  CouponModel markAsUsed(String transactionId) {
    return copyWith(
      status: CouponStatus.used,
      usedAt: DateTime.now(),
      usedInTransactionId: transactionId,
      updatedAt: DateTime.now(),
    );
  }

  CouponModel copyWith({
    String? id,
    String? userId,
    String? code,
    String? title,
    String? description,
    CouponType? discountType,
    int? discount,
    double? minAmount,
    CouponStatus? status,
    DateTime? expiryDate,
    DateTime? usedAt,
    String? usedInTransactionId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CouponModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      discountType: discountType ?? this.discountType,
      discount: discount ?? this.discount,
      minAmount: minAmount ?? this.minAmount,
      status: status ?? this.status,
      expiryDate: expiryDate ?? this.expiryDate,
      usedAt: usedAt ?? this.usedAt,
      usedInTransactionId: usedInTransactionId ?? this.usedInTransactionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
