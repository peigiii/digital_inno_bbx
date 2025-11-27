import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../widgets/state/empty_state_widget.dart';

/// ✅ 修复：完善我的列表页面，显示用户发布的废料
class BBXMyListingsStandaloneScreen extends StatefulWidget {
  const BBXMyListingsStandaloneScreen({Key? key}) : super(key: key);

  @override
  State<BBXMyListingsStandaloneScreen> createState() => _BBXMyListingsStandaloneScreenState();
}

class _BBXMyListingsStandaloneScreenState extends State<BBXMyListingsStandaloneScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, '/create-listing'),
            tooltip: 'Create Listing',
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Please login first'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('listings')
                  .where('userId', isEqualTo: user!.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return EmptyStateWidget.noListings(
                    onCreateListing: () => Navigator.pushNamed(context, '/create-listing'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  color: AppTheme.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return _buildListingCard(doc.id, data);
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/create-listing'),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add),
        label: const Text('New Listing'),
      ),
    );
  }

  Widget _buildListingCard(String listingId, Map<String, dynamic> data) {
    final status = data['status'] ?? 'available';
    final wasteType = data['wasteType'] ?? 'Unknown';
    final quantity = data['quantity'] ?? 0;
    final unit = data['unit'] ?? 'Tons';
    final price = (data['pricePerUnit'] ?? 0).toDouble();
    final imageUrl = (data['imageUrls'] as List?)?.isNotEmpty == true
        ? data['imageUrls'][0]
        : null;
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          '/listing-detail',
          arguments: {'listingId': listingId},
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppTheme.primary50,
                ),
                child: imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.inventory_2,
                            color: AppTheme.primary,
                            size: 32,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.inventory_2,
                        color: AppTheme.primary,
                        size: 32,
                      ),
              ),
              const SizedBox(width: 12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            wasteType,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildStatusChip(status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$quantity $unit',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'RM ${price.toStringAsFixed(2)} / $unit',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (createdAt != null)
                      Text(
                        _formatDate(createdAt),
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              
              // Arrow
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    
    switch (status.toLowerCase()) {
      case 'available':
        color = Colors.green;
        label = 'Available';
        break;
      case 'sold':
        color = Colors.blue;
        label = 'Sold';
        break;
      case 'expired':
        color = Colors.grey;
        label = 'Expired';
        break;
      default:
        color = Colors.orange;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
