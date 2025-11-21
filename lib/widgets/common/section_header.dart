import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// 区块标题组件
/// 用于页面中不同区块的标题展示，带可选的"查看更多"链接
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onActionTap;
  final IconData? actionIcon;
  final EdgeInsetsGeometry? padding;
  final bool showDivider;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onActionTap,
    this.actionIcon,
    this.padding,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: padding ??
              const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMD,
                vertical: AppTheme.spacingMD,
              ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 左侧标题
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.h3,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // 右侧操作按钮
              if (actionText != null || actionIcon != null)
                InkWell(
                  onTap: onActionTap,
                  borderRadius: AppTheme.borderRadiusStandard,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingSM,
                      vertical: AppTheme.spacingXS,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (actionText != null)
                          Text(
                            actionText!,
                            style: AppTheme.body2.copyWith(
                              color: AppTheme.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (actionIcon != null) ...[
                          if (actionText != null)
                            const SizedBox(width: 4),
                          Icon(
                            actionIcon,
                            size: 16,
                            color: AppTheme.accent,
                          ),
                        ] else if (actionText != null)
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: AppTheme.accent,
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
          ),
      ],
    );
  }
}

/// 简洁版区块标题（无副标题）
class SimpleSectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onMoreTap;
  final EdgeInsetsGeometry? padding;

  const SimpleSectionHeader({
    super.key,
    required this.title,
    this.onMoreTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return SectionHeader(
      title: title,
      actionText: onMoreTap != null ? '查看更多' : null,
      onActionTap: onMoreTap,
      padding: padding,
    );
  }
}

/// 带图标的区块标题
class IconSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final String? actionText;
  final VoidCallback? onActionTap;
  final EdgeInsetsGeometry? padding;

  const IconSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    this.actionText,
    this.onActionTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMD,
            vertical: AppTheme.spacingMD,
          ),
      child: Row(
        children: [
          // 图标
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

          // 标题
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.h4,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 操作按钮
          if (actionText != null)
            InkWell(
              onTap: onActionTap,
              borderRadius: AppTheme.borderRadiusStandard,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSM,
                  vertical: AppTheme.spacingXS,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionText!,
                      style: AppTheme.body2.copyWith(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppTheme.accent,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 带数量徽章的区块标题
class BadgeSectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final String? actionText;
  final VoidCallback? onActionTap;
  final EdgeInsetsGeometry? padding;

  const BadgeSectionHeader({
    super.key,
    required this.title,
    required this.count,
    this.actionText,
    this.onActionTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMD,
            vertical: AppTheme.spacingMD,
          ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 标题和徽�?
          Row(
            children: [
              Text(
                title,
                style: AppTheme.h3,
              ),
              const SizedBox(width: AppTheme.spacingSM),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSM,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(12),
                  ),
                ),
                child: Text(
                  count.toString(),
                  style: AppTheme.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          // 操作按钮
          if (actionText != null)
            InkWell(
              onTap: onActionTap,
              borderRadius: AppTheme.borderRadiusStandard,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSM,
                  vertical: AppTheme.spacingXS,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionText!,
                      style: AppTheme.body2.copyWith(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppTheme.accent,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 可展开的区块标�?
class ExpandableSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isExpanded;
  final VoidCallback onTap;
  final EdgeInsetsGeometry? padding;

  const ExpandableSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.isExpanded,
    required this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: padding ??
            const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMD,
              vertical: AppTheme.spacingMD,
            ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.h4,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
