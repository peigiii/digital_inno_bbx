import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BBXRecyclersScreen extends StatefulWidget {
  const BBXRecyclersScreen({super.key});

  @override
  State<BBXRecyclersScreen> createState() => _BBXRecyclersScreenState();
}

class _BBXRecyclersScreenState extends State<BBXRecyclersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedWasteType = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _getRecyclersStream() {
    return FirebaseFirestore.instance
        .collection('recyclers')
        .limit(20)
        .snapshots()
        .timeout(
          const Duration(seconds: 10),
          onTimeout: (sink) {
            sink.addError(Exception('查询超时，请检查网络连接'));
          },
        );
  }

  List<DocumentSnapshot> _filterRecyclers(List<DocumentSnapshot> recyclers) {
    var filtered = recyclers;

    // Filter by waste type
    if (_selectedWasteType != 'all') {
      filtered = filtered.where((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) return false;
        final accepts = data['accepts'] as List<dynamic>?;
        return accepts?.contains(_selectedWasteType) ?? false;
      }).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) return false;

        final name = (data['name'] ?? '').toString().toLowerCase();
        final city = (data['city'] ?? '').toString().toLowerCase();
        final searchLower = _searchQuery.toLowerCase();

        return name.contains(searchLower) || city.contains(searchLower);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Waste Recyclers'),
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
                    hintText: '搜索处理者或城市...',
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
                // Waste Type Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'All Types'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Food_Waste', 'Food Waste'),
                      const SizedBox(width: 8),
                      _buildFilterChip('EFB', 'EFB'),
                      const SizedBox(width: 8),
                      _buildFilterChip('POME', 'POME'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Other', 'Other'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Recyclers List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getRecyclersStream(),
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

                final allRecyclers = snapshot.data?.docs ?? [];
                final filteredRecyclers = _filterRecyclers(allRecyclers);

                if (filteredRecyclers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.recycling,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty && _selectedWasteType == 'all'
                              ? '暂无处理者数据'
                              : '未找到匹配的处理者',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: filteredRecyclers.length,
                  itemBuilder: (context, index) {
                    final recyclerData = filteredRecyclers[index].data() as Map<String, dynamic>;
                    return _buildRecyclerCard(recyclerData);
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
    final isSelected = _selectedWasteType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedWasteType = value;
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

  Widget _buildRecyclerCard(Map<String, dynamic> recyclerData) {
    final name = recyclerData['name'] ?? 'Unknown Recycler';
    final city = recyclerData['city'] ?? 'N/A';
    final verified = recyclerData['verified'] ?? false;
    final rating = (recyclerData['rating'] ?? 0.0).toDouble();
    final capacity = recyclerData['capacity'] ?? 0;
    final accepts = recyclerData['accepts'] as List<dynamic>? ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _showRecyclerDetails(recyclerData);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recycler Icon and Verified Badge
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF4CAF50),
                    radius: 24,
                    child: const Icon(
                      Icons.recycling,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  if (verified)
                    const Icon(
                      Icons.verified,
                      color: Color(0xFF2196F3),
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Recycler Name
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Capacity
              if (capacity > 0)
                Row(
                  children: [
                    const Icon(
                      Icons.inventory_2,
                      size: 14,
                      color: Color(0xFF4CAF50),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '$capacity tons/month',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 4),
              // City
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      city,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Accepted Waste Types
              if (accepts.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: accepts.take(2).map((wasteType) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        wasteType.toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (accepts.length > 2)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+${accepts.length - 2} more',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
              // Rating
              if (rating > 0) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      size: 14,
                      color: Color(0xFFFFC107),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showRecyclerDetails(Map<String, dynamic> recyclerData) {
    final accepts = recyclerData['accepts'] as List<dynamic>? ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFF4CAF50),
              child: Icon(Icons.recycling, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recyclerData['name'] ?? 'Unknown Recycler',
                    style: const TextStyle(fontSize: 18),
                  ),
                  if (recyclerData['verified'] == true)
                    const Row(
                      children: [
                        Icon(Icons.verified, size: 16, color: Color(0xFF2196F3)),
                        SizedBox(width: 4),
                        Text(
                          'Verified',
                          style: TextStyle(fontSize: 12, color: Color(0xFF2196F3)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('城市', recyclerData['city'] ?? 'N/A'),
              if (recyclerData['capacity'] != null && recyclerData['capacity'] > 0)
                _buildDetailRow('处理能力', '${recyclerData['capacity']} tons/month'),
              if (recyclerData['contact'] != null)
                _buildDetailRow('联系方式', recyclerData['contact']),
              if (recyclerData['rating'] != null && recyclerData['rating'] > 0)
                _buildDetailRow('评分', '${recyclerData['rating'].toStringAsFixed(1)} ⭐'),
              if (accepts.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '接受的废料类型',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: accepts.map((wasteType) {
                    return Chip(
                      label: Text(
                        wasteType.toString(),
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: const Color(0xFF4CAF50).withOpacity(0.15),
                      labelStyle: const TextStyle(color: Color(0xFF2E7D32)),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
