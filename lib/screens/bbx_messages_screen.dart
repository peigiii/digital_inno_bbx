import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/date_formatter.dart';
import '../utils/search_history.dart';
import 'bbx_chat_screen.dart';

class BBXMessagesScreen extends StatefulWidget {
  const BBXMessagesScreen({super.key});

  @override
  State<BBXMessagesScreen> createState() => _BBXMessagesScreenState();
}

class _BBXMessagesScreenState extends State<BBXMessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<String> _searchHistory = [];
  bool _showSearchHistory = false;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    final history = await SearchHistory.getHistory('messages');
    if (mounted) {
      setState(() {
        _searchHistory = history;
      });
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isNotEmpty) {
      await SearchHistory.addToHistory('messages', query);
      await _loadSearchHistory();
    }
    setState(() {
      _searchQuery = query;
      _showSearchHistory = false;
    });
  }

  Future<void> _refreshConversations() async {
    setState(() {
          });
  }

  Stream<QuerySnapshot> _getConversationsStream() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .limit(20)
        .snapshots();
  }

  List<DocumentSnapshot> _filterConversations(List<DocumentSnapshot> conversations) {
    if (_searchQuery.isEmpty) return conversations;

    return conversations.where((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return false;

      final lastMessage = (data['lastMessage'] ?? '').toString().toLowerCase();
      final searchLower = _searchQuery.toLowerCase();

      return lastMessage.contains(searchLower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return Container(
        color: const Color(0xFFF5F5F5),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.login,
                size: 80,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                '请先登录以查看消?,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFFF5F5F5),
      child: Column(
        children: [
          // Search Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索对话...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          // Conversations List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getConversationsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '加载失败: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {});
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('重试'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF4CAF50),
                    ),
                  );
                }

                final allConversations = snapshot.data?.docs ?? [];
                final filteredConversations = _filterConversations(allConversations);

                if (filteredConversations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.message_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty ? '暂无消息' : '未找到匹配的对话',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isEmpty ? '还没有任何对? : '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshConversations,
                  color: const Color(0xFF4CAF50),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredConversations.length,
                    itemBuilder: (context, index) {
                      final conversationDoc = filteredConversations[index];
                      final conversationData = conversationDoc.data() as Map<String, dynamic>;
                      return _buildConversationCard(
                        conversationDoc.id,
                        conversationData,
                        currentUserId,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationCard(
    String conversationId,
    Map<String, dynamic> conversationData,
    String currentUserId,
  ) {
    final participants = conversationData['participants'] as List<dynamic>? ?? [];
    final lastMessage = conversationData['lastMessage'] ?? 'No messages yet';
    final lastMessageTime = conversationData['lastMessageTime'] as Timestamp?;
    final unreadCount = conversationData['unreadCount'] as Map<String, dynamic>? ?? {};
    final myUnreadCount = unreadCount[currentUserId] ?? 0;

    // Get the other participant's ID
    final otherUserId = participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => 'Unknown',
    );

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF4CAF50),
              radius: 28,
              child: Text(
                otherUserId.toString()[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            if (myUnreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    myUnreadCount > 99 ? '99+' : myUnreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        title: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(otherUserId)
              .get(),
          builder: (context, userSnapshot) {
            final userName = userSnapshot.hasData && userSnapshot.data!.data() != null
                ? (userSnapshot.data!.data() as Map<String, dynamic>)['displayName'] ?? 'Unknown User'
                : 'Loading...';

            return Text(
              userName,
              style: TextStyle(
                fontWeight: myUnreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                fontSize: 16,
              ),
            );
          },
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              lastMessage,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: myUnreadCount > 0 ? Colors.black87 : Colors.grey[600],
                fontWeight: myUnreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            if (lastMessageTime != null) ...[
              const SizedBox(height: 4),
              Text(
                _formatTimestamp(lastMessageTime),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Color(0xFF4CAF50),
        ),
        onTap: () {
          _openChatScreen(conversationId, otherUserId);
        },
      ),
    );
  }

  Future<void> _openChatScreen(String conversationId, String otherUserId) async {
    // Get other user's name
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(otherUserId)
          .get();

      final userName = userDoc.exists
          ? (userDoc.data() as Map<String, dynamic>)['displayName'] ?? 'Unknown User'
          : 'Unknown User';

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BBXChatScreen(
              conversationId: conversationId,
              otherUserId: otherUserId,
              otherUserName: userName,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('打开聊天失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    return DateFormatter.formatTimestamp(timestamp);
  }
}
