import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import '../utils/app_constants.dart';

/// 废料列表服务
/// 提供列表的CRUD操作和搜索功能
class ListingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 创建废料列表
  Future<String> createListing(ListingModel listing) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('用户未登录');

      // 确保设置了必要字段
      final listingData = listing.copyWith(
        userId: user.uid,
        userEmail: user.email ?? '',
        status: ListingStatusConstants.available,
        complianceStatus: 'pending',
      );

      final docRef = await _firestore
          .collection(CollectionConstants.listings)
          .add(listingData.toMap())
          .timeout(ApiConstants.defaultTimeout);

      return docRef.id;
    } catch (e) {
      throw Exception('创建列表失败: $e');
    }
  }

  /// 更新废料列表
  Future<void> updateListing(String listingId, Map<String, dynamic> updates) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('用户未登录');

      // 获取现有列表
      final doc = await _firestore
          .collection(CollectionConstants.listings)
          .doc(listingId)
          .get();

      if (!doc.exists) throw Exception('列表不存在');

      final listing = ListingModel.fromDocument(doc);

      // 验证权限
      if (listing.userId != user.uid) {
        // 检查是否是管理员
        final userDoc = await _firestore.collection(CollectionConstants.users).doc(user.uid).get();
        final isAdmin = userDoc.data()?['isAdmin'] ?? false;
        if (!isAdmin) throw Exception('无权限修改此列表');
      }

      // 添加更新时间
      final finalUpdates = {
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection(CollectionConstants.listings)
          .doc(listingId)
          .update(finalUpdates)
          .timeout(ApiConstants.defaultTimeout);
    } catch (e) {
      throw Exception('更新列表失败: $e');
    }
  }

  /// 删除废料列表
  Future<void> deleteListing(String listingId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('用户未登录');

      // 获取现有列表
      final doc = await _firestore
          .collection(CollectionConstants.listings)
          .doc(listingId)
          .get();

      if (!doc.exists) throw Exception('列表不存在');

      final listing = ListingModel.fromDocument(doc);

      // 验证权限
      if (listing.userId != user.uid) {
        final userDoc = await _firestore.collection(CollectionConstants.users).doc(user.uid).get();
        final isAdmin = userDoc.data()?['isAdmin'] ?? false;
        if (!isAdmin) throw Exception('无权限删除此列表');
      }

      // 检查是否有待处理的报价
      final offers = await _firestore
          .collection(CollectionConstants.offers)
          .where('listingId', isEqualTo: listingId)
          .where('status', isEqualTo: OfferStatusConstants.pending)
          .get();

      if (offers.docs.isNotEmpty) {
        throw Exception('该列表有待处理的报价，无法删除');
      }

      // 软删除：更新状态而不是实际删除
      await _firestore
          .collection(CollectionConstants.listings)
          .doc(listingId)
          .update({
        'status': 'deleted',
        'deletedAt': FieldValue.serverTimestamp(),
      }).timeout(ApiConstants.defaultTimeout);
    } catch (e) {
      throw Exception('删除列表失败: $e');
    }
  }

  /// 获取单个列表
  Future<ListingModel?> getListing(String listingId) async {
    try {
      final doc = await _firestore
          .collection(CollectionConstants.listings)
          .doc(listingId)
          .get()
          .timeout(ApiConstants.defaultTimeout);

      if (!doc.exists) return null;

      return ListingModel.fromDocument(doc);
    } catch (e) {
      throw Exception('获取列表失败: $e');
    }
  }

  /// 获取用户的列表（Stream）
  Stream<List<ListingModel>> getUserListings({String? userId}) {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _firestore
        .collection(CollectionConstants.listings)
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(PaginationConstants.largePageSize)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ListingModel.fromDocument(doc)).toList());
  }

  /// 搜索列表
  Future<List<ListingModel>> searchListings({
    String? category,
    String? status,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore.collection(CollectionConstants.listings);

      // 筛选条件
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      } else {
        query = query.where('status', isEqualTo: ListingStatusConstants.available);
      }

      if (category != null && category != 'all') {
        query = query.where('wasteType', isEqualTo: category);
      }

      query = query.orderBy('createdAt', descending: true);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(limit);

      final snapshot = await query.get().timeout(ApiConstants.defaultTimeout);

      return snapshot.docs.map((doc) => ListingModel.fromDocument(doc)).toList();
    } catch (e) {
      throw Exception('搜索列表失败: $e');
    }
  }

  /// 标记列表为已售出
  Future<void> markAsSold(String listingId) async {
    await updateListing(listingId, {
      'status': ListingStatusConstants.sold,
    });
  }

  /// 标记列表为已过期
  Future<void> markAsExpired(String listingId) async {
    await updateListing(listingId, {
      'status': ListingStatusConstants.expired,
    });
  }

  /// 批量删除列表
  Future<void> bulkDeleteListings(List<String> listingIds) async {
    try {
      final batch = _firestore.batch();

      for (final id in listingIds) {
        final docRef = _firestore.collection(CollectionConstants.listings).doc(id);
        batch.update(docRef, {
          'status': 'deleted',
          'deletedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit().timeout(ApiConstants.defaultTimeout);
    } catch (e) {
      throw Exception('批量删除失败: $e');
    }
  }

  /// 批量更新状态
  Future<void> bulkUpdateStatus(List<String> listingIds, String status) async {
    try {
      final batch = _firestore.batch();

      for (final id in listingIds) {
        final docRef = _firestore.collection(CollectionConstants.listings).doc(id);
        batch.update(docRef, {
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit().timeout(ApiConstants.defaultTimeout);
    } catch (e) {
      throw Exception('批量更新失败: $e');
    }
  }

  /// 获取统计信息
  Future<Map<String, int>> getStatistics(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(CollectionConstants.listings)
          .where('userId', isEqualTo: userId)
          .get()
          .timeout(ApiConstants.defaultTimeout);

      int total = 0;
      int available = 0;
      int sold = 0;
      int expired = 0;

      for (final doc in snapshot.docs) {
        final listing = ListingModel.fromDocument(doc);
        total++;
        switch (listing.status) {
          case ListingStatusConstants.available:
            available++;
            break;
          case ListingStatusConstants.sold:
            sold++;
            break;
          case ListingStatusConstants.expired:
            expired++;
            break;
        }
      }

      return {
        'total': total,
        'available': available,
        'sold': sold,
        'expired': expired,
      };
    } catch (e) {
      throw Exception('获取统计失败: $e');
    }
  }
}
