import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// 用户服务
class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 根据用户ID获取用户信息
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        return null;
      }
      return UserModel.fromDocument(doc);
    } catch (e) {
      print('获取用户信息失败: $e');
      return null;
    }
  }

  /// 获取用户信息（Stream�?
  Stream<UserModel?> getUserStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) {
        return null;
      }
      return UserModel.fromDocument(doc);
    });
  }
}
