import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/firebase_auth/firebase_auth.dart';
import '../../models/message_model.dart';
import '../../services/chat_service.dart';
import 'bbx_chat_screen.dart';

/// 对话列表页面
class BBXConversationsScreen extends StatefulWidget {
  const BBXConversationsScreen({super.key});

  @override
  State<BBXConversationsScreen> createState() => _BBXConversationsScreenState();
}

class _BBXConversationsScreenState extends State<BBXConversationsScreen> {
  final _chatService = ChatService();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('消息'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: 实现搜索功能
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ConversationModel>>(
        stream: _chatService.getMyConversations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('加载失败：${snapshot.error}'));
          }

          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              return _buildConversationTile(conversations[index]);
            },
          );
        },
      ),
    );
  }

  /// 空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            '暂无消息',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '开始与其他用户聊天吧',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  /// 对话列表项
  Widget _buildConversationTile(ConversationModel conversation) {
    final otherUserId = conversation.getOtherParticipantId(_currentUserId!);
    if (otherUserId == null) return const SizedBox.shrink();

    return FutureBuilder<Map<String, dynamic>>(
      future: _getUserInfo(otherUserId),
      builder: (context, snapshot) {
        final userInfo = snapshot.data ?? {};
        final displayName = userInfo['displayName'] ?? '未知用户';
        final photoURL = userInfo['photoURL'];

        final unreadCount = conversation.getUnreadCount(_currentUserId!);
        final hasUnread = unreadCount > 0;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            radius: 28,
            backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
            child: photoURL == null ? Text(displayName[0].toUpperCase()) : null,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  displayName,
                  style: TextStyle(
                    fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              Text(
                _formatTime(conversation.lastMessageAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          subtitle: Row(
            children: [
              Expanded(
                child: Text(
                  conversation.lastMessage ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (hasUnread)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BBXChatScreen(
                  conversationId: conversation.id,
                  otherUserId: otherUserId,
                  otherUserName: displayName,
                  otherUserAvatar: photoURL,
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 获取用户信息
  Future<Map<String, dynamic>> _getUserInfo(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data() ?? {};
    } catch (e) {
      return {};
    }
  }

  /// 格式化时间
  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      // 今天：显示时间
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      // 昨天
      return '昨天';
    } else if (difference.inDays < 7) {
      // 本周：显示星期
      const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      return weekdays[dateTime.weekday - 1];
    } else {
      // 更早：显示日期
      return DateFormat('MM/dd').format(dateTime);
    }
  }
}
