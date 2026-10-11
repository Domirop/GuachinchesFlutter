import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';

String _hex(Color c) {
  final argb = c.toARGB32();
  return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
}

String _alpha(Color c) => (c.a).toStringAsFixed(3);

/// Borde «mar de nubes» de la hoja de contenido: dos capas de nubes del
/// color del lienzo que derivan despacio en sentidos opuestos (46 s y 70 s,
/// lineal, en bucle). Es uno de los tres únicos bucles del sistema.
class GmCloudEdge extends StatelessWidget {
  static const double height = 26;

  const GmCloudEdge({super.key});

  // Trazos del tablero (402 de ancho, repetidos 2× para el bucle).
  static const _pathB =
      'M0 32V20c14 0 20-10 34-10s22 9 36 9 18-12 36-12 24 11 40 11 20-8 34-8 22 10 38 10 16-7 30-7 22 9 36 9 18-11 34-11 24 12 40 12 14-4 24-4v13zM402 32V20c14 0 20-10 34-10s22 9 36 9 18-12 36-12 24 11 40 11 20-8 34-8 22 10 38 10 16-7 30-7 22 9 36 9 18-11 34-11 24 12 40 12 14-4 24-4v13z';
  static const _pathA =
      'M0 28V22c10 0 14-8 26-8s16 6 26 6 14-12 30-12 20 10 32 10 14-6 26-6 18 8 30 8 16-10 30-10 22 12 36 12 12-5 24-5 18 7 30 7 16-9 30-9 20 8 32 8 14-4 22-4 12 3 28 3v6zM402 28V22c10 0 14-8 26-8s16 6 26 6 14-12 30-12 20 10 32 10 14-6 26-6 18 8 30 8 16-10 30-10 22 12 36 12 12-5 24-5 18 7 30 7 16-9 30-9 20 8 32 8 14-4 22-4 12 3 28 3v6z';

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final w = MediaQuery.sizeOf(context).width;
    final fill = _hex(gm.canvas);
    Widget layer(String d, double top, double opacity) => Positioned(
          left: 0,
          top: top,
          width: w * 2,
          height: height,
          child: Opacity(
            opacity: opacity,
            child: SvgPicture.string(
              '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 804 32" preserveAspectRatio="none"><path fill="$fill" d="$d"/></svg>',
              width: w * 2,
              height: height,
              fit: BoxFit.fill,
            ),
          ),
        );

    final b = layer(_pathB, 0, 0.55);
    final a = layer(_pathA, 4, 1);

    return IgnorePointer(
      child: SizedBox(
        height: height,
        width: w,
        child: ClipRect(
          child: RepaintBoundary(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // billow-b: 70 s, sentido inverso.
                GmLoop(
                  period: GmMotion.billowB,
                  reverse: true,
                  child: Stack(clipBehavior: Clip.none, children: [b]),
                  builder: (_, t, c) => Transform.translate(
                      offset: Offset(-w * t, 0), child: c),
                ),
                // billow-a: 46 s.
                GmLoop(
                  period: GmMotion.billowA,
                  child: Stack(clipBehavior: Clip.none, children: [a]),
                  builder: (_, t, c) => Transform.translate(
                      offset: Offset(-w * t, 0), child: c),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pie de la home: volcán mascota que parpadea una vez (y suelta una
/// bocanada) + «Eso es todo por hoy. ¡Buen provecho!».
class GmHomeFooter extends StatelessWidget {
  const GmHomeFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final ink = _hex(gm.volcInk);
    final puff =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 70"><path d="M44 22c-6 0-9-4-7-8 1-3 5-4 7-2 1-4 6-6 10-3 3-2 8-1 8 3 4 0 6 4 4 7-1 2-4 3-6 3z" fill="${_hex(gm.label2)}" fill-opacity="${(0.22 * gm.label2.a).toStringAsFixed(3)}"/></svg>';
    final body =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 70">'
        '<path d="M6 68l28-34c3-3.4 6-4.1 8.6-2.2l4.3 3c3.2 2.2 6.6 2.2 9.8 0l4.3-3c2.6-1.9 5.6-1.2 8.6 2.2L94 68z" fill="${_hex(gm.volcFill)}" stroke="${_hex(gm.sep)}" stroke-opacity="${_alpha(gm.sep)}" stroke-width="1.2" stroke-linejoin="round"/>'
        '<path d="M38.5 33.5l5.6 4c4 2.8 9.2 2.8 13.2 0l5.6-4" fill="none" stroke="#E0603A" stroke-width="3.4" stroke-linecap="round"/>'
        '<path d="M45 56q5 3.8 10 0" fill="none" stroke="$ink" stroke-width="2.2" stroke-linecap="round"/>'
        '<circle cx="37" cy="56" r="3" fill="#E0603A" fill-opacity="0.3"/><circle cx="63" cy="56" r="3" fill="#E0603A" fill-opacity="0.3"/>'
        '</svg>';
    final eyes =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 70"><circle cx="42.5" cy="50" r="2.8" fill="$ink"/><circle cx="57.5" cy="50" r="2.8" fill="$ink"/></svg>';

    return Semantics(
      identifier: 'home-footer',
      container: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
        child: Column(
          children: [
            SizedBox(
              width: 100,
              height: 70,
              child: GmOnce(
                duration: const Duration(milliseconds: 1100),
                delay: const Duration(milliseconds: 2400),
                builder: (_, t, __) {
                  // Parpadeo (300 ms) y, justo después, la bocanada sube.
                  final bt = (t * 1100 / 300).clamp(0.0, 1.0);
                  final eyeY = gmKeyframes(bt, const [(0, 1), (0.5, 0.1), (1, 1)]);
                  final pt = ((t * 1100 - 200) / 900).clamp(0.0, 1.0);
                  final puffDy = gmKeyframes(pt, const [(0, 0), (0.45, -5), (1, 0)]);
                  final puffS = gmKeyframes(pt, const [(0, 1), (0.45, 1.12), (1, 1)]);
                  return Stack(
                    children: [
                      Transform(
                        alignment: const Alignment(0.04, -0.5),
                        transform: Matrix4.translationValues(0, puffDy, 0)
                          ..multiply(Matrix4.diagonal3Values(puffS, puffS, 1)),
                        child: SvgPicture.string(puff, width: 100, height: 70),
                      ),
                      SvgPicture.string(body, width: 100, height: 70),
                      Transform(
                        // Centro de los ojos: y = 50/70.
                        alignment: const Alignment(0, 50 / 35 - 1),
                        transform: Matrix4.diagonal3Values(1, eyeY, 1),
                        child: SvgPicture.string(eyes, width: 100, height: 70),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Eso es todo por hoy. ¡Buen provecho!',
              textAlign: TextAlign.center,
              style: GmText.body(color: gm.label, w: FontWeight.w600),
            ),
            Text(
              'Hecho en Canarias por Jonay y Joana',
              textAlign: TextAlign.center,
              style: GmText.meta(color: gm.label2),
            ),
          ],
        ),
      ),
    );
  }
}
