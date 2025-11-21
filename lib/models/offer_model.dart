import 'package:cloud_firestore/cloud_firestore.dart';

class OfferModel {
  final String id;
  final String listingId;
  final String recyclerId; // buyerId
  final String recyclerName;
  final String? recyclerCompany;
  final String? recyclerContact;
  final String producerId; // sellerId
  final double offerPrice;
  final double originalPrice;   final String message;
  final String? sellerResponse;   final double? counterOfferPrice;   final DateTime? collectionDate;   final DateTime? scheduledPickupDate;   final String? deliveryMethod;   final String? deliveryNote;   final String status; // pending, negotiating, accepted, rejected, expired, cancelled
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;   final DateTime? respondedAt;   final String? rejectionReason;

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

    factory OfferModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OfferModel.fromMap(doc.id, data);
  }

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

    Map<String, dynamic> toMap() {
    return {
      'listingId': listingId,
      'recyclerId': recyclerId,
      'buyerId': recyclerId,       'recyclerName': recyclerName,
      'recyclerCompany': recyclerCompany,
      'recyclerContact': recyclerContact,
      'producerId': producerId,
      'sellerId': producerId,       'offerPrice': offerPrice,
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

    double get discountPercentage {
    if (originalPrice <= 0) return 0;
    return ((originalPrice - offerPrice) / originalPrice * 100);
  }

    bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

    bool get canAccept {
    return status == 'pending' || status == 'negotiating';
  }

    bool get canNegotiate {
    return status == 'pending' && !isExpired;
  }

    bool get isPending => status == 'pending';

    bool get isAccepted => status == 'accepted';

    bool get isRejected => status == 'rejected';

    bool get isCancelled => status == 'cancelled';

    bool get isNegotiating => status == 'negotiating';

    String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'negotiating':
        return 'Negotiating';
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      case 'expired':
        return 'Expired';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

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
        return deliveryMethod ?? 'Not specified';
    }
  }

    String get buyerId => recyclerId;

    String get sellerId => producerId;

  @override
  String toString() {
    return 'OfferModel(id: $id, offerPrice: $offerPrice, status: $status, recyclerName: $recyclerName)';
  }
}
