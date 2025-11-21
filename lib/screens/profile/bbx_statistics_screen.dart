import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bbx_loading.dart';

/// BBX 统计页面
class BBXStatisticsScreen extends StatefulWidget {
  const BBXStatisticsScreen({super.key});

  @override
  State<BBXStatisticsScreen> createState() => _BBXStatisticsScreenState();
}

class _BBXStatisticsScreenState extends State<BBXStatisticsScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool isLoading = true;

  // 统计数据
  int totalListings = 0;
  int totalOffers = 0;
  int totalTransactions = 0;
  double totalRevenue = 0.0;
  double totalExpense = 0.0;
  int totalViews = 0;
  double averageRating = 0.0;
  int totalReviews = 0;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    // TODO: �?Firestore 加载实际数据
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      totalListings = 24;
      totalOffers = 56;
      totalTransactions = 32;
      totalRevenue = 15680.50;
      totalExpense = 8420.30;
      totalViews = 1234;
      averageRating = 4.8;
      totalReviews = 45;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: BBXFullScreenLoading()),
      );
    }

    final netProfit = totalRevenue - totalExpense;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('我的统计'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 财务概览
            const Text('财务概览', style: AppTheme.heading3),
            const SizedBox(height: AppTheme.spacing12),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary500, AppTheme.primary400],
                ),
                borderRadius: AppTheme.borderRadiusMedium,
                boxShadow: AppTheme.shadowMedium,
              ),
              padding: const EdgeInsets.all(AppTheme.spacing20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildFinancialItem(
                          '总收�?,
                          totalRevenue,
                          Icons.trending_up,
                          AppTheme.success,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      Expanded(
                        child: _buildFinancialItem(
                          '总支�?,
                          totalExpense,
                          Icons.trending_down,
                          AppTheme.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  const Divider(color: Colors.white, height: 1),
                  const SizedBox(height: AppTheme.spacing16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '净利润',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'RM ${netProfit.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: AppTheme.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacing24),

            // 业务统计
            const Text('业务统计', style: AppTheme.heading3),
            const SizedBox(height: AppTheme.spacing12),
            _buildStatGrid([
              _StatItem('发布商品', totalListings, Icons.inventory_2_rounded,
                  AppTheme.primary500),
              _StatItem('收到报价', totalOffers, Icons.local_offer_rounded,
                  AppTheme.secondary500),
              _StatItem('完成交易', totalTransactions,
                  Icons.check_circle_rounded, AppTheme.success),
              _StatItem('商品浏览', totalViews, Icons.visibility_rounded,
                  AppTheme.info),
            ]),

            const SizedBox(height: AppTheme.spacing24),

            // 评价统计
            const Text('评价统计', style: AppTheme.heading3),
            const SizedBox(height: AppTheme.spacing12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppTheme.borderRadiusMedium,
                boxShadow: AppTheme.shadowSmall,
              ),
              padding: const EdgeInsets.all(AppTheme.spacing20),
              child: Column(
                children: [
                  Row(
                    children: [
                      // 评分
                      Column(
                        children: [
                          Text(
                            averageRating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: AppTheme.bold,
                              color: AppTheme.primary500,
                            ),
                          ),
                          Row(
                            children: List.generate(
                              5,
                              (index) => Icon(
                                index < averageRating.floor()
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$totalReviews 条评�?,
                            style: AppTheme.caption,
                          ),
                        ],
                      ),

                      const SizedBox(width: AppTheme.spacing32),

                      // 评分分布
                      Expanded(
                        child: Column(
                          children: [
                            _buildRatingBar(5, 32),
                            _buildRatingBar(4, 8),
                            _buildRatingBar(3, 3),
                            _buildRatingBar(2, 1),
                            _buildRatingBar(1, 1),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacing24),

            // 月度趋势（简化版�?
            const Text('月度趋势', style: AppTheme.heading3),
            const SizedBox(height: AppTheme.spacing12),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppTheme.borderRadiusMedium,
                boxShadow: AppTheme.shadowSmall,
              ),
              padding: const EdgeInsets.all(AppTheme.spacing20),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.show_chart_rounded,
                      size: 64,
                      color: AppTheme.neutral400,
                    ),
                    SizedBox(height: AppTheme.spacing8),
                    Text(
                      '图表功能开发中',
                      style: TextStyle(
                        color: AppTheme.neutral500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialItem(
      String label, double amount, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'RM ${amount.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: AppTheme.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatGrid(List<_StatItem> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppTheme.spacing12,
        crossAxisSpacing: AppTheme.spacing12,
        childAspectRatio: 1.5,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppTheme.borderRadiusMedium,
            boxShadow: AppTheme.shadowSmall,
          ),
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, color: item.color, size: 32),
              const SizedBox(height: 8),
              Text(
                item.value.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: AppTheme.bold,
                  color: item.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: AppTheme.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRatingBar(int stars, int count) {
    final percentage = count / totalReviews;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(
              '$stars',
              style: AppTheme.caption,
            ),
          ),
          const Icon(Icons.star, size: 14, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: AppTheme.neutral200,
                valueColor: const AlwaysStoppedAnimation(AppTheme.primary500),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            child: Text(
              count.toString(),
              style: AppTheme.caption,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  _StatItem(this.label, this.value, this.icon, this.color);
}
