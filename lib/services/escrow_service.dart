import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

///
class EscrowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

    Future<String> createTransaction({
    required String sellerId,
    required String listingId,
    required double amount,
    required String paymentMethod,
    Map<String, dynamic>? metadata,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');

    final transaction = await _firestore.collection('transactions').add({
      'buyerId': userId,
      'sellerId': sellerId,
      'listingId': listingId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'status': 'pending',
      'escrowStatus': 'held',
      'trackingNumber': null,
      'shippingProof': [],
      'completedAt': null,
      'createdAt': FieldValue.serverTimestamp(),
      'metadata': metadata ?? {},
    });

    return transaction.id;
  }

    Future<void> payTransaction(String transactionId) async {
    await _firestore.collection('transactions').doc(transactionId).update({
      'status': 'paid',
      'paidAt': FieldValue.serverTimestamp(),
    });
  }

    Future<void> uploadShippingProof({
    required String transactionId,
    required String trackingNumber,
    required List<String> proofUrls,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');

        final doc = await _firestore
        .collection('transactions')
        .doc(transactionId)
        .get();

    if (!doc.exists) throw Exception('Transaction not found?');

    final data = doc.data()!;
    if (data['sellerId'] != userId) {
      throw Exception('Permission denied for this transaction?');
    }

    await _firestore.collection('transactions').doc(transactionId).update({
      'status': 'shipped',
      'trackingNumber': trackingNumber,
      'shippingProof': proofUrls,
      'shippedAt': FieldValue.serverTimestamp(),
    });
  }

    Future<void> confirmReceived(String transactionId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');

        final doc = await _firestore
        .collection('transactions')
        .doc(transactionId)
        .get();

    if (!doc.exists) throw Exception('Transaction not found?');

    final data = doc.data()!;
    if (data['buyerId'] != userId) {
      throw Exception('Permission denied for this transaction?');
    }

    await _firestore.collection('transactions').doc(transactionId).update({
      'status': 'completed',
      'escrowStatus': 'released',
      'completedAt': FieldValue.serverTimestamp(),
    });

          }

    Future<void> requestRefund({
    required String transactionId,
    required String reason,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');

        final doc = await _firestore
        .collection('transactions')
        .doc(transactionId)
        .get();

    if (!doc.exists) throw Exception('Transaction not found?');

    final data = doc.data()!;
    if (data['buyerId'] != userId) {
      throw Exception('Permission denied for this transaction?');
    }

    await _firestore.collection('transactions').doc(transactionId).update({
      'status': 'refund_requested',
      'refundReason': reason,
      'refundRequestedAt': FieldValue.serverTimestamp(),
    });
  }

    Future<void> processRefund({
    required String transactionId,
    required bool approved,
    String? note,
  }) async {
    final status = approved ? 'refunded' : 'refund_rejected';
    final escrowStatus = approved ? 'refunded' : 'released';

    await _firestore.collection('transactions').doc(transactionId).update({
      'status': status,
      'escrowStatus': escrowStatus,
      'refundProcessedAt': FieldValue.serverTimestamp(),
      'refundNote': note,
    });

      }

    Stream<QuerySnapshot> getUserPurchases() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');

    return _firestore
        .collection('transactions')
        .where('buyerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

    Stream<QuerySnapshot> getUserSales() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');

    return _firestore
        .collection('transactions')
        .where('sellerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

    Stream<DocumentSnapshot> getTransactionDetails(String transactionId) {
    return _firestore
        .collection('transactions')
        .doc(transactionId)
        .snapshots();
  }

    Future<void> cancelTransaction(String transactionId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');

    final doc = await _firestore
        .collection('transactions')
        .doc(transactionId)
        .get();

    if (!doc.exists) throw Exception('Transaction not found?');

    final data = doc.data()!;

        if (data['buyerId'] != userId) {
      throw Exception('Permission denied for this transaction?');
    }

    if (data['status'] != 'pending') {
      throw Exception('Cannot cancel order in this state');
    }

    await _firestore.collection('transactions').doc(transactionId).update({
      'status': 'cancelled',
      'cancelledAt': FieldValue.serverTimestamp(),
    });
  }

    bool canRequestRefund(Map<String, dynamic> transaction) {
    if (transaction['status'] != 'completed') return false;

    final completedAt = (transaction['completedAt'] as Timestamp?)?.toDate();
    if (completedAt == null) return false;

    final daysSinceCompletion = DateTime.now().difference(completedAt).inDays;
    return daysSinceCompletion <= 7;
  }

    Future<Map<String, dynamic>> getTransactionStats(String userId) async {
    final purchases = await _firestore
        .collection('transactions')
        .where('buyerId', isEqualTo: userId)
        .get();

    final sales = await _firestore
        .collection('transactions')
        .where('sellerId', isEqualTo: userId)
        .get();

    int completedPurchases = 0;
    int completedSales = 0;
    double totalSpent = 0;
    double totalEarned = 0;

    for (var doc in purchases.docs) {
      final data = doc.data();
      if (data['status'] == 'completed') {
        completedPurchases++;
        totalSpent += (data['amount'] as num).toDouble();
      }
    }

    for (var doc in sales.docs) {
      final data = doc.data();
      if (data['status'] == 'completed') {
        completedSales++;
        totalEarned += (data['amount'] as num).toDouble();
      }
    }

    return {
      'totalPurchases': purchases.size,
      'totalSales': sales.size,
      'completedPurchases': completedPurchases,
      'completedSales': completedSales,
      'totalSpent': totalSpent,
      'totalEarned': totalEarned,
      'completionRate': sales.size > 0
          ? (completedSales / sales.size * 100).toStringAsFixed(1)
          : '0',
    };
  }
}

enum TransactionStatus {
  pending('pending', 'WaitBranch?),
  paid('paid', 'AlreadyBranch?),
  shipped('shipped', 'AlreadySend?),
  completed('completed', 'AlreadyDone?),
  cancelled('cancelled', 'AlreadyTake?),
  refundRequested('refund_requested', 'ApplyRetreat?),
  refunded('refunded', 'AlreadyRetreat?),
  refundRejected('refund_rejected', 'RefundBy?),
  disputed('disputed', 'HaveFight?);

  final String value;
  final String label;
  const TransactionStatus(this.value, this.label);

  static TransactionStatus fromString(String value) {
    return TransactionStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TransactionStatus.pending,
    );
  }
}

enum EscrowStatus {
  held('held', 'Fund Escrow?),
  released('released', 'Funds Released?),
  refunded('refunded', 'AlreadyRetreat?);

  final String value;
  final String label;
  const EscrowStatus(this.value, this.label);

  static EscrowStatus fromString(String value) {
    return EscrowStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => EscrowStatus.held,
    );
  }
}
