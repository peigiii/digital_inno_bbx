import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// BBX 全屏加载组件
class BBXFullScreenLoading extends StatelessWidget {
  final String? message;

  const BBXFullScreenLoading({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary500),
            ),
            if (message != null) ...[
              const SizedBox(height: AppTheme.spacing16),
              Text(
                message!,
                style: AppTheme.body2.copyWith(
                  color: AppTheme.neutral600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// BBX 列表加载组件（骨架屏）
class BBXListLoading extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const BBXListLoading({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 120,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Container(
          height: itemHeight,
          margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppTheme.borderRadiusMedium,
          ),
          child: const _ShimmerLoading(),
        );
      },
    );
  }
}

/// BBX 卡片加载组件
class BBXCardLoading extends StatelessWidget {
  final double? width;
  final double? height;

  const BBXCardLoading({
    super.key,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height ?? 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.borderRadiusMedium,
      ),
      child: const _ShimmerLoading(),
    );
  }
}

/// BBX 按钮加载组件
class BBXButtonLoading extends StatelessWidget {
  final double? width;
  final double? height;

  const BBXButtonLoading({
    super.key,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height ?? AppTheme.buttonHeight,
      decoration: BoxDecoration(
        borderRadius: AppTheme.borderRadiusLarge,
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }
}

/// Shimmer 加载动画组件
class _ShimmerLoading extends StatefulWidget {
  const _ShimmerLoading();

  @override
  State<_ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<_ShimmerLoading>
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
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine,
      ),
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
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(_animation.value, 0),
              end: const Alignment(2, 0),
              colors: const [
                AppTheme.neutral100,
                AppTheme.neutral200,
                AppTheme.neutral100,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}
