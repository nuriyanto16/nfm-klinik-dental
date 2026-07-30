import 'package:flutter/material.dart';

/// Animated pulsing / shimmer Skeleton Box for loading placeholders.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.margin,
  });

  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.35, end: 0.85).animate(
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
          margin: widget.margin,
          decoration: BoxDecoration(
            color: Colors.grey.shade300.withValues(alpha: _animation.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

/// Promo Carousel Skeleton Placeholder
class SkeletonBanner extends StatelessWidget {
  const SkeletonBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: SkeletonBox(
        width: double.infinity,
        height: 160,
        borderRadius: 20,
      ),
    );
  }
}

/// Horizontal List Skeleton (for Articles & Testimonials)
class SkeletonHorizontalList extends StatelessWidget {
  const SkeletonHorizontalList({
    super.key,
    this.itemWidth = 200,
    this.itemHeight = 180,
    this.itemCount = 3,
  });

  final double itemWidth;
  final double itemHeight;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: itemHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, i) => Container(
          width: itemWidth,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: double.infinity, height: itemHeight * 0.45, borderRadius: 12),
              const SizedBox(height: 10),
              const SkeletonBox(width: 80, height: 12, borderRadius: 6),
              const SizedBox(height: 8),
              const SkeletonBox(width: double.infinity, height: 14, borderRadius: 6),
              const SizedBox(height: 6),
              const SkeletonBox(width: 120, height: 12, borderRadius: 6),
            ],
          ),
        ),
      ),
    );
  }
}

/// Doctor Card Skeleton
class SkeletonDoctorCard extends StatelessWidget {
  const SkeletonDoctorCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              SkeletonBox(width: 50, height: 50, borderRadius: 25),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 140, height: 16, borderRadius: 6),
                    SizedBox(height: 6),
                    SkeletonBox(width: 100, height: 12, borderRadius: 6),
                  ],
                ),
              ),
              SkeletonBox(width: 40, height: 16, borderRadius: 6),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(
              4,
              (i) => const Padding(
                padding: EdgeInsets.only(right: 6),
                child: SkeletonBox(width: 50, height: 22, borderRadius: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Treatment Card Skeleton
class SkeletonTreatmentCard extends StatelessWidget {
  const SkeletonTreatmentCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Row(
        children: [
          SkeletonBox(width: 80, height: 80, borderRadius: 12),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 140, height: 16, borderRadius: 6),
                SizedBox(height: 8),
                SkeletonBox(width: 80, height: 12, borderRadius: 6),
                SizedBox(height: 6),
                SkeletonBox(width: 110, height: 14, borderRadius: 6),
              ],
            ),
          ),
          SizedBox(width: 8),
          SkeletonBox(width: 60, height: 36, borderRadius: 999),
        ],
      ),
    );
  }
}

/// Reservation Card Skeleton
class SkeletonReservationCard extends StatelessWidget {
  const SkeletonReservationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SkeletonBox(width: 36, height: 36, borderRadius: 18),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 120, height: 14, borderRadius: 6),
                      SizedBox(height: 4),
                      SkeletonBox(width: 90, height: 10, borderRadius: 6),
                    ],
                  ),
                ],
              ),
              SkeletonBox(width: 70, height: 24, borderRadius: 20),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              SkeletonBox(width: 18, height: 18, borderRadius: 4),
              SizedBox(width: 8),
              SkeletonBox(width: 140, height: 14, borderRadius: 6),
            ],
          ),
          Divider(height: 20),
          SkeletonBox(width: 160, height: 12, borderRadius: 6),
        ],
      ),
    );
  }
}

/// Vertical List Skeleton Wrapper
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    required this.itemBuilder,
    this.itemCount = 4,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget Function(BuildContext, int) itemBuilder;
  final int itemCount;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: itemBuilder,
    );
  }
}

/// Clinic Grid Skeleton
class SkeletonBranchGrid extends StatelessWidget {
  const SkeletonBranchGrid({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: itemCount,
      itemBuilder: (context, i) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: double.infinity, height: 110, borderRadius: 18),
            Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 100, height: 14, borderRadius: 6),
                  SizedBox(height: 6),
                  SkeletonBox(width: 40, height: 12, borderRadius: 6),
                  SizedBox(height: 6),
                  SkeletonBox(width: 120, height: 10, borderRadius: 6),
                  SizedBox(height: 12),
                  SkeletonBox(width: double.infinity, height: 32, borderRadius: 999),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
