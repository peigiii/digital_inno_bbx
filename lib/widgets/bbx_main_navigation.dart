import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BBXMainNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final int unreadMessages;

  const BBXMainNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.unreadMessages = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppTheme.bottomNavHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: AppTheme.shadowMedium,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _buildNavItem(
              context,
              index: 0,
              icon: Icons.home_rounded,
              label: '首页',
            ),
            _buildNavItem(
              context,
              index: 1,
              icon: Icons.category_rounded,
              label: '分类',
            ),
            const Spacer(),
            _buildNavItem(
              context,
              index: 3,
              icon: Icons.chat_bubble_rounded,
              label: '消息',
              badge: unreadMessages > 0 ? unreadMessages.toString() : null,
            ),
            _buildNavItem(
              context,
              index: 4,
              icon: Icons.person_rounded,
              label: '我的',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
    String? badge,
  }) {
    final isSelected = currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppTheme.primary500 : AppTheme.neutral500,
                  size: AppTheme.iconSizeMedium,
                ),
                if (badge != null)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: AppTheme.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: AppTheme.captionSize,
                fontWeight: isSelected ? AppTheme.semibold : AppTheme.regular,
                color: isSelected ? AppTheme.primary500 : AppTheme.neutral500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BBXFloatingPostButton extends StatelessWidget {
  final VoidCallback onPressed;

  const BBXFloatingPostButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      left: MediaQuery.of(context).size.width / 2 - 28,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: AppTheme.elevation4,
          ),
          child: const Icon(
            Icons.add_circle_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }
}
