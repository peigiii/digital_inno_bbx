import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/offer_model.dart';
import '../models/transaction_model.dart';

class OfferService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

    String? get _currentUserId => _auth.currentUser?.uid;

    ///
                    ///
    Future<String> createOffer({
    required String listingId,
    required String sellerId,
    required double offerPrice,
    required double originalPrice,
    String message = '',
    DateTime? scheduledPickupDate,
    String deliveryMethod = 'self_collect',
    String? deliveryNote,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not logged in');
    }

        final userDoc = await _firestore.collection('users').doc(_currentUserId).get();
    final userData = userDoc.data() ?? {};

        final now = DateTime.now();
    final expiresAt = now.add(const Duration(hours: 48));

    final offer = OfferModel(
      id: '',       listingId: listingId,
      recyclerId: _currentUserId!,
      recyclerName: userData['displayName'] ?? 'UnknownUser',
      recyclerCompany: userData['company'],
      recyclerContact: userData['phone'],
      producerId: sellerId,
      offerPrice: offerPrice,
      originalPrice: originalPrice,
      message: message,
      scheduledPickupDate: scheduledPickupDate,
      deliveryMethod: deliveryMethod,
      deliveryNote: deliveryNote,
      status: 'pending',
      createdAt: now,
      expiresAt: expiresAt,
    );

        final docRef = await _firestore.collection('offers').add(offer.toMap());

    
    return docRef.id;
  }

    Future<void> acceptOffer(String offerId) async {
    if (_currentUserId == null) {
      throw Exception('User not logged in');
    }

    final offerDoc = await _firestore.collection('offers').doc(offerId).get();
    if (!offerDoc.exists) {
      throw Exception('Offer not found');
    }

    final offer = OfferModel.fromDocument(offerDoc);

        if (offer.sellerId != _currentUserId) {
      throw Exception('Permission denied');
    }

        if (!offer.canAccept) {
      throw Exception('QuoteStatusNoAllowAccept');
    }

        if (offer.isExpired) {
      throw Exception('QuoteExpired');
    }

        await _firestore.collection('offers').doc(offerId).update({
      'status': 'accepted',
      'respondedAt': FieldValue.serverTimestamp(),
    });

        await _createTransaction(offerId);

      }

    Future<void> rejectOffer(String offerId, String reason) async {
    if (_currentUserId == null) {
      throw Exception('User not logged in');
    }

    final offerDoc = await _firestore.collection('offers').doc(offerId).get();
    if (!offerDoc.exists) {
      throw Exception('Offer not found');
    }

    final offer = OfferModel.fromDocument(offerDoc);

        if (offer.sellerId != _currentUserId) {
      throw Exception('Permission denied');
    }

        await _firestore.collection('offers').doc(offerId).update({
      'status': 'rejected',
      'rejectionReason': reason,
      'respondedAt': FieldValue.serverTimestamp(),
    });

      }

    Future<void> counterOffer(String offerId, double counterPrice, String message) async {
    if (_currentUserId == null) {
      throw Exception('User not logged in');
    }

    final offerDoc = await _firestore.collection('offers').doc(offerId).get();
    if (!offerDoc.exists) {
      throw Exception('Offer not found');
    }

    final offer = OfferModel.fromDocument(offerDoc);

        if (offer.sellerId != _currentUserId) {
      throw Exception('Permission denied');
    }

        if (!offer.canNegotiate) {
      throw Exception('QuoteStatusNoAllowDiscussPrice');
    }

        await _firestore.collection('offers').doc(offerId).update({
      'status': 'negotiating',
      'counterOfferPrice': counterPrice,
      'sellerResponse': message,
      'respondedAt': FieldValue.serverTimestamp(),
    });

      }

    Future<void> acceptCounterOffer(String offerId) async {
    if (_currentUserId == null) {
      throw Exception('User not logged in');
    }

    final offerDoc = await _firestore.collection('offers').doc(offerId).get();
    if (!offerDoc.exists) {
      throw Exception('Offer not found');
    }

    final offer = OfferModel.fromDocument(offerDoc);

        if (offer.buyerId != _currentUserId) {
      throw Exception('Permission denied');
    }

        if (offer.status != 'negotiating') {
      throw Exception('QuoteStatusNoRightSure');
    }

    if (offer.counterOfferPrice == null) {
      throw Exception('NoneReturnPriceInfo');
    }

        await _firestore.collection('offers').doc(offerId).update({
      'status': 'accepted',
      'offerPrice': offer.counterOfferPrice,
      'respondedAt': FieldValue.serverTimestamp(),
    });

        await _createTransaction(offerId);

      }

    Future<void> cancelOffer(String offerId) async {
    if (_currentUserId == null) {
      throw Exception('User not logged in');
    }

    final offerDoc = await _firestore.collection('offers').doc(offerId).get();
    if (!offerDoc.exists) {
      throw Exception('Offer not found');
    }

    final offer = OfferModel.fromDocument(offerDoc);

        if (offer.buyerId != _currentUserId) {
      throw Exception('Permission denied');
    }

        if (offer.status != 'pending' && offer.status != 'negotiating') {
      throw Exception('QuoteStatusNoAllowCancel');
    }

        await _firestore.collection('offers').doc(offerId).update({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });

      }

    Stream<List<OfferModel>> getMyOffers() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('offers')
        .where('buyerId', isEqualTo: _currentUserId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .handleError((error) {
          print('Error getting my offers: $error');
        })
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            try {
              return OfferModel.fromDocument(doc);
            } catch (e) {
              print('ParseQuoteFailure ${doc.id}: $e');
              return null;
            }
          }).whereType<OfferModel>().toList();
        });
  }

    Stream<List<OfferModel>> getReceivedOffers() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('offers')
        .where('sellerId', isEqualTo: _currentUserId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .handleError((error) {
          print('Error getting received offers: $error');
        })
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            try {
              return OfferModel.fromDocument(doc);
            } catch (e) {
              print('ParseQuoteFailure ${doc.id}: $e');
              return null;
            }
          }).whereType<OfferModel>().toList();
        });
  }

    Stream<List<OfferModel>> getOffersForListing(String listingId) {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('offers')
        .where('listingId', isEqualTo: listingId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
          print('Error getting offers for listing: $error');
        })
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            try {
              return OfferModel.fromDocument(doc);
            } catch (e) {
              print('ParseQuoteFailure ${doc.id}: $e');
              return null;
            }
          }).whereType<OfferModel>().toList();
        });
  }

    Future<void> _createTransaction(String offerId) async {
    final offerDoc = await _firestore.collection('offers').doc(offerId).get();
    if (!offerDoc.exists) {
      throw Exception('Offer not found');
    }

    final offer = OfferModel.fromDocument(offerDoc);

        final platformFee = offer.offerPrice * 0.03;
    final totalAmount = offer.offerPrice + platformFee;

    final transaction = TransactionModel(
      id: '',       offerId: offerId,
      buyerId: offer.buyerId,
      sellerId: offer.sellerId,
      listingId: offer.listingId,
      amount: offer.offerPrice,
      platformFee: platformFee,
      totalAmount: totalAmount,
      status: 'confirmed',
      escrowStatus: 'held',
      createdAt: DateTime.now(),
    );

        await _firestore.collection('transactions').add(transaction.toMap());

      }

    Future<void> updateTransactionStatus(String transactionId, String status) async {
    if (_currentUserId == null) {
      throw Exception('User not logged in');
    }

    await _firestore.collection('transactions').doc(transactionId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });

      }

    Stream<List<TransactionModel>> getMyTransactions() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('transactions')
        .where('buyerId', isEqualTo: _currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TransactionModel.fromDocument(doc)).toList();
    });
  }

    Future<OfferModel?> getOffer(String offerId) async {
    final doc = await _firestore.collection('offers').doc(offerId).get();
    if (!doc.exists) {
      return null;
    }
    return OfferModel.fromDocument(doc);
  }

    Future<TransactionModel?> getTransaction(String transactionId) async {
    final doc = await _firestore.collection('transactions').doc(transactionId).get();
    if (!doc.exists) {
      return null;
    }
    return TransactionModel.fromDocument(doc);
  }
}
