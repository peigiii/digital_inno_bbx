import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final String userType; // producer, processor, recycler, public
  final bool isAdmin;
  final String? companyName;
  final String? city;
  final String? contact;
  final String? fcmToken;
  final double averageRating;
  final int ratingCount;
  final bool verified;
  final String subscriptionPlan; // free, basic, professional, enterprise
  final Map<String, dynamic>? creditScore;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    this.userType = 'public',
    this.isAdmin = false,
    this.companyName,
    this.city,
    this.contact,
    this.fcmToken,
    this.averageRating = 0.0,
    this.ratingCount = 0,
    this.verified = false,
    this.subscriptionPlan = 'free',
    this.creditScore,
    this.createdAt,
    this.updatedAt,
  });

    factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(doc.id, data);
  }

    factory UserModel.fromMap(String uid, Map<String, dynamic> data) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoURL: data['photoURL'],
      userType: data['userType'] ?? 'public',
      isAdmin: data['isAdmin'] ?? false,
      companyName: data['companyName'],
      city: data['city'],
      contact: data['contact'],
      fcmToken: data['fcmToken'],
      averageRating: (data['averageRating'] ?? 0).toDouble(),
      ratingCount: data['ratingCount'] ?? 0,
      verified: data['verified'] ?? false,
      subscriptionPlan: data['subscriptionPlan'] ?? 'free',
      creditScore: data['creditScore'] as Map<String, dynamic>?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

    Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'userType': userType,
      'isAdmin': isAdmin,
      'companyName': companyName,
      'city': city,
      'contact': contact,
      'fcmToken': fcmToken,
      'averageRating': averageRating,
      'ratingCount': ratingCount,
      'verified': verified,
      'subscriptionPlan': subscriptionPlan,
      'creditScore': creditScore,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

    UserModel copyWith({
    String? email,
    String? displayName,
    String? photoURL,
    String? userType,
    bool? isAdmin,
    String? companyName,
    String? city,
    String? contact,
    String? fcmToken,
    double? averageRating,
    int? ratingCount,
    bool? verified,
    String? subscriptionPlan,
    Map<String, dynamic>? creditScore,
  }) {
    return UserModel(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      userType: userType ?? this.userType,
      isAdmin: isAdmin ?? this.isAdmin,
      companyName: companyName ?? this.companyName,
      city: city ?? this.city,
      contact: contact ?? this.contact,
      fcmToken: fcmToken ?? this.fcmToken,
      averageRating: averageRating ?? this.averageRating,
      ratingCount: ratingCount ?? this.ratingCount,
      verified: verified ?? this.verified,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      creditScore: creditScore ?? this.creditScore,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

    String get userTypeDisplay {
    switch (userType) {
      case 'producer':
        return 'Producer';
      case 'processor':
        return 'Processor';
      case 'recycler':
        return 'Recycler';
      case 'public':
        return 'Public User';
      default:
        return userType;
    }
  }

    String get subscriptionPlanDisplay {
    switch (subscriptionPlan) {
      case 'free':
        return 'Free';
      case 'basic':
        return 'Basic';
      case 'professional':
        return 'Professional';
      case 'enterprise':
        return 'Enterprise';
      default:
        return subscriptionPlan;
    }
  }

    bool get isPremium => subscriptionPlan != 'free';

    int? get creditScoreValue => creditScore?['totalScore'] as int?;

    String? get creditLevel => creditScore?['creditLevel'] as String?;

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, displayName: $displayName, userType: $userType)';
  }
}
