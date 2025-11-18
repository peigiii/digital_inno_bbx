import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';

/// 聊天服务类
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 获取当前用户ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// 获取或创建对话
  ///
  /// 如果对话已存在，返回对话ID
  /// 如果对话不存在，创建新对话并返回ID
  Future<String> getOrCreateConversation(String otherUserId) async {
    if (_currentUserId == null) {
      throw Exception('用户未登录');
    }

    if (_currentUserId == otherUserId) {
      throw Exception('不能与自己对话');
    }

    // 查找现有对话
    final existingConversations = await _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: _currentUserId)
        .get();

    // 遍历结果，检查是否包含otherUserId
    for (var doc in existingConversations.docs) {
      final conversation = ConversationModel.fromDocument(doc);
      if (conversation.participantIds.contains(otherUserId)) {
        // 找到现有对话
        return doc.id;
      }
    }

    // 没找到，创建新对话
    final newConversation = ConversationModel(
      id: '',
      participantIds: [_currentUserId!, otherUserId],
      createdAt: DateTime.now(),
    );

    final docRef = await _firestore.collection('conversations').add(newConversation.toMap());
    return docRef.id;
  }

  /// 发送消息
  ///
  /// 参数：
  /// - conversationId: 对话ID
  /// - receiverId: 接收者ID
  /// - content: 消息内容
  /// - type: 消息类型（text/image/file/location/listing）
  /// - imageUrl: 图片URL（可选）
  /// - fileUrl: 文件URL（可选）
  /// - fileName: 文件名（可选）
  /// - location: 位置信息（可选）
  /// - listingId: 商品ID（可选）
  Future<String> sendMessage({
    required String conversationId,
    required String receiverId,
    required String content,
    String type = 'text',
    String? imageUrl,
    String? fileUrl,
    String? fileName,
    Map<String, dynamic>? location,
    String? listingId,
  }) async {
    if (_currentUserId == null) {
      throw Exception('用户未登录');
    }

    final now = DateTime.now();

    // 创建消息
    final message = MessageModel(
      id: '',
      conversationId: conversationId,
      senderId: _currentUserId!,
      receiverId: receiverId,
      content: content,
      type: type,
      createdAt: now,
      imageUrl: imageUrl,
      fileUrl: fileUrl,
      fileName: fileName,
      location: location,
      listingId: listingId,
    );

    // 保存消息到Firestore
    final docRef = await _firestore.collection('messages').add(message.toMap());

    // 更新对话信息
    await _firestore.collection('conversations').doc(conversationId).update({
      'lastMessage': content,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessageSenderId': _currentUserId,
      // 增加接收者的未读数
      'unreadCount.$receiverId': FieldValue.increment(1),
    });

    // TODO: 发送推送通知给接收者

    return docRef.id;
  }

  /// 获取对话的消息列表
  ///
  /// 返回最近100条消息，按时间降序排序
  Stream<List<MessageModel>> getMessages(String conversationId) {
    return _firestore
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MessageModel.fromDocument(doc)).toList();
    });
  }

  /// 获取我的对话列表
  Stream<List<ConversationModel>> getMyConversations() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: _currentUserId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ConversationModel.fromDocument(doc)).toList();
    });
  }

  /// 标记消息为已读
  ///
  /// 将对话中所有未读消息标记为已读，并重置未读数
  Future<void> markAsRead(String conversationId) async {
    if (_currentUserId == null) {
      throw Exception('用户未登录');
    }

    final now = DateTime.now();

    // 重置当前用户的未读数
    await _firestore.collection('conversations').doc(conversationId).update({
      'unreadCount.$_currentUserId': 0,
    });

    // 批量更新所有未读消息
    final unreadMessages = await _firestore
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .where('receiverId', isEqualTo: _currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    // 使用批处理更新
    final batch = _firestore.batch();
    for (var doc in unreadMessages.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readAt': Timestamp.fromDate(now),
      });
    }

    await batch.commit();
  }

  /// 更新输入状态
  ///
  /// 显示"对方正在输入..."提示
  Future<void> updateTypingStatus(String conversationId, bool isTyping) async {
    if (_currentUserId == null) {
      throw Exception('用户未登录');
    }

    await _firestore.collection('conversations').doc(conversationId).update({
      'isTyping.$_currentUserId': isTyping,
    });
  }

  /// 删除消息
  Future<void> deleteMessage(String messageId) async {
    if (_currentUserId == null) {
      throw Exception('用户未登录');
    }

    // 获取消息信息
    final messageDoc = await _firestore.collection('messages').doc(messageId).get();
    if (!messageDoc.exists) {
      throw Exception('消息不存在');
    }

    final message = MessageModel.fromDocument(messageDoc);

    // 只能删除自己发送的消息
    if (message.senderId != _currentUserId) {
      throw Exception('无权删除此消息');
    }

    // 删除消息
    await _firestore.collection('messages').doc(messageId).delete();
  }

  /// 获取单个对话详情
  Future<ConversationModel?> getConversation(String conversationId) async {
    final doc = await _firestore.collection('conversations').doc(conversationId).get();
    if (!doc.exists) {
      return null;
    }
    return ConversationModel.fromDocument(doc);
  }

  /// 获取未读消息总数
  Future<int> getTotalUnreadCount() async {
    if (_currentUserId == null) {
      return 0;
    }

    final conversations = await _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: _currentUserId)
        .get();

    int totalUnread = 0;
    for (var doc in conversations.docs) {
      final conversation = ConversationModel.fromDocument(doc);
      totalUnread += conversation.getUnreadCount(_currentUserId!);
    }

    return totalUnread;
  }

  /// 发送图片消息
  Future<String> sendImageMessage({
    required String conversationId,
    required String receiverId,
    required String imageUrl,
    String caption = '',
  }) async {
    return await sendMessage(
      conversationId: conversationId,
      receiverId: receiverId,
      content: caption.isNotEmpty ? caption : '发送了一张图片',
      type: 'image',
      imageUrl: imageUrl,
    );
  }

  /// 发送文件消息
  Future<String> sendFileMessage({
    required String conversationId,
    required String receiverId,
    required String fileUrl,
    required String fileName,
  }) async {
    return await sendMessage(
      conversationId: conversationId,
      receiverId: receiverId,
      content: '发送了文件：$fileName',
      type: 'file',
      fileUrl: fileUrl,
      fileName: fileName,
    );
  }

  /// 发送位置消息
  Future<String> sendLocationMessage({
    required String conversationId,
    required String receiverId,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    return await sendMessage(
      conversationId: conversationId,
      receiverId: receiverId,
      content: address ?? '发送了位置',
      type: 'location',
      location: {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      },
    );
  }

  /// 发送商品链接
  Future<String> sendListingMessage({
    required String conversationId,
    required String receiverId,
    required String listingId,
    String? listingTitle,
  }) async {
    return await sendMessage(
      conversationId: conversationId,
      receiverId: receiverId,
      content: listingTitle ?? '分享了商品',
      type: 'listing',
      listingId: listingId,
    );
  }
}
