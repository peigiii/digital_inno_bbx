import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// BBX 底部导航栏组�?
/// 包含5个Tab：首页、商品列表、发布（凸起）、消息、个人中�?
class BBXBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final int? unreadMessageCount;

  const BBXBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.unreadMessageCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72 + MediaQuery.of(context).padding.bottom,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: AppTheme.elevation8,
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // 常规导航项（左侧2�?+ 右侧2个）
            Row(
              children: [
                // 左侧：首页、商品列�?
                _buildNavItem(
                  icon: Icons.home_rounded,
                  label: '首页',
                  index: 0,
                  isSelected: currentIndex == 0,
                ),
                _buildNavItem(
                  icon: Icons.inventory_2_rounded,
                  label: '商品',
                  index: 1,
                  isSelected: currentIndex == 1,
                ),

                // 中间空位（留给凸起按钮）
                const Spacer(),

                // 右侧：消息、个人中�?
                _buildNavItem(
                  icon: Icons.chat_bubble_rounded,
                  label: '消息',
                  index: 3,
                  isSelected: currentIndex == 3,
                  badge: unreadMessageCount,
                ),
                _buildNavItem(
                  icon: Icons.person_rounded,
                  label: '我的',
                  index: 4,
                  isSelected: currentIndex == 4,
                ),
              ],
            ),

            // 中间凸起的发布按�?
            Positioned(
              left: MediaQuery.of(context).size.width / 2 - 32,
              top: -8, // 向上凸起8px
              child: _buildCenterButton(),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建常规导航�?
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
    int? badge,
  }) {
    final color = isSelected ? AppTheme.primary500 : AppTheme.neutral600;

    return Expanded(
      child: Material(
        color: Colors.transparent,
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
                    size: 24,
                    color: color,
                  ),
                  // 未读消息角标
                  if (badge != null && badge > 0)
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
                          badge > 99 ? '99+' : badge.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
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
                  fontSize: 11,
                  color: color,
                  fontWeight: isSelected ? AppTheme.semibold : AppTheme.regular,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建中间凸起的发布按�?
  Widget _buildCenterButton() {
    final isSelected = currentIndex == 2;

    return GestureDetector(
      onTap: () => onTap(2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: AppTheme.elevation4,
            ),
            child: const Icon(
              Icons.add_circle_rounded,
              size: 28,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '发布',
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? AppTheme.primary500 : AppTheme.neutral600,
              fontWeight: isSelected ? AppTheme.semibold : AppTheme.regular,
            ),
          ),
        ],
      ),
    );
  }
}
