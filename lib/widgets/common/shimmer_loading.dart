import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/app_theme.dart';

class ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.dividerLight,
      highlightColor: AppTheme.surface,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppTheme.dividerLight,
          borderRadius: borderRadius ?? AppTheme.borderRadiusStandard,
        ),
      ),
    );
  }
}

class ShimmerCircle extends StatelessWidget {
  final double size;

  const ShimmerCircle({
    super.key,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.dividerLight,
      highlightColor: AppTheme.surface,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppTheme.dividerLight,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class ShimmerLine extends StatelessWidget {
  final double? width;
  final double height;

  const ShimmerLine({
    super.key,
    this.width,
    this.height = 16,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerBox(
      width: width,
      height: height,
      borderRadius: const BorderRadius.all(Radius.circular(4)),
    );
  }
}

class ListItemShimmer extends StatelessWidget {
  final bool showAvatar;
  final bool showTrailing;

  const ListItemShimmer({
    super.key,
    this.showAvatar = true,
    this.showTrailing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMD,
        vertical: AppTheme.spacingSM,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.borderRadiusLarge,
        boxShadow: AppTheme.shadowMedium,
      ),
      child: Row(
        children: [
          if (showAvatar) ...[
            const ShimmerCircle(size: 48),
            const SizedBox(width: AppTheme.spacingMD),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLine(
                  width: MediaQuery.of(context).size.width * 0.6,
                  height: 18,
                ),
                const SizedBox(height: 8),
                ShimmerLine(
                  width: MediaQuery.of(context).size.width * 0.4,
                  height: 14,
                ),
              ],
            ),
          ),
          if (showTrailing) ...[
            const SizedBox(width: AppTheme.spacingMD),
            const ShimmerBox(
              width: 60,
              height: 32,
            ),
          ],
        ],
      ),
    );
  }
}

class CardShimmer extends StatelessWidget {
  final double? height;
  final bool showImage;

  const CardShimmer({
    super.key,
    this.height,
    this.showImage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.cardSpacing),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.borderRadiusLarge,
        boxShadow: AppTheme.shadowMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showImage) ...[
            ShimmerBox(
              width: double.infinity,
              height: 180,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusLarge),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(AppTheme.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLine(
                  width: MediaQuery.of(context).size.width * 0.7,
                  height: 20,
                ),
                const SizedBox(height: 12),
                const ShimmerLine(
                  width: double.infinity,
                  height: 14,
                ),
                const SizedBox(height: 8),
                ShimmerLine(
                  width: MediaQuery.of(context).size.width * 0.5,
                  height: 14,
                ),
                if (height != null) SizedBox(height: height! - 100),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProductCardShimmer extends StatelessWidget {
  const ProductCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.cardSpacing),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.borderRadiusLarge,
        boxShadow: AppTheme.shadowMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                    const ShimmerBox(
            width: double.infinity,
            height: 200,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusLarge),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                                const ShimmerLine(
                  width: double.infinity,
                  height: 18,
                ),
                const SizedBox(height: 8),
                                ShimmerLine(
                  width: MediaQuery.of(context).size.width * 0.6,
                  height: 14,
                ),
                const SizedBox(height: 12),
                                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const ShimmerLine(
                      width: 80,
                      height: 20,
                    ),
                    const SizedBox(width: AppTheme.spacingMD),
                    ShimmerBox(
                      width: 100,
                      height: 36,
                      borderRadius: AppTheme.borderRadiusStandard,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TableRowShimmer extends StatelessWidget {
  final int columns;

  const TableRowShimmer({
    super.key,
    this.columns = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMD,
        vertical: AppTheme.spacingSM,
      ),
      child: Row(
        children: List.generate(
          columns,
          (index) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSM),
              child: ShimmerLine(
                height: 16,
                width: double.infinity,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AvatarShimmer extends StatelessWidget {
  final double size;
  final bool showLabel;

  const AvatarShimmer({
    super.key,
    this.size = 48,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ShimmerCircle(size: size),
        if (showLabel) ...[
          const SizedBox(height: 8),
          ShimmerLine(
            width: size * 1.5,
            height: 14,
          ),
        ],
      ],
    );
  }
}

class StatCardShimmer extends StatelessWidget {
  const StatCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      margin: const EdgeInsets.all(AppTheme.cardSpacing),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.borderRadiusLarge,
        boxShadow: AppTheme.shadowMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShimmerBox(
                width: 40,
                height: 40,
                borderRadius: AppTheme.borderRadiusStandard,
              ),
              const SizedBox(width: AppTheme.spacingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ShimmerLine(
                      width: 60,
                      height: 12,
                    ),
                    const SizedBox(height: 8),
                    ShimmerLine(
                      width: MediaQuery.of(context).size.width * 0.3,
                      height: 24,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PageLoadingShimmer extends StatelessWidget {
  final int itemCount;

  const PageLoadingShimmer({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMD),
      itemBuilder: (context, index) => const ListItemShimmer(),
    );
  }
}

class GridLoadingShimmer extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;

  const GridLoadingShimmer({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.75,
        crossAxisSpacing: AppTheme.spacingMD,
        mainAxisSpacing: AppTheme.spacingMD,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => const ProductCardShimmer(),
    );
  }
}
