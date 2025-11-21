import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/message_model.dart';
import '../../services/chat_service.dart';
import 'bbx_chat_screen.dart';

/// Conversations Screen
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
        title: const Text('Messages'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
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
            return Center(child: Text('Load failed: ${snapshot.error}'));
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

  /// Empty State
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start chatting with other users',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  /// Conversation List Item
  Widget _buildConversationTile(ConversationModel conversation) {
    final otherUserId = conversation.getOtherParticipantId(_currentUserId!);
    if (otherUserId == null) return const SizedBox.shrink();

    return FutureBuilder<Map<String, dynamic>>(
      future: _getUserInfo(otherUserId),
      builder: (context, snapshot) {
        final userInfo = snapshot.data ?? {};
        final displayName = userInfo['displayName'] ?? 'Unknown User';
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

  /// Get User Info
  Future<Map<String, dynamic>> _getUserInfo(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data() ?? {};
    } catch (e) {
      return {};
    }
  }

  /// Format Time
  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      // Today
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // This Week
      return DateFormat('EEEE').format(dateTime); // Day name
    } else {
      // Older
      return DateFormat('MM/dd').format(dateTime);
    }
  }
}
