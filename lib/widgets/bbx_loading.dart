import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 加载状态组件
class BBXLoading extends StatelessWidget {
  final String? message;
  final bool showMessage;
  final Color? color;

  const BBXLoading({
    super.key,
    this.message,
    this.showMessage = false,
    this.color,
  });

  /// 全屏加载
  factory BBXLoading.fullScreen({String? message}) {
    return BBXLoading(
      message: message,
      showMessage: message != null,
    );
  }

  /// 小型加载指示器
  factory BBXLoading.small({Color? color}) {
    return BBXLoading(
      showMessage: false,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? AppTheme.primary500,
              ),
            ),
          ),
          if (showMessage && message != null) ...[
            const SizedBox(height: AppTheme.spacing16),
            Text(
              message!,
              style: AppTheme.body2.copyWith(
                color: AppTheme.neutral600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// 列表加载组件（骨架屏）
class BBXListLoading extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsetsGeometry? padding;

  const BBXListLoading({
    super.key,
    required this.itemCount,
    this.itemHeight = 120,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding ?? const EdgeInsets.all(AppTheme.spacing16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
          child: BBXShimmerLoading(
            width: double.infinity,
            height: itemHeight,
            borderRadius: AppTheme.borderRadiusMedium,
          ),
        );
      },
    );
  }
}

/// Shimmer 加载效果（用于列表骨架屏）
class BBXShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const BBXShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<BBXShimmerLoading> createState() => _BBXShimmerLoadingState();
}

class _BBXShimmerLoadingState extends State<BBXShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppTheme.neutral200,
                AppTheme.neutral100,
                AppTheme.neutral200,
              ],
              stops: [
                0.0,
                _animation.value / 2 + 0.5,
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }
}
