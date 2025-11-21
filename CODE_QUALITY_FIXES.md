# BBX Marketplace 代码质量修复方案

## P0 严重问题修复清单

### 1. 修复 Firestore 安全规则

**文件**: `firestore.rules`

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    function isAdmin() {
      return isAuthenticated() && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }

    // 用户集合
    match /users/{userId} {
      allow read: if true;
      allow create: if isAuthenticated() && request.auth.uid == userId;
      allow update: if isOwner(userId) || isAdmin();
      allow delete: if false;
    }

    // ✅ 修复: 使用正确的集合名 listings
    match /listings/{listingId} {
      allow read: if true;
      allow create: if isAuthenticated();
      allow update: if isAuthenticated() && (request.auth.uid == resource.data.userId || isAdmin());
      allow delete: if isAuthenticated() && (request.auth.uid == resource.data.userId || isAdmin());
    }

    // 报价集合
    match /offers/{offerId} {
      allow read: if isAuthenticated() && (
        request.auth.uid == resource.data.recyclerId ||
        request.auth.uid == resource.data.buyerId ||
        request.auth.uid == resource.data.producerId ||
        request.auth.uid == resource.data.sellerId ||
        isAdmin()
      );
      allow create: if isAuthenticated();
      allow update: if isAuthenticated() && (
        request.auth.uid == resource.data.producerId ||
        request.auth.uid == resource.data.sellerId ||
        isAdmin()
      );
      allow delete: if isAuthenticated() && (
        request.auth.uid == resource.data.recyclerId ||
        request.auth.uid == resource.data.buyerId ||
        isAdmin()
      );
    }

    // 交易集合
    match /transactions/{transactionId} {
      allow read: if isAuthenticated() && (
        request.auth.uid == resource.data.buyerId ||
        request.auth.uid == resource.data.sellerId ||
        isAdmin()
      );
      allow create: if isAuthenticated();
      allow update: if isAuthenticated() && (
        request.auth.uid == resource.data.buyerId ||
        request.auth.uid == resource.data.sellerId ||
        isAdmin()
      );
      allow delete: if false;
    }

    // ✅ 修复: 使用正确的字段名 participantIds
    match /conversations/{conversationId} {
      allow read: if isAuthenticated() && request.auth.uid in resource.data.participantIds;
      allow create: if isAuthenticated();
      allow update: if isAuthenticated() && request.auth.uid in resource.data.participantIds;
    }

    // ✅ 新增: 消息集合(顶层)
    match /messages/{messageId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if isAuthenticated() && request.auth.uid == resource.data.senderId;
      allow delete: if isAuthenticated() && request.auth.uid == resource.data.senderId;
    }

    // ✅ 新增: 物流更新集合
    match /logistics_updates/{updateId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if isAdmin();
      allow delete: if isAdmin();
    }

    // ✅ 新增: 优惠券集合
    match /coupons/{couponId} {
      allow read: if isAuthenticated() && request.auth.uid == resource.data.userId;
      allow create: if isAdmin();
      allow update: if isAdmin() || (isAuthenticated() && request.auth.uid == resource.data.userId);
      allow delete: if isAdmin();
    }

    // 默认拒绝所有其他访问
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

### 2. 修复 Firestore 索引

**文件**: `firestore.indexes.json`

需要替换的内容:
- 所有 `waste_listings` → `listings`
- 所有 `lastMessageTime` → `lastMessageAt`
- 所有 `participants` → `participantIds`

### 3. 删除开发模式代码

**文件**: `lib/services/offer_service.dart`

**删除 line 252-277** (getMyOffers 方法):
```dart
// ❌ 删除这段代码
Stream<List<OfferModel>> getMyOffers() {
  if (_currentUserId == null) {
    return Stream.value([]);
  }

  // 开发模式:如果用户没有数据,显示所有offers供测试
  return _firestore
      .collection('offers')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .asyncMap((snapshot) async {
    final allOffers = snapshot.docs.map((doc) => OfferModel.fromDocument(doc)).toList();

    final myOffers = allOffers.where((o) => o.buyerId == _currentUserId).toList();

    if (myOffers.isEmpty && allOffers.isNotEmpty) {
      debugPrint('⚠️ 开发模式:显示所有offers数据');
      return allOffers; // 🔴 严重问题!
    }

    return myOffers;
  });
}
```

