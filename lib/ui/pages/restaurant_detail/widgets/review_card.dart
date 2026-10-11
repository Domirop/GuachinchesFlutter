import 'package:flutter/material.dart';
import 'package:guachinches/data/model/Review.dart';
import 'package:guachinches/ui/pages/restaurant_detail/ficha_logic.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

/// Reseña tal cual la escribió cada persona (tablero FichaCompleta): avatar
/// con la inicial sobre un fondo teñido, nombre de pila, estrellas y, si
/// existen, título y texto. Sin fecha (el modelo no la trae).
class ReviewCard extends StatelessWidget {
  final Review review;

  /// Posición en la lista: elige el tinte del avatar (azul, vino, verde).
  final int index;

  const ReviewCard({super.key, required this.review, this.index = 0});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final name = fichaFirstName(review.usuario?.nombre);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final ratingNum = (double.tryParse(review.rating)?.round() ?? 0).clamp(0, 5);
    final palettes = [
      (gm.avAbg, gm.avAink),
      (gm.avTbg, gm.avTink),
      (gm.avPbg, gm.avPink),
    ];
    final (bg, ink) = palettes[index % palettes.length];
    final title = review.title.trim();
    final text = fichaReviewText(review.review);

    return GmCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GmText.cardTitle(color: gm.label)
                          .copyWith(letterSpacing: 0),
                    ),
                    const SizedBox(height: 2),
                    Semantics(
                      label: '$ratingNum de 5 estrellas',
                      excludeSemantics: true,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (i) {
                          final filled = i < ratingNum;
                          return Icon(
                            filled ? Icons.star : Icons.star_border,
                            color: filled ? GmColors.star : gm.label2,
                            size: 13,
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (title.isNotEmpty || text.isNotEmpty) const SizedBox(height: 10),
          if (title.isNotEmpty)
            Text(
              title,
              style: GmText.cardTitle(color: gm.label)
                  .copyWith(letterSpacing: -0.25),
            ),
          if (title.isNotEmpty && text.isNotEmpty) const SizedBox(height: 4),
          if (text.isNotEmpty)
            Text(
              text,
              style: TextStyle(
                fontSize: 15,
                height: 21 / 15,
                fontWeight: FontWeight.w400,
                color: gm.label,
              ),
            ),
        ],
      ),
    );
  }
}
