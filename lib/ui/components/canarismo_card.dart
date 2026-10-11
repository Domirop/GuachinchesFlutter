import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:guachinches/core/analytics/analytics.dart';
import 'package:guachinches/core/analytics/analytics_events.dart';
import 'package:guachinches/data/canarismos.dart';
import 'package:guachinches/ui/pages/canarismo/canarismo_detail_screen.dart';
import 'package:guachinches/ui/pages/canarismo/canarismo_share_card.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';

/// «El canarismo del día» — la única tarjeta destacada del home (vino + oro).
///
/// Bocadillo «¡ey!» que se balancea una vez, la palabra entra letra a letra
/// en arcos (X e Y con curvas distintas, una vez), significado, ejemplo con
/// filete dorado (si el significado trae una cita «…»), cápsula Compartir y
/// la fila «Descubre más canarismos». Tocar la tarjeta abre el detalle.
class CanarismoCard extends StatelessWidget {
  const CanarismoCard({super.key});

  static const _cream = GmColors.cream;

  /// Separa «significado: «ejemplo».» en (significado, ejemplo).
  static (String, String?) splitMeaning(String s) {
    final m = RegExp(r'«[^»]+»').firstMatch(s);
    if (m == null) return (s.trim(), null);
    var meaning = s.replaceRange(m.start, m.end, '').trim();
    meaning = meaning.replaceAll(RegExp(r'[\s:;,.]+$'), '');
    if (meaning.isEmpty) return (s.trim(), null);
    return ('$meaning.', m.group(0));
  }

