import 'package:flutter/material.dart';
import 'package:guachinches/data/model/curated_list.dart';
import 'package:guachinches/ui/components/curated_hero_image.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart'
    show gmDisplayName;
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

/// Guía de Jonay y Joana (rediseño iOS 27): tarjeta r28 con la foto r22 a
/// 6 px, píldora de tipo + «N sitios» en cristal, título 17/22, subtítulo a
/// dos líneas y chincheta + zona en secundario.
class CardCuratedList extends StatelessWidget {
  final CuratedList list;
  final VoidCallback onTap;

  const CardCuratedList({
    super.key,
    required this.list,
    required this.onTap,
  });

  static const double width = 284;

  /// 6 + 160 + 11 + título 17/22 + 3 + dos líneas 15/20 + 7 + 13/18 + 8 + 6,
  /// con el texto escalado por el tamaño de texto del sistema.
  static double heightFor(BuildContext context) {
    final t = MediaQuery.textScalerOf(context);
    return 6 +
        160 +
        11 +
        gmScaledLine(t, 17, 22) +
        3 +
        gmScaledLine(t, 15, 20) * 2 +
        7 +
        gmScaledLine(t, 13, 18) +
        8 +
        6 +
        1;
  }

  /// «RUTA» → «Ruta» (las píldoras van en tipo frase).
  static String _sentence(String s) {
    final t = s.trim();
    if (t.isEmpty || t != t.toUpperCase()) return t;
    return t[0] + t.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return SizedBox(
      width: width,
      child: GmPressable(
        onTap: onTap,
        semanticsLabel: list.title,
        child: GmCard(
          radius: GmRadius.guide,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(GmRadius.guidePhoto),
                  child: SizedBox(
                    height: 160,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                list.accent.withValues(alpha: 0.55),
                                list.accent.withValues(alpha: 0.15),
                              ],
                            ),
                          ),
                        ),
                        if (list.heroAsset != null)
                          CuratedHeroImage(source: list.heroAsset!)
                        else if (list.heroEmoji != null)
                          Positioned(
                            right: -10,
                            bottom: -18,
                            child: Text(list.heroEmoji!,
                                style: const TextStyle(fontSize: 110)),
                          ),
                        if (list.eyebrow.trim().isNotEmpty)
                          Positioned(
                            left: 10,
                            top: 10,
                            child: GmPhotoChip(label: _sentence(list.eyebrow)),
                          ),
                        Positioned(
                          right: 10,
                          top: 10,
                          child: GmPhotoChip(
                              label: list.count == 1
                                  ? '1 sitio'
                                  : '${list.count} sitios'),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 11, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        gmDisplayName(list.title),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GmText.guideTitle(color: gm.label),
                      ),
                      const SizedBox(height: 3),
                      SizedBox(
                        height: gmScaledLine(
                                MediaQuery.textScalerOf(context), 15, 20) *
                            2,
                        child: Text(
                          list.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GmText.body(color: gm.label2),
                        ),
                      ),
                      if (list.location.trim().isNotEmpty) ...[
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            GmIcon(GmIcons.pin, size: 12, color: gm.accent),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                list.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GmText.eyebrow(color: gm.label2),
                              ),
                            ),
                          ],
                        ),
                      ] else
                        SizedBox(
                            height:
                                7 + MediaQuery.textScalerOf(context).scale(18)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
