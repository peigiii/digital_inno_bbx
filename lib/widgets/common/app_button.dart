import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// 主按钮 - 绿色填充
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double? height;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null && !isLoading;

    return SizedBox(
      width: width,
      height: height ?? AppTheme.buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDisabled ? AppTheme.textDisabled : AppTheme.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppTheme.textDisabled,
          disabledForegroundColor: Colors.white70,
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.borderRadiusStandard,
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : icon != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 20),
                      const SizedBox(width: AppTheme.spacingSM),
                      Text(text, style: AppTheme.button),
                    ],
                  )
                : Text(text, style: AppTheme.button),
      ),
    );
  }
}

/// 次按钮 - 白色带边框
class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double? height;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null && !isLoading;

    return SizedBox(
      width: width,
      height: height ?? AppTheme.buttonHeight,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: isDisabled ? AppTheme.textDisabled : AppTheme.primary,
          disabledForegroundColor: AppTheme.textDisabled,
          side: BorderSide(
            color: isDisabled ? AppTheme.textDisabled : AppTheme.primary,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.borderRadiusStandard,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              )
            : icon != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 20),
                      const SizedBox(width: AppTheme.spacingSM),
                      Text(text, style: AppTheme.button),
                    ],
                  )
                : Text(text, style: AppTheme.button),
      ),
    );
  }
}

/// 文字按钮
class AppTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? textColor;
  final double? fontSize;

  const AppTextButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.textColor,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final color = textColor ?? AppTheme.accent;

    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        disabledForegroundColor: AppTheme.textDisabled,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMD,
          vertical: AppTheme.spacingSM,
        ),
      ),
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            )
          : icon != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: fontSize ?? 16),
                    const SizedBox(width: AppTheme.spacingXS),
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: fontSize ?? 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : Text(
                  text,
                  style: TextStyle(
                    fontSize: fontSize ?? 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
    );
  }
}

/// 图标按钮
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? backgroundColor;
  final double? size;
  final String? tooltip;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.backgroundColor,
    this.size,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      color: color ?? AppTheme.textPrimary,
      iconSize: size ?? AppTheme.iconSizeMedium,
      style: backgroundColor != null
          ? IconButton.styleFrom(
              backgroundColor: backgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: AppTheme.borderRadiusStandard,
              ),
            )
          : null,
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}

/// 危险按钮（删除等操作）
class DangerButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double? height;

  const DangerButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height ?? AppTheme.buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.error,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppTheme.textDisabled,
          disabledForegroundColor: Colors.white70,
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.borderRadiusStandard,
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : icon != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 20),
                      const SizedBox(width: AppTheme.spacingSM),
                      Text(text, style: AppTheme.button),
                    ],
                  )
                : Text(text, style: AppTheme.button),
      ),
    );
  }
}

/// 小按钮（适用于表格等紧凑场景）
class SmallButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final bool outlined;

  const SmallButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.color,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? AppTheme.primary;

    final child = icon != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14),
              const SizedBox(width: 4),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          )
        : Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          );

    if (outlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: buttonColor,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: const Size(0, 32),
          side: BorderSide(color: buttonColor),
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.borderRadiusSmall,
          ),
        ),
        child: child,
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: const Size(0, 32),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.borderRadiusSmall,
        ),
      ),
      child: child,
    );
  }
}
