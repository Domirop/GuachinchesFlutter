import 'package:flutter/material.dart';
import 'package:guachinches/data/model/Review.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

/// Resumen de reseñas (tablero FichaCompleta): nota grande con coma, cinco
/// estrellas, «N reseñas» y la distribución 5→1 en barras.
class RatingSummary extends StatelessWidget {
  final Restaurant restaurant;

  const RatingSummary({super.key, required this.restaurant});

  static Map<int, int> distribution(List<Review> reviews) {
    final m = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final r in reviews) {
      final n = double.tryParse(r.rating)?.round() ?? 0;
      if (n >= 1 && n <= 5) m[n] = m[n]! + 1;
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final reviews = restaurant.valoraciones;
    final dist = distribution(reviews);
    final total = reviews.length;
    final avg = restaurant.avgRating;
    final label2 = TextStyle(
      fontSize: 12,
      height: 14 / 12,
      fontWeight: FontWeight.w400,
      color: gm.label2,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return GmCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                avg > 0 ? avg.toStringAsFixed(1).replaceAll('.', ',') : '–',
                style: TextStyle(
                  fontSize: 44,
                  height: 48 / 44,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                  color: gm.label,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  final filled = i < avg.round();
                  return Icon(
                    filled ? Icons.star : Icons.star_border,
                    color: filled ? GmColors.star : gm.label2,
                    size: 13,
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(total == 1 ? '1 reseña' : '$total reseñas',
                  style: GmText.eyebrow(color: gm.label2, w: FontWeight.w400)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Semantics(
              label: 'Distribución de las $total reseñas',
              excludeSemantics: true,
              child: Column(
                children: [
                  for (var star = 5; star >= 1; star--)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.5),
                      child: Row(
                        children: [
                          SizedBox(
                              width: 10, child: Text('$star', style: label2)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(GmRadius.pill),
                              child: SizedBox(
                                height: 6,
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                        child: ColoredBox(color: gm.fill)),
                                    FractionallySizedBox(
                                      heightFactor: 1,
                                      widthFactor: total == 0
                                          ? 0
                                          : dist[star]! / total,
                                      child: const ColoredBox(
                                          color: GmColors.star),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 14,
                            child: Text('${dist[star]}',
                                textAlign: TextAlign.right, style: label2),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
