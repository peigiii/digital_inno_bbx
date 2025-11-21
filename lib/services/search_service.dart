import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/listing_model.dart';

/// 搜索服务类
class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 获取当前用户ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// 高级搜索
  ///
  /// 参数：
  /// - keyword: 关键词
  /// - wasteTypes: 废料类型列表
  /// - minPrice: 最低价格
  /// - maxPrice: 最高价格
  /// - minQuantity: 最低数量
  /// - maxQuantity: 最高数量
  /// - location: 地点
  /// - maxDistance: 最大距离（km）
  /// - minRating: 最低评分
  /// - verifiedOnly: 只显示认证卖家
  /// - sortBy: 排序字段（price/quantity/date/distance）
  /// - ascending: 升序/降序
  ///
  /// 返回：商品列表
  Future<List<ListingModel>> advancedSearch({
    String? keyword,
    List<String>? wasteTypes,
    double? minPrice,
    double? maxPrice,
    double? minQuantity,
    double? maxQuantity,
    String? location,
    double? maxDistance,
    double? minRating,
    bool verifiedOnly = false,
    String sortBy = 'date',
    bool ascending = false,
  }) async {
    // 构建基础查询
    Query query = _firestore.collection('listings');

    // 基础条件：只查询可用的商品
    query = query.where('status', isEqualTo: 'available');

    // 废料类型筛选
    if (wasteTypes != null && wasteTypes.isNotEmpty) {
      query = query.where('wasteType', whereIn: wasteTypes);
    }

    // 价格范围筛选
    if (minPrice != null && minPrice > 0) {
      query = query.where('pricePerUnit', isGreaterThanOrEqualTo: minPrice);
    }
    if (maxPrice != null && maxPrice > 0) {
      query = query.where('pricePerUnit', isLessThanOrEqualTo: maxPrice);
    }

    // 认证卖家筛选
    // 注意：这需要在 Firestore 中添加 sellerVerified 字段
    // if (verifiedOnly) {
    //   query = query.where('sellerVerified', isEqualTo: true);
    // }

    // 排序
    String orderByField = 'createdAt';
    switch (sortBy) {
      case 'price':
        orderByField = 'pricePerUnit';
        break;
      case 'quantity':
        orderByField = 'quantity';
        break;
      case 'date':
        orderByField = 'createdAt';
        break;
      default:
        orderByField = 'createdAt';
    }

    query = query.orderBy(orderByField, descending: !ascending);

    // 限制结果数量
    query = query.limit(100);

    // 执行查询
    final snapshot = await query.get();
    List<ListingModel> results = snapshot.docs.map((doc) => ListingModel.fromDocument(doc)).toList();

    // 客户端筛选（Firestore无法实现的条件）
    results = results.where((listing) {
      // 关键词筛选
      if (keyword != null && keyword.isNotEmpty) {
        final keywordLower = keyword.toLowerCase();
        final titleMatch = listing.title.toLowerCase().contains(keywordLower);
        final descMatch = listing.description.toLowerCase().contains(keywordLower);
        final typeMatch = listing.wasteType.toLowerCase().contains(keywordLower);
        if (!titleMatch && !descMatch && !typeMatch) {
          return false;
        }
      }

      // 数量范围筛选
      if (minQuantity != null && listing.quantity < minQuantity) {
        return false;
      }
      if (maxQuantity != null && listing.quantity > maxQuantity) {
        return false;
      }

      // TODO: 评分筛选（需要计算卖家评分）
      // if (minRating != null && listing.sellerRating < minRating) {
      //   return false;
      // }

      // TODO: 地理位置距离筛选
      // if (maxDistance != null && location != null) {
      //   final distance = calculateDistance(...);
      //   if (distance > maxDistance) {
      //     return false;
      //   }
      // }

      return true;
    }).toList();

    // 保存搜索历史
    if (keyword != null && keyword.isNotEmpty) {
      _saveSearchHistory(keyword, wasteTypes);
    }

    return results;
  }

  /// 智能推荐
  ///
  /// 基于用户偏好推荐商品
  Future<List<ListingModel>> getRecommendations() async {
    if (_currentUserId == null) {
      return [];
    }

    // 获取用户偏好
    final preferences = await _getUserPreferences(_currentUserId!);

    // 构建查询
    Query query = _firestore.collection('listings');

    // 基础条件
    query = query.where('status', isEqualTo: 'available');

    // 排除自己发布的商品
    query = query.where('userId', isNotEqualTo: _currentUserId);

    // 如果有偏好，优先推荐用户感兴趣的废料类型
    if (preferences.isNotEmpty) {
      query = query.where('wasteType', whereIn: preferences.take(10).toList());
    }

    // 按创建时间降序
    query = query.orderBy('createdAt', descending: true);

    // 限制结果
    query = query.limit(20);

    // 执行查询
    final snapshot = await query.get();
    List<ListingModel> results = snapshot.docs.map((doc) => ListingModel.fromDocument(doc)).toList();

    // 智能排序
    results = _rankByRelevance(results);

    // 返回前10个
    return results.take(10).toList();
  }

  /// 获取用户偏好
  ///
  /// 基于用户的报价记录，分析用户感兴趣的废料类型
  Future<List<String>> _getUserPreferences(String userId) async {
    try {
      // 获取用户的报价记录
      final offersSnapshot = await _firestore
          .collection('offers')
          .where('buyerId', isEqualTo: userId)
          .limit(20)
          .get();

      // 提取商品ID
      final listingIds = offersSnapshot.docs
          .map((doc) => doc.data()['listingId'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .toSet()
          .toList();

      if (listingIds.isEmpty) {
        return [];
      }

      // 获取商品的废料类型
      final wasteTypes = <String>[];
      for (var listingId in listingIds.take(10)) {
        final listingDoc = await _firestore.collection('listings').doc(listingId).get();
        if (listingDoc.exists) {
          final listing = ListingModel.fromDocument(listingDoc);
          wasteTypes.add(listing.wasteType);
        }
      }

      // 返回去重后的废料类型
      return wasteTypes.toSet().toList();
    } catch (e) {
      print('获取用户偏好失败: $e');
      return [];
    }
  }

  /// 智能排序
  ///
  /// 基于多个因素对商品进行排序
  List<ListingModel> _rankByRelevance(List<ListingModel> listings) {
    final random = math.Random();

    // 计算每个商品的评分
    final scoredListings = listings.map((listing) {
      // 计算综合评分
      double score = 0;

      // 因素1：卖家评分（权重2）
      // TODO: 添加卖家评分字段
      // score += (listing.sellerRating ?? 3.0) * 2;

      // 因素2：价格合理性（价格越低越好）
      final priceScore = math.max(0, 100 - listing.pricePerUnit) / 100;
      score += priceScore * 1.5;

      // 因素3：新鲜度（越新越好）
      if (listing.createdAt != null) {
        final daysOld = DateTime.now().difference(listing.createdAt!).inDays;
        final freshnessScore = math.max(0, 30 - daysOld) / 30;
        score += freshnessScore * 1.0;
      }

      // 因素4：随机性（增加多样性）
      score += random.nextDouble() * 0.5;

      return MapEntry(listing, score);
    }).toList();

    // 按评分降序排序
    scoredListings.sort((a, b) => b.value.compareTo(a.value));

    // 返回排序后的商品列表
    return scoredListings.map((entry) => entry.key).toList();
  }

  /// 保存搜索历史
  Future<void> _saveSearchHistory(String keyword, List<String>? wasteTypes) async {
    if (_currentUserId == null) return;

    try {
      await _firestore.collection('search_history').add({
        'userId': _currentUserId,
        'keyword': keyword,
        'wasteTypes': wasteTypes ?? [],
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('保存搜索历史失败: $e');
    }
  }

  /// 获取搜索历史
  Future<List<Map<String, dynamic>>> getSearchHistory() async {
    if (_currentUserId == null) {
      return [];
    }

    try {
      final snapshot = await _firestore
          .collection('search_history')
          .where('userId', isEqualTo: _currentUserId)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'keyword': data['keyword'] ?? '',
          'wasteTypes': data['wasteTypes'] ?? [],
          'timestamp': data['timestamp'],
        };
      }).toList();
    } catch (e) {
      print('获取搜索历史失败: $e');
      return [];
    }
  }

  /// 获取热门搜索
  List<String> getTrendingSearches() {
    // 返回固定的热门类型列表
    return [
      'Palm Oil EFB',
      'Wood',
      'Food Waste',
      'Rice Husk',
      'Coconut Shell',
      'Palm Shell',
      'Sugarcane Bagasse',
      'Sawdust',
    ];
  }

  /// 计算两点之间的距离（Haversine公式）
  ///
  /// 参数：
  /// - lat1, lon1: 第一个点的纬度和经度
  /// - lat2, lon2: 第二个点的纬度和经度
  ///
  /// 返回：距离（km）
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // 地球半径（km）

    // 转换为弧度
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// 角度转弧度
  double _toRadians(double degree) {
    return degree * math.pi / 180;
  }

  /// 快速搜索（简化版）
  Future<List<ListingModel>> quickSearch(String keyword) async {
    return await advancedSearch(
      keyword: keyword,
      sortBy: 'date',
      ascending: false,
    );
  }

  /// 按废料类型搜索
  Future<List<ListingModel>> searchByWasteType(String wasteType) async {
    return await advancedSearch(
      wasteTypes: [wasteType],
      sortBy: 'date',
      ascending: false,
    );
  }

  /// 附近的商品
  ///
  /// TODO: 需要实现地理位置查询（使用 geoflutterfire 或类似库）
  Future<List<ListingModel>> getNearbyListings({
    required double latitude,
    required double longitude,
    double radiusInKm = 50,
  }) async {
    // 临时实现：返回所有可用商品
    final snapshot = await _firestore
        .collection('listings')
        .where('status', isEqualTo: 'available')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();

    return snapshot.docs.map((doc) => ListingModel.fromDocument(doc)).toList();
  }

  /// 清除搜索历史
  Future<void> clearSearchHistory() async {
    if (_currentUserId == null) return;

    try {
      final snapshot = await _firestore
          .collection('search_history')
          .where('userId', isEqualTo: _currentUserId)
          .get();

      // 批量删除
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('清除搜索历史失败: $e');
    }
  }
}
