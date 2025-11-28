import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bbx_avatar.dart';
import '../../models/message_model.dart';
import '../../services/chat_service.dart';

class BBXNewChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;

  const BBXNewChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
  });

  @override
  State<BBXNewChatScreen> createState() => _BBXNewChatScreenState();
}

class _BBXNewChatScreenState extends State<BBXNewChatScreen> {
  final _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _auth = FirebaseAuth.instance;
  bool _isTyping = false;
  bool _isSending = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    // 监听输入框文本变化
    _messageController.addListener(() {
      setState(() {
        _hasText = _messageController.text.trim().isNotEmpty;
      });
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      _chatService.markAsRead(widget.conversationId);
    });
  }

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
                    Expanded(
            child: _buildMessagesList(),
          ),

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
                  _isTyping ? 'Typing......' : 'Online',
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

    Widget _buildMessagesList() {
    return StreamBuilder<List<MessageModel>>(
      stream: _chatService.getMessages(widget.conversationId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Load Failed: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data ?? [];

        if (messages.isEmpty) {
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
                  'Start Chat',
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
          itemCount: messages.length,
          itemBuilder: (context, index) {
            return _buildMessageBubble(messages[index]);
          },
        );
      },
    );
  }

    Widget _buildMessageBubble(MessageModel message) {
    final user = _auth.currentUser;
    final isMine = message.senderId == user?.uid;
    final content = message.content;
    final type = message.type;
    final createdAt = message.createdAt;
    final isRead = message.isRead;

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
                  child: _buildMessageContent(type, content, isMine),
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

    Widget _buildMessageContent(String type, String content, bool isMine) {
    switch (type) {
      case 'text':
        return Text(
          content,
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
                content,
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
                      'Item Title',
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
                        IconButton(
              icon: const Icon(Icons.add_circle_rounded),
              onPressed: _showAttachmentOptions,
              color: AppTheme.neutral600,
              iconSize: 28,
            ),
            const SizedBox(width: AppTheme.spacing8),

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
                  textInputAction: TextInputAction.send,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'InputMessage...',
                    isDense: true,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),

            const SizedBox(width: AppTheme.spacing8),

                        if (_hasText && !_isSending)
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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.neutral200,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.mic_rounded,
                    color: AppTheme.neutral600,
                  ),
                  onPressed: () {},
                ),
              ),
          ],
        ),
      ),
    );
  }

    Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      await _chatService.sendMessage(
        conversationId: widget.conversationId,
        receiverId: widget.otherUserId,
        content: content,
      );

      _messageController.clear();

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Send Failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

    void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppTheme.neutral300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Send Attachment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: AppTheme.spacing16,
              crossAxisSpacing: AppTheme.spacing16,
              children: [
                _buildAttachmentOption(
                  Icons.photo_library_rounded,
                  'Gallery',
                  () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Gallery feature coming soon...'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                _buildAttachmentOption(
                  Icons.camera_alt_rounded,
                  'Photo',
                  () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Photo feature coming soon...'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                _buildAttachmentOption(
                  Icons.location_on_rounded,
                  'Location',
                  () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Location feature coming soon...'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                _buildAttachmentOption(
                  Icons.shopping_bag_rounded,
                  'ItemLink',
                  () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Item link feature coming soon...'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
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

    void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.report_outlined),
              title: const Text('Report'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('ClearChatRecord'),
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
