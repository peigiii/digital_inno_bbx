import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String content;   final String type;   final DateTime? createdAt;
  final bool isRead;   final DateTime? readAt;   final String? imageUrl;   final String? fileUrl;   final String? fileName;   final Map<String, dynamic>? location;   final String? listingId; 
  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.type = 'text',
    this.createdAt,
    this.isRead = false,
    this.readAt,
    this.imageUrl,
    this.fileUrl,
    this.fileName,
    this.location,
    this.listingId,
  });

    factory MessageModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel.fromMap(doc.id, data);
  }

    factory MessageModel.fromMap(String id, Map<String, dynamic> data) {
    return MessageModel(
      id: id,
      conversationId: data['conversationId'] ?? '',
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      content: data['content'] ?? '',
      type: data['type'] ?? 'text',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      isRead: data['isRead'] ?? false,
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
      imageUrl: data['imageUrl'],
      fileUrl: data['fileUrl'],
      fileName: data['fileName'],
      location: data['location'] as Map<String, dynamic>?,
      listingId: data['listingId'],
    );
  }

    Map<String, dynamic> toMap() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'isRead': isRead,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'imageUrl': imageUrl,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'location': location,
      'listingId': listingId,
    };
  }

    MessageModel copyWith({
    String? content,
    String? type,
    bool? isRead,
    DateTime? readAt,
    String? imageUrl,
    String? fileUrl,
    String? fileName,
    Map<String, dynamic>? location,
    String? listingId,
  }) {
    return MessageModel(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiverId,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      imageUrl: imageUrl ?? this.imageUrl,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      location: location ?? this.location,
      listingId: listingId ?? this.listingId,
    );
  }

    bool get isText => type == 'text';

    bool get isImage => type == 'image';

    bool get isFile => type == 'file';

    bool get isLocation => type == 'location';

    bool get isListing => type == 'listing';

  @override
  String toString() {
    return 'MessageModel(id: $id, type: $type, content: $content, isRead: $isRead)';
  }
}

class ConversationModel {
  final String id;
  final List<String> participantIds;   final String? lastMessage;   final DateTime? lastMessageAt;   final String? lastMessageSenderId;   final Map<String, int> unreadCount;   final Map<String, bool> isTyping;   final DateTime? createdAt;

  ConversationModel({
    required this.id,
    required this.participantIds,
    this.lastMessage,
    this.lastMessageAt,
    this.lastMessageSenderId,
    this.unreadCount = const {},
    this.isTyping = const {},
    this.createdAt,
  });

    factory ConversationModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ConversationModel.fromMap(doc.id, data);
  }

    factory ConversationModel.fromMap(String id, Map<String, dynamic> data) {
    return ConversationModel(
      id: id,
      participantIds: (data['participantIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      lastMessage: data['lastMessage'],
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
      lastMessageSenderId: data['lastMessageSenderId'],
      unreadCount: (data['unreadCount'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, (value as num).toInt()),
          ) ??
          {},
      isTyping: (data['isTyping'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as bool),
          ) ??
          {},
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

    Map<String, dynamic> toMap() {
    return {
      'participantIds': participantIds,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount': unreadCount,
      'isTyping': isTyping,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

    ConversationModel copyWith({
    List<String>? participantIds,
    String? lastMessage,
    DateTime? lastMessageAt,
    String? lastMessageSenderId,
    Map<String, int>? unreadCount,
    Map<String, bool>? isTyping,
  }) {
    return ConversationModel(
      id: id,
      participantIds: participantIds ?? this.participantIds,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCount: unreadCount ?? this.unreadCount,
      isTyping: isTyping ?? this.isTyping,
      createdAt: createdAt,
    );
  }

    int getUnreadCount(String userId) {
    return unreadCount[userId] ?? 0;
  }

    String? getOtherParticipantId(String currentUserId) {
    try {
      return participantIds.firstWhere((id) => id != currentUserId);
    } catch (e) {
      return null;
    }
  }

    bool isUserTyping(String userId) {
    return isTyping[userId] ?? false;
  }

  @override
  String toString() {
    return 'ConversationModel(id: $id, participants: ${participantIds.length}, lastMessage: $lastMessage)';
  }
}
