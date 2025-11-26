import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BBXStatusChip extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final bool isSmall;

  const BBXStatusChip({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.isSmall = false,
  });

    factory BBXStatusChip.status(String status, {bool isSmall = false}) {
    Color bgColor;
    Color txtColor;
    String label;

    switch (status.toLowerCase()) {
      case 'pending':
        bgColor = AppTheme.warning.withOpacity(0.1);
        txtColor = AppTheme.warning;
        label = 'WaitPlace?;
        break;
      case 'confirmed':
        bgColor = AppTheme.info.withOpacity(0.1);
        txtColor = AppTheme.info;
        label = 'AlreadySure?;
        break;
      case 'paid':
        bgColor = AppTheme.success.withOpacity(0.1);
        txtColor = AppTheme.success;
        label = 'AlreadyBranch?;
        break;
      case 'in_transit':
        bgColor = AppTheme.accent.withOpacity(0.1);
        txtColor = AppTheme.accent;
        label = 'LuckLose?;
        break;
      case 'completed':
        bgColor = AppTheme.success.withOpacity(0.1);
        txtColor = AppTheme.success;
        label = 'AlreadyDone?;
        break;
      case 'cancelled':
        bgColor = AppTheme.error.withOpacity(0.1);
        txtColor = AppTheme.error;
        label = 'AlreadyTake?;
        break;
      case 'negotiating':
        bgColor = AppTheme.info.withOpacity(0.1);
        txtColor = AppTheme.info;
        label = 'DiscussPrice?;
        break;
      case 'accepted':
        bgColor = AppTheme.success.withOpacity(0.1);
        txtColor = AppTheme.success;
        label = 'AlreadyConnect?;
        break;
      case 'rejected':
        bgColor = AppTheme.error.withOpacity(0.1);
        txtColor = AppTheme.error;
        label = 'AlreadyRefuse?;
        break;
      case 'expired':
        bgColor = AppTheme.neutral400.withOpacity(0.1);
        txtColor = AppTheme.neutral600;
        label = 'AlreadyPass?;
        break;
      default:
        bgColor = AppTheme.neutral300;
        txtColor = AppTheme.neutral700;
        label = status;
    }

    return BBXStatusChip(
      label: label,
      backgroundColor: bgColor,
      textColor: txtColor,
      isSmall: isSmall,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? AppTheme.spacing8 : AppTheme.spacing12,
        vertical: isSmall ? AppTheme.spacing4 : AppTheme.spacing4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.neutral200,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: isSmall ? 12 : 14,
              color: textColor ?? AppTheme.textPrimary,
            ),
            SizedBox(width: isSmall ? 4 : 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: isSmall ? 10 : 12,
              fontWeight: AppTheme.semibold,
              color: textColor ?? AppTheme.textPrimary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class BBXCategoryChip extends StatelessWidget {
  final String category;
  final bool isSmall;
  final VoidCallback? onTap;

  const BBXCategoryChip({
    super.key,
    required this.category,
    this.isSmall = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getCategoryColor(category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? AppTheme.spacing8 : AppTheme.spacing12,
          vertical: isSmall ? AppTheme.spacing4 : AppTheme.spacing4,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Text(
          _getCategoryLabel(category),
          style: TextStyle(
            fontSize: isSmall ? 10 : 12,
            fontWeight: AppTheme.medium,
            color: color,
            height: 1.2,
          ),
        ),
      ),
    );
  }

  String _getCategoryLabel(String category) {
    switch (category.toLowerCase()) {
      case 'plastic':
        return 'Plastic';
      case 'metal':
        return 'Metal';
      case 'paper':
        return 'Paper';
      case 'glass':
        return 'Glass';
      case 'electronic':
        return 'Electronic';
      case 'organic':
        return 'HaveMachine';
      case 'construction':
        return 'BuildBuild';
      case 'textile':
        return 'Textile';
      default:
        return 'Other';
    }
  }
}

class BBXFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const BBXFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing16,
          vertical: AppTheme.spacing8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary500 : AppTheme.neutral100,
          borderRadius: AppTheme.borderRadiusLarge,
          border: Border.all(
            color: isSelected ? AppTheme.primary500 : AppTheme.neutral300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppTheme.neutral700,
              ),
              const SizedBox(width: AppTheme.spacing4),
            ],
            Text(
              label,
              style: AppTheme.body2.copyWith(
                color: isSelected ? Colors.white : AppTheme.neutral700,
                fontWeight: isSelected ? AppTheme.semibold : AppTheme.regular,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
