import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/offer_model.dart';
import '../models/transaction_model.dart';

/// 报价服务类
class OfferService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 获取当前用户ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// 创建报价
  ///
  /// 参数：
  /// - listingId: 商品ID
  /// - sellerId: 卖家ID
  /// - offerPrice: 报价金额
  /// - originalPrice: 原价
  /// - message: 留言
  /// - scheduledPickupDate: 预计收集日期
  /// - deliveryMethod: 收集方式（self_pickup/platform_logistics/seller_delivery 或 self_collect/delivery）
  /// - deliveryNote: 配送备注
  ///
  /// 返回：报价ID
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
      throw Exception('用户未登录');
    }

    // 获取当前用户信息
    final userDoc = await _firestore.collection('users').doc(_currentUserId).get();
    final userData = userDoc.data() ?? {};

    // 计算48小时过期时间
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(hours: 48));

    final offer = OfferModel(
      id: '', // Firestore会自动生成
      listingId: listingId,
      recyclerId: _currentUserId!,
      recyclerName: userData['displayName'] ?? '未知用户',
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

    // 保存到Firestore
    final docRef = await _firestore.collection('offers').add(offer.toMap());

    // TODO: 发送通知给卖家

    return docRef.id;
  }

  /// 卖家接受报价
  Future<void> acceptOffer(String offerId) async {
    if (_currentUserId == null) {
      throw Exception('用户未登录');
    }

    final offerDoc = await _firestore.collection('offers').doc(offerId).get();
    if (!offerDoc.exists) {
      throw Exception('报价不存在');
    }

    final offer = OfferModel.fromDocument(offerDoc);

    // 检查权限：只有卖家可以接受
    if (offer.sellerId != _currentUserId) {
      throw Exception('无权操作');
    }

    // 检查状态：只能接受待处理或议价中的报价
    if (!offer.canAccept) {
      throw Exception('报价状态不允许接受');
    }

    // 检查是否过期
    if (offer.isExpired) {
      throw Exception('报价已过期');
    }

    // 更新报价状态
    await _firestore.collection('offers').doc(offerId).update({
      'status': 'accepted',
      'respondedAt': FieldValue.serverTimestamp(),
    });

    // 创建交易
    await _createTransaction(offerId);

    // TODO: 发送通知给买家
  }

  /// 卖家拒绝报价
  Future<void> rejectOffer(String offerId, String reason) async {
    if (_currentUserId == null) {
      throw Exception('用户未登录');
    }

    final offerDoc = await _firestore.collection('offers').doc(offerId).get();
    if (!offerDoc.exists) {
      throw Exception('报价不存在');
    }

    final offer = OfferModel.fromDocument(offerDoc);

    // 检查权限
    if (offer.sellerId != _currentUserId) {
      throw Exception('无权操作');
    }

    // 更新报价状态
    await _firestore.collection('offers').doc(offerId).update({
      'status': 'rejected',
      'rejectionReason': reason,
      'respondedAt': FieldValue.serverTimestamp(),
    });

    // TODO: 发送通知给买家
  }

  /// 卖家还价
  Future<void> counterOffer(String offerId, double counterPrice, String message) async {
    if (_currentUserId == null) {
      throw Exception('用户未登录');
    }

    final offerDoc = await _firestore.collection('offers').doc(offerId).get();
    if (!offerDoc.exists) {
      throw Exception('报价不存在');
    }

    final offer = OfferModel.fromDocument(offerDoc);

    // 检查权限
    if (offer.sellerId != _currentUserId) {
      throw Exception('无权操作');
    }

    // 检查是否可以议价
    if (!offer.canNegotiate) {
      throw Exception('报价状态不允许议价');
    }

    // 更新报价
    await _firestore.collection('offers').doc(offerId).update({
      'status': 'negotiating',
      'counterOfferPrice': counterPrice,
      'sellerResponse': message,
      'respondedAt': FieldValue.serverTimestamp(),
    });

    // TODO: 发送通知给买家
  }

  /// 买家接受还价
  Future<void> acceptCounterOffer(String offerId) async {
    if (_currentUserId == null) {
      throw Exception('用户未登录');
    }

    final offerDoc = await _firestore.collection('offers').doc(offerId).get();
    if (!offerDoc.exists) {
      throw Exception('报价不存在');
    }

    final offer = OfferModel.fromDocument(offerDoc);

    // 检查权限：只有买家可以接受还价
    if (offer.buyerId != _currentUserId) {
      throw Exception('无权操作');
    }

    // 检查状态
    if (offer.status != 'negotiating') {
      throw Exception('报价状态不正确');
    }

    if (offer.counterOfferPrice == null) {
      throw Exception('没有还价信息');
    }

    // 更新报价：接受还价，更新offerPrice为counterOfferPrice
    await _firestore.collection('offers').doc(offerId).update({
      'status': 'accepted',
      'offerPrice': offer.counterOfferPrice,
      'respondedAt': FieldValue.serverTimestamp(),
    });

    // 创建交易
    await _createTransaction(offerId);

    // TODO: 发送通知给卖家
  }

  /// 买家取消报价
  Future<void> cancelOffer(String offerId) async {
    if (_currentUserId == null) {
      throw Exception('用户未登录');
    }

    final offerDoc = await _firestore.collection('offers').doc(offerId).get();
    if (!offerDoc.exists) {
      throw Exception('报价不存在');
    }

    final offer = OfferModel.fromDocument(offerDoc);

    // 检查权限
    if (offer.buyerId != _currentUserId) {
      throw Exception('无权操作');
    }

    // 检查状态：只能取消待处理或议价中的报价
    if (offer.status != 'pending' && offer.status != 'negotiating') {
      throw Exception('报价状态不允许取消');
    }

    // 更新报价状态
    await _firestore.collection('offers').doc(offerId).update({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // TODO: 发送通知给卖家
  }

  /// 获取我发出的报价（买家视角）
  Stream<List<OfferModel>> getMyOffers() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('offers')
        .where('buyerId', isEqualTo: _currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => OfferModel.fromDocument(doc)).toList();
    });
  }

  /// 获取我收到的报价（卖家视角）
  Stream<List<OfferModel>> getReceivedOffers() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('offers')
        .where('sellerId', isEqualTo: _currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => OfferModel.fromDocument(doc)).toList();
    });
  }

  /// 获取某商品的所有报价
  Stream<List<OfferModel>> getOffersForListing(String listingId) {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('offers')
        .where('listingId', isEqualTo: listingId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => OfferModel.fromDocument(doc)).toList();
    });
  }

  /// 创建交易记录（私有方法）
  Future<void> _createTransaction(String offerId) async {
    final offerDoc = await _firestore.collection('offers').doc(offerId).get();
    if (!offerDoc.exists) {
      throw Exception('报价不存在');
    }

    final offer = OfferModel.fromDocument(offerDoc);

    // 计算平台费（3%）
    final platformFee = offer.offerPrice * 0.03;
    final totalAmount = offer.offerPrice + platformFee;

    final transaction = TransactionModel(
      id: '', // Firestore会自动生成
      offerId: offerId,
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

    // 保存到Firestore
    await _firestore.collection('transactions').add(transaction.toMap());

    // TODO: 发送通知给双方
  }

  /// 更新交易状态
  Future<void> updateTransactionStatus(String transactionId, String status) async {
    if (_currentUserId == null) {
      throw Exception('用户未登录');
    }

    await _firestore.collection('transactions').doc(transactionId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // TODO: 发送通知
  }

  /// 获取我的交易记录（买家视角）
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

  /// 获取单个报价详情
  Future<OfferModel?> getOffer(String offerId) async {
    final doc = await _firestore.collection('offers').doc(offerId).get();
    if (!doc.exists) {
      return null;
    }
    return OfferModel.fromDocument(doc);
  }

  /// 获取单个交易详情
  Future<TransactionModel?> getTransaction(String transactionId) async {
    final doc = await _firestore.collection('transactions').doc(transactionId).get();
    if (!doc.exists) {
      return null;
    }
    return TransactionModel.fromDocument(doc);
  }
}
