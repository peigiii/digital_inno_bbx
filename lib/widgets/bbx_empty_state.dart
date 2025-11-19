import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 空状态组件 - 用于显示无数据、无结果等状态
class BBXEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget? action;

  const BBXEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.action,
  });

  /// 无数据状态
  factory BBXEmptyState.noData({
    String title = '暂无数据',
    String description = '暂时没有内容',
    Widget? action,
  }) {
    return BBXEmptyState(
      icon: Icons.inbox_outlined,
      title: title,
      description: description,
      action: action,
    );
  }

  /// 无搜索结果状态
  factory BBXEmptyState.noResults({
    String title = '无搜索结果',
    String description = '试试其他关键词',
    Widget? action,
  }) {
    return BBXEmptyState(
      icon: Icons.search_off,
      title: title,
      description: description,
      action: action,
    );
  }

  /// 错误状态
  factory BBXEmptyState.error({
    String title = '出错了',
    String description = '请稍后重试',
    Widget? action,
  }) {
    return BBXEmptyState(
      icon: Icons.error_outline,
      title: title,
      description: description,
      action: action,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 80,
              color: AppTheme.neutral400,
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              title,
              style: AppTheme.heading3.copyWith(
                color: AppTheme.neutral600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              description,
              style: AppTheme.body2.copyWith(
                color: AppTheme.neutral500,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: AppTheme.spacing24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