**替换为**:
```dart
// ✅ 正确的实现
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
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          try {
            return OfferModel.fromDocument(doc);
          } catch (e) {
            print('解析报价失败 ${doc.id}: $e');
            return null;
          }
        }).whereType<OfferModel>().toList();
      });
}
```

**同样修复 getReceivedOffers** (line 279-305):
```dart
// ✅ 正确的实现
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
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          try {
            return OfferModel.fromDocument(doc);
          } catch (e) {
            print('解析报价失败 ${doc.id}: $e');
            return null;
          }
        }).whereType<OfferModel>().toList();
      });
}
```

**文件**: `lib/services/transaction_service.dart`

**修复 getMyBuyerTransactions** (line 334-367):
```dart
// ✅ 正确的实现
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
```

**修复 getMySellerTransactions** (line 369-402):
```dart
// ✅ 正确的实现
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
```

### 4. 修复 coupon_model.dart

**文件**: `lib/models/coupon_model.dart`

**修复 line 50-72** (fromFirestore 方法):
```dart
factory CouponModel.fromFirestore(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;

  return CouponModel(
    id: doc.id,
    userId: data['userId'] ?? '',
    code: data['code'] ?? '',
    title: data['title'] ?? '',
    description: data['description'] ?? '',
    discountType: data['discountType'] == 'percentage'
        ? CouponType.percentage
        : CouponType.fixed,
    discount: data['discount'] ?? 0,
    minAmount: (data['minAmount'] ?? 0).toDouble(),
    status: _parseStatus(data['status']),
    // ✅ 修复: 添加 null 检查和默认值
    expiryDate: (data['expiryDate'] as Timestamp?)?.toDate() ??
        DateTime.now().add(Duration(days: 30)),
    usedAt: data['usedAt'] != null
        ? (data['usedAt'] as Timestamp).toDate()
        : null,
    usedInTransactionId: data['usedInTransactionId'],
    createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );
}
```

## P1 重要问题修复清单

### 1. 为 Stream map 添加错误处理

**模式**:
```dart
// ✅ 标准错误处理模式
.map((snapshot) {
  return snapshot.docs.map((doc) {
    try {
      return Model.fromDocument(doc);
    } catch (e) {
      print('解析失败 ${doc.id}: $e');
      return null;
    }
  }).whereType<Model>().toList();
});
```

**需要修复的文件**:
- `lib/services/listing_service.dart:150`
- `lib/services/chat_service.dart:125, 141`

### 2. 为异步操作添加错误处理

**模式**:
```dart
Future<void> someAsyncOperation() async {
  try {
    // ... 操作代码 ...
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('操作失败: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

## 测试清单

修复完成后,请测试以下功能:

### 基础功能测试
- [ ] 用户注册/登录
- [ ] 查看商品列表
- [ ] 查看商品详情
- [ ] 发布商品
- [ ] 编辑商品
- [ ] 删除商品

### 报价功能测试
- [ ] 提交报价
- [ ] 查看我的报价(买家)
- [ ] 查看收到的报价(卖家)
- [ ] 接受报价
- [ ] 拒绝报价
- [ ] 议价

### 交易功能测试
- [ ] 创建交易
- [ ] 上传支付凭证
- [ ] 更新物流状态
- [ ] 确认收货
- [ ] 完成交易
- [ ] 取消交易

### 聊天功能测试
- [ ] 发送消息
- [ ] 接收消息
- [ ] 查看对话列表
- [ ] 标记已读

### 安全性测试
- [ ] 用户A不能看到用户B的报价
- [ ] 用户A不能看到用户B的交易
- [ ] 用户A不能修改用户B的商品
- [ ] 未登录用户不能进行操作

## 部署检查清单

部署到生产环境前:

- [ ] 已删除所有 debugPrint 开发日志
- [ ] 已删除所有开发模式代码
- [ ] firestore.rules 已部署
- [ ] firestore.indexes.json 已创建索引
- [ ] 所有功能测试通过
- [ ] 安全性测试通过
- [ ] 已进行代码审查
- [ ] 已更新文档

## 监控建议

部署后建议监控:
- Firestore 错误日志
- 安全规则拒绝日志
- 应用崩溃日志
- 用户反馈

---

**预计修复时间**: 4-6小时
**优先级**: P0 (必须立即修复)
**风险**: 高 (涉及用户隐私和数据安全)
