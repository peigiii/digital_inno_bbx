import 'package:cloud_firestore/cloud_firestore.dart';

class LogisticsUpdateModel {
  final String id;
  final String transactionId;   final String status;   final String? location;   final String description;   final String? imageUrl;   final String createdBy;   final DateTime createdAt; 
  LogisticsUpdateModel({
    required this.id,
    required this.transactionId,
    required this.status,
    this.location,
    required this.description,
    this.imageUrl,
    required this.createdBy,
    required this.createdAt,
  });

    factory LogisticsUpdateModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LogisticsUpdateModel.fromMap(doc.id, data);
  }

    factory LogisticsUpdateModel.fromMap(String id, Map<String, dynamic> data) {
    return LogisticsUpdateModel(
      id: id,
      transactionId: data['transactionId'] ?? '',
      status: data['status'] ?? '',
      location: data['location'],
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

    Map<String, dynamic> toMap() {
    return {
      'transactionId': transactionId,
      'status': status,
      'location': location,
      'description': description,
      'imageUrl': imageUrl,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

    LogisticsUpdateModel copyWith({
    String? status,
    String? location,
    String? description,
    String? imageUrl,
  }) {
    return LogisticsUpdateModel(
      id: id,
      transactionId: transactionId,
      status: status ?? this.status,
      location: location ?? this.location,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }

    String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'WaitSend?';
      case 'picked_up':
        return 'AlreadyTake?';
      case 'in_transit':
        return 'LuckLose?';
      case 'delivered':
        return 'Delivered';
      case 'completed':
        return 'AlreadyDone?';
      default:
        return status;
    }
  }

  @override
  String toString() {
    return 'LogisticsUpdateModel(id: $id, transactionId: $transactionId, status: $status, description: $description)';
  }
}
