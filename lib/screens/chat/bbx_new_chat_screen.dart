import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bbx_avatar.dart';
import '../../widgets/bbx_button.dart';
import '../../widgets/bbx_bottom_sheet.dart';
import '../../widgets/bbx_notification.dart';

/// BBX 聊天详情页（完全重构）
class BBXNewChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserName;
  final String? otherUserAvatar;

  const BBXNewChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserName,
    this.otherUserAvatar,
  });

  @override
  State<BBXNewChatScreen> createState() => _BBXNewChatScreenState();
}

class _BBXNewChatScreenState extends State<BBXNewChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutral100,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // 消息列表
          Expanded(
            child: _buildMessagesList(),
          ),

          // 输入栏
          _buildInputBar(),
        ],
      ),
    );
  }

  /// AppBar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          BBXAvatar(
            imageUrl: widget.otherUserAvatar,
            name: widget.otherUserName,
            size: 40,
          ),
          const SizedBox(width: AppTheme.spacing8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: AppTheme.heading4,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _isTyping ? '正在输入...' : '在线',
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.neutral500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert_rounded),
          onPressed: () {
            _showMoreOptions();
          },
        ),
      ],
    );
  }

  /// 消息列表
  Widget _buildMessagesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('加载失败：${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 64,
                  color: AppTheme.neutral400,
                ),
                const SizedBox(height: AppTheme.spacing16),
                const Text(
                  '开始聊天吧',
                  style: AppTheme.body1,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.all(AppTheme.spacing16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            return _buildMessageBubble(doc);
          },
        );
      },
    );
  }

  /// 消息气泡
  Widget _buildMessageBubble(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final user = FirebaseAuth.instance.currentUser;
    final isMine = data['senderId'] == user?.uid;
    final message = data['message'] ?? '';
    final type = data['type'] ?? 'text';
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final isRead = data['isRead'] ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            BBXAvatar(
              imageUrl: widget.otherUserAvatar,
              name: widget.otherUserName,
              size: 32,
            ),
            const SizedBox(width: AppTheme.spacing8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing16,
                    vertical: AppTheme.spacing12,
                  ),
                  decoration: BoxDecoration(
                    color: isMine ? AppTheme.primary500 : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(
                          isMine ? AppTheme.radiusLarge : AppTheme.radiusSmall),
                      topRight: Radius.circular(
                          isMine ? AppTheme.radiusSmall : AppTheme.radiusLarge),
                      bottomLeft: const Radius.circular(AppTheme.radiusLarge),
                      bottomRight: const Radius.circular(AppTheme.radiusLarge),
                    ),
                    boxShadow: AppTheme.elevation1,
                  ),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  child: _buildMessageContent(type, message, isMine),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (createdAt != null)
                      Text(
                        _formatTime(createdAt),
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.neutral500,
                        ),
                      ),
                    if (isMine) ...[
                      const SizedBox(width: 4),
                      Icon(
                        isRead ? Icons.done_all_rounded : Icons.done_rounded,
                        size: 14,
                        color: isRead ? AppTheme.accent : AppTheme.neutral500,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 消息内容
  Widget _buildMessageContent(String type, String message, bool isMine) {
    switch (type) {
      case 'text':
        return Text(
          message,
          style: AppTheme.body1.copyWith(
            color: isMine ? Colors.white : AppTheme.neutral900,
          ),
        );
      case 'image':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: AppTheme.borderRadiusMedium,
              child: Image.network(
                message,
                width: 200,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 200,
                  height: 200,
                  color: AppTheme.neutral200,
                  child: const Icon(Icons.broken_image_rounded),
                ),
              ),
            ),
          ],
        );
      case 'listing':
        return Container(
          padding: const EdgeInsets.all(AppTheme.spacing12),
          decoration: BoxDecoration(
            color: isMine
                ? Colors.white.withOpacity(0.2)
                : AppTheme.neutral100,
            borderRadius: AppTheme.borderRadiusMedium,
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.neutral200,
                  borderRadius: AppTheme.borderRadiusMedium,
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '商品标题',
                      style: AppTheme.body2.copyWith(
                        color: isMine ? Colors.white : AppTheme.neutral900,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'RM 150.00',
                      style: AppTheme.heading4.copyWith(
                        color:
                            isMine ? Colors.white : AppTheme.primary500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      default:
        return Text(message);
    }
  }

  /// 输入栏
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppTheme.neutral300, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // 附件按钮
            BBXIconButton(
              icon: Icons.add_circle_rounded,
              onPressed: _showAttachmentOptions,
              color: AppTheme.neutral600,
              size: 48,
            ),
            const SizedBox(width: AppTheme.spacing8),

            // 输入框
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing16,
                  vertical: AppTheme.spacing8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.neutral100,
                  borderRadius: AppTheme.borderRadiusLarge,
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '输入消息...',
                    isDense: true,
                  ),
                  onChanged: (text) {
                    setState(() {});
                  },
                ),
              ),
            ),

            const SizedBox(width: AppTheme.spacing8),

            // 发送按钮
            if (_messageController.text.isNotEmpty)
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppTheme.primary500,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                  ),
                  onPressed: _sendMessage,
                ),
              )
            else
              BBXIconButton(
                icon: Icons.mic_rounded,
                onPressed: () {},
                color: AppTheme.neutral600,
                size: 48,
              ),
          ],
        ),
      ),
    );
  }

  /// 发送消息
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .add({
        'senderId': user.uid,
        'message': message,
        'type': 'text',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 更新对话的最后消息
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .update({
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      // 滚动到底部
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      BBXNotification.showError(context, '发送失败：$e');
    }
  }

  /// 显示附件选项
  void _showAttachmentOptions() {
    BBXBottomSheet.show(
      context: context,
      title: '发送',
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: GridView.count(
          shrinkWrap: true,
          crossAxisCount: 3,
          mainAxisSpacing: AppTheme.spacing16,
          crossAxisSpacing: AppTheme.spacing16,
          children: [
            _buildAttachmentOption(
              Icons.photo_library_rounded,
              '相册',
              () {},
            ),
            _buildAttachmentOption(
              Icons.camera_alt_rounded,
              '拍照',
              () {},
            ),
            _buildAttachmentOption(
              Icons.location_on_rounded,
              '位置',
              () {},
            ),
            _buildAttachmentOption(
              Icons.shopping_bag_rounded,
              '商品链接',
              () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(
      IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primary500.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppTheme.primary500,
              size: 28,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            label,
            style: AppTheme.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 显示更多选项
  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.report_outlined),
              title: const Text('举报'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('清空聊天记录'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
