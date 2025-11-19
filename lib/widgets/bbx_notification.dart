import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// BBX 应用内通知组件
class BBXNotification {
  /// 显示成功通知
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      backgroundColor: AppTheme.success.withOpacity(0.1),
      borderColor: AppTheme.success,
      icon: Icons.check_circle_rounded,
      iconColor: AppTheme.success,
      duration: duration,
    );
  }

  /// 显示错误通知
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 5),
  }) {
    _show(
      context,
      message: message,
      backgroundColor: AppTheme.error.withOpacity(0.1),
      borderColor: AppTheme.error,
      icon: Icons.error_rounded,
      iconColor: AppTheme.error,
      duration: duration,
    );
  }

  /// 显示信息通知
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      backgroundColor: AppTheme.info.withOpacity(0.1),
      borderColor: AppTheme.info,
      icon: Icons.info_rounded,
      iconColor: AppTheme.info,
      duration: duration,
    );
  }

  /// 显示警告通知
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    _show(
      context,
      message: message,
      backgroundColor: AppTheme.warning.withOpacity(0.1),
      borderColor: AppTheme.warning,
      icon: Icons.warning_rounded,
      iconColor: AppTheme.warning,
      duration: duration,
    );
  }

  /// 通用显示方法
  static void _show(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required Color borderColor,
    required IconData icon,
    required Color iconColor,
    required Duration duration,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _BBXNotificationWidget(
        message: message,
        backgroundColor: backgroundColor,
        borderColor: borderColor,
        icon: icon,
        iconColor: iconColor,
        onDismiss: () => overlayEntry.remove(),
      ),
    );

    overlay.insert(overlayEntry);

    // 自动移除
    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}

/// 通知 Widget
class _BBXNotificationWidget extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final Color borderColor;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onDismiss;

  const _BBXNotificationWidget({
    required this.message,
    required this.backgroundColor,
    required this.borderColor,
    required this.icon,
    required this.iconColor,
    required this.onDismiss,
  });

  @override
  State<_BBXNotificationWidget> createState() => _BBXNotificationWidgetState();
}

class _BBXNotificationWidgetState extends State<_BBXNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: AppTheme.borderRadiusLarge,
                border: Border(
                  left: BorderSide(
                    color: widget.borderColor,
                    width: 4,
                  ),
                ),
                boxShadow: AppTheme.elevation4,
              ),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    color: widget.iconColor,
                    size: AppTheme.iconSizeMedium,
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: AppTheme.body2.copyWith(
                        color: AppTheme.neutral900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      _controller.reverse().then((_) => widget.onDismiss());
                    },
                    icon: const Icon(Icons.close_rounded),
                    color: AppTheme.neutral600,
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// SnackBar 样式的通知（备选方案）
class BBXSnackBar {
  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    Color? backgroundColor,
    IconData? icon,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white),
              const SizedBox(width: AppTheme.spacing12),
            ],
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        backgroundColor: backgroundColor ?? AppTheme.primary500,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.borderRadiusLarge,
        ),
        duration: duration,
      ),
    );
  }
}
