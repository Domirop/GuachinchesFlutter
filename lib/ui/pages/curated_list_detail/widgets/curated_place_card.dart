import 'package:flutter/material.dart';
import 'package:guachinches/ui/pages/curated_list_detail/curated_list_logic.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart'
    show GmPhoto;
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

/// Tarjeta de la rejilla de la lista curada: tarjeta r24 con la foto 3:4 r18
/// a 6 px (portada del vídeo cuando hay visita, si no la foto del local),
/// chip «Vídeo», corazón de 44 y debajo nombre, nota de la guía y la fila
/// «zona · ≈ precio».
class CuratedPlaceCard extends StatelessWidget {
  final CuratedPlace place;
  final VoidCallback onTap;

  const CuratedPlaceCard({super.key, required this.place, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final p = place;
    final label = [
      p.name,
      if (p.note != null) p.note!,
      if (p.zone != null) p.zone!,
      if (p.price != null) p.price!.replaceAll('≈', 'unos'),
      if (p.hasVideo) 'con vídeo de Jonay y Joana',
    ].join(', ');

    return Stack(
      children: [
        GmPressable(
          semanticsIdentifier: 'curated-list-place-${p.restaurantId}',
          semanticsLabel: label,
          onTap: onTap,
          child: GmCard(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 3 / 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(GmRadius.photo),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        GmPhoto(
                          p.photo,
                          fallbacks: p.photoFallbacks,
                          alignment: const Alignment(0, -0.16),
                        ),
                        if (p.hasVideo)
                          Positioned(
                            left: 8,
                            top: 8,
                            child: GmPhotoChip(
                              dark: true,
                              leading: GmIcon(GmIcons.play,
                                  size: 10, color: Colors.white),
                              label: 'Vídeo',
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 9, 6, 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GmText.cardTitle(color: gm.label),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        p.note ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GmText.meta(color: gm.label2),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.zone ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GmText.meta(color: gm.label2),
                            ),
                          ),
                          if (p.price != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              p.price!,
                              style: GmText.meta(color: gm.label)
                                  .copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: GmFavButton(
            restaurantId: p.restaurantId,
            restaurantName: p.name,
          ),
        ),
      ],
    );
  }
}

/// Esqueleto de la tarjeta con su misma forma.
class CuratedPlaceSkeleton extends StatelessWidget {
  const CuratedPlaceSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    Widget bar(double w, double h) => FractionallySizedBox(
          widthFactor: w,
          child: Container(
            height: h,
            decoration: BoxDecoration(
              color: gm.fill,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        );
    return GmCard(
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: gm.fill,
                borderRadius: BorderRadius.circular(GmRadius.photo),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 12, 6, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(0.8, 13),
                const SizedBox(height: 8),
                bar(0.55, 10),
                const SizedBox(height: 8),
                bar(0.65, 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
