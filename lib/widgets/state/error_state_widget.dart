import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// ErrorStatusShowComponents
/// UseAtShowFriendGood of ErrorInfoandLiftSupplyRetryOptions
class ErrorStateWidget extends StatelessWidget {
  /// ErrorTitle
  final String title;

  /// ErrorDetailedDescription
  final String message;

  /// RetryReturnTune
  final VoidCallback? onRetry;

  /// BackReturnTune
  final VoidCallback? onBack;

  /// CustomIcon
  final IconData? icon;

  /// IconColor
  final Color? iconColor;

  const ErrorStateWidget({
    super.key,
    this.title = 'Load Failed',
    this.message = 'Please check network and try again',
    this.onRetry,
    this.onBack,
    this.icon,
    this.iconColor,
  });

  /// NetworkErrorPreSet
  factory ErrorStateWidget.network({
    VoidCallback? onRetry,
    VoidCallback? onBack,
  }) {
    return ErrorStateWidget(
      title: 'Network Connection Failed',
      message: 'Please check your network connection',
      icon: Icons.wifi_off_rounded,
      onRetry: onRetry,
      onBack: onBack,
    );
  }

  /// Data not foundPreSet
  factory ErrorStateWidget.notFound({
    String title = 'Content Not Found',
    String message = 'Content may have been deleted',
    VoidCallback? onBack,
  }) {
    return ErrorStateWidget(
      title: title,
      message: message,
      icon: Icons.search_off_rounded,
      iconColor: AppTheme.neutral500,
      onBack: onBack,
    );
  }

  /// Server ErrorPreSet
  factory ErrorStateWidget.serverError({
    VoidCallback? onRetry,
    VoidCallback? onBack,
  }) {
    return ErrorStateWidget(
      title: 'Server Error',
      message: 'Server temporarily unavailable, please try again later',
      icon: Icons.error_outline_rounded,
      onRetry: onRetry,
      onBack: onBack,
    );
  }

  /// PermissionErrorPreSet
  factory ErrorStateWidget.permissionDenied({
    String message = 'You do not have permission to access this content',
    VoidCallback? onBack,
  }) {
    return ErrorStateWidget(
      title: 'No Access Permission',
      message: message,
      icon: Icons.lock_outline_rounded,
      iconColor: AppTheme.warning,
      onBack: onBack,
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
            // ErrorIcon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: (iconColor ?? AppTheme.error).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.error_outline_rounded,
                size: 64,
                color: iconColor ?? AppTheme.error,
              ),
            ),

            const SizedBox(height: 24),

            // ErrorTitle
            Text(
              title,
              style: AppTheme.heading2.copyWith(
                color: AppTheme.neutral900,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // ErrorDescription
            Text(
              message,
              style: AppTheme.body2.copyWith(
                color: AppTheme.neutral600,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 32),

            // ActionPressButton
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // BackPressButton
                if (onBack != null) ...[
                  OutlinedButton.icon(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Back'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.neutral700,
                      side: BorderSide(color: AppTheme.neutral300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  if (onRetry != null) const SizedBox(width: 12),
                ],

                // RetryPressButton
                if (onRetry != null)
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary500,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      elevation: 0,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