  void _open(BuildContext context, Canarismo c) {
    Analytics.I.logEvent(AnalyticsEvents.canarismoOpened, {
      'palabra': c.palabra,
      'source': 'home_banner',
    });
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => CanarismoDetailScreen(initial: c)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final c = canarismoOfDay();
    final (meaning, example) = splitMeaning(c.significado);

    return Semantics(
      identifier: 'home-canarismo',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: GmSpace.gutter),
        child: Container(
          decoration: BoxDecoration(
            color: GmColors.wine,
            borderRadius: BorderRadius.circular(GmRadius.guide),
            border: gm.isDark ? Border.all(color: gm.wineEdge) : null,
            boxShadow: const [
              BoxShadow(
                color: Color(0xB32A0E14),
                offset: Offset(0, 14),
                blurRadius: 34,
                spreadRadius: -14,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Semantics(
            identifier: 'home-canarismo-toggle',
            button: true,
            child: GmPressable(
              pressedScale: 0.985,
              onTap: () => _open(context, c),
              child: Stack(
                children: [
                  // Luz dorada arriba-derecha + poso granate abajo-izquierda.
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.topRight,
                            radius: 1.1,
                            colors: [Color(0x33C9A96B), Color(0x00C9A96B)],
                            stops: [0, 0.55],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.bottomLeft,
                            radius: 0.8,
                            colors: [Color(0x8C781E2D), Color(0x00781E2D)],
                            stops: [0, 0.7],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Positioned(right: 18, top: 16, child: _EyBubble()),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('El canarismo del día',
                                style: GmText.eyebrow(color: GmColors.gold)),
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.only(right: 70),
                              child: _ArcWord(word: c.palabra),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              meaning,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                height: 22 / 16,
                                fontWeight: FontWeight.w400,
                                color: _cream.withValues(alpha: 0.92),
                              ),
                            ),
                            if (example != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.only(left: 12),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    left: BorderSide(
                                        color: GmColors.gold, width: 3),
                                  ),
                                ),
                                child: Text(
                                  example,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    height: 21 / 15,
                                    fontWeight: FontWeight.w400,
                                    fontStyle: FontStyle.italic,
                                    color: GmColors.creamHi,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Semantics(
                              identifier: 'home-canarismo-share',
                              button: true,
                              child: GmPressable(
                                onTap: () => shareCanarismoAsImage(context, c),
                                pressedScale: 0.94,
                                child: Container(
                                  height: 44,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18),
                                  decoration: BoxDecoration(
                                    color: _cream.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(
                                        GmRadius.pill),
                                    border: Border.all(
                                        color: _cream.withValues(alpha: 0.22)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      GmIcon(GmIcons.share,
                                          size: 16, color: GmColors.creamHi),
                                      const SizedBox(width: 7),
                                      const Text(
                                        'Compartir',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: GmColors.creamHi,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        constraints: const BoxConstraints(minHeight: 50),
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                                color: _cream.withValues(alpha: 0.14)),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Descubre más canarismos',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: GmColors.creamHi,
                                ),
                              ),
                            ),
                            GmIcon(GmIcons.chevronRight,
                                size: 14, color: GmColors.gold),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// La palabra del día, letra a letra en arcos: X (−6 px, −8°, asentar) e Y
/// (−12 px con aplastado al tocar suelo) con curvas distintas. 700 ms por
/// letra, escalonado 70 ms, arranca a 200 ms. Una vez.
class _ArcWord extends StatelessWidget {
  final String word;
  const _ArcWord({required this.word});

  @override
  Widget build(BuildContext context) {
    final letters = word.characters.toList();
    final total = 200 + (letters.length - 1) * 70 + 700;
    const style = TextStyle(
      fontSize: 46,
      height: 52 / 46,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.4,
      color: GmColors.creamHi,
    );
    const yCurve = Cubic(0.55, 0, 0.8, 0.4);
    return Semantics(
      label: word,
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: GmOnce(
          duration: Duration(milliseconds: total),
          builder: (_, t, __) {
            final ms = t * total;
            return Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < letters.length; i++)
                  Builder(builder: (_) {
                    final lt = ((ms - 200 - i * 70) / 700).clamp(0.0, 1.0);
                    final x = GmMotion.settle.transform(lt);
                    final dx = -6 * (1 - x);
                    final rot = -8 * (1 - x) * math.pi / 180;
                    final dy = gmKeyframes(lt, const [
                      (0, -12), (0.6, 2), (0.8, -1), (1, 0)
                    ], curve: yCurve);
                    final sx = gmKeyframes(lt, const [
                      (0, 1), (0.6, 1.06), (0.8, 0.98), (1, 1)
                    ], curve: yCurve);
                    final sy = gmKeyframes(lt, const [
                      (0, 1), (0.6, 0.92), (0.8, 1.03), (1, 1)
                    ], curve: yCurve);
                    return Transform.translate(
                      offset: Offset(dx, dy),
                      child: Transform.rotate(
                        angle: rot,
                        child: Transform(
                          alignment: Alignment.bottomCenter,
                          transform: Matrix4.diagonal3Values(sx, sy, 1),
                          child: Text(letters[i], style: style),
                        ),
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Bocadillo «¡ey!» girado 8°: se balancea una vez a 1,4 s.
class _EyBubble extends StatelessWidget {
  const _EyBubble();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: GmOnce(
        duration: const Duration(milliseconds: 1200),
        delay: const Duration(milliseconds: 1400),
        builder: (_, t, child) {
          final rot = gmKeyframes(t, const [
            (0, 8), (0.3, -4), (0.6, 12), (0.85, 7), (1, 8)
          ]);
          final s = gmKeyframes(t, const [
            (0, 1), (0.3, 1.08), (0.6, 0.98), (0.85, 1), (1, 1)
          ]);
          return Transform(
            alignment: const Alignment(-0.6, 0.8),
            transform: Matrix4.rotationZ(rot * math.pi / 180)
              ..multiply(Matrix4.diagonal3Values(s, s, 1)),
            child: child,
          );
        },
        child: const CustomPaint(
          size: Size(62, 56),
          painter: _BubblePainter(),
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  const _BubblePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Path()
      ..moveTo(31, 4)
      ..cubicTo(46, 4, 58, 13.4, 58, 25)
      ..cubicTo(58, 36.6, 46, 46, 31, 46)
      ..cubicTo(28, 46, 25.2, 45.6, 22.6, 45)
      ..lineTo(10, 52)
      ..lineTo(13, 41.4)
      ..cubicTo(7.6, 37.6, 4, 31.6, 4, 25)
      ..cubicTo(4, 13.4, 16, 4, 31, 4)
      ..close();
    canvas.drawPath(p, Paint()..color = const Color(0x29C9A96B));
    canvas.drawPath(
        p,
        Paint()
          ..color = GmColors.gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    final tp = TextPainter(
      text: const TextSpan(
        text: '¡ey!',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: GmColors.gold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(31 - tp.width / 2, 25 - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
