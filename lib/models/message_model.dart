import 'package:cloud_firestore/cloud_firestore.dart';

/// 消息模型
class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String content; // 消息内容
  final String type; // 消息类型：text/image/file/location/listing
  final DateTime? createdAt;
  final bool isRead; // 是否已读
  final DateTime? readAt; // 已读时间
  final String? imageUrl; // 图片URL（当type=image�?
  final String? fileUrl; // 文件URL（当type=file�?
  final String? fileName; // 文件名（当type=file�?
  final Map<String, dynamic>? location; // 位置信息（当type=location�?
  final String? listingId; // 商品ID（当type=listing�?

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

  /// �?Firestore 文档创建
  factory MessageModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel.fromMap(doc.id, data);
  }

  /// �?Map 创建
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

  /// 转换�?Map（用于Firestore�?
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

  /// 复制并修改部分字�?
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

  /// 是否为文本消�?
  bool get isText => type == 'text';

  /// 是否为图片消�?
  bool get isImage => type == 'image';

  /// 是否为文件消�?
  bool get isFile => type == 'file';

  /// 是否为位置消�?
  bool get isLocation => type == 'location';

  /// 是否为商品链�?
  bool get isListing => type == 'listing';

  @override
  String toString() {
    return 'MessageModel(id: $id, type: $type, content: $content, isRead: $isRead)';
  }
}

/// 对话模型
class ConversationModel {
  final String id;
  final List<String> participantIds; // 两个用户的ID
  final String? lastMessage; // 最后一条消息内�?
  final DateTime? lastMessageAt; // 最后消息时�?
  final String? lastMessageSenderId; // 最后消息发送者ID
  final Map<String, int> unreadCount; // 未读数：userId -> count
  final Map<String, bool> isTyping; // 正在输入：userId -> isTyping
  final DateTime? createdAt;

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

  /// �?Firestore 文档创建
  factory ConversationModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ConversationModel.fromMap(doc.id, data);
  }

  /// �?Map 创建
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

  /// 转换�?Map（用于Firestore�?
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

  /// 复制并修改部分字�?
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

  /// 获取某用户的未读�?
  int getUnreadCount(String userId) {
    return unreadCount[userId] ?? 0;
  }

  /// 获取对方的用户ID
  String? getOtherParticipantId(String currentUserId) {
    try {
      return participantIds.firstWhere((id) => id != currentUserId);
    } catch (e) {
      return null;
    }
  }

  /// 检查某用户是否正在输入
  bool isUserTyping(String userId) {
    return isTyping[userId] ?? false;
  }

  @override
  String toString() {
    return 'ConversationModel(id: $id, participants: ${participantIds.length}, lastMessage: $lastMessage)';
  }
}
