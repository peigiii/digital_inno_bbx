import 'package:cloud_firestore/cloud_firestore.dart';

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

    factory ListingModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ListingModel.fromMap(doc.id, data);
  }

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

    double get totalPrice => quantity * pricePerUnit;

    bool get isAvailable => status == 'available';

    bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

    bool get isCompliant => complianceStatus == 'approved';

    double? get latitude => location?['latitude'] as double?;
  double? get longitude => location?['longitude'] as double?;

    String get wasteTypeDisplay {
    switch (wasteType) {
      case 'EFB (Empty Fruit Bunches)':
        return 'EFB (Empty Fruit Bunches)';
      case 'POME (Palm Oil Mill Effluent)':
        return 'POME';
      case 'Palm Shell':
        return 'Palm Shell';
      case 'Palm Fiber':
        return 'Palm Fiber';
      case 'Palm Kernel Cake':
        return 'Palm Kernel Cake';
      case 'Coconut Husk':
        return 'Coconut Husk';
      case 'Rice Husk':
        return 'Rice Husk';
      case 'Sugarcane Bagasse':
        return 'Sugarcane Bagasse';
      case 'Wood Chips':
        return 'Wood Chips';
      case 'Other Biomass':
        return 'Other Biomass';
      default:
        return wasteType;
    }
  }

    String get statusDisplay {
    switch (status) {
      case 'available':
        return '可用';
      case 'pending':
        return 'Pending';
      case 'sold':
        return 'Sold';
      case 'expired':
        return 'Expired';
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
