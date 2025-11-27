import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class DashboardCounterService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 获取用户的报价数量（待处理的）
  static Stream<int> getPendingQuotesCount() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('offers')
        .where('buyerId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      debugPrint('📊 [Counter] Pending quotes: ${snapshot.docs.length}');
      return snapshot.docs.length;
    }).handleError((error) {
      debugPrint('❌ [Counter] Error getting quotes count: $error');
      return 0;
    });
  }

  /// 获取用户的交易数量（进行中的）
  static Stream<int> getOngoingTransactionsCount() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('transactions')
        .where('participants', arrayContains: currentUser.uid)
        .where('status', whereIn: ['pending', 'in_progress', 'confirmed'])
        .snapshots()
        .map((snapshot) {
      debugPrint('📊 [Counter] Ongoing transactions: ${snapshot.docs.length}');
      return snapshot.docs.length;
    }).handleError((error) {
      debugPrint('❌ [Counter] Error getting transactions count: $error');
      return 0;
    });
  }

  /// 获取用户的收藏数量
  static Stream<int> getFavoritesCount() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('favorites')
        .where('userId', isEqualTo: currentUser.uid)
        .snapshots()
        .map((snapshot) {
      debugPrint('📊 [Counter] Favorites: ${snapshot.docs.length}');
      return snapshot.docs.length;
    }).handleError((error) {
      debugPrint('❌ [Counter] Error getting favorites count: $error');
      return 0;
    });
  }

  /// 获取用户收到的报价数量（作为卖家）
  static Stream<int> getReceivedQuotesCount() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('offers')
        .where('sellerId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      debugPrint('📊 [Counter] Received quotes: ${snapshot.docs.length}');
      return snapshot.docs.length;
    }).handleError((error) {
      debugPrint('❌ [Counter] Error getting received quotes count: $error');
      return 0;
    });
  }

  /// 获取用户的商品数量
  static Stream<int> getMyListingsCount() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('listings')
        .where('userId', isEqualTo: currentUser.uid)
        .where('status', whereIn: ['available', 'open'])
        .snapshots()
        .map((snapshot) {
      debugPrint('📊 [Counter] My listings: ${snapshot.docs.length}');
      return snapshot.docs.length;
    }).handleError((error) {
      debugPrint('❌ [Counter] Error getting listings count: $error');
      return 0;
    });
  }

  /// 获取附近的商品数量（简化版本，返回所有可用商品）
  static Stream<int> getNearbyItemsCount() {
    return _firestore
        .collection('listings')
        .where('status', whereIn: ['available', 'open'])
        .limit(50) // 限制查询数量以提高性能
        .snapshots()
        .map((snapshot) {
      debugPrint('📊 [Counter] Nearby items: ${snapshot.docs.length}');
      return snapshot.docs.length;
    }).handleError((error) {
      debugPrint('❌ [Counter] Error getting nearby items count: $error');
      return 0;
    });
  }
}
