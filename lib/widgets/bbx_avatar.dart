import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// BBX 头像组件
class BBXAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final bool showBorder;
  final Color? borderColor;
  final VoidCallback? onTap;

  const BBXAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = AppTheme.avatarSizeMedium,
    this.showBorder = false,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: borderColor ?? AppTheme.primary500,
                width: 2,
              )
            : null,
        color: AppTheme.neutral200,
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildPlaceholder(),
              )
            : _buildPlaceholder(),
      ),
    );

    if (onTap != null) {
      avatar = GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _buildPlaceholder() {
    String initials = '';
    if (name != null && name!.isNotEmpty) {
      final words = name!.trim().split(' ');
      initials = words.length > 1
          ? '${words[0][0]}${words[1][0]}'.toUpperCase()
          : name![0].toUpperCase();
    }

    return Container(
      color: AppTheme.neutral300,
      child: Center(
        child: initials.isNotEmpty
            ? Text(
                initials,
                style: TextStyle(
                  color: AppTheme.neutral700,
                  fontSize: size * 0.4,
                  fontWeight: AppTheme.semibold,
                ),
              )
            : Icon(
                Icons.person_rounded,
                color: AppTheme.neutral500,
                size: size * 0.6,
              ),
      ),
    );
  }
}

/// BBX 带角标的头像组件
class BBXAvatarWithBadge extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final String? badgeText;
  final Color? badgeColor;
  final IconData? badgeIcon;
  final VoidCallback? onTap;

  const BBXAvatarWithBadge({
    super.key,
    this.imageUrl,
    this.name,
    this.size = AppTheme.avatarSizeMedium,
    this.badgeText,
    this.badgeColor,
    this.badgeIcon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        BBXAvatar(
          imageUrl: imageUrl,
          name: name,
          size: size,
          onTap: onTap,
        ),
        if (badgeText != null || badgeIcon != null)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: badgeColor ?? AppTheme.error,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              constraints: BoxConstraints(
                minWidth: size * 0.3,
                minHeight: size * 0.3,
              ),
              child: badgeIcon != null
                  ? Icon(
                      badgeIcon,
                      color: Colors.white,
                      size: size * 0.2,
                    )
                  : badgeText != null
                      ? Text(
                          badgeText!,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: size * 0.15,
                            fontWeight: AppTheme.bold,
                          ),
                          textAlign: TextAlign.center,
                        )
                      : null,
            ),
          ),
      ],
    );
  }
}

/// BBX 在线状态头像组�?
class BBXAvatarOnline extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final bool isOnline;
  final VoidCallback? onTap;

  const BBXAvatarOnline({
    super.key,
    this.imageUrl,
    this.name,
    this.size = AppTheme.avatarSizeMedium,
    required this.isOnline,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        BBXAvatar(
          imageUrl: imageUrl,
          name: name,
          size: size,
          onTap: onTap,
        ),
        Positioned(
          right: size * 0.05,
          bottom: size * 0.05,
          child: Container(
            width: size * 0.25,
            height: size * 0.25,
            decoration: BoxDecoration(
              color: isOnline ? AppTheme.success : AppTheme.neutral400,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// BBX 认证头像组件
class BBXAvatarVerified extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final bool isVerified;
  final VoidCallback? onTap;

  const BBXAvatarVerified({
    super.key,
    this.imageUrl,
    this.name,
    this.size = AppTheme.avatarSizeMedium,
    required this.isVerified,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVerified) {
      return BBXAvatar(
        imageUrl: imageUrl,
        name: name,
        size: size,
        onTap: onTap,
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        BBXAvatar(
          imageUrl: imageUrl,
          name: name,
          size: size,
          onTap: onTap,
        ),
        Positioned(
          right: size * 0.02,
          bottom: size * 0.02,
          child: Container(
            padding: EdgeInsets.all(size * 0.05),
            decoration: const BoxDecoration(
              color: AppTheme.accent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: size * 0.2,
            ),
          ),
        ),
      ],
    );
  }
}
