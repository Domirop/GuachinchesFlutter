import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';

/// Shimmer rápido sin dependencia externa.
class _Shimmer extends StatefulWidget {
  final double width, height, radius;

  const _Shimmer({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.06, end: 0.18).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.crema.withValues(alpha: _anim.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// Fila de cards skeleton (horizontal scroll).
class CardRowSkeleton extends StatelessWidget {
  const CardRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => const _Shimmer(width: 200, height: 200, radius: 14),
      ),
    );
  }
}

/// Fila de cards ranking skeleton.
class RankingRowSkeleton extends StatelessWidget {
  const RankingRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(
            children: [
              const _Shimmer(width: 32, height: 20, radius: 4),
              const SizedBox(width: 12),
              const _Shimmer(width: 48, height: 48, radius: 10),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _Shimmer(width: double.infinity, height: 14, radius: 4),
                    SizedBox(height: 6),
                    _Shimmer(width: 120, height: 10, radius: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder del slot "Abiertos cerca ahora" durante bootstrap.
///
/// Replica el layout de [OpenNowCallout] con tres barras shimmer (eyebrow,
/// headline, support) y banda lateral neutra. Sin LiveDot, chevron ni
/// GestureDetector — no afirma ningún estado de datos.
class OpenNowCalloutSkeleton extends StatelessWidget {
  const OpenNowCalloutSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'home-cerca-ahora-skeleton',
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        decoration: BoxDecoration(
          color: context.brand.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.brand.border, width: 1),
        ),
        clipBehavior: Clip.hardEdge,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: context.brand.border,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      _Shimmer(width: 100, height: 10, radius: 4),
                      SizedBox(height: 8),
                      _Shimmer(width: double.infinity, height: 18, radius: 6),
                      SizedBox(height: 6),
                      _Shimmer(width: 140, height: 11, radius: 4),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
