import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 钱包交易类型
enum WalletTransactionType {
  deposit,
  withdraw,
  payment,
  refund,
  reward,
}

/// 钱包交易记录
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

/// 钱包服务
class WalletService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 获取余额
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
      print('获取余额失败: $e');
      return 0.0;
    }
  }

  /// 初始化钱�?
  Future<void> _initializeWallet(String userId) async {
    await _firestore.collection('wallets').doc(userId).set({
      'balance': 0.0,
      'transactions': [],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 充�?
  Future<bool> deposit(double amount) async {
    if (amount <= 0) {
      throw Exception('充值金额必须大�?');
    }

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('用户未登�?);

      final doc = await _firestore.collection('wallets').doc(userId).get();

      if (!doc.exists) {
        await _initializeWallet(userId);
      }

      final transaction = WalletTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: WalletTransactionType.deposit,
        amount: amount,
        description: '账户充�?,
        timestamp: DateTime.now(),
      );

      await _firestore.collection('wallets').doc(userId).update({
        'balance': FieldValue.increment(amount),
        'transactions': FieldValue.arrayUnion([transaction.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 同时更新用户文档中的余额
      await _firestore.collection('users').doc(userId).update({
        'walletBalance': FieldValue.increment(amount),
      });

      return true;
    } catch (e) {
      print('充值失�? $e');
      return false;
    }
  }

  /// 提现
  Future<bool> withdraw(double amount) async {
    if (amount <= 0) {
      throw Exception('提现金额必须大于0');
    }

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('用户未登�?);

      final balance = await getBalance();

      if (balance < amount) {
        throw Exception('余额不足');
      }

      final transaction = WalletTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: WalletTransactionType.withdraw,
        amount: -amount,
        description: '账户提现',
        timestamp: DateTime.now(),
      );

      await _firestore.collection('wallets').doc(userId).update({
        'balance': FieldValue.increment(-amount),
        'transactions': FieldValue.arrayUnion([transaction.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 同时更新用户文档中的余额
      await _firestore.collection('users').doc(userId).update({
        'walletBalance': FieldValue.increment(-amount),
      });

      return true;
    } catch (e) {
      print('提现失败: $e');
      return false;
    }
  }

  /// 支付（用于购买商品）
  Future<bool> payment(
    double amount,
    String description,
    String? transactionId,
  ) async {
    if (amount <= 0) {
      throw Exception('支付金额必须大于0');
    }

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('用户未登�?);

      final balance = await getBalance();

      if (balance < amount) {
        throw Exception('余额不足');
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

      // 同时更新用户文档中的余额
      await _firestore.collection('users').doc(userId).update({
        'walletBalance': FieldValue.increment(-amount),
      });

      return true;
    } catch (e) {
      print('支付失败: $e');
      return false;
    }
  }

  /// 退�?
  Future<bool> refund(
    double amount,
    String description,
    String? transactionId,
  ) async {
    if (amount <= 0) {
      throw Exception('退款金额必须大�?');
    }

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('用户未登�?);

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

      // 同时更新用户文档中的余额
      await _firestore.collection('users').doc(userId).update({
        'walletBalance': FieldValue.increment(amount),
      });

      return true;
    } catch (e) {
      print('退款失�? $e');
      return false;
    }
  }

  /// 奖励（积分兑换等�?
  Future<bool> addReward(double amount, String description) async {
    if (amount <= 0) {
      throw Exception('奖励金额必须大于0');
    }

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('用户未登�?);

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

      // 同时更新用户文档中的余额
      await _firestore.collection('users').doc(userId).update({
        'walletBalance': FieldValue.increment(amount),
      });

      return true;
    } catch (e) {
      print('添加奖励失败: $e');
      return false;
    }
  }

  /// 获取交易记录
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
      print('获取交易记录失败: $e');
      return [];
    }
  }

  /// 获取特定类型的交易记�?
  Future<List<WalletTransaction>> getTransactionsByType(
    WalletTransactionType type, {
    int limit = 50,
  }) async {
    final allTransactions = await getTransactions(limit: limit);
    return allTransactions.where((t) => t.type == type).toList();
  }
}
