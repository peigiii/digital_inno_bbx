import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum WalletTransactionType {
  deposit,
  withdraw,
  payment,
  refund,
  reward,
}

class WalletTransaction {
  final String id;
  final WalletTransactionType type;
  final double amount;
  final String description;
  final DateTime timestamp;
  final String? relatedTransactionId;

  WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.timestamp,
    this.relatedTransactionId,
  });

  factory WalletTransaction.fromMap(Map<String, dynamic> data) {
    return WalletTransaction(
      id: data['id'] ?? '',
      type: _parseType(data['type']),
      amount: (data['amount'] as num).toDouble(),
      description: data['description'] ?? '',
      timestamp: data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.parse(data['timestamp']),
      relatedTransactionId: data['relatedTransactionId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'amount': amount,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'relatedTransactionId': relatedTransactionId,
    };
  }

  static WalletTransactionType _parseType(String? value) {
    switch (value?.toLowerCase()) {
      case 'deposit':
        return WalletTransactionType.deposit;
      case 'withdraw':
        return WalletTransactionType.withdraw;
      case 'payment':
        return WalletTransactionType.payment;
      case 'refund':
        return WalletTransactionType.refund;
      case 'reward':
        return WalletTransactionType.reward;
      default:
        return WalletTransactionType.deposit;
    }
  }
}

class WalletService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

    Future<double> getBalance() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return 0.0;

      final doc = await _firestore.collection('wallets').doc(userId).get();

      if (!doc.exists) {
        await _initializeWallet(userId);
        return 0.0;
      }

      return (doc.data()?['balance'] ?? 0).toDouble();
    } catch (e) {
      print('Failed to get balance: $e');
      return 0.0;
    }
  }

    Future<void> _initializeWallet(String userId) async {
    await _firestore.collection('wallets').doc(userId).set({
      'balance': 0.0,
      'transactions': [],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

    Future<bool> deposit(double amount) async {
    if (amount <= 0) {
      throw Exception('Top-up amount must be greater than 0');
    }

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      final doc = await _firestore.collection('wallets').doc(userId).get();

      if (!doc.exists) {
        await _initializeWallet(userId);
      }

      final transaction = WalletTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: WalletTransactionType.deposit,
        amount: amount,
        description: 'Account Top-up',
        timestamp: DateTime.now(),
      );

      await _firestore.collection('wallets').doc(userId).update({
        'balance': FieldValue.increment(amount),
        'transactions': FieldValue.arrayUnion([transaction.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

            await _firestore.collection('users').doc(userId).update({
        'walletBalance': FieldValue.increment(amount),
      });

      return true;
    } catch (e) {
      print('Top-up failed: $e');
      return false;
    }
  }

    Future<bool> withdraw(double amount) async {
    if (amount <= 0) {
      throw Exception('Withdrawal amount must be greater than 0');
    }

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      final balance = await getBalance();

      if (balance < amount) {
        throw Exception('Insufficient balance');
      }

      final transaction = WalletTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: WalletTransactionType.withdraw,
        amount: -amount,
        description: 'Account Withdrawal',
        timestamp: DateTime.now(),
      );

      await _firestore.collection('wallets').doc(userId).update({
        'balance': FieldValue.increment(-amount),
        'transactions': FieldValue.arrayUnion([transaction.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

            await _firestore.collection('users').doc(userId).update({
        'walletBalance': FieldValue.increment(-amount),
      });

      return true;
    } catch (e) {
      print('Withdrawal failed: $e');
      return false;
    }
  }

    Future<bool> payment(
    double amount,
    String description,
    String? transactionId,
  ) async {
    if (amount <= 0) {
      throw Exception('Payment amount must be greater than 0');
    }

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      final balance = await getBalance();

      if (balance < amount) {
        throw Exception('Insufficient balance');
      }

      final transaction = WalletTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: WalletTransactionType.payment,
        amount: -amount,
        description: description,
        timestamp: DateTime.now(),
        relatedTransactionId: transactionId,
      );

      await _firestore.collection('wallets').doc(userId).update({
        'balance': FieldValue.increment(-amount),
        'transactions': FieldValue.arrayUnion([transaction.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

            await _firestore.collection('users').doc(userId).update({
        'walletBalance': FieldValue.increment(-amount),
      });

      return true;
    } catch (e) {
      print('Payment failed: $e');
      return false;
    }
  }

    Future<bool> refund(
    double amount,
    String description,
    String? transactionId,
  ) async {
    if (amount <= 0) {
      throw Exception('Refund amount must be greater than 0');
    }

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      final transaction = WalletTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: WalletTransactionType.refund,
        amount: amount,
        description: description,
        timestamp: DateTime.now(),
        relatedTransactionId: transactionId,
      );

      await _firestore.collection('wallets').doc(userId).update({
        'balance': FieldValue.increment(amount),
        'transactions': FieldValue.arrayUnion([transaction.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

            await _firestore.collection('users').doc(userId).update({
        'walletBalance': FieldValue.increment(amount),
      });

      return true;
    } catch (e) {
      print('Refund failed: $e');
      return false;
    }
  }

    Future<bool> addReward(double amount, String description) async {
    if (amount <= 0) {
      throw Exception('Reward amount must be greater than 0');
    }

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      final transaction = WalletTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: WalletTransactionType.reward,
        amount: amount,
        description: description,
        timestamp: DateTime.now(),
      );

      await _firestore.collection('wallets').doc(userId).update({
        'balance': FieldValue.increment(amount),
        'transactions': FieldValue.arrayUnion([transaction.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

            await _firestore.collection('users').doc(userId).update({
        'walletBalance': FieldValue.increment(amount),
      });

      return true;
    } catch (e) {
      print('Failed to add reward: $e');
      return false;
    }
  }

    Future<List<WalletTransaction>> getTransactions({int limit = 50}) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final doc = await _firestore.collection('wallets').doc(userId).get();

      if (!doc.exists) return [];

      final transactions = doc.data()?['transactions'] as List<dynamic>?;

      if (transactions == null) return [];

      return transactions
          .map((t) => WalletTransaction.fromMap(t as Map<String, dynamic>))
          .take(limit)
          .toList();
    } catch (e) {
      print('Failed to get transactions: $e');
      return [];
    }
  }

    Future<List<WalletTransaction>> getTransactionsByType(
    WalletTransactionType type, {
    int limit = 50,
  }) async {
    final allTransactions = await getTransactions(limit: limit);
    return allTransactions.where((t) => t.type == type).toList();
  }
}
