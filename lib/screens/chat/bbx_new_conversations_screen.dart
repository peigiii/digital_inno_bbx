import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bbx_avatar.dart';
import '../../widgets/bbx_chip.dart';
import '../../models/message_model.dart';
import '../../services/chat_service.dart';
import 'bbx_new_chat_screen.dart';

class BBXNewConversationsScreen extends StatefulWidget {
  const BBXNewConversationsScreen({super.key});

  @override
  State<BBXNewConversationsScreen> createState() => _BBXNewConversationsScreenState();
}

class _BBXNewConversationsScreenState extends State<BBXNewConversationsScreen> {
  final _chatService = ChatService();
  final _auth = FirebaseAuth.instance;
  String _selectedFilter = 'all';

  final List<String> _filters = ['all', 'unread'];
  final Map<String, String> _filterLabels = {
    'all': 'All',
    'unread': 'Unread',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Message', style: AppTheme.heading2),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
                    _buildFilterBar(),

                    Expanded(
            child: _buildConversationsList(),
          ),
        ],
      ),
    );
  }

    Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing8,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacing8),
              child: BBXFilterChip(
                label: _filterLabels[filter]!,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

    Widget _buildConversationsList() {
    final user = _auth.currentUser;
    if (user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: AppTheme.neutral400),
            const SizedBox(height: 16),
            Text(
              'Please login first',
              style: AppTheme.body1.copyWith(color: AppTheme.neutral600),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<List<ConversationModel>>(
      stream: _chatService.getMyConversations(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppTheme.error),
                const SizedBox(height: 16),
                Text(
                  'Load Failed: ${snapshot.error}',
                  style: AppTheme.body1.copyWith(color: AppTheme.error),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final conversations = snapshot.data ?? [];

        // 应用过滤器
        List<ConversationModel> filteredConversations = conversations;
        if (_selectedFilter == 'unread') {
          filteredConversations = conversations.where((conv) {
            final unreadCount = conv.unreadCount[user.uid] ?? 0;
            return unreadCount > 0;
          }).toList();
        }

        if (filteredConversations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 64, color: AppTheme.neutral400),
                const SizedBox(height: 16),
                Text(
                  'No messages',
                  style: AppTheme.heading4.copyWith(color: AppTheme.neutral600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start a conversation',
                  style: AppTheme.body2.copyWith(color: AppTheme.neutral500),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredConversations.length,
          itemBuilder: (context, index) {
            return _buildConversationCard(filteredConversations[index], user.uid);
          },
        );
      },
    );
  }

    Widget _buildConversationCard(ConversationModel conversation, String currentUserId) {
    final otherUserId = conversation.getOtherParticipantId(currentUserId);
    if (otherUserId == null) return const SizedBox.shrink();

    return FutureBuilder<Map<String, dynamic>>(
      future: _getUserInfo(otherUserId),
      builder: (context, snapshot) {
        final userInfo = snapshot.data ?? {};
        final otherUserName = userInfo['displayName'] ?? userInfo['email'] ?? 'Unknown User';
        final otherUserAvatar = userInfo['photoURL'];
        final unreadCount = conversation.getUnreadCount(currentUserId);
        final lastMessage = conversation.lastMessage ?? '';
        final lastMessageTime = conversation.lastMessageAt;

        return Dismissible(
          key: Key(conversation.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: AppTheme.error,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: AppTheme.spacing16),
            child: const Icon(
              Icons.delete_rounded,
              color: Colors.white,
            ),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BBXNewChatScreen(
                    conversationId: conversation.id,
                    otherUserId: otherUserId,
                    otherUserName: otherUserName,
                    otherUserAvatar: otherUserAvatar,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing16,
                vertical: AppTheme.spacing12,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.neutral300,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  BBXAvatar(
                    imageUrl: otherUserAvatar,
                    name: otherUserName,
                    size: 56,
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                otherUserName,
                                style: AppTheme.heading4,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (lastMessageTime != null)
                              Text(
                                _formatTime(lastMessageTime),
                                style: AppTheme.caption.copyWith(
                                  color: AppTheme.neutral500,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _formatLastMessage(lastMessage),
                                style: AppTheme.body2.copyWith(
                                  color: unreadCount > 0
                                      ? AppTheme.neutral900
                                      : AppTheme.neutral600,
                                  fontWeight: unreadCount > 0
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (unreadCount > 0) ...[
                              const SizedBox(width: AppTheme.spacing8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: const BoxDecoration(
                                  color: AppTheme.error,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                child: Text(
                                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getUserInfo(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      return doc.data() ?? {};
    } catch (e) {
      return {};
    }
  }

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
      const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return weekdays[dateTime.weekday - 1];
    } else {
      // Older: Display Date
      return DateFormat('MM/dd').format(dateTime);
    }
  }

  String _formatLastMessage(String message) {
    if (message.isEmpty) return '';

        if (message.startsWith('[Image]')) return '[Image]';
    if (message.startsWith('[File]')) return '[File]';
    if (message.startsWith('[Location]')) return '[Location]';
    if (message.startsWith('[Item]')) return '[ItemLink]';

    return message;
  }
}
