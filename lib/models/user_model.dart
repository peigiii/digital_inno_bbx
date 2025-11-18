import 'package:cloud_firestore/cloud_firestore.dart';

/// 用户模型
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

  /// 从 Firestore 文档创建
  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(doc.id, data);
  }

  /// 从 Map 创建
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

  /// 转换为 Map（用于Firestore）
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

  /// 复制并修改部分字段
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

  /// 获取用户类型显示文本
  String get userTypeDisplay {
    switch (userType) {
      case 'producer':
        return '生产者';
      case 'processor':
        return '处理者';
      case 'recycler':
        return '回收商';
      case 'public':
        return '普通用户';
      default:
        return userType;
    }
  }

  /// 获取订阅计划显示文本
  String get subscriptionPlanDisplay {
    switch (subscriptionPlan) {
      case 'free':
        return '免费版';
      case 'basic':
        return '基础版';
      case 'professional':
        return '专业版';
      case 'enterprise':
        return '企业版';
      default:
        return subscriptionPlan;
    }
  }

  /// 是否是高级用户
  bool get isPremium => subscriptionPlan != 'free';

  /// 获取信用评分
  int? get creditScoreValue => creditScore?['totalScore'] as int?;

  /// 获取信用等级
  String? get creditLevel => creditScore?['creditLevel'] as String?;

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, displayName: $displayName, userType: $userType)';
  }
}
