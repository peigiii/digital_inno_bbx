import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/favorite_model.dart';
import '../models/listing_model.dart';

class FavoriteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _collectionName = 'favorites';

  /// Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Add a listing to favorites
  Future<void> addFavorite(String listingId, BuildContext? context) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Check if already favorited
      final existing = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('listingId', isEqualTo: listingId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        debugPrint('[FavoriteService] Listing already favorited: $listingId');
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Already in favorites'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Add to favorites
      final favorite = FavoriteModel(
        id: '', // Will be auto-generated
        userId: userId,
        listingId: listingId,
        createdAt: DateTime.now(),
      );

      await _firestore.collection(_collectionName).add(favorite.toFirestore());

      debugPrint('[FavoriteService] Added to favorites: $listingId');

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to favorites'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('[FavoriteService] Error adding favorite: $e');
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to favorites: $e'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }

  /// Remove a listing from favorites
  Future<void> removeFavorite(String listingId, BuildContext? context) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Find and delete the favorite
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('listingId', isEqualTo: listingId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint('[FavoriteService] Favorite not found: $listingId');
        return;
      }

      await snapshot.docs.first.reference.delete();

      debugPrint('[FavoriteService] Removed from favorites: $listingId');

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from favorites'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('[FavoriteService] Error removing favorite: $e');
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove from favorites: $e'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }

  /// Check if a listing is favorited by current user
  Future<bool> isFavorite(String listingId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return false;
      }

      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('listingId', isEqualTo: listingId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('[FavoriteService] Error checking favorite status: $e');
      return false;
    }
  }

  /// Get stream of favorite status for a listing
  Stream<bool> isFavoriteStream(String listingId) {
    final userId = _currentUserId;
    if (userId == null) {
      return Stream.value(false);
    }

    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .where('listingId', isEqualTo: listingId)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty)
        .handleError((error) {
      debugPrint('[FavoriteService] Error in favorite status stream: $error');
      return false;
    });
  }

  /// Get all favorites for current user as a stream
  Stream<List<FavoriteModel>> getUserFavorites() {
    final userId = _currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              return FavoriteModel.fromDocument(doc);
            } catch (e) {
              debugPrint('[FavoriteService] Error parsing favorite: $e');
              return null;
            }
          })
          .whereType<FavoriteModel>()
          .toList();
    }).handleError((error) {
      debugPrint('[FavoriteService] Error in favorites stream: $error');
      return <FavoriteModel>[];
    });
  }

  /// Get favorite listings with full listing data
  Stream<List<ListingModel>> getFavoriteListings() {
    final userId = _currentUserId;
    if (userId == null) {
      debugPrint('[FavoriteService] No user logged in, returning empty list');
      return Stream.value([]);
    }

    debugPrint('[FavoriteService] Fetching favorites for user: $userId');

    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      debugPrint('[FavoriteService] Received ${snapshot.docs.length} favorite documents');
      
      if (snapshot.docs.isEmpty) {
        return <ListingModel>[];
      }

      final listingIds = snapshot.docs
          .map((doc) => doc.data()['listingId'] as String?)
          .whereType<String>()
          .toList();

      debugPrint('[FavoriteService] Fetching ${listingIds.length} listings');

      if (listingIds.isEmpty) {
        return <ListingModel>[];
      }

      // Fetch listings in batches (Firestore 'in' query limit is 10)
      final listings = <ListingModel>[];
      for (var i = 0; i < listingIds.length; i += 10) {
        final batch = listingIds.skip(i).take(10).toList();
        try {
          final listingsSnapshot = await _firestore
              .collection('listings')
              .where(FieldPath.documentId, whereIn: batch)
              .get();

          listings.addAll(
            listingsSnapshot.docs.map((doc) {
              try {
                return ListingModel.fromDocument(doc);
              } catch (e) {
                debugPrint('[FavoriteService] Error parsing listing: $e');
                return null;
              }
            }).whereType<ListingModel>(),
          );
        } catch (e) {
          debugPrint('[FavoriteService] Error fetching listings batch: $e');
        }
      }

      debugPrint('[FavoriteService] Returning ${listings.length} listings');
      return listings;
    }).handleError((error) {
      debugPrint('[FavoriteService] Error fetching favorite listings: $error');
      return <ListingModel>[];
    });
  }

  /// Toggle favorite status (add if not favorited, remove if favorited)
  Future<void> toggleFavorite(String listingId, BuildContext? context) async {
    try {
      final isFav = await isFavorite(listingId);
      if (isFav) {
        await removeFavorite(listingId, context);
      } else {
        await addFavorite(listingId, context);
      }
    } catch (e) {
      debugPrint('[FavoriteService] Error toggling favorite: $e');
      rethrow;
    }
  }

  /// Get count of user's favorites
  Future<int> getFavoritesCount() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return 0;
      }

      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('[FavoriteService] Error getting favorites count: $e');
      return 0;
    }
  }

  /// Get count stream for user's favorites
  Stream<int> getFavoritesCountStream() {
    final userId = _currentUserId;
    if (userId == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .handleError((error) {
      debugPrint('[FavoriteService] Error in favorites count stream: $error');
      return 0;
    });
  }

  /// Remove all favorites for a listing (when listing is deleted)
  Future<void> removeAllFavoritesForListing(String listingId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('listingId', isEqualTo: listingId)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('[FavoriteService] Removed all favorites for listing: $listingId');
    } catch (e) {
      debugPrint('[FavoriteService] Error removing favorites for listing: $e');
      rethrow;
    }
  }
}
