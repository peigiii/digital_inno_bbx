import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:printing/printing.dart';
import '../services/pdf_generator_service.dart';
import '../utils/date_formatter.dart';

class BBXOffersScreen extends StatefulWidget {
  const BBXOffersScreen({super.key});

  @override
  State<BBXOffersScreen> createState() => _BBXOffersScreenState();
}

class _BBXOffersScreenState extends State<BBXOffersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _getOffersStream() {
    Query query = FirebaseFirestore.instance
        .collection('offers')
        .limit(20);

    if (_selectedStatus != 'all') {
      query = query.where('status', isEqualTo: _selectedStatus);
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  List<DocumentSnapshot> _filterOffers(List<DocumentSnapshot> offers) {
    if (_searchQuery.isEmpty) return offers;

    return offers.where((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return false;

      final listingId = (data['listingId'] ?? '').toString().toLowerCase();
      final message = (data['message'] ?? '').toString().toLowerCase();
      final searchLower = _searchQuery.toLowerCase();

      return listingId.contains(searchLower) || message.contains(searchLower);
    }).toList();
  }

  Future<void> _updateOfferStatus(String offerId, String newStatus, Map<String, dynamic> offerData) async {
    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF4CAF50),
                  ),
                  SizedBox(height: 16),
                  Text('处理中...'),
                ],
              ),
            ),
          ),
        ),
      );
    }

    try {
      final batch = FirebaseFirestore.instance.batch();

      // Update offer status
      final offerRef = FirebaseFirestore.instance.collection('offers').doc(offerId);
      batch.update(offerRef, {
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (newStatus == 'accepted') {
        // Get listing data
        final listingDoc = await FirebaseFirestore.instance
            .collection('waste_listings')
            .doc(offerData['listingId'])
            .get();

        if (!listingDoc.exists) {
          throw Exception('废料信息不存在');
        }

        final listingData = listingDoc.data() as Map<String, dynamic>;

        // Update listing status to sold
        final listingRef = FirebaseFirestore.instance
            .collection('waste_listings')
            .doc(offerData['listingId']);
        batch.update(listingRef, {
          'status': 'sold',
          'soldAt': FieldValue.serverTimestamp(),
          'soldTo': offerData['recyclerId'],
        });

        // Create transaction record
        final transactionId = DateTime.now().millisecondsSinceEpoch.toString();
        final transactionRef = FirebaseFirestore.instance
            .collection('transactions')
            .doc(transactionId);

        batch.set(transactionRef, {
          'transactionId': transactionId,
          'listingId': offerData['listingId'],
          'offerId': offerId,
          'producerId': offerData['producerId'],
          'processorId': offerData['recyclerId'],
          'amount': offerData['offerPrice'],
          'status': 'pending',
          'wasteType': listingData['wasteType'],
          'quantity': listingData['quantity'],
          'unit': listingData['unit'],
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Commit batch
        await batch.commit().timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw Exception('操作超时，请检查网络连接');
          },
        );

        // Generate PDF
        try {
          // Get producer and processor data
          final producerDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(offerData['producerId'])
              .get();
          final processorDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(offerData['recyclerId'])
              .get();

          if (producerDoc.exists && processorDoc.exists) {
            final pdfService = PDFGeneratorService();
            final pdfFile = await pdfService.generateCompliancePassport(
              transactionId: transactionId,
              producer: producerDoc.data() as Map<String, dynamic>,
              processor: processorDoc.data() as Map<String, dynamic>,
              wasteDetails: listingData,
            );

            // Show PDF
            if (mounted) {
              Navigator.pop(context); // Close loading dialog
              await Printing.layoutPdf(
                onLayout: (format) async => pdfFile.readAsBytes(),
              );
            }
          }
        } catch (pdfError) {
          // PDF generation failed, but transaction was successful
          debugPrint('PDF generation failed: $pdfError');
        }
      } else {
        // Just commit the rejection
        await batch.commit();
      }

      if (mounted) {
        if (newStatus == 'accepted') {
          // PDF dialog already closed the loading dialog
          if (Navigator.canPop(context)) {
            Navigator.pop(context); // Close loading dialog if still open
          }
        } else {
          Navigator.pop(context); // Close loading dialog
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('报价已${newStatus == "accepted" ? "接受" : "拒绝"}'),
            backgroundColor: newStatus == "accepted"
                ? const Color(0xFF4CAF50)
                : const Color(0xFFF44336),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Offers'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜索报价...',
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
                const SizedBox(height: 12),
                // Status Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'All Offers'),
                      const SizedBox(width: 8),
                      _buildFilterChip('pending', 'Pending'),
                      const SizedBox(width: 8),
                      _buildFilterChip('accepted', 'Accepted'),
                      const SizedBox(width: 8),
                      _buildFilterChip('rejected', 'Rejected'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Offers List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getOffersStream(),
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

                final allOffers = snapshot.data?.docs ?? [];
                final filteredOffers = _filterOffers(allOffers);

                if (filteredOffers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_offer_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty && _selectedStatus == 'all'
                              ? '暂无报价'
                              : '未找到匹配的报价',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (_searchQuery.isEmpty && _selectedStatus == 'all') ...[
                          const SizedBox(height: 8),
                          Text(
                            '还没有收到任何报价',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredOffers.length,
                  itemBuilder: (context, index) {
                    final offerDoc = filteredOffers[index];
                    final offerData = offerDoc.data() as Map<String, dynamic>;
                    return _buildOfferCard(offerDoc.id, offerData);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = value;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF4CAF50).withOpacity(0.2),
      checkmarkColor: const Color(0xFF4CAF50),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildOfferCard(String offerId, Map<String, dynamic> offerData) {
    final status = offerData['status'] ?? 'pending';
    final offerPrice = offerData['offerPrice'] ?? 0;
    final message = offerData['message'] ?? '';
    final listingId = offerData['listingId'] ?? 'N/A';
    final recyclerId = offerData['recyclerId'] ?? 'N/A';
    final createdAt = offerData['createdAt'] as Timestamp?;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Status Badge and Price
            Row(
              children: [
                _buildStatusBadge(status),
                const Spacer(),
                Text(
                  'RM ${offerPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            // Listing and Recycler Info
            _buildInfoRow(Icons.list, 'Listing ID', listingId),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.recycling, 'Recycler ID', recyclerId),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '留言',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
            if (createdAt != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTimestamp(createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
            // Action Buttons (only for pending offers)
            if (status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateOfferStatus(offerId, 'accepted', offerData),
                      icon: const Icon(Icons.check),
                      label: const Text('接受'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateOfferStatus(offerId, 'rejected', offerData),
                      icon: const Icon(Icons.close),
                      label: const Text('拒绝'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF44336),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case 'accepted':
        backgroundColor = const Color(0xFF4CAF50);
        textColor = Colors.white;
        label = 'Accepted';
        icon = Icons.check_circle;
        break;
      case 'rejected':
        backgroundColor = const Color(0xFFF44336);
        textColor = Colors.white;
        label = 'Rejected';
        icon = Icons.cancel;
        break;
      default:
        backgroundColor = const Color(0xFFFFC107);
        textColor = Colors.white;
        label = 'Pending';
        icon = Icons.pending;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF4CAF50)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    return DateFormatter.formatTimestamp(timestamp);
  }
}
