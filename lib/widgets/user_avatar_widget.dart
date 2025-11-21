import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 通用的用户头像组�?
///
/// 支持�?
/// - 网络图片加载（使�?cached_network_image�?
/// - 首字母后备显�?
/// - 加载占位�?
/// - 错误处理
/// - 可自定义大小和背景色
class UserAvatarWidget extends StatelessWidget {
  final String? photoURL;
  final String displayName;
  final double radius;
  final Color? backgroundColor;

  const UserAvatarWidget({
    super.key,
    this.photoURL,
    required this.displayName,
    this.radius = 28,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // 如果有头�?URL，显示网络图�?
    if (photoURL != null && photoURL!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? const Color(0xFF4CAF50),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: photoURL!,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: backgroundColor ?? const Color(0xFF4CAF50),
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
            errorWidget: (context, url, error) => _buildInitialsAvatar(),
          ),
        ),
      );
    }

    // 否则显示首字�?
    return _buildInitialsAvatar();
  }

  Widget _buildInitialsAvatar() {
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
    final fontSize = radius * 0.8;

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? const Color(0xFF4CAF50),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
