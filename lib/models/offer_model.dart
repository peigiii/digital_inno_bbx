import 'package:cloud_firestore/cloud_firestore.dart';

/// 报价模型
class OfferModel {
  final String id;
  final String listingId;
  final String recyclerId; // buyerId
  final String recyclerName;
  final String? recyclerCompany;
  final String? recyclerContact;
  final String producerId; // sellerId
  final double offerPrice;
  final double originalPrice; // 商品原价
  final String message;
  final String? sellerResponse; // 卖家回复
  final double? counterOfferPrice; // 还价金额
  final DateTime? collectionDate; // 预计收集日期
  final DateTime? scheduledPickupDate; // 预计收集日期（别名）
  final String? deliveryMethod; // 收集方式：self_pickup/platform_logistics/seller_delivery �?self_collect/delivery（新�?
  final String? deliveryNote; // 配送备�?
  final String status; // pending, negotiating, accepted, rejected, expired, cancelled
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt; // 48小时过期
  final DateTime? respondedAt; // 卖家回复时间
  final String? rejectionReason;

  OfferModel({
    required this.id,
    required this.listingId,
    required this.recyclerId,
    required this.recyclerName,
    this.recyclerCompany,
    this.recyclerContact,
    required this.producerId,
    required this.offerPrice,
    required this.originalPrice,
    this.message = '',
    this.sellerResponse,
    this.counterOfferPrice,
    this.collectionDate,
    this.scheduledPickupDate,
    this.deliveryMethod,
    this.deliveryNote,
    this.status = 'pending',
    this.createdAt,
    this.updatedAt,
    this.expiresAt,
    this.respondedAt,
    this.rejectionReason,
  });

  /// �?Firestore 文档创建
  factory OfferModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OfferModel.fromMap(doc.id, data);
  }

  /// �?Map 创建
  factory OfferModel.fromMap(String id, Map<String, dynamic> data) {
    return OfferModel(
      id: id,
      listingId: data['listingId'] ?? '',
      recyclerId: data['recyclerId'] ?? data['buyerId'] ?? '',
      recyclerName: data['recyclerName'] ?? '',
      recyclerCompany: data['recyclerCompany'],
      recyclerContact: data['recyclerContact'],
      producerId: data['producerId'] ?? data['sellerId'] ?? '',
      offerPrice: (data['offerPrice'] ?? 0).toDouble(),
      originalPrice: (data['originalPrice'] ?? 0).toDouble(),
      message: data['message'] ?? '',
      sellerResponse: data['sellerResponse'],
      counterOfferPrice: data['counterOfferPrice'] != null
          ? (data['counterOfferPrice'] as num).toDouble()
          : null,
      collectionDate: (data['collectionDate'] as Timestamp?)?.toDate(),
      scheduledPickupDate: (data['scheduledPickupDate'] as Timestamp?)?.toDate(),
      deliveryMethod: data['deliveryMethod'],
      deliveryNote: data['deliveryNote'],
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      respondedAt: (data['respondedAt'] as Timestamp?)?.toDate(),
      rejectionReason: data['rejectionReason'],
    );
  }

  /// 转换�?Map（用于Firestore�?
  Map<String, dynamic> toMap() {
    return {
      'listingId': listingId,
      'recyclerId': recyclerId,
      'buyerId': recyclerId, // 别名
      'recyclerName': recyclerName,
      'recyclerCompany': recyclerCompany,
      'recyclerContact': recyclerContact,
      'producerId': producerId,
      'sellerId': producerId, // 别名
      'offerPrice': offerPrice,
      'originalPrice': originalPrice,
      'message': message,
      'sellerResponse': sellerResponse,
      'counterOfferPrice': counterOfferPrice,
      'collectionDate': collectionDate != null ? Timestamp.fromDate(collectionDate!) : null,
      'scheduledPickupDate': scheduledPickupDate != null ? Timestamp.fromDate(scheduledPickupDate!) : null,
      'deliveryMethod': deliveryMethod,
      'deliveryNote': deliveryNote,
      'status': status,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'rejectionReason': rejectionReason,
    };
  }

  /// 复制并修改部分字�?
  OfferModel copyWith({
    double? offerPrice,
    double? originalPrice,
    String? message,
    String? sellerResponse,
    double? counterOfferPrice,
    DateTime? collectionDate,
    DateTime? scheduledPickupDate,
    String? deliveryMethod,
    String? deliveryNote,
    String? status,
    DateTime? expiresAt,
    DateTime? respondedAt,
    String? rejectionReason,
  }) {
    return OfferModel(
      id: id,
      listingId: listingId,
      recyclerId: recyclerId,
      recyclerName: recyclerName,
      recyclerCompany: recyclerCompany,
      recyclerContact: recyclerContact,
      producerId: producerId,
      offerPrice: offerPrice ?? this.offerPrice,
      originalPrice: originalPrice ?? this.originalPrice,
      message: message ?? this.message,
      sellerResponse: sellerResponse ?? this.sellerResponse,
      counterOfferPrice: counterOfferPrice ?? this.counterOfferPrice,
      collectionDate: collectionDate ?? this.collectionDate,
      scheduledPickupDate: scheduledPickupDate ?? this.scheduledPickupDate,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      deliveryNote: deliveryNote ?? this.deliveryNote,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      expiresAt: expiresAt ?? this.expiresAt,
      respondedAt: respondedAt ?? this.respondedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  /// 计算折扣百分�?
  double get discountPercentage {
    if (originalPrice <= 0) return 0;
    return ((originalPrice - offerPrice) / originalPrice * 100);
  }

  /// 检查是否过�?
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// 检查是否可以接�?
  bool get canAccept {
    return status == 'pending' || status == 'negotiating';
  }

  /// 检查是否可以议�?
  bool get canNegotiate {
    return status == 'pending' && !isExpired;
  }

  /// 是否待处�?
  bool get isPending => status == 'pending';

  /// 是否已接�?
  bool get isAccepted => status == 'accepted';

  /// 是否已拒�?
  bool get isRejected => status == 'rejected';

  /// 是否已取�?
  bool get isCancelled => status == 'cancelled';

  /// 是否正在议价
  bool get isNegotiating => status == 'negotiating';

  /// 获取状态显示文�?
  String get statusDisplay {
    switch (status) {
      case 'pending':
        return '待处�?;
      case 'negotiating':
        return '议价�?;
      case 'accepted':
        return '已接�?;
      case 'rejected':
        return '已拒�?;
      case 'expired':
        return '已过�?;
      case 'cancelled':
        return '已取�?;
      default:
        return status;
    }
  }

  /// 获取收集方式显示文本
  String get deliveryMethodDisplay {
    switch (deliveryMethod) {
      case 'self_pickup':
        return '自行收集';
      case 'platform_logistics':
        return '使用平台物流';
      case 'seller_delivery':
        return '卖家送货';
      case 'self_collect':
        return '自提';
      case 'delivery':
        return '邮寄';
      default:
        return deliveryMethod ?? '未指�?;
    }
  }

  /// 别名：buyerId
  String get buyerId => recyclerId;

  /// 别名：sellerId
  String get sellerId => producerId;

  @override
  String toString() {
    return 'OfferModel(id: $id, offerPrice: $offerPrice, status: $status, recyclerName: $recyclerName)';
  }
}
