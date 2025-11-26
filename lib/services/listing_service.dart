import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import '../utils/app_constants.dart';

class ListingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

    Future<String> createListing(ListingModel listing) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

            final listingData = listing.copyWith(
        status: ListingStatusConstants.available,
        complianceStatus: 'pending',
      );

      final docRef = await _firestore
          .collection(CollectionConstants.listings)
          .add(listingData.toMap())
          .timeout(ApiConstants.defaultTimeout);

      return docRef.id;
    } catch (e) {
      throw Exception('CreateColTableFailure: $e');
    }
  }

    Future<void> updateListing(String listingId, Map<String, dynamic> updates) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

            final doc = await _firestore
          .collection(CollectionConstants.listings)
          .doc(listingId)
          .get();

      if (!doc.exists) throw Exception('Listing not found');

      final listing = ListingModel.fromDocument(doc);

            if (listing.userId != user.uid) {
                final userDoc = await _firestore.collection(CollectionConstants.users).doc(user.uid).get();
        final isAdmin = userDoc.data()?['isAdmin'] ?? false;
        if (!isAdmin) throw Exception('No permission to modify this list');
      }

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
      throw Exception('UpdateColTableFailure: $e');
    }
  }

    Future<void> deleteListing(String listingId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

            final doc = await _firestore
          .collection(CollectionConstants.listings)
          .doc(listingId)
          .get();

      if (!doc.exists) throw Exception('Listing not found');

      final listing = ListingModel.fromDocument(doc);

            if (listing.userId != user.uid) {
        final userDoc = await _firestore.collection(CollectionConstants.users).doc(user.uid).get();
        final isAdmin = userDoc.data()?['isAdmin'] ?? false;
        if (!isAdmin) throw Exception('No permission to delete this list');
      }

            final offers = await _firestore
          .collection(CollectionConstants.offers)
          .where('listingId', isEqualTo: listingId)
          .where('status', isEqualTo: OfferStatusConstants.pending)
          .get();

      if (offers.docs.isNotEmpty) {
        throw Exception('Cannot delete listing with pending offers');
      }

            await _firestore
          .collection(CollectionConstants.listings)
          .doc(listingId)
          .update({
        'status': 'deleted',
        'deletedAt': FieldValue.serverTimestamp(),
      }).timeout(ApiConstants.defaultTimeout);
    } catch (e) {
      throw Exception('DeleteColTableFailure: $e');
    }
  }

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
      throw Exception('Get ListFailure: $e');
    }
  }

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

  /// SearchColTable
  Future<List<ListingModel>> searchListings({
    String? category,
    String? status,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore.collection(CollectionConstants.listings);

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
      throw Exception('SearchColTableFailure: $e');
    }
  }

    Future<void> markAsSold(String listingId) async {
    await updateListing(listingId, {
      'status': ListingStatusConstants.sold,
    });
  }

    Future<void> markAsExpired(String listingId) async {
    await updateListing(listingId, {
      'status': ListingStatusConstants.expired,
    });
  }

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
      throw Exception('BatchDelete Failed: $e');
    }
  }

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
      throw Exception('BatchUpdate Failed: $e');
    }
  }

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
      throw Exception('GetStatisticsFailure: $e');
    }
  }
}
