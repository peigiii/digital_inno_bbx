import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/user_avatar_widget.dart';

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
                final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .get();

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
        title: const Text('ConfirmRetreat?),
        content: const Text('OKWantLogout??),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retreat?),
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
        return 'BirthProduce?';
      case 'processor':
        return 'Process?';
      case 'recycler':
        return 'ReturnCollect?';
      case 'admin':
        return 'Manage?';
      default:
        return 'NormalUse?';
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
        title: const Text('IndividualProfile'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
                        UserAvatarWidget(
              photoURL: userData?['photoURL'],
              displayName: userData?['displayName'] ?? currentUser?.email ?? 'User',
              radius: 60,
            ),
            const SizedBox(height: 16),

                        Text(
              userData?['displayName'] ?? currentUser?.displayName ?? 'Unknown User',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

                        Text(
              currentUser?.email ?? '',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

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

                        Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow('CompanyName', userData?['companyName'] ?? '-'),
                    const Divider(),
                    _buildInfoRow('City', userData?['city'] ?? '-'),
                    const Divider(),
                    _buildInfoRow('ContactPhone', userData?['contact'] ?? '-'),
                    const Divider(),
                    _buildInfoRow(
                      'AuthenticateState?,
                      userData?['verified'] == true ? '?AlreadyRecognize? : '?NotRecognize?,
                    ),
                    if (userData?['isAdmin'] == true) ...[
                      const Divider(),
                      _buildInfoRow('Permission', '🔑 Manage?),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

                        Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Points',
                    '$userPoints',
                    Icons.stars,
                    Colors.amber,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'SubscriptionPlan',
                    userData?['subscriptionPlan'] ?? 'Free',
                    Icons.card_membership,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

                        SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Navigate to account settings
                  Navigator.pushNamed(context, '/account-settings');
                },
                icon: const Icon(Icons.edit),
                label: const Text('EditProfile'),
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

                        SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('LogoutClimb?),
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
