import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BBXAdminScreen extends StatefulWidget {
  const BBXAdminScreen({super.key});

  @override
  State<BBXAdminScreen> createState() => _BBXAdminScreenState();
}

class _BBXAdminScreenState extends State<BBXAdminScreen> {
  int _totalUsers = 0;
  int _totalListings = 0;
  int _totalOffers = 0;
  int _activeTransactions = 0;
  double _totalRevenue = 0.0;
  int _totalRecyclers = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkAdminPermission();
    _loadStatistics();
  }

  Future<void> _checkAdminPermission() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        final isAdmin = userDoc.data()?['isAdmin'] ?? false;

        if (!isAdmin && mounted) {
                    Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No permission to access admin panel?),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
            if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PermissionVerification Failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load all statistics in parallel
      final results = await Future.wait([
        _getTotalUsers(),
        _getTotalListings(),
        _getTotalOffers(),
        _getActiveTransactions(),
        _getTotalRevenue(),
        _getTotalRecyclers(),
      ]).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('StatisticsDataLoadTimeout');
        },
      );

      if (mounted) {
        setState(() {
          _totalUsers = results[0] as int;
          _totalListings = results[1] as int;
          _totalOffers = results[2] as int;
          _activeTransactions = results[3] as int;
          _totalRevenue = results[4] as double;
          _totalRecyclers = results[5] as int;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<int> _getTotalUsers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .get();
    return snapshot.docs.length;
  }

  Future<int> _getTotalListings() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('listings')
        .get();
    return snapshot.docs.length;
  }

  Future<int> _getTotalOffers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('offers')
        .get();
    return snapshot.docs.length;
  }

  Future<int> _getActiveTransactions() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('offers')
        .where('status', isEqualTo: 'accepted')
        .get();
    return snapshot.docs.length;
  }

  Future<double> _getTotalRevenue() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('offers')
        .where('status', isEqualTo: 'accepted')
        .get();

    double total = 0.0;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final price = data['offerPrice'] ?? 0;
      total += price.toDouble();
    }
    return total;
  }

  Future<int> _getTotalRecyclers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('recyclers')
        .get();
    return snapshot.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4CAF50),
              ),
            )
          : _error != null
              ? Center(
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
                        'Load Failed: $_error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadStatistics,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.admin_panel_settings,
                              size: 40,
                              color: Colors.white,
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome, Admin',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'BBX Platform Statistics',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Statistics Grid
                      GridView.count(
                        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildStatCard(
                            title: 'Total Users',
                            value: _totalUsers.toString(),
                            icon: Icons.people,
                            color: const Color(0xFF2196F3),
                            trend: '+12%',
                          ),
                          _buildStatCard(
                            title: 'Total Listings',
                            value: _totalListings.toString(),
                            icon: Icons.list,
                            color: const Color(0xFF4CAF50),
                            trend: '+8%',
                          ),
                          _buildStatCard(
                            title: 'Total Recyclers',
                            value: _totalRecyclers.toString(),
                            icon: Icons.recycling,
                            color: const Color(0xFF00BCD4),
                            trend: '+5%',
                          ),
                          _buildStatCard(
                            title: 'Total Offers',
                            value: _totalOffers.toString(),
                            icon: Icons.local_offer,
                            color: const Color(0xFFFFC107),
                            trend: '+15%',
                          ),
                          _buildStatCard(
                            title: 'Active Transactions',
                            value: _activeTransactions.toString(),
                            icon: Icons.trending_up,
                            color: const Color(0xFF9C27B0),
                            trend: '+20%',
                          ),
                          _buildStatCard(
                            title: 'Total Revenue',
                            value: 'RM ${_totalRevenue.toStringAsFixed(0)}',
                            icon: Icons.attach_money,
                            color: const Color(0xFF4CAF50),
                            trend: '+25%',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Recent Activity Section
                      _buildSectionTitle('Recent Activity'),
                      const SizedBox(height: 12),
                      _buildActivityCard(
                        icon: Icons.person_add,
                        title: 'New User Registration',
                        subtitle: '3 new users joined today',
                        time: '2 hours ago',
                        color: const Color(0xFF2196F3),
                      ),
                      const SizedBox(height: 8),
                      _buildActivityCard(
                        icon: Icons.add_circle,
                        title: 'New Listing Created',
                        subtitle: '5 new waste listings added',
                        time: '4 hours ago',
                        color: const Color(0xFF4CAF50),
                      ),
                      const SizedBox(height: 8),
                      _buildActivityCard(
                        icon: Icons.check_circle,
                        title: 'Offer Accepted',
                        subtitle: '2 offers were accepted',
                        time: '6 hours ago',
                        color: const Color(0xFF9C27B0),
                      ),
                      const SizedBox(height: 24),
                      // Quick Actions
                      _buildSectionTitle('Quick Actions'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              icon: Icons.people,
                              label: 'Manage Users',
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('User management feature coming soon'),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildActionButton(
                              icon: Icons.verified,
                              label: 'Verify Recyclers',
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Recycler verification feature coming soon'),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trend,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    trend,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildActivityCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: Text(
          time,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
