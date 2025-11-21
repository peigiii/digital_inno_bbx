import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserInitializer {
  /// 确保用户文档存在，不存在则创建默认文�?
  static Future<void> ensureUserDocumentExists() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);

      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        print('⚠️ 用户文档不存在，正在创建...');

        // 创建完整的用户文�?
        await docRef.set({
          'email': user.email ?? '',
          'displayName': user.displayName ?? user.email?.split('@')[0] ?? 'User',
          'userType': 'producer', // 默认类型
          'companyName': '',
          'city': '',
          'contact': '',
          'photoURL': '',
          'isAdmin': false,
          'verified': false,
          'createdAt': FieldValue.serverTimestamp(),
          'fcmToken': '',
          'averageRating': 0.0,
          'ratingCount': 0,
          'subscriptionPlan': 'free',
        });

        print('�?用户文档创建成功');
      } else {
        print('�?用户文档已存�?);
      }
    } catch (e) {
      print('�?初始化用户文档失�? $e');
    }
  }

  /// 修复现有用户的缺失字�?
  static Future<void> fixUserDocument(String userId) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId);

      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() ?? {};

        // 补充缺失的字�?
        Map<String, dynamic> updates = {};

        if (!data.containsKey('averageRating')) {
          updates['averageRating'] = 0.0;
        }
        if (!data.containsKey('ratingCount')) {
          updates['ratingCount'] = 0;
        }
        if (!data.containsKey('subscriptionPlan')) {
          updates['subscriptionPlan'] = 'free';
        }
        if (!data.containsKey('fcmToken')) {
          updates['fcmToken'] = '';
        }
        if (!data.containsKey('displayName') || data['displayName'] == null || data['displayName'] == '') {
          updates['displayName'] = data['email']?.split('@')[0] ?? 'User';
        }
        if (!data.containsKey('photoURL')) {
          updates['photoURL'] = '';
        }

        if (updates.isNotEmpty) {
          await docRef.update(updates);
          print('�?用户文档字段已修�?);
        }
      }
    } catch (e) {
      print('�?修复用户文档失败: $e');
    }
  }
}
