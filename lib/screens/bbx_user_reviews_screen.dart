import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 用户评价展示页面
/// 显示用户收到的所有评价和统计信息
class BBXUserReviewsScreen extends StatefulWidget {
  final String userId;

  const BBXUserReviewsScreen({
    super.key,
    required this.userId,
  });

  @override
  State<BBXUserReviewsScreen> createState() => _BBXUserReviewsScreenState();
}

class _BBXUserReviewsScreenState extends State<BBXUserReviewsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('用户评价'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // 评价统计卡片
          _buildStatsCard(),
          // 筛选栏
          _buildFilterBar(),
          // 评价列表
          Expanded(child: _buildReviewsList()),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('reviews')
          .where('revieweeId', isEqualTo: widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 150);
        }

        final reviews = snapshot.data!.docs;
        final totalReviews = reviews.length;

        if (totalReviews == 0) {
          return Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  '暂无评价',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          );
        }

        // 计算统计数据
        double totalRating = 0;
        Map<int, int> ratingDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

        for (var doc in reviews) {
          final data = doc.data() as Map<String, dynamic>;
          final overallRating = (data['overallRating'] ?? 0.0).toDouble();
          totalRating += overallRating;
          ratingDistribution[overallRating.round()] =
              (ratingDistribution[overallRating.round()] ?? 0) + 1;
        }

        final averageRating = totalRating / totalReviews;

        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 平均评分
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          Text(
                            averageRating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          _buildStars(averageRating),
                          const SizedBox(height: 8),
                          Text(
                            '$totalReviews 条评�?,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          for (int i = 5; i >= 1; i--)
                            _buildRatingBar(
                              i,
                              ratingDistribution[i] ?? 0,
                              totalReviews,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, color: Colors.amber, size: 20);
        } else if (index < rating) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 20);
        } else {
          return Icon(Icons.star_border, color: Colors.grey[400], size: 20);
        }
      }),
    );
  }

  Widget _buildRatingBar(int stars, int count, int total) {
    final percentage = total > 0 ? count / total : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$stars', style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          const Icon(Icons.star, size: 12, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            child: Text(
              count.toString(),
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[100],
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('all', '全部'),
            const SizedBox(width: 8),
            _buildFilterChip('5', '好评 (5�?'),
            const SizedBox(width: 8),
            _buildFilterChip('3-4', '中评 (3-4�?'),
            const SizedBox(width: 8),
            _buildFilterChip('1-2', '差评 (1-2�?'),
            const SizedBox(width: 8),
            _buildFilterChip('images', '有图'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
    );
  }

  Widget _buildReviewsList() {
    Query query = _firestore
        .collection('reviews')
        .where('revieweeId', isEqualTo: widget.userId)
        .orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('错误: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var reviews = snapshot.data!.docs;

        // 应用筛�?
        reviews = reviews.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final rating = (data['overallRating'] ?? 0.0).toDouble();

          switch (_selectedFilter) {
            case '5':
              return rating >= 5.0;
            case '3-4':
              return rating >= 3.0 && rating < 5.0;
            case '1-2':
              return rating < 3.0;
            case 'images':
              return data['images'] != null &&
                  (data['images'] as List).isNotEmpty;
            default:
              return true;
          }
        }).toList();

        if (reviews.isEmpty) {
          return const Center(child: Text('暂无评价'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final doc = reviews[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildReviewCard(data);
          },
        );
      },
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> data) {
    final overallRating = (data['overallRating'] ?? 0.0).toDouble();
    final isAnonymous = data['isAnonymous'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 评价者信息和评分
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isAnonymous)
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        child: Icon(Icons.person, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '匿名用户',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  )
                else
                  FutureBuilder<DocumentSnapshot>(
                    future: _firestore
                        .collection('users')
                        .doc(data['reviewerId'])
                        .get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const Text('用户');
                      }

                      final userData =
                          snapshot.data!.data() as Map<String, dynamic>;
                      return Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: userData['avatarUrl'] != null
                                ? NetworkImage(userData['avatarUrl'])
                                : null,
                            child: userData['avatarUrl'] == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            userData['name'] ?? '用户',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      );
                    },
                  ),
                _buildStars(overallRating),
              ],
            ),
            const SizedBox(height: 12),

            // 多维度评�?
            if (data['descriptionScore'] != null ||
                data['serviceScore'] != null ||
                data['deliveryScore'] != null) ...[
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (data['descriptionScore'] != null)
                    _buildScoreChip(
                      '描述相符',
                      (data['descriptionScore'] as num).toDouble(),
                    ),
                  if (data['serviceScore'] != null)
                    _buildScoreChip(
                      '服务态度',
                      (data['serviceScore'] as num).toDouble(),
                    ),
                  if (data['deliveryScore'] != null)
                    _buildScoreChip(
                      '物流速度',
                      (data['deliveryScore'] as num).toDouble(),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // 标签
            if (data['tags'] != null && (data['tags'] as List).isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (data['tags'] as List).map((tag) {
                  return Chip(
                    label: Text(tag.toString()),
                    backgroundColor: Colors.blue[50],
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                    ),
                    padding: EdgeInsets.zero,
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // 评价内容
            if (data['comment'] != null && data['comment'].isNotEmpty) ...[
              Text(
                data['comment'],
                style: TextStyle(color: Colors.grey[800]),
              ),
              const SizedBox(height: 12),
            ],

            // 评价图片
            if (data['images'] != null &&
                (data['images'] as List).isNotEmpty) ...[
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: (data['images'] as List).length,
                  itemBuilder: (context, index) {
                    final imageUrl = (data['images'] as List)[index];
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(imageUrl, fit: BoxFit.cover),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],

            // 时间
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(data['createdAt']),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                if (data['transactionId'] != null)
                  Text(
                    '交易订单',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreChip(String label, double score) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(width: 4),
        ...List.generate(5, (index) {
          return Icon(
            index < score ? Icons.star : Icons.star_border,
            size: 12,
            color: Colors.amber,
          );
        }),
      ],
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '-';
    final date = timestamp.toDate();
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
