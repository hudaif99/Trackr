import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';

/// A shimmer skeleton placeholder that mimics the shape of its child.
class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceVariant,
      highlightColor: AppColors.border,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// A skeleton that fills available width at the given height.
class SkeletonLine extends StatelessWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const SkeletonLine({
    super.key,
    this.height = 14,
    this.width,
    this.borderRadius = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceVariant,
      highlightColor: AppColors.border,
      child: Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Skeleton loader for an expense list tile.
class ExpenseTileSkeleton extends StatelessWidget {
  const ExpenseTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const SkeletonLoader(width: 44, height: 44, borderRadius: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonLine(height: 14, width: 160),
                const SizedBox(height: 6),
                SkeletonLine(height: 11, width: MediaQuery.sizeOf(context).width * 0.3),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const SkeletonLine(height: 16, width: 60),
        ],
      ),
    );
  }
}

/// Skeleton for the dashboard spending card.
class SpendingCardSkeleton extends StatelessWidget {
  const SpendingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceVariant,
      highlightColor: AppColors.border,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 120, height: 12, color: AppColors.border),
            const SizedBox(height: 12),
            Container(width: 200, height: 40, color: AppColors.border),
            const SizedBox(height: 8),
            Container(width: 80, height: 10, color: AppColors.border),
          ],
        ),
      ),
    );
  }
}
