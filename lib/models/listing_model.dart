import 'package:cloud_firestore/cloud_firestore.dart';

/// 废料列表模型
class ListingModel {
  final String id;
  final String userId;
  final String userEmail;
  final String title;
  final String description;
  final String wasteType;
  final double quantity;
  final String unit;
  final double pricePerUnit;
  final String contactInfo;
  final Map<String, dynamic>? location; // {latitude: double, longitude: double}
  final List<String> imageUrls;
  final String status; // available, pending, sold, expired
  final String complianceStatus; // pending, approved, rejected
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;

  ListingModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.title,
    required this.description,
    required this.wasteType,
    required this.quantity,
    required this.unit,
    required this.pricePerUnit,
    required this.contactInfo,
    this.location,
    this.imageUrls = const [],
    this.status = 'available',
    this.complianceStatus = 'pending',
    this.createdAt,
    this.updatedAt,
    this.expiresAt,
  });

  /// �?Firestore 文档创建
  factory ListingModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ListingModel.fromMap(doc.id, data);
  }

  /// �?Map 创建
  factory ListingModel.fromMap(String id, Map<String, dynamic> data) {
    return ListingModel(
      id: id,
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      wasteType: data['wasteType'] ?? '',
      quantity: (data['quantity'] ?? 0).toDouble(),
      unit: data['unit'] ?? '',
      pricePerUnit: (data['pricePerUnit'] ?? 0).toDouble(),
      contactInfo: data['contactInfo'] ?? '',
      location: data['location'] as Map<String, dynamic>?,
      imageUrls: (data['imageUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      status: data['status'] ?? 'available',
      complianceStatus: data['complianceStatus'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
    );
  }

  /// 转换�?Map（用于Firestore�?
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'title': title,
      'description': description,
      'wasteType': wasteType,
      'quantity': quantity,
      'unit': unit,
      'pricePerUnit': pricePerUnit,
      'contactInfo': contactInfo,
      'location': location,
      'imageUrls': imageUrls,
      'status': status,
      'complianceStatus': complianceStatus,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    };
  }

  /// 复制并修改部分字�?
  ListingModel copyWith({
    String? title,
    String? description,
    String? wasteType,
    double? quantity,
    String? unit,
    double? pricePerUnit,
    String? contactInfo,
    Map<String, dynamic>? location,
    List<String>? imageUrls,
    String? status,
    String? complianceStatus,
    DateTime? expiresAt,
  }) {
    return ListingModel(
      id: id,
      userId: userId,
      userEmail: userEmail,
      title: title ?? this.title,
      description: description ?? this.description,
      wasteType: wasteType ?? this.wasteType,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      contactInfo: contactInfo ?? this.contactInfo,
      location: location ?? this.location,
      imageUrls: imageUrls ?? this.imageUrls,
      status: status ?? this.status,
      complianceStatus: complianceStatus ?? this.complianceStatus,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  /// 计算总价
  double get totalPrice => quantity * pricePerUnit;

  /// 是否可用
  bool get isAvailable => status == 'available';

  /// 是否已过�?
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// 是否通过合规审核
  bool get isCompliant => complianceStatus == 'approved';

  /// 获取位置坐标
  double? get latitude => location?['latitude'] as double?;
  double? get longitude => location?['longitude'] as double?;

  /// 获取废料类型显示文本
  String get wasteTypeDisplay {
    switch (wasteType) {
      case 'EFB (Empty Fruit Bunches)':
        return '棕榈空果�?;
      case 'POME (Palm Oil Mill Effluent)':
        return '棕榈油厂废水';
      case 'Palm Shell':
        return '棕榈�?;
      case 'Palm Fiber':
        return '棕榈纤维';
      case 'Palm Kernel Cake':
        return '棕榈仁饼';
      case 'Coconut Husk':
        return '椰壳';
      case 'Rice Husk':
        return '稻壳';
      case 'Sugarcane Bagasse':
        return '甘蔗�?;
      case 'Wood Chips':
        return '木屑';
      case 'Other Biomass':
        return '其他生物�?;
      default:
        return wasteType;
    }
  }

  /// 获取状态显示文�?
  String get statusDisplay {
    switch (status) {
      case 'available':
        return '可用';
      case 'pending':
        return '待处�?;
      case 'sold':
        return '已售�?;
      case 'expired':
        return '已过�?;
      default:
        return status;
    }
  }

  // Compatibility getters for backward compatibility
  List<String> get images => imageUrls;
  String get category => wasteType;
  String get sellerName => userEmail.split('@').first;

  @override
  String toString() {
    return 'ListingModel(id: $id, title: $title, wasteType: $wasteType, quantity: $quantity $unit, status: $status)';
  }
}

// Backward compatibility typedef
typedef Listing = ListingModel;

// Add fromFirestore as an extension
extension ListingModelExtensions on ListingModel {
  static ListingModel fromFirestore(DocumentSnapshot doc) {
    return ListingModel.fromDocument(doc);
  }
}
