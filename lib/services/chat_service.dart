import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';
import 'notification_service.dart'; // ✅ 导入通知服务

/// Chat Service
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService(); // ✅ 添加通知服务

  /// Get Current User ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Get or Create Conversation
  ///
  /// If conversation exists, return ID
  /// If not, create new and return ID
  Future<String> getOrCreateConversation(String otherUserId) async {
    if (_currentUserId == null) {
      throw Exception('User not logged in');
    }

    if (_currentUserId == otherUserId) {
      throw Exception('Cannot chat with yourself');
    }

    // Find existing conversation
    final existingConversations = await _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: _currentUserId)
        .get();

    // Check if otherUserId is in participants
    for (var doc in existingConversations.docs) {
      final conversation = ConversationModel.fromDocument(doc);
      if (conversation.participantIds.contains(otherUserId)) {
        // Found existing
        return doc.id;
      }
    }

    // Not found, create new
    final newConversation = ConversationModel(
      id: '',
      participantIds: [_currentUserId!, otherUserId],
      createdAt: DateTime.now(),
    );

    final docRef = await _firestore.collection('conversations').add(newConversation.toMap());
    return docRef.id;
  }

  /// Send Message
  ///
  /// Params:
  /// - conversationId
  /// - receiverId
  /// - content
  /// - type (text/image/file/location/listing)
  /// - imageUrl (optional)
  /// - fileUrl (optional)
  /// - fileName (optional)
  /// - location (optional)
  /// - listingId (optional)
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
      throw Exception('User not logged in');
    }

    final now = DateTime.now();

    // Create Message
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

    // Save to Firestore
    final docRef = await _firestore.collection('messages').add(message.toMap());

    // Update Conversation
    await _firestore.collection('conversations').doc(conversationId).update({
      'lastMessage': content,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessageSenderId': _currentUserId,
      // Increment unread count for receiver
      'unreadCount.$receiverId': FieldValue.increment(1),
    });

    // ✅ 发送消息通知
    final senderDoc = await _firestore.collection('users').doc(_currentUserId).get();
    final senderName = senderDoc.data()?['displayName'] ?? 'Someone';
    await _notificationService.sendNotification(
      userId: receiverId,
      title: 'New Message from $senderName',
      body: type == 'text' ? content : 'Sent you a $type',
      data: {'conversationId': conversationId, 'type': 'new_message'},
    );

    return docRef.id;
  }

  /// Get Messages Stream
  ///
  /// Returns last 100 messages, desc order
  Stream<List<MessageModel>> getMessages(String conversationId) {
    return _firestore
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .handleError((error) {
          print('Error getting messages: $error');
        })
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            try {
              return MessageModel.fromDocument(doc);
            } catch (e) {
              print('Error parsing message ${doc.id}: $e');
              return null;
            }
          }).whereType<MessageModel>().toList();
        });
  }

  /// Get My Conversations Stream
  Stream<List<ConversationModel>> getMyConversations() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: _currentUserId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .handleError((error) {
          print('Error getting conversations: $error');
        })
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            try {
              return ConversationModel.fromDocument(doc);
            } catch (e) {
              print('Error parsing conversation ${doc.id}: $e');
              return null;
            }
          }).whereType<ConversationModel>().toList();
        });
  }

  /// Mark Messages as Read
  Future<void> markAsRead(String conversationId) async {
    if (_currentUserId == null) {
      throw Exception('User not logged in');
    }

    final now = DateTime.now();

    // Reset unread count for current user
    await _firestore.collection('conversations').doc(conversationId).update({
      'unreadCount.$_currentUserId': 0,
    });

    // Batch update unread messages
    final unreadMessages = await _firestore
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .where('receiverId', isEqualTo: _currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in unreadMessages.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readAt': Timestamp.fromDate(now),
      });
    }

    await batch.commit();
  }

  /// Update Typing Status
  Future<void> updateTypingStatus(String conversationId, bool isTyping) async {
    if (_currentUserId == null) {
      throw Exception('User not logged in');
    }

    await _firestore.collection('conversations').doc(conversationId).update({
      'isTyping.$_currentUserId': isTyping,
    });
  }

  /// Delete Message
  Future<void> deleteMessage(String messageId) async {
    if (_currentUserId == null) {
      throw Exception('User not logged in');
    }

    // Get Message
    final messageDoc = await _firestore.collection('messages').doc(messageId).get();
    if (!messageDoc.exists) {
      throw Exception('Message not found');
    }

    final message = MessageModel.fromDocument(messageDoc);

    // Permission Check
    if (message.senderId != _currentUserId) {
      throw Exception('Permission denied to delete message');
    }

    // Delete
    await _firestore.collection('messages').doc(messageId).delete();
  }

  /// Get Single Conversation
  Future<ConversationModel?> getConversation(String conversationId) async {
    final doc = await _firestore.collection('conversations').doc(conversationId).get();
    if (!doc.exists) {
      return null;
    }
    return ConversationModel.fromDocument(doc);
  }

  /// Get Total Unread Count
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

  /// Send Image Message
  Future<String> sendImageMessage({
    required String conversationId,
    required String receiverId,
    required String imageUrl,
    String caption = '',
  }) async {
    return await sendMessage(
      conversationId: conversationId,
      receiverId: receiverId,
      content: caption.isNotEmpty ? caption : 'Sent an image',
      type: 'image',
      imageUrl: imageUrl,
    );
  }

  /// Send File Message
  Future<String> sendFileMessage({
    required String conversationId,
    required String receiverId,
    required String fileUrl,
    required String fileName,
  }) async {
    return await sendMessage(
      conversationId: conversationId,
      receiverId: receiverId,
      content: 'Sent a file: $fileName',
      type: 'file',
      fileUrl: fileUrl,
      fileName: fileName,
    );
  }

  /// Send Location Message
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
      content: address ?? 'Sent location',
      type: 'location',
      location: {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      },
    );
  }

  /// Send Listing Message
  Future<String> sendListingMessage({
    required String conversationId,
    required String receiverId,
    required String listingId,
    String? listingTitle,
  }) async {
    return await sendMessage(
      conversationId: conversationId,
      receiverId: receiverId,
      content: listingTitle ?? 'Shared a listing',
      type: 'listing',
      listingId: listingId,
    );
  }
}
