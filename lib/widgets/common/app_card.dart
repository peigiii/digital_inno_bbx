import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// 统一卡片容器
/// 提供标准的圆角、阴影、内边距
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final VoidCallback? onTap;
  final List<BoxShadow>? shadows;
  final BorderRadius? borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.onTap,
    this.shadows,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      padding: padding ?? const EdgeInsets.all(AppTheme.cardPadding),
      decoration: BoxDecoration(
        color: color ?? AppTheme.surface,
        borderRadius: borderRadius ?? AppTheme.borderRadiusLarge,
        boxShadow: shadows ?? AppTheme.shadowMedium,
      ),
      child: child,
    );

    if (onTap != null) {
      return Padding(
        padding: margin ?? const EdgeInsets.all(AppTheme.cardSpacing),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius ?? AppTheme.borderRadiusLarge,
            child: cardContent,
          ),
        ),
      );
    }

    return Padding(
      padding: margin ?? const EdgeInsets.all(AppTheme.cardSpacing),
      child: cardContent,
    );
  }
}

/// 带标题的卡片
class TitledCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const TitledCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: padding,
      margin: margin,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTheme.h4,
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppTheme.spacingMD),
          child,
        ],
      ),
    );
  }
}

/// 信息卡片（用于提示、警告等�?
class InfoCard extends StatelessWidget {
  final String message;
  final InfoCardType type;
  final IconData? icon;
  final Widget? action;
  final VoidCallback? onClose;

  const InfoCard({
    super.key,
    required this.message,
    this.type = InfoCardType.info,
    this.icon,
    this.action,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color iconColor;
    IconData defaultIcon;

    switch (type) {
      case InfoCardType.success:
        backgroundColor = AppTheme.success.withOpacity(0.1);
        iconColor = AppTheme.success;
        defaultIcon = Icons.check_circle_outline;
        break;
      case InfoCardType.warning:
        backgroundColor = AppTheme.warning.withOpacity(0.1);
        iconColor = AppTheme.warning;
        defaultIcon = Icons.warning_amber_outlined;
        break;
      case InfoCardType.error:
        backgroundColor = AppTheme.error.withOpacity(0.1);
        iconColor = AppTheme.error;
        defaultIcon = Icons.error_outline;
        break;
      case InfoCardType.info:
      default:
        backgroundColor = AppTheme.info.withOpacity(0.1);
        iconColor = AppTheme.info;
        defaultIcon = Icons.info_outline;
        break;
    }

    return AppCard(
      color: backgroundColor,
      shadows: const [],
      child: Row(
        children: [
          Icon(
            icon ?? defaultIcon,
            color: iconColor,
            size: 24,
          ),
          const SizedBox(width: AppTheme.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: AppTheme.body2.copyWith(color: AppTheme.textPrimary),
                ),
                if (action != null) ...[
                  const SizedBox(height: AppTheme.spacingSM),
                  action!,
                ],
              ],
            ),
          ),
          if (onClose != null) ...[
            const SizedBox(width: AppTheme.spacingSM),
            IconButton(
              icon: const Icon(Icons.close),
              iconSize: 20,
              color: AppTheme.textSecondary,
              onPressed: onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }
}

enum InfoCardType {
  info,
  success,
  warning,
  error,
}

/// 统计卡片（用于展示数字指标）
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final String? subtitle;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingSM),
                  decoration: BoxDecoration(
                    color: (iconColor ?? AppTheme.primary).withOpacity(0.1),
                    borderRadius: AppTheme.borderRadiusStandard,
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: iconColor ?? AppTheme.primary,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMD),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTheme.caption,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: AppTheme.h2,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppTheme.spacingSM),
            Text(
              subtitle!,
              style: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

/// 列表项卡片（适用于列表中的项目）
class ListItemCard extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const ListItemCard({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMD,
        vertical: AppTheme.spacingSM,
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: AppTheme.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.subtitle1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: AppTheme.body2.copyWith(color: AppTheme.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppTheme.spacingMD),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// 空状态卡�?
class EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  const EmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: AppTheme.spacingMD),
            Text(
              title,
              style: AppTheme.h4.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: AppTheme.spacingSM),
              Text(
                message!,
                style: AppTheme.body2.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppTheme.spacingLG),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
