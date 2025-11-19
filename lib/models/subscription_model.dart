import 'package:cloud_firestore/cloud_firestore.dart';

/// 订阅计划类型
enum SubscriptionPlanType {
  free,
  basic,
  professional,
  enterprise,
}

/// 订阅状态
enum SubscriptionStatus {
  active,
  inactive,
  expired,
  cancelled,
}

/// 订阅模型
class SubscriptionModel {
  final String id;
  final String userId;
  final SubscriptionPlanType planType;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime? endDate;
  final double price;
  final String period; // '1个月', '1年' 等
  final List<String> features;
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

  /// 从 Firestore 文档创建
  factory SubscriptionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return SubscriptionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      planType: _parsePlanType(data['planType']),
      status: _parseStatus(data['status']),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate:
          data['endDate'] != null ? (data['endDate'] as Timestamp).toDate() : null,
      price: (data['price'] ?? 0).toDouble(),
      period: data['period'] ?? '1个月',
      features: List<String>.from(data['features'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// 从 Map 创建
  factory SubscriptionModel.fromMap(Map<String, dynamic> data) {
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

  /// 转换为 Map
  Map<String, dynamic> toMap() {
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

  /// 是否激活
  bool get isActive => status == SubscriptionStatus.active;

  /// 是否过期
  bool get isExpired {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!);
  }

  /// 剩余天数
  int get daysRemaining {
    if (endDate == null) return 0;
    final difference = endDate!.difference(DateTime.now());
    return difference.inDays;
  }

  /// 获取计划显示名称
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

  /// 获取状态显示名称
  String get statusDisplayName {
    switch (status) {
      case SubscriptionStatus.active:
        return '激活';
      case SubscriptionStatus.inactive:
        return '未激活';
      case SubscriptionStatus.expired:
        return '已过期';
      case SubscriptionStatus.cancelled:
        return '已取消';
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
