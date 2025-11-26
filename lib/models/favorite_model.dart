import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteModel {
  final String id;
  final String userId;
  final String listingId;
  final DateTime createdAt;

  FavoriteModel({
    required this.id,
    required this.userId,
    required this.listingId,
    required this.createdAt,
  });

  /// Create FavoriteModel from Firestore DocumentSnapshot
  factory FavoriteModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('Document data is null for favorite: ${doc.id}');
    }

    return FavoriteModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      listingId: data['listingId'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Create FavoriteModel from Map
  factory FavoriteModel.fromMap(String id, Map<String, dynamic> data) {
    return FavoriteModel(
      id: id,
      userId: data['userId'] as String? ?? '',
      listingId: data['listingId'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert FavoriteModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'listingId': listingId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Convert to Map for creation (using server timestamp)
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'listingId': listingId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  @override
  String toString() {
    return 'FavoriteModel(id: $id, userId: $userId, listingId: $listingId, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FavoriteModel &&
        other.id == id &&
        other.userId == userId &&
        other.listingId == listingId;
  }

  @override
  int get hashCode => Object.hash(id, userId, listingId);
}
