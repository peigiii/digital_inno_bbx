import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// 空状态显示组件
/// 用于显示友好的空数据提示和引导用户操作
class EmptyStateWidget extends StatelessWidget {
  /// 显示图标
  final IconData icon;

  /// 标题
  final String title;

  /// 说明文字
  final String message;

  /// 操作按钮文字
  final String? actionLabel;

  /// 操作按钮回调
  final VoidCallback? onAction;

  /// 次要操作文字
  final String? secondaryActionLabel;

  /// 次要操作回调
  final VoidCallback? onSecondaryAction;

  /// 图标颜色
  final Color? iconColor;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.iconColor,
  });

  /// 空商品列表预设
  factory EmptyStateWidget.noListings({
    VoidCallback? onCreateListing,
    VoidCallback? onBrowseAll,
  }) {
    return EmptyStateWidget(
      icon: Icons.inventory_2_outlined,
      title: '还没有商品',
      message: '发布您的第一个商品，开始交易吧',
      actionLabel: '发布商品',
      onAction: onCreateListing,
      secondaryActionLabel: '浏览全部',
      onSecondaryAction: onBrowseAll,
    );
  }

  /// 空收藏列表预设
  factory EmptyStateWidget.noFavorites({
    VoidCallback? onBrowse,
  }) {
    return EmptyStateWidget(
      icon: Icons.favorite_border_rounded,
      title: '还没有收藏',
      message: '收藏您喜欢的商品，方便下次查看',
      iconColor: AppTheme.error,
      actionLabel: '去逛逛',
      onAction: onBrowse,
    );
  }

  /// 空交易列表预设
  factory EmptyStateWidget.noTransactions({
    VoidCallback? onBrowse,
  }) {
    return EmptyStateWidget(
      icon: Icons.receipt_long_outlined,
      title: '还没有交易',
      message: '您的交易记录会显示在这里',
      actionLabel: '去购物',
      onAction: onBrowse,
    );
  }

  /// 空报价列表预设
  factory EmptyStateWidget.noOffers({
    VoidCallback? onBrowse,
  }) {
    return EmptyStateWidget(
      icon: Icons.local_offer_outlined,
      title: '还没有报价',
      message: '浏览商品并提交您的报价',
      actionLabel: '浏览商品',
      onAction: onBrowse,
    );
  }

  /// 空消息列表预设
  factory EmptyStateWidget.noMessages() {
    return EmptyStateWidget(
      icon: Icons.chat_bubble_outline_rounded,
      title: '还没有对话',
      message: '与卖家沟通的消息会显示在这里',
      iconColor: AppTheme.primary500,
    );
  }

  /// 搜索无结果预设
  factory EmptyStateWidget.noSearchResults({
    String? searchTerm,
    VoidCallback? onClearSearch,
  }) {
    return EmptyStateWidget(
      icon: Icons.search_off_rounded,
      title: '未找到相关商品',
      message: searchTerm != null
          ? '没有找到"$searchTerm"的相关结果'
          : '尝试使用其他关键词搜索',
      actionLabel: '清除搜索',
      onAction: onClearSearch,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 空状态图标
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (iconColor ?? AppTheme.neutral400).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 80,
                color: iconColor ?? AppTheme.neutral400,
              ),
            ),

            const SizedBox(height: 24),

            // 标题
            Text(
              title,
              style: AppTheme.heading2.copyWith(
                color: AppTheme.neutral900,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // 说明
            Text(
              message,
              style: AppTheme.body2.copyWith(
                color: AppTheme.neutral600,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            // 操作按钮
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary500,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  ),
                ),
              ),
            ],

            // 次要操作按钮
            if (secondaryActionLabel != null && onSecondaryAction != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onSecondaryAction,
                child: Text(secondaryActionLabel!),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primary500,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
