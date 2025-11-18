import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/user_avatar_widget.dart';
import 'bbx_edit_profile_screen.dart';

class BBXProfileScreen extends StatefulWidget {
  const BBXProfileScreen({super.key});

  @override
  State<BBXProfileScreen> createState() => _BBXProfileScreenState();
}

class _BBXProfileScreenState extends State<BBXProfileScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? userData;
  int userPoints = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      if (currentUser != null) {
        // 加载用户基本信息
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .get();

        // 加载用户积分
        final rewardsDoc = await FirebaseFirestore.instance
            .collection('rewards')
            .doc(currentUser!.uid)
            .get();

        if (mounted) {
          setState(() {
            userData = userDoc.data();
            userPoints = rewardsDoc.data()?['points'] ?? 0;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('退出'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  String _getUserTypeLabel(String? userType) {
    switch (userType) {
      case 'producer':
        return '生产者';
      case 'processor':
        return '处理者';
      case 'recycler':
        return '回收商';
      case 'admin':
        return '管理员';
      default:
        return '普通用户';
    }
  }

  Color _getUserTypeColor(String? userType) {
    switch (userType) {
      case 'producer':
        return const Color(0xFF2196F3);
      case 'processor':
        return const Color(0xFF4CAF50);
      case 'recycler':
        return const Color(0xFFFF9800);
      case 'admin':
        return const Color(0xFFF44336);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF4CAF50),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('个人资料'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 头像
            UserAvatarWidget(
              photoURL: userData?['photoURL'],
              displayName: userData?['displayName'] ?? currentUser?.email ?? 'User',
              radius: 60,
            ),
            const SizedBox(height: 16),

            // 用户名
            Text(
              userData?['displayName'] ?? currentUser?.displayName ?? 'Unknown User',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // 邮箱
            Text(
              currentUser?.email ?? '',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

            // 用户类型徽章
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getUserTypeColor(userData?['userType']),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    userData?['isAdmin'] == true
                        ? Icons.admin_panel_settings
                        : Icons.person,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getUserTypeLabel(userData?['userType']),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 信息卡片
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow('公司名称', userData?['companyName'] ?? '-'),
                    const Divider(),
                    _buildInfoRow('城市', userData?['city'] ?? '-'),
                    const Divider(),
                    _buildInfoRow('联系电话', userData?['contact'] ?? '-'),
                    const Divider(),
                    _buildInfoRow(
                      '认证状态',
                      userData?['verified'] == true ? '✅ 已认证' : '⏳ 未认证',
                    ),
                    if (userData?['isAdmin'] == true) ...[
                      const Divider(),
                      _buildInfoRow('权限', '🔑 管理员'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 统计信息
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '积分',
                    '$userPoints',
                    Icons.stars,
                    Colors.amber,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    '订阅计划',
                    userData?['subscriptionPlan'] ?? 'Free',
                    Icons.card_membership,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 编辑资料按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BBXEditProfileScreen(),
                    ),
                  );
                  if (result == true) {
                    // 重新加载数据
                    setState(() {
                      isLoading = true;
                    });
                    _loadUserData();
                  }
                },
                icon: const Icon(Icons.edit),
                label: const Text('编辑资料'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 退出登录按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('退出登录'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
