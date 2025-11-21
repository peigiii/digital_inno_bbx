import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// BBX 空状态组�?
class BBXEmptyState extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? description;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final Widget? customWidget;

  const BBXEmptyState({
    super.key,
    this.icon,
    required this.title,
    this.description,
    this.buttonText,
    this.onButtonPressed,
    this.customWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 自定义组件或图标
            if (customWidget != null)
              customWidget!
            else if (icon != null)
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.neutral100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 64,
                  color: AppTheme.neutral400,
                ),
              ),

            const SizedBox(height: AppTheme.spacing24),

            // 标题
            Text(
              title,
              style: AppTheme.heading3.copyWith(
                color: AppTheme.neutral700,
              ),
              textAlign: TextAlign.center,
            ),

            // 描述
            if (description != null) ...[
              const SizedBox(height: AppTheme.spacing12),
              Text(
                description!,
                style: AppTheme.body2.copyWith(
                  color: AppTheme.neutral500,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // 按钮
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: AppTheme.spacing32),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: onButtonPressed,
                  child: Text(buttonText!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 创建"无数�?空状�?
  factory BBXEmptyState.noData({
    String? title,
    String? description,
    String? buttonText,
    VoidCallback? onButtonPressed,
  }) {
    return BBXEmptyState(
      icon: Icons.inbox_rounded,
      title: title ?? '暂无数据',
      description: description,
      buttonText: buttonText,
      onButtonPressed: onButtonPressed,
    );
  }

  /// 创建"无搜索结�?空状�?
  factory BBXEmptyState.noSearchResults({
    String? title,
    String? description,
    String? buttonText,
    VoidCallback? onButtonPressed,
  }) {
    return BBXEmptyState(
      icon: Icons.search_off_rounded,
      title: title ?? '未找到相关内�?,
      description: description ?? '试试其他关键�?,
      buttonText: buttonText,
      onButtonPressed: onButtonPressed,
    );
  }

  /// 创建"无收�?空状�?
  factory BBXEmptyState.noFavorites({
    String? title,
    String? description,
    String? buttonText,
    VoidCallback? onButtonPressed,
  }) {
    return BBXEmptyState(
      icon: Icons.favorite_border_rounded,
      title: title ?? '还没有收�?,
      description: description ?? '收藏你喜欢的商品',
      buttonText: buttonText ?? '去逛�?,
      onButtonPressed: onButtonPressed,
    );
  }

  /// 创建"无消�?空状�?
  factory BBXEmptyState.noMessages({
    String? title,
    String? description,
  }) {
    return BBXEmptyState(
      icon: Icons.chat_bubble_outline_rounded,
      title: title ?? '收件箱空�?,
      description: description ?? '开始与卖家沟通吧',
    );
  }

  /// 创建"无交�?空状�?
  factory BBXEmptyState.noTransactions({
    String? title,
    String? description,
    String? buttonText,
    VoidCallback? onButtonPressed,
  }) {
    return BBXEmptyState(
      icon: Icons.receipt_long_outlined,
      title: title ?? '暂无交易记录',
      description: description,
      buttonText: buttonText ?? '去逛�?,
      onButtonPressed: onButtonPressed,
    );
  }
}
