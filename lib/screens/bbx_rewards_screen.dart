import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BBXRewardsScreen extends StatefulWidget {
  const BBXRewardsScreen({super.key});

  @override
  State<BBXRewardsScreen> createState() => _BBXRewardsScreenState();
}

class _BBXRewardsScreenState extends State<BBXRewardsScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  int totalPoints = 0;
  String tier = 'bronze';
  List<Map<String, dynamic>> transactions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRewardsData();
  }

  Future<void> _loadRewardsData() async {
    if (currentUser == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('rewards')
          .doc(currentUser!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          totalPoints = data['points'] ?? 0;
          tier = data['tier'] ?? 'bronze';
          transactions = List<Map<String, dynamic>>.from(data['transactions'] ?? []);
          isLoading = false;
        });
      } else {
        await _initializeRewards();
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _initializeRewards() async {
    if (currentUser == null) return;

    await FirebaseFirestore.instance
        .collection('rewards')
        .doc(currentUser!.uid)
        .set({
      'points': 50,
      'tier': 'bronze',
      'transactions': [
        {
          'type': 'earn',
          'points': 50,
          'reason': 'Registration Reward',
          'timestamp': DateTime.now().toIso8601String(),
        }
      ],
    });

    await _loadRewardsData();
  }

  String _getTierIcon(String tier) {
    switch (tier) {
      case 'bronze':
        return '🥉';
      case 'silver':
        return '🥈';
      case 'gold':
        return '🥇';
      case 'platinum':
        return '💎';
      default:
        return '🏅';
    }
  }

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'bronze':
        return Colors.brown;
      case 'silver':
        return Colors.grey;
      case 'gold':
        return Colors.amber;
      case 'platinum':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic timestamp) {
    try {
      DateTime date;
      if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else {
        return 'Just now';
      }
      return DateFormat('yyyy-MM-dd HH:mm').format(date);
    } catch (e) {
      return 'Just now';
    }
  }

  Future<void> _redeemReward(String rewardType, int pointsCost) async {
    if (totalPoints < pointsCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient points'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final newTransaction = {
        'type': 'redeem',
        'points': -pointsCost,
        'reason': rewardType,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await FirebaseFirestore.instance
          .collection('rewards')
          .doc(currentUser!.uid)
          .update({
        'points': FieldValue.increment(-pointsCost),
        'transactions': FieldValue.arrayUnion([newTransaction]),
      });

      setState(() {
        totalPoints -= pointsCost;
        transactions.insert(0, newTransaction);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Redeemed: $rewardType'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Redemption failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reward Points'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getTierColor(tier),
                    _getTierColor(tier).withOpacity(0.7),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _getTierIcon(tier),
                    style: const TextStyle(fontSize: 64),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${tier.toUpperCase()} Member',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$totalPoints Points',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How to earn points',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildEarnRule('Registration', '+50 Points', Icons.person_add),
                  _buildEarnRule('Complete Transaction', '+10 Points/Tx', Icons.check_circle),
                  _buildEarnRule('Invite Friend', '+20 Points', Icons.group_add),
                  _buildEarnRule('Verify Account', '+30 Points', Icons.verified),
                  _buildEarnRule('Daily Use', '+5 Points/Day', Icons.calendar_today),
                  _buildEarnRule('Write Review', '+5 Points', Icons.star),
                ],
              ),
            ),

            const Divider(),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Redeem Rewards',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildRewardCard(
                    'RM 10 Discount',
                    100,
                    Icons.discount,
                    Colors.green,
                  ),
                  _buildRewardCard(
                    'Priority Match 7 Days',
                    50,
                    Icons.priority_high,
                    Colors.blue,
                  ),
                  _buildRewardCard(
                    'Donate to NGO',
                    200,
                    Icons.favorite,
                    Colors.red,
                  ),
                ],
              ),
            ),

            const Divider(),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Points History',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (transactions.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No history'),
                      ),
                    )
                  else
                    ...transactions.take(10).map((transaction) {
                      final isEarn = transaction['type'] == 'earn';
                      return ListTile(
                        leading: Icon(
                          isEarn ? Icons.add_circle : Icons.remove_circle,
                          color: isEarn ? Colors.green : Colors.red,
                        ),
                        title: Text(transaction['reason'] ?? ''),
                        subtitle: Text(_formatDate(transaction['timestamp'])),
                        trailing: Text(
                          '${isEarn ? '+' : ''}${transaction['points']}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isEarn ? Colors.green : Colors.red,
                          ),
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarnRule(String action, String points, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF4CAF50)),
        title: Text(action),
        trailing: Text(
          points,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF4CAF50),
          ),
        ),
      ),
    );
  }

  Widget _buildRewardCard(String title, int points, IconData icon, Color color) {
    final canAfford = totalPoints >= points;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('$points Points'),
        trailing: SizedBox(
          width: 70,
          height: 36,
          child: ElevatedButton(
            onPressed: canAfford ? () => _redeemReward(title, points) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canAfford ? color : Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('Redeem', style: TextStyle(fontSize: 13)),
          ),
        ),
      ),
    );
  }
}
