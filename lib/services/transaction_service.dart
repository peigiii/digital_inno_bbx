import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';
import '../models/logistics_update_model.dart';
import '../models/offer_model.dart';
import '../models/listing_model.dart';

/// 交易服务
class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// 1. 确认交易 - 当报价被接受时，自动创建交易记录
  Future<String> confirmTransaction(String offerId) async {
    try {
      // 获取报价详情
      final offerDoc = await _firestore.collection('offers').doc(offerId).get();
      if (!offerDoc.exists) {
        throw Exception('报价不存�?);
      }
      final offer = OfferModel.fromDocument(offerDoc);

      // 获取商品详情
      final listingDoc = await _firestore.collection('listings').doc(offer.listingId).get();
      if (!listingDoc.exists) {
        throw Exception('商品不存�?);
      }
      final listing = ListingModel.fromDocument(listingDoc);

      // 计算总金�?= 报价金额 + 平台费（3%�?
      final amount = offer.offerPrice;
      final platformFee = amount * 0.03;
      final totalAmount = amount + platformFee;

      // 创建交易记录
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
        deliveryMethod: offer.deliveryMethod, // 从报价继承配送方�?
        pickupScheduledDate: offer.scheduledPickupDate,
        createdAt: DateTime.now(),
      );

      // 保存交易记录
      await transactionRef.set(transaction.toMap());

      // 更新报价状态为已完�?
      await _firestore.collection('offers').doc(offerId).update({
        'status': 'completed',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // TODO: 发送通知给买家和卖家

      return transactionRef.id;
    } catch (e) {
      throw Exception('创建交易失败: $e');
    }
  }

  /// 2. 上传支付凭证
  Future<void> uploadPaymentProof(String transactionId, File imageFile) async {
    try {
      // 上传图片�?Firebase Storage
      final storageRef = _storage.ref().child('transactions/$transactionId/payment_proof.jpg');
      final uploadTask = await storageRef.putFile(imageFile);

      // 获取下载URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // 更新交易记录
      await _firestore.collection('transactions').doc(transactionId).update({
        'paymentProofUrl': downloadUrl,
        'paymentStatus': 'paid',
        'paidAt': FieldValue.serverTimestamp(),
      });

      // TODO: 发送通知给卖�?

    } catch (e) {
      throw Exception('上传支付凭证失败: $e');
    }
  }

  /// 3. 标记为已取货
  Future<void> markAsPickedUp(String transactionId, File? pickupPhoto) async {
    try {
      String? photoUrl;

      // 可选上传取货照�?
      if (pickupPhoto != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final storageRef = _storage.ref().child('transactions/$transactionId/logistics/pickup_$timestamp.jpg');
        final uploadTask = await storageRef.putFile(pickupPhoto);
        photoUrl = await uploadTask.ref.getDownloadURL();
      }

      // 更新交易状�?
      await _firestore.collection('transactions').doc(transactionId).update({
        'shippingStatus': 'picked_up',
        'actualPickupDate': FieldValue.serverTimestamp(),
        'shippedAt': FieldValue.serverTimestamp(),
      });

      // 创建物流更新记录
      await _createLogisticsUpdate(
        transactionId: transactionId,
        status: 'picked_up',
        description: '卖家已取�?,
        imageUrl: photoUrl,
      );

      // TODO: 发送通知给买�?

    } catch (e) {
      throw Exception('标记已取货失�? $e');
    }
  }

  /// 4. 更新物流状�?
  Future<void> updateShippingStatus({
    required String transactionId,
    required String newStatus,
    String? location,
    String? description,
    File? photo,
  }) async {
    try {
      // 验证状态转换合法�?
      final transactionDoc = await _firestore.collection('transactions').doc(transactionId).get();
      if (!transactionDoc.exists) {
        throw Exception('交易不存�?);
      }
      final transaction = TransactionModel.fromDocument(transactionDoc);

      // 状态转换验�?
      if (!_isValidStatusTransition(transaction.shippingStatus, newStatus)) {
        throw Exception('无效的状态转�?);
      }

      String? photoUrl;
      // 上传照片（如果有�?
      if (photo != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final storageRef = _storage.ref().child('transactions/$transactionId/logistics/$timestamp.jpg');
        final uploadTask = await storageRef.putFile(photo);
        photoUrl = await uploadTask.ref.getDownloadURL();
      }

      // 更新交易状�?
      await _firestore.collection('transactions').doc(transactionId).update({
        'shippingStatus': newStatus,
      });

      // 创建物流更新记录
      await _createLogisticsUpdate(
        transactionId: transactionId,
        status: newStatus,
        location: location,
        description: description ?? '物流状态更�?,
        imageUrl: photoUrl,
      );

      // TODO: 发送通知

    } catch (e) {
      throw Exception('更新物流状态失�? $e');
    }
  }

  /// 5. 买家确认收货
  Future<void> confirmDelivery(String transactionId) async {
    try {
      // 更新交易状�?
      await _firestore.collection('transactions').doc(transactionId).update({
        'shippingStatus': 'delivered',
        'deliveryDate': FieldValue.serverTimestamp(),
      });

      // 创建物流更新记录
      await _createLogisticsUpdate(
        transactionId: transactionId,
        status: 'delivered',
        description: '买家已确认收�?,
      );

      // TODO: 发送通知给卖�?

    } catch (e) {
      throw Exception('确认收货失败: $e');
    }
  }

  /// 6. 完成交易
  Future<void> completeTransaction(String transactionId) async {
    try {
      // 获取交易信息
      final transactionDoc = await _firestore.collection('transactions').doc(transactionId).get();
      if (!transactionDoc.exists) {
        throw Exception('交易不存�?);
      }
      final transaction = TransactionModel.fromDocument(transactionDoc);

      // 批量更新
      final batch = _firestore.batch();

      // 更新交易状�?
      batch.update(_firestore.collection('transactions').doc(transactionId), {
        'shippingStatus': 'completed',
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });

      // 更新商品状态为已售�?
      batch.update(_firestore.collection('listings').doc(transaction.listingId), {
        'status': 'sold',
        'soldAt': FieldValue.serverTimestamp(),
      });

      // 更新买家交易计数
      batch.update(_firestore.collection('users').doc(transaction.buyerId), {
        'totalTransactions': FieldValue.increment(1),
      });

      // 更新卖家交易计数
      batch.update(_firestore.collection('users').doc(transaction.sellerId), {
        'totalTransactions': FieldValue.increment(1),
      });

      // 提交批量操作
      await batch.commit();

      // 创建物流更新记录
      await _createLogisticsUpdate(
        transactionId: transactionId,
        status: 'completed',
        description: '交易已完�?,
      );

      // TODO: 发送通知

    } catch (e) {
      throw Exception('完成交易失败: $e');
    }
  }

  /// 7. 取消交易
  Future<void> cancelTransaction(String transactionId, String reason) async {
    try {
      // 获取交易信息
      final transactionDoc = await _firestore.collection('transactions').doc(transactionId).get();
      if (!transactionDoc.exists) {
        throw Exception('交易不存�?);
      }
      final transaction = TransactionModel.fromDocument(transactionDoc);

      // 批量更新
      final batch = _firestore.batch();

      // 更新交易状�?
      final updateData = {
        'status': 'cancelled',
        'cancellationReason': reason,
        'cancelledAt': FieldValue.serverTimestamp(),
      };

      // 如果已支付，标记为待退�?
      if (transaction.paymentStatus == 'paid') {
        updateData['paymentStatus'] = 'refunded';
        updateData['refundReason'] = reason;
        updateData['refundRequestedAt'] = FieldValue.serverTimestamp();
      }

      batch.update(_firestore.collection('transactions').doc(transactionId), updateData);

      // 恢复商品为可用状�?
      batch.update(_firestore.collection('listings').doc(transaction.listingId), {
        'status': 'available',
      });

      // 提交批量操作
      await batch.commit();

      // TODO: 发送通知

    } catch (e) {
      throw Exception('取消交易失败: $e');
    }
  }

  /// 8. 获取我的交易列表
  Stream<List<TransactionModel>> getMyTransactions(String userId, {String? status}) {
    try {
      Query query = _firestore.collection('transactions')
          .where('buyerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true);

      // 也需要获取我作为卖家的交�?
      Query sellerQuery = _firestore.collection('transactions')
          .where('sellerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true);

      // 可选按状态筛�?
      if (status != null) {
        query = query.where('shippingStatus', isEqualTo: status);
        sellerQuery = sellerQuery.where('shippingStatus', isEqualTo: status);
      }

      // 合并两个查询结果
      // 注意：Firestore 不支持直接合并查询，需要分别查询后合并
      // 这里我们返回买家查询，实际使用时需要特殊处�?
      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) => TransactionModel.fromDocument(doc)).toList();
      });
    } catch (e) {
      throw Exception('获取交易列表失败: $e');
    }
  }

  /// 获取我作为买家的交易
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
            print('解析交易失败 ${doc.id}: $e');
            return null;
          }
        }).whereType<TransactionModel>().toList();
      });
    } catch (e) {
      throw Exception('获取买家交易列表失败: $e');
    }
  }

  /// 获取我作为卖家的交易
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
            print('解析交易失败 ${doc.id}: $e');
            return null;
          }
        }).whereType<TransactionModel>().toList();
      });
    } catch (e) {
      throw Exception('获取卖家交易列表失败: $e');
    }
  }

  /// 9. 获取交易详情
  Future<TransactionModel> getTransactionDetails(String transactionId) async {
    try {
      final doc = await _firestore.collection('transactions').doc(transactionId).get();
      if (!doc.exists) {
        throw Exception('交易不存�?);
      }
      return TransactionModel.fromDocument(doc);
    } catch (e) {
      throw Exception('获取交易详情失败: $e');
    }
  }

  /// 获取交易详情（Stream�?
  Stream<TransactionModel> getTransactionDetailsStream(String transactionId) {
    return _firestore.collection('transactions').doc(transactionId).snapshots().map((doc) {
      if (!doc.exists) {
        throw Exception('交易不存�?);
      }
      return TransactionModel.fromDocument(doc);
    });
  }

  /// 10. 获取物流更新记录
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
      throw Exception('获取物流更新失败: $e');
    }
  }

  // ==================== 私有辅助方法 ====================

  /// 创建物流更新记录
  Future<void> _createLogisticsUpdate({
    required String transactionId,
    required String status,
    String? location,
    required String description,
    String? imageUrl,
  }) async {
    try {
      // 获取当前用户ID
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
      // 物流记录创建失败不应该影响主流程
      print('创建物流记录失败: $e');
    }
  }

  /// 验证状态转换是否合�?
  bool _isValidStatusTransition(String currentStatus, String newStatus) {
    // 定义合法的状态转�?
    const validTransitions = {
      'pending': ['picked_up'],
      'picked_up': ['in_transit', 'delivered'],
      'in_transit': ['delivered'],
      'delivered': ['completed'],
    };

    final allowedNextStates = validTransitions[currentStatus];
    return allowedNextStates?.contains(newStatus) ?? false;
  }

  /// 根据用户角色获取交易列表（合并买家和卖家�?
  Stream<List<TransactionModel>> getAllMyTransactions(String userId, {String? statusFilter}) {
    // 这是一个组合查询，需要特殊处�?
    // 由于 Firestore 限制，我们需要分别查询买家和卖家的交易，然后合并

    final buyerStream = getMyBuyerTransactions(userId, status: statusFilter);
    final sellerStream = getMySellerTransactions(userId, status: statusFilter);

    // 合并两个�?
    return buyerStream.asyncMap((buyerTransactions) async {
      // 这种方式不是最优的，实际应该使用更好的流合并方�?
      // 但为了简单起见，我们暂时这样处理
      final sellerSnapshot = await sellerStream.first;

      // 合并并去�?
      final allTransactions = [...buyerTransactions, ...sellerSnapshot];

      // 按创建时间排�?
      allTransactions.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));

      return allTransactions;
    });
  }

  /// 更新交易记录
  Future<void> updateTransaction(String transactionId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('transactions').doc(transactionId).update(data);
    } catch (e) {
      throw Exception('更新交易失败: $e');
    }
  }
}
