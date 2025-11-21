import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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

                        Text(
              title,
              style: AppTheme.heading3.copyWith(
                color: AppTheme.neutral700,
              ),
              textAlign: TextAlign.center,
            ),

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

    factory BBXEmptyState.noData({
    String? title,
    String? description,
    String? buttonText,
    VoidCallback? onButtonPressed,
  }) {
    return BBXEmptyState(
      icon: Icons.inbox_rounded,
      title: title ?? 'No data',
      description: description,
      buttonText: buttonText,
      onButtonPressed: onButtonPressed,
    );
  }

    factory BBXEmptyState.noSearchResults({
    String? title,
    String? description,
    String? buttonText,
    VoidCallback? onButtonPressed,
  }) {
    return BBXEmptyState(
      icon: Icons.search_off_rounded,
      title: title ?? 'No results found',
      description: description ?? 'Try other keywords',
      buttonText: buttonText,
      onButtonPressed: onButtonPressed,
    );
  }

    factory BBXEmptyState.noFavorites({
    String? title,
    String? description,
    String? buttonText,
    VoidCallback? onButtonPressed,
  }) {
    return BBXEmptyState(
      icon: Icons.favorite_border_rounded,
      title: title ?? 'No favorites yet',
      description: description ?? 'Favorite items you like',
      buttonText: buttonText ?? 'Browse',
      onButtonPressed: onButtonPressed,
    );
  }

    factory BBXEmptyState.noMessages({
    String? title,
    String? description,
  }) {
    return BBXEmptyState(
      icon: Icons.chat_bubble_outline_rounded,
      title: title ?? 'Inbox empty',
      description: description ?? 'Start chatting with seller',
    );
  }

    factory BBXEmptyState.noTransactions({
    String? title,
    String? description,
    String? buttonText,
    VoidCallback? onButtonPressed,
  }) {
    return BBXEmptyState(
      icon: Icons.receipt_long_outlined,
      title: title ?? 'No transactions yet',
      description: description,
      buttonText: buttonText ?? 'Browse',
      onButtonPressed: onButtonPressed,
    );
  }
}
