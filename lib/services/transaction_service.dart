import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';
import '../models/logistics_update_model.dart';
import '../models/offer_model.dart';
import '../models/listing_model.dart';

/// Transaction Service
class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// 1. Confirm Transaction - Create transaction when offer is accepted
  Future<String> confirmTransaction(String offerId) async {
    try {
      // Get Offer Details
      final offerDoc = await _firestore.collection('offers').doc(offerId).get();
      if (!offerDoc.exists) {
        throw Exception('Offer not found');
      }
      final offer = OfferModel.fromDocument(offerDoc);

      // Get Listing Details
      final listingDoc = await _firestore.collection('listings').doc(offer.listingId).get();
      if (!listingDoc.exists) {
        throw Exception('Listing not found');
      }
      final listing = ListingModel.fromDocument(listingDoc);

      // Calculate Total Amount = Offer Price + Platform Fee (3%)
      final amount = offer.offerPrice;
      final platformFee = amount * 0.03;
      final totalAmount = amount + platformFee;

      // Create Transaction Record
      final transactionRef = _firestore.collection('transactions').doc();
      final transaction = TransactionModel(
        id: transactionRef.id,
        offerId: offerId,
        buyerId: offer.buyerId,
        sellerId: listing.userId,
        listingId: offer.listingId,
        amount: amount,
        platformFee: platformFee,
        totalAmount: totalAmount,
        status: 'confirmed',
        paymentStatus: 'pending',
        shippingStatus: 'pending',
        escrowStatus: 'held',
        deliveryMethod: offer.deliveryMethod, // Inherit from Offer
        pickupScheduledDate: offer.scheduledPickupDate,
        createdAt: DateTime.now(),
      );

      // Save Transaction
      await transactionRef.set(transaction.toMap());

      // Update Offer Status to Completed
      await _firestore.collection('offers').doc(offerId).update({
        'status': 'completed',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // TODO: Send notifications

      return transactionRef.id;
    } catch (e) {
      throw Exception('Create transaction failed: $e');
    }
  }

  /// 2. Upload Payment Proof
  Future<void> uploadPaymentProof(String transactionId, File imageFile) async {
    try {
      // Upload Image to Firebase Storage
      final storageRef = _storage.ref().child('transactions/$transactionId/payment_proof.jpg');
      final uploadTask = await storageRef.putFile(imageFile);

      // Get Download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Update Transaction
      await _firestore.collection('transactions').doc(transactionId).update({
        'paymentProofUrl': downloadUrl,
        'paymentStatus': 'paid',
        'paidAt': FieldValue.serverTimestamp(),
      });

      // TODO: Send notification to seller

    } catch (e) {
      throw Exception('Upload payment proof failed: $e');
    }
  }

  /// 3. Mark as Picked Up
  Future<void> markAsPickedUp(String transactionId, File? pickupPhoto) async {
    try {
      String? photoUrl;

      // Optional Photo Upload
      if (pickupPhoto != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final storageRef = _storage.ref().child('transactions/$transactionId/logistics/pickup_$timestamp.jpg');
        final uploadTask = await storageRef.putFile(pickupPhoto);
        photoUrl = await uploadTask.ref.getDownloadURL();
      }

      // Update Transaction Status
      await _firestore.collection('transactions').doc(transactionId).update({
        'shippingStatus': 'picked_up',
        'actualPickupDate': FieldValue.serverTimestamp(),
        'shippedAt': FieldValue.serverTimestamp(),
      });

      // Create Logistics Update Record
      await _createLogisticsUpdate(
        transactionId: transactionId,
        status: 'picked_up',
        description: 'Seller marked as Picked Up',
        imageUrl: photoUrl,
      );

      // TODO: Send notification to buyer

    } catch (e) {
      throw Exception('Mark as picked up failed: $e');
    }
  }

  /// 4. Update Shipping Status
  Future<void> updateShippingStatus({
    required String transactionId,
    required String newStatus,
    String? location,
    String? description,
    File? photo,
  }) async {
    try {
      // Validate Transaction
      final transactionDoc = await _firestore.collection('transactions').doc(transactionId).get();
      if (!transactionDoc.exists) {
        throw Exception('Transaction not found');
      }
      final transaction = TransactionModel.fromDocument(transactionDoc);

      // Validate Status Transition
      if (!_isValidStatusTransition(transaction.shippingStatus, newStatus)) {
        throw Exception('Invalid status transition');
      }

      String? photoUrl;
      // Upload Photo if exists
      if (photo != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final storageRef = _storage.ref().child('transactions/$transactionId/logistics/$timestamp.jpg');
        final uploadTask = await storageRef.putFile(photo);
        photoUrl = await uploadTask.ref.getDownloadURL();
      }

      // Update Transaction Status
      await _firestore.collection('transactions').doc(transactionId).update({
        'shippingStatus': newStatus,
      });

      // Create Logistics Update Record
      await _createLogisticsUpdate(
        transactionId: transactionId,
        status: newStatus,
        location: location,
        description: description ?? 'Logistics status updated',
        imageUrl: photoUrl,
      );

      // TODO: Send notification

    } catch (e) {
      throw Exception('Update shipping status failed: $e');
    }
  }

  /// 5. Confirm Delivery (Buyer)
  Future<void> confirmDelivery(String transactionId) async {
    try {
      // Update Transaction Status
      await _firestore.collection('transactions').doc(transactionId).update({
        'shippingStatus': 'delivered',
        'deliveryDate': FieldValue.serverTimestamp(),
      });

      // Create Logistics Update Record
      await _createLogisticsUpdate(
        transactionId: transactionId,
        status: 'delivered',
        description: 'Buyer confirmed receipt',
      );

      // TODO: Send notification to seller

    } catch (e) {
      throw Exception('Confirm delivery failed: $e');
    }
  }

  /// 6. Complete Transaction
  Future<void> completeTransaction(String transactionId) async {
    try {
      // Get Transaction Details
      final transactionDoc = await _firestore.collection('transactions').doc(transactionId).get();
      if (!transactionDoc.exists) {
        throw Exception('Transaction not found');
      }
      final transaction = TransactionModel.fromDocument(transactionDoc);

      // Batch Update
      final batch = _firestore.batch();

      // Update Transaction Status
      batch.update(_firestore.collection('transactions').doc(transactionId), {
        'shippingStatus': 'completed',
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Update Listing Status to Sold
      batch.update(_firestore.collection('listings').doc(transaction.listingId), {
        'status': 'sold',
        'soldAt': FieldValue.serverTimestamp(),
      });

      // Update Buyer Transaction Count
      batch.update(_firestore.collection('users').doc(transaction.buyerId), {
        'totalTransactions': FieldValue.increment(1),
      });

      // Update Seller Transaction Count
      batch.update(_firestore.collection('users').doc(transaction.sellerId), {
        'totalTransactions': FieldValue.increment(1),
      });

      // Commit Batch
      await batch.commit();

      // Create Logistics Update Record
      await _createLogisticsUpdate(
        transactionId: transactionId,
        status: 'completed',
        description: 'Transaction Completed',
      );

      // TODO: Send notifications

    } catch (e) {
      throw Exception('Complete transaction failed: $e');
    }
  }

  /// 7. Cancel Transaction
  Future<void> cancelTransaction(String transactionId, String reason) async {
    try {
      // Get Transaction Details
      final transactionDoc = await _firestore.collection('transactions').doc(transactionId).get();
      if (!transactionDoc.exists) {
        throw Exception('Transaction not found');
      }
      final transaction = TransactionModel.fromDocument(transactionDoc);

      // Batch Update
      final batch = _firestore.batch();

      // Update Transaction Status
      final updateData = {
        'status': 'cancelled',
        'cancellationReason': reason,
        'cancelledAt': FieldValue.serverTimestamp(),
      };

      // If Paid, Mark for Refund
      if (transaction.paymentStatus == 'paid') {
        updateData['paymentStatus'] = 'refunded';
        updateData['refundReason'] = reason;
        updateData['refundRequestedAt'] = FieldValue.serverTimestamp();
      }

      batch.update(_firestore.collection('transactions').doc(transactionId), updateData);

      // Restore Listing Status
      batch.update(_firestore.collection('listings').doc(transaction.listingId), {
        'status': 'available',
      });

      // Commit Batch
      await batch.commit();

      // TODO: Send notifications

    } catch (e) {
      throw Exception('Cancel transaction failed: $e');
    }
  }

  /// 8. Get My Transactions
  Stream<List<TransactionModel>> getMyTransactions(String userId, {String? status}) {
    try {
      Query query = _firestore.collection('transactions')
          .where('buyerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true);

      // Also need seller transactions
      Query sellerQuery = _firestore.collection('transactions')
          .where('sellerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true);

      // Optional Status Filter
      if (status != null) {
        query = query.where('shippingStatus', isEqualTo: status);
        sellerQuery = sellerQuery.where('shippingStatus', isEqualTo: status);
      }

      // Merge results (Simplified for stream)
      // Note: This returns buyer transactions. Actual implementation needs merge.
      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) => TransactionModel.fromDocument(doc)).toList();
      });
    } catch (e) {
      throw Exception('Get transactions failed: $e');
    }
  }

  /// Get My Buyer Transactions
  Stream<List<TransactionModel>> getMyBuyerTransactions(String userId, {String? status}) {
    try {
      Query query = _firestore
          .collection('transactions')
          .where('buyerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50);

      if (status != null) {
        query = query.where('shippingStatus', isEqualTo: status);
      }

      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          try {
            return TransactionModel.fromDocument(doc);
          } catch (e) {
            print('Parse transaction failed ${doc.id}: $e');
            return null;
          }
        }).whereType<TransactionModel>().toList();
      });
    } catch (e) {
      throw Exception('Get buyer transactions failed: $e');
    }
  }

  /// Get My Seller Transactions
  Stream<List<TransactionModel>> getMySellerTransactions(String userId, {String? status}) {
    try {
      Query query = _firestore
          .collection('transactions')
          .where('sellerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50);

      if (status != null) {
        query = query.where('shippingStatus', isEqualTo: status);
      }

      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          try {
            return TransactionModel.fromDocument(doc);
          } catch (e) {
            print('Parse transaction failed ${doc.id}: $e');
            return null;
          }
        }).whereType<TransactionModel>().toList();
      });
    } catch (e) {
      throw Exception('Get seller transactions failed: $e');
    }
  }

  /// 9. Get Transaction Details
  Future<TransactionModel> getTransactionDetails(String transactionId) async {
    try {
      final doc = await _firestore.collection('transactions').doc(transactionId).get();
      if (!doc.exists) {
        throw Exception('Transaction not found');
      }
      return TransactionModel.fromDocument(doc);
    } catch (e) {
      throw Exception('Get transaction details failed: $e');
    }
  }

  /// Get Transaction Details Stream
  Stream<TransactionModel> getTransactionDetailsStream(String transactionId) {
    return _firestore.collection('transactions').doc(transactionId).snapshots().map((doc) {
      if (!doc.exists) {
        throw Exception('Transaction not found');
      }
      return TransactionModel.fromDocument(doc);
    });
  }

  /// 10. Get Logistics Updates
  Stream<List<LogisticsUpdateModel>> getLogisticsUpdates(String transactionId) {
    try {
      return _firestore
          .collection('logistics_updates')
          .where('transactionId', isEqualTo: transactionId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => LogisticsUpdateModel.fromDocument(doc)).toList();
      });
    } catch (e) {
      throw Exception('Get logistics updates failed: $e');
    }
  }

  // ==================== Private Helpers ====================

  /// Create Logistics Update Record
  Future<void> _createLogisticsUpdate({
    required String transactionId,
    required String status,
    String? location,
    required String description,
    String? imageUrl,
  }) async {
    try {
      // Get Current User ID
      final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 'system';

      final updateRef = _firestore.collection('logistics_updates').doc();
      final update = LogisticsUpdateModel(
        id: updateRef.id,
        transactionId: transactionId,
        status: status,
        location: location,
        description: description,
        imageUrl: imageUrl,
        createdBy: currentUserId,
        createdAt: DateTime.now(),
      );

      await updateRef.set(update.toMap());
    } catch (e) {
      // Logistics update failure shouldn't block main flow
      print('Create logistics record failed: $e');
    }
  }

  /// Validate Status Transition
  bool _isValidStatusTransition(String currentStatus, String newStatus) {
    // Define valid transitions
    const validTransitions = {
      'pending': ['picked_up'],
      'picked_up': ['in_transit', 'delivered'],
      'in_transit': ['delivered'],
      'delivered': ['completed'],
    };

    final allowedNextStates = validTransitions[currentStatus];
    return allowedNextStates?.contains(newStatus) ?? false;
  }

  /// Get All My Transactions (Buyer + Seller)
  Stream<List<TransactionModel>> getAllMyTransactions(String userId, {String? statusFilter}) {
    // This is a combined query
    // Firestore limits prevent direct OR queries on different fields, so we merge streams

    final buyerStream = getMyBuyerTransactions(userId, status: statusFilter);
    final sellerStream = getMySellerTransactions(userId, status: statusFilter);

    // Merge Streams
    return buyerStream.asyncMap((buyerTransactions) async {
      // Note: This isn't optimal stream merging but sufficient for now
      final sellerSnapshot = await sellerStream.first;

      // Merge and Deduplicate
      final allTransactions = [...buyerTransactions, ...sellerSnapshot];

      // Sort by Created At
      allTransactions.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));

      return allTransactions;
    });
  }

  /// Update Transaction Record
  Future<void> updateTransaction(String transactionId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('transactions').doc(transactionId).update(data);
    } catch (e) {
      throw Exception('Update transaction failed: $e');
    }
  }
}
