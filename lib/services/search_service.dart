import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/listing_model.dart';

class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

    String? get _currentUserId => _auth.currentUser?.uid;

    ///
                            ///
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
        Query query = _firestore.collection('listings');

        query = query.where('status', isEqualTo: 'available');

        if (wasteTypes != null && wasteTypes.isNotEmpty) {
      query = query.where('wasteType', whereIn: wasteTypes);
    }

        if (minPrice != null && minPrice > 0) {
      query = query.where('pricePerUnit', isGreaterThanOrEqualTo: minPrice);
    }
    if (maxPrice != null && maxPrice > 0) {
      query = query.where('pricePerUnit', isLessThanOrEqualTo: maxPrice);
    }

            // if (verifiedOnly) {
    //   query = query.where('sellerVerified', isEqualTo: true);
    // }

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

        query = query.limit(100);

        final snapshot = await query.get();
    List<ListingModel> results = snapshot.docs.map((doc) => ListingModel.fromDocument(doc)).toList();

        results = results.where((listing) {
            if (keyword != null && keyword.isNotEmpty) {
        final keywordLower = keyword.toLowerCase();
        final titleMatch = listing.title.toLowerCase().contains(keywordLower);
        final descMatch = listing.description.toLowerCase().contains(keywordLower);
        final typeMatch = listing.wasteType.toLowerCase().contains(keywordLower);
        if (!titleMatch && !descMatch && !typeMatch) {
          return false;
        }
      }

            if (minQuantity != null && listing.quantity < minQuantity) {
        return false;
      }
      if (maxQuantity != null && listing.quantity > maxQuantity) {
        return false;
      }

            // if (minRating != null && listing.sellerRating < minRating) {
      //   return false;
      // }

            // if (maxDistance != null && location != null) {
      //   final distance = calculateDistance(...);
      //   if (distance > maxDistance) {
      //     return false;
      //   }
      // }

      return true;
    }).toList();

        if (keyword != null && keyword.isNotEmpty) {
      _saveSearchHistory(keyword, wasteTypes);
    }

    return results;
  }

    ///
    Future<List<ListingModel>> getRecommendations() async {
    if (_currentUserId == null) {
      return [];
    }

        final preferences = await _getUserPreferences(_currentUserId!);

        Query query = _firestore.collection('listings');

        query = query.where('status', isEqualTo: 'available');

        query = query.where('userId', isNotEqualTo: _currentUserId);

        if (preferences.isNotEmpty) {
      query = query.where('wasteType', whereIn: preferences.take(10).toList());
    }

        query = query.orderBy('createdAt', descending: true);

        query = query.limit(20);

        final snapshot = await query.get();
    List<ListingModel> results = snapshot.docs.map((doc) => ListingModel.fromDocument(doc)).toList();

        results = _rankByRelevance(results);

        return results.take(10).toList();
  }

    ///
    Future<List<String>> _getUserPreferences(String userId) async {
    try {
            final offersSnapshot = await _firestore
          .collection('offers')
          .where('buyerId', isEqualTo: userId)
          .limit(20)
          .get();

            final listingIds = offersSnapshot.docs
          .map((doc) => doc.data()['listingId'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .toSet()
          .toList();

      if (listingIds.isEmpty) {
        return [];
      }

            final wasteTypes = <String>[];
      for (var listingId in listingIds.take(10)) {
        final listingDoc = await _firestore.collection('listings').doc(listingId).get();
        if (listingDoc.exists) {
          final listing = ListingModel.fromDocument(listingDoc);
          wasteTypes.add(listing.wasteType);
        }
      }

            return wasteTypes.toSet().toList();
    } catch (e) {
      print('获取用户偏好失败: $e');
      return [];
    }
  }

    ///
    List<ListingModel> _rankByRelevance(List<ListingModel> listings) {
    final random = math.Random();

        final scoredListings = listings.map((listing) {
            double score = 0;

                  // score += (listing.sellerRating ?? 3.0) * 2;

            final priceScore = math.max(0, 100 - listing.pricePerUnit) / 100;
      score += priceScore * 1.5;

            if (listing.createdAt != null) {
        final daysOld = DateTime.now().difference(listing.createdAt!).inDays;
        final freshnessScore = math.max(0, 30 - daysOld) / 30;
        score += freshnessScore * 1.0;
      }

            score += random.nextDouble() * 0.5;

      return MapEntry(listing, score);
    }).toList();

        scoredListings.sort((a, b) => b.value.compareTo(a.value));

        return scoredListings.map((entry) => entry.key).toList();
  }

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

    List<String> getTrendingSearches() {
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

    ///
        ///
    double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; 
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

    double _toRadians(double degree) {
    return degree * math.pi / 180;
  }

    Future<List<ListingModel>> quickSearch(String keyword) async {
    return await advancedSearch(
      keyword: keyword,
      sortBy: 'date',
      ascending: false,
    );
  }

    Future<List<ListingModel>> searchByWasteType(String wasteType) async {
    return await advancedSearch(
      wasteTypes: [wasteType],
      sortBy: 'date',
      ascending: false,
    );
  }

    ///
    Future<List<ListingModel>> getNearbyListings({
    required double latitude,
    required double longitude,
    double radiusInKm = 50,
  }) async {
        final snapshot = await _firestore
        .collection('listings')
        .where('status', isEqualTo: 'available')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();

    return snapshot.docs.map((doc) => ListingModel.fromDocument(doc)).toList();
  }

    Future<void> clearSearchHistory() async {
    if (_currentUserId == null) return;

    try {
      final snapshot = await _firestore
          .collection('search_history')
          .where('userId', isEqualTo: _currentUserId)
          .get();

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
