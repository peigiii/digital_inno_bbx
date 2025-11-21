import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

///
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
