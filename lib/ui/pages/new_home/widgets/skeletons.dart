import 'package:flutter/material.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/ui/components/shimmer_box.dart';

/// Fila de cards skeleton (horizontal scroll). Medidas configurables para
/// que el esqueleto coincida con la tarjeta real de cada carrusel.
class CardRowSkeleton extends StatelessWidget {
  final double itemWidth;
  final double itemHeight;
  final double radius;

  const CardRowSkeleton({
    super.key,
    this.itemWidth = 200,
    this.itemHeight = 200,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: itemHeight + 10,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) =>
            ShimmerBox(width: itemWidth, height: itemHeight, radius: radius),
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
              const ShimmerBox(width: 32, height: 20, radius: 4),
              const SizedBox(width: 12),
              const ShimmerBox(width: 48, height: 48, radius: 10),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBox(width: double.infinity, height: 14, radius: 4),
                    SizedBox(height: 6),
                    ShimmerBox(width: 120, height: 10, radius: 4),
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
                      ShimmerBox(width: 100, height: 10, radius: 4),
                      SizedBox(height: 8),
                      ShimmerBox(width: double.infinity, height: 18, radius: 6),
                      SizedBox(height: 6),
                      ShimmerBox(width: 140, height: 11, radius: 4),
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
