import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// 错误状态显示组件
/// 用于显示友好的错误信息和提供重试选项
class ErrorStateWidget extends StatelessWidget {
  /// 错误标题
  final String title;

  /// 错误详细说明
  final String message;

  /// 重试回调
  final VoidCallback? onRetry;

  /// 返回回调
  final VoidCallback? onBack;

  /// 自定义图标
  final IconData? icon;

  /// 图标颜色
  final Color? iconColor;

  const ErrorStateWidget({
    super.key,
    this.title = '加载失败',
    this.message = '请检查网络连接后重试',
    this.onRetry,
    this.onBack,
    this.icon,
    this.iconColor,
  });

  /// 网络错误预设
  factory ErrorStateWidget.network({
    VoidCallback? onRetry,
    VoidCallback? onBack,
  }) {
    return ErrorStateWidget(
      title: '网络连接失败',
      message: '请检查您的网络连接',
      icon: Icons.wifi_off_rounded,
      onRetry: onRetry,
      onBack: onBack,
    );
  }

  /// 数据不存在预设
  factory ErrorStateWidget.notFound({
    String title = '内容不存在',
    String message = '该内容可能已被删除',
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

  /// 服务器错误预设
  factory ErrorStateWidget.serverError({
    VoidCallback? onRetry,
    VoidCallback? onBack,
  }) {
    return ErrorStateWidget(
      title: '服务器错误',
      message: '服务器暂时无法响应，请稍后重试',
      icon: Icons.error_outline_rounded,
      onRetry: onRetry,
      onBack: onBack,
    );
  }

  /// 权限错误预设
  factory ErrorStateWidget.permissionDenied({
    String message = '您没有访问此内容的权限',
    VoidCallback? onBack,
  }) {
    return ErrorStateWidget(
      title: '无访问权限',
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
            // 错误图标
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

            // 错误标题
            Text(
              title,
              style: AppTheme.heading2.copyWith(
                color: AppTheme.neutral900,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // 错误说明
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

            // 操作按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 返回按钮
                if (onBack != null) ...[
                  OutlinedButton.icon(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('返回'),
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

                // 重试按钮
                if (onRetry != null)
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('重试'),
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
