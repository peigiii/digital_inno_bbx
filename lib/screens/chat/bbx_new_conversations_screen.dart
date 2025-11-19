import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bbx_avatar.dart';
import '../../widgets/bbx_chip.dart';
import '../../widgets/bbx_empty_state.dart';
import '../../widgets/bbx_loading.dart';
import 'bbx_new_chat_screen.dart';
import '../../utils/page_transitions.dart';

/// BBX 对话列表页（完全重构）
class BBXNewConversationsScreen extends StatefulWidget {
  const BBXNewConversationsScreen({super.key});

  @override
  State<BBXNewConversationsScreen> createState() => _BBXNewConversationsScreenState();
}

class _BBXNewConversationsScreenState extends State<BBXNewConversationsScreen> {
  String _selectedFilter = 'all';

  final List<String> _filters = ['all', 'unread', 'buyer', 'seller'];
  final Map<String, String> _filterLabels = {
    'all': '全部',
    'unread': '未读',
    'buyer': '买家',
    'seller': '卖家',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('消息', style: AppTheme.heading2),
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
          // 快捷筛选
          _buildFilterBar(),

          // 对话列表
          Expanded(
            child: _buildConversationsList(),
          ),
        ],
      ),
    );
  }

  /// 筛选栏
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

  /// 对话列表
  Widget _buildConversationsList() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return BBXEmptyState.noData(description: '请先登录');
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('conversations')
          .where('participants', arrayContains: user.uid)
          .orderBy('lastMessageTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return BBXEmptyState.noData(description: '加载失败');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const BBXListLoading(itemCount: 5);
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return BBXEmptyState.noMessages();
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            return _buildConversationCard(doc);
          },
        );
      },
    );
  }

  /// 对话卡片
  Widget _buildConversationCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final otherUserName = data['otherUserName'] ?? '未知用户';
    final otherUserAvatar = data['otherUserAvatar'] as String?;
    final lastMessage = data['lastMessage'] ?? '';
    final lastMessageTime = (data['lastMessageTime'] as Timestamp?)?.toDate();
    final unreadCount = data['unreadCount'] ?? 0;
    final isOnline = data['isOnline'] ?? false;

    return Dismissible(
      key: Key(doc.id),
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
          PageTransitions.navigateTo(
            context,
            BBXNewChatScreen(
              conversationId: doc.id,
              otherUserName: otherUserName,
              otherUserAvatar: otherUserAvatar,
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
              // 头像（带在线状态）
              BBXAvatarOnline(
                imageUrl: otherUserAvatar,
                name: otherUserName,
                size: 56,
                isOnline: isOnline,
              ),
              const SizedBox(width: AppTheme.spacing12),

              // 内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 顶部行：姓名 + 时间
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

                    // 底部行：最后消息 + 未读角标
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
                                  ? AppTheme.semibold
                                  : AppTheme.regular,
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
                              unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: AppTheme.bold,
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
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${time.month}月${time.day}日';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  String _formatLastMessage(String message) {
    if (message.isEmpty) return '';

    // 处理特殊消息类型
    if (message.startsWith('[图片]')) return '[图片]';
    if (message.startsWith('[文件]')) return '[文件]';
    if (message.startsWith('[位置]')) return '[位置]';
    if (message.startsWith('[商品]')) return '[商品链接]';

    return message;
  }
}
