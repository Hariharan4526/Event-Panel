import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/app_theme.dart';

class LoadingSkeleton extends StatelessWidget {
  final double? height;
  final double? width;
  final double borderRadius;

  const LoadingSkeleton({
    super.key,
    this.height,
    this.width,
    this.borderRadius = AppTheme.radiusMedium,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.darkCard,
      highlightColor: AppTheme.darkCardSecondary,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class EventCardSkeleton extends StatelessWidget {
  const EventCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LoadingSkeleton(
            height: 200,
            borderRadius: AppTheme.radiusLarge,
          ),
          const SizedBox(height: AppTheme.spacing2),
          const LoadingSkeleton(
            height: 20,
            width: 200,
          ),
          const SizedBox(height: AppTheme.spacing1),
          const LoadingSkeleton(
            height: 16,
            width: 150,
          ),
        ],
      ),
    );
  }
}

class ListItemSkeleton extends StatelessWidget {
  const ListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing2),
      padding: const EdgeInsets.all(AppTheme.spacing2),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: const Row(
        children: [
          LoadingSkeleton(
            height: 60,
            width: 60,
            borderRadius: AppTheme.radiusMedium,
          ),
          SizedBox(width: AppTheme.spacing2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoadingSkeleton(
                  height: 16,
                  width: double.infinity,
                ),
                SizedBox(height: AppTheme.spacing1),
                LoadingSkeleton(
                  height: 14,
                  width: 120,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

