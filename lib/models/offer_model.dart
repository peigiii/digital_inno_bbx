import 'package:cloud_firestore/cloud_firestore.dart';

/// 报价模型
class OfferModel {
  final String id;
  final String listingId;
  final String recyclerId;
  final String recyclerName;
  final String? recyclerCompany;
  final String? recyclerContact;
  final String producerId;
  final double offerPrice;
  final String message;
  final DateTime? collectionDate;
  final String status; // pending, accepted, rejected, cancelled
  final DateTime? createdAt;
  final DateTime? updatedAt;
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
    this.message = '',
    this.collectionDate,
    this.status = 'pending',
    this.createdAt,
    this.updatedAt,
    this.rejectionReason,
  });

  /// 从 Firestore 文档创建
  factory OfferModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OfferModel.fromMap(doc.id, data);
  }

  /// 从 Map 创建
  factory OfferModel.fromMap(String id, Map<String, dynamic> data) {
    return OfferModel(
      id: id,
      listingId: data['listingId'] ?? '',
      recyclerId: data['recyclerId'] ?? '',
      recyclerName: data['recyclerName'] ?? '',
      recyclerCompany: data['recyclerCompany'],
      recyclerContact: data['recyclerContact'],
      producerId: data['producerId'] ?? '',
      offerPrice: (data['offerPrice'] ?? 0).toDouble(),
      message: data['message'] ?? '',
      collectionDate: (data['collectionDate'] as Timestamp?)?.toDate(),
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      rejectionReason: data['rejectionReason'],
    );
  }

  /// 转换为 Map（用于Firestore）
  Map<String, dynamic> toMap() {
    return {
      'listingId': listingId,
      'recyclerId': recyclerId,
      'recyclerName': recyclerName,
      'recyclerCompany': recyclerCompany,
      'recyclerContact': recyclerContact,
      'producerId': producerId,
      'offerPrice': offerPrice,
      'message': message,
      'collectionDate': collectionDate != null ? Timestamp.fromDate(collectionDate!) : null,
      'status': status,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'rejectionReason': rejectionReason,
    };
  }

  /// 复制并修改部分字段
  OfferModel copyWith({
    double? offerPrice,
    String? message,
    DateTime? collectionDate,
    String? status,
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
      message: message ?? this.message,
      collectionDate: collectionDate ?? this.collectionDate,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  /// 是否待处理
  bool get isPending => status == 'pending';

  /// 是否已接受
  bool get isAccepted => status == 'accepted';

  /// 是否已拒绝
  bool get isRejected => status == 'rejected';

  /// 是否已取消
  bool get isCancelled => status == 'cancelled';

  /// 获取状态显示文本
  String get statusDisplay {
    switch (status) {
      case 'pending':
        return '待处理';
      case 'accepted':
        return '已接受';
      case 'rejected':
        return '已拒绝';
      case 'cancelled':
        return '已取消';
      default:
        return status;
    }
  }

  @override
  String toString() {
    return 'OfferModel(id: $id, offerPrice: $offerPrice, status: $status, recyclerName: $recyclerName)';
  }
}
