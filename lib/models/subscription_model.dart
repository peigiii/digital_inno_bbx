import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionPlanType {
  free,
  basic,
  professional,
  enterprise,
}

<<<<<<< Updated upstream
/// 订阅状�?
=======
>>>>>>> Stashed changes
enum SubscriptionStatus {
  active,
  inactive,
  expired,
  cancelled,
}

class SubscriptionModel {
  final String id;
  final String userId;
  final SubscriptionPlanType planType;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime? endDate;
  final double price;
<<<<<<< Updated upstream
  final String period; // '1个月', '1�? �?
  final List<String> features;
=======
  final String period;   final List<String> features;
>>>>>>> Stashed changes
  final DateTime createdAt;
  final DateTime updatedAt;

  SubscriptionModel({
    required this.id,
    required this.userId,
    required this.planType,
    required this.status,
    required this.startDate,
    this.endDate,
    required this.price,
    required this.period,
    required this.features,
    required this.createdAt,
    required this.updatedAt,
  });

<<<<<<< Updated upstream
  /// �?Firestore 文档创建
  factory SubscriptionModel.fromFirestore(DocumentSnapshot doc) {
=======
    factory SubscriptionModel.fromFirestore(DocumentSnapshot doc) {
>>>>>>> Stashed changes
    final data = doc.data() as Map<String, dynamic>;

    return SubscriptionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      planType: _parsePlanType(data['planType']),
      status: _parseStatus(data['status']),
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate:
          data['endDate'] != null ? (data['endDate'] as Timestamp).toDate() : null,
      price: (data['price'] ?? 0).toDouble(),
      period: data['period'] ?? '1个月',
      features: List<String>.from(data['features'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

<<<<<<< Updated upstream
  /// �?Map 创建
  factory SubscriptionModel.fromMap(Map<String, dynamic> data) {
=======
    factory SubscriptionModel.fromMap(Map<String, dynamic> data) {
>>>>>>> Stashed changes
    return SubscriptionModel(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      planType: _parsePlanType(data['planType']),
      status: _parseStatus(data['status']),
      startDate: data['startDate'] is Timestamp
          ? (data['startDate'] as Timestamp).toDate()
          : DateTime.parse(data['startDate']),
      endDate: data['endDate'] != null
          ? (data['endDate'] is Timestamp
              ? (data['endDate'] as Timestamp).toDate()
              : DateTime.parse(data['endDate']))
          : null,
      price: (data['price'] ?? 0).toDouble(),
      period: data['period'] ?? '1个月',
      features: List<String>.from(data['features'] ?? []),
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.parse(data['createdAt']),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(data['updatedAt']),
    );
  }

<<<<<<< Updated upstream
  /// 转换�?Map
  Map<String, dynamic> toMap() {
=======
    Map<String, dynamic> toMap() {
>>>>>>> Stashed changes
    return {
      'userId': userId,
      'planType': planType.toString().split('.').last,
      'status': status.toString().split('.').last,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'price': price,
      'period': period,
      'features': features,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

<<<<<<< Updated upstream
  /// 是否激�?
  bool get isActive => status == SubscriptionStatus.active;
=======
    bool get isActive => status == SubscriptionStatus.active;
>>>>>>> Stashed changes

    bool get isExpired {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!);
  }

    int get daysRemaining {
    if (endDate == null) return 0;
    final difference = endDate!.difference(DateTime.now());
    return difference.inDays;
  }

    String get planDisplayName {
    switch (planType) {
      case SubscriptionPlanType.free:
        return 'Free';
      case SubscriptionPlanType.basic:
        return 'Basic';
      case SubscriptionPlanType.professional:
        return 'Professional';
      case SubscriptionPlanType.enterprise:
        return 'Enterprise';
    }
  }

<<<<<<< Updated upstream
  /// 获取状态显示名�?
  String get statusDisplayName {
    switch (status) {
      case SubscriptionStatus.active:
        return '激�?;
      case SubscriptionStatus.inactive:
        return '未激�?;
      case SubscriptionStatus.expired:
        return '已过�?;
      case SubscriptionStatus.cancelled:
        return '已取�?;
=======
    String get statusDisplayName {
    switch (status) {
      case SubscriptionStatus.active:
        return '激?';
      case SubscriptionStatus.inactive:
        return '未激?';
      case SubscriptionStatus.expired:
        return '已过?';
      case SubscriptionStatus.cancelled:
        return '已取?';
>>>>>>> Stashed changes
    }
  }

  static SubscriptionPlanType _parsePlanType(String? value) {
    switch (value?.toLowerCase()) {
      case 'basic':
        return SubscriptionPlanType.basic;
      case 'professional':
        return SubscriptionPlanType.professional;
      case 'enterprise':
        return SubscriptionPlanType.enterprise;
      default:
        return SubscriptionPlanType.free;
    }
  }

  static SubscriptionStatus _parseStatus(String? value) {
    switch (value?.toLowerCase()) {
      case 'active':
        return SubscriptionStatus.active;
      case 'inactive':
        return SubscriptionStatus.inactive;
      case 'expired':
        return SubscriptionStatus.expired;
      case 'cancelled':
        return SubscriptionStatus.cancelled;
      default:
        return SubscriptionStatus.inactive;
    }
  }

  SubscriptionModel copyWith({
    String? id,
    String? userId,
    SubscriptionPlanType? planType,
    SubscriptionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    double? price,
    String? period,
    List<String>? features,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubscriptionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      planType: planType ?? this.planType,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      price: price ?? this.price,
      period: period ?? this.period,
      features: features ?? this.features,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
