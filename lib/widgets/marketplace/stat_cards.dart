import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// 数据统计卡片
class StatCards extends StatelessWidget {
  final Map<String, dynamic>? stats;

  const StatCards({super.key, this.stats});

  @override
  Widget build(BuildContext context) {
    final totalTonnage = stats?['totalTonnage'] ?? 0;
    final activeUsers = stats?['activeUsers'] ?? 0;
    final completedOrders = stats?['completedOrders'] ?? 0;
    final carbonReduced = stats?['carbonReduced'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: AppTheme.spacingMD,
        mainAxisSpacing: AppTheme.spacingMD,
        childAspectRatio: 1.5,
        children: [
          _buildStatCard(
            icon: Icons.inventory_2,
            value: '${_formatNumber(totalTonnage)}',
            label: '总交易量（吨）',
            color: AppTheme.primary,
          ),
          _buildStatCard(
            icon: Icons.people,
            value: '${_formatNumber(activeUsers)}',
            label: '活跃用户',
            color: AppTheme.accent,
          ),
          _buildStatCard(
            icon: Icons.check_circle,
            value: '${_formatNumber(completedOrders)}',
            label: '成交订单',
            color: AppTheme.success,
          ),
          _buildStatCard(
            icon: Icons.eco,
            value: '${_formatNumber(carbonReduced)}',
            label: '减少碳排放（吨）',
            color: AppTheme.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppTheme.borderRadiusLarge,
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: AppTheme.spacingSM),
          Text(
            value,
            style: AppTheme.h3.copyWith(color: color),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatNumber(num number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
