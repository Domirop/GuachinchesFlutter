import 'package:flutter/material.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_canarias_paths.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';

/// Colores propios del mapa del juego (día/noche; ninguno claro fijo en noche).
class QuizMapColors {
  final Color land;
  final Color stroke;
  final Color seaA;
  final Color seaB;
  final Color onAccent;
  const QuizMapColors._(
      this.land, this.stroke, this.seaA, this.seaB, this.onAccent);

  static const day = QuizMapColors._(Color(0xFFFFFFFF), Color(0x4D5A4018),
      Color(0xFFDCEEF7), Color(0xFFC6E2F0), Color(0xFFFFFFFF));
  static const night = QuizMapColors._(Color(0xFF1E3140), Color(0x57C8E1F5),
      Color(0xFF0F2A3B), Color(0xFF0B2231), Color(0xFF0A141B));

  static QuizMapColors of(GmColors gm) => gm.isDark ? night : day;

  LinearGradient get sea => LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [seaA, seaB]);
}

/// Etiqueta de una isla en el viewBox del tablero (`-12 -60 1000 520`).
class _IslandInfo {
  final String slug;
  final String name;
  final Offset label;
  final TextAlign anchor;
  final Offset flag;
  const _IslandInfo(this.slug, this.name, this.label, this.anchor, this.flag);
}

const _info = [
  _IslandInfo('la_palma', 'La Palma', Offset(68, 260), TextAlign.center,
      Offset(70, 122)),
  _IslandInfo('el_hierro', 'El Hierro', Offset(4, 452), TextAlign.left,
      Offset(30, 360)),
  _IslandInfo('la_gomera', 'La Gomera', Offset(190, 370), TextAlign.center,
      Offset(198, 276)),
  _IslandInfo('tenerife', 'Tenerife', Offset(300, 178), TextAlign.center,
      Offset(404, 226)),
  _IslandInfo('gran_canaria', 'Gran Canaria', Offset(534, 434),
      TextAlign.center, Offset(534, 288)),
  _IslandInfo('fuerteventura', 'Fuerteventura', Offset(826, 364),
      TextAlign.center, Offset(830, 152)),
  _IslandInfo('lanzarote', 'Lanzarote', Offset(866, 74), TextAlign.right,
      Offset(930, 2)),
];

/// Nombre de una isla por slug (el del backend manda si llega).
String quizIslandName(String slug) {
  for (final i in _info) {
    if (i.slug == slug) return i.name;
  }
  return slug;
}

/// Orden oeste→este de las islas (el del mapa).
const kQuizIslandOrder = [
  'la_palma',
  'el_hierro',
  'la_gomera',
  'tenerife',
  'gran_canaria',
  'fuerteventura',
  'lanzarote',
];

const _vbLeft = -12.0;
const _vbTop = -60.0;
const _vbW = 1000.0;
const _vbH = 520.0;

/// Siluetas de `quiz_canarias_paths.dart` llevadas al viewBox del tablero
/// (+100 en x). Se parsean una sola vez.
final Map<String, Path> _paths = {
  for (final i in kCanariasIslands)
    i.slug: parseCanariasPath(i).shift(const Offset(100, 0)),
};

/// Mapa de conquista con las 7 siluetas reales en su disposición real.
/// Conquistadas: oro con bandera vino+oro. [selected]: isla elegida (acción).
/// [fresh]: recién conquistada (brillo + la bandera cae una vez).
/// [selectable] + [onSelect]: tocar una isla la elige.
class QuizIslandMap extends StatelessWidget {
  final Set<String> owned;
  final String? selected;
  final String? fresh;
  final Set<String> selectable;
  final ValueChanged<String>? onSelect;
  final bool labels;

  const QuizIslandMap({
    super.key,
    required this.owned,
    this.selected,
    this.fresh,
    this.selectable = const {},
    this.onSelect,
    this.labels = true,
  });

  String? _hit(Offset local, Size size) {
    final k = size.width / _vbW;
    final p = Offset(local.dx / k + _vbLeft, local.dy / k + _vbTop);
    String? best;
    var bestD = double.infinity;
    for (final slug in selectable) {
      final path = _paths[slug];
      if (path == null) continue;
      if (path.contains(p)) return slug;
      final b = path.getBounds();
      if (b.inflate(36).contains(p)) {
        final d = (b.center - p).distanceSquared;
        if (d < bestD) {
          bestD = d;
          best = slug;
        }
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final mc = QuizMapColors.of(gm);
    final n = owned.length;
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final size = Size(w, w * _vbH / _vbW);
      Widget paint(double t) => CustomPaint(
            size: size,
            painter: _MapPainter(
              gm: gm,
              mc: mc,
              owned: owned,
              selected: selected,
              fresh: fresh,
              labels: labels,
              t: t,
            ),
          );
      Widget map = fresh == null
          ? paint(1)
          : GmOnce(
              duration: const Duration(milliseconds: 1700),
              trigger: GmTrigger.mount,
              builder: (_, t, __) => paint(t),
            );
      if (onSelect != null) {
        map = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) {
            final s = _hit(d.localPosition, size);
            if (s != null) onSelect!(s);
          },
          child: map,
        );
      }
      return Semantics(
        image: true,
        label: 'Mapa de conquista: $n de 7 islas conquistadas',
        child: ExcludeSemantics(child: RepaintBoundary(child: map)),
      );
    });
  }
}

class _MapPainter extends CustomPainter {
  final GmColors gm;
  final QuizMapColors mc;
  final Set<String> owned;
  final String? selected;
  final String? fresh;
  final bool labels;
  final double t;

  _MapPainter({
    required this.gm,
    required this.mc,
    required this.owned,
    required this.selected,
    required this.fresh,
    required this.labels,
    required this.t,
  });

  static const _gold = [
    Color(0xFFF3DFA8),
    Color(0xFFD6B675),
    Color(0xFFB08A48)
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / _vbW;
    canvas.save();
    canvas.scale(k);
    canvas.translate(-_vbLeft, -_vbTop);
    final ms = t * 1700;

    for (final info in _info) {
      final path = _paths[info.slug];
      if (path == null) continue;
      final own = owned.contains(info.slug);
      final sel = info.slug == selected;
      final fill = Paint();
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round;
      if (sel) {
        fill.color = gm.accentSoft;
        stroke
          ..color = gm.accent
          ..strokeWidth = 6;
      } else if (own) {
        final b = path.getBounds();
        fill.shader = LinearGradient(
          begin: Alignment.topLeft,
          end: const Alignment(-0.2, 1),
          colors: _gold,
          stops: const [0, 0.55, 1],
        ).createShader(b);
        stroke
          ..color = const Color(0xFF8A6A2E)
          ..strokeWidth = 2.5;
      } else {
        fill.color = mc.land;
        stroke
          ..color = mc.stroke
          ..strokeWidth = 2.5;
      }
      canvas.drawPath(path, fill);
      if (own && info.slug == fresh) {
        // islglow: del azul suave al oro (1,2 s desde 0,2 s).
        final g = ((ms - 200) / 1200).clamp(0.0, 1.0);
        final a = (1 - GmMotion.ease.transform(g)) * gm.accentSoft.a;
        if (a > 0) {
          canvas.drawPath(
              path, Paint()..color = gm.accentSoft.withValues(alpha: a));
        }
      }
      canvas.drawPath(path, stroke);
    }

    // Banderas de las conquistadas (la nueva cae una vez).
    for (final info in _info) {
      if (!owned.contains(info.slug)) continue;
      var dy = 0.0, sx = 1.0, sy = 1.0;
      if (info.slug == fresh) {
        final f = ((ms - 500) / 1100).clamp(0.0, 1.0);
        dy = gmKeyframes(
            f, const [(0, -40), (0.45, 0), (0.65, -8), (0.85, 0), (1, 0)]);
        sx = gmKeyframes(
            f, const [(0, 1), (0.45, 1.1), (0.65, 0.96), (0.85, 1), (1, 1)]);
        sy = gmKeyframes(
            f, const [(0, 1), (0.45, 0.86), (0.65, 1.05), (0.85, 1), (1, 1)]);
      }
      _flag(canvas, info.flag, dy, sx, sy);
    }

    if (labels) {
      for (final info in _info) {
        final own = owned.contains(info.slug);
        if (info.slug == selected) {
          _selLabel(canvas, info);
        } else {
          _label(
            canvas,
            info,
            TextStyle(
              fontSize: 35,
              fontWeight: own ? FontWeight.w700 : FontWeight.w600,
              color: own ? gm.label : gm.label2,
            ),
          );
        }
      }
    }
    canvas.restore();
  }

  void _flag(Canvas canvas, Offset at, double dy, double sx, double sy) {
    canvas.save();
    // Base del mástil en (at.dx, at.dy); el muelle se apoya en la base.
    canvas.translate(at.dx, at.dy + dy);
    canvas.scale(sx, sy);
    canvas.translate(-6, -58);
    canvas.drawLine(
        const Offset(6, 58),
        const Offset(6, 4),
        Paint()
          ..color = const Color(0xFF6B4A1E)
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round);
    final cloth = Path()
      ..moveTo(8, 6)
      ..lineTo(40, 6)
      ..lineTo(32, 17)
      ..lineTo(40, 28)
      ..lineTo(8, 28)
      ..close();
    canvas.drawPath(cloth, Paint()..color = GmColors.wine);
    canvas.drawPath(
        cloth,
        Paint()
          ..color = GmColors.gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round);
    canvas.restore();
  }

  TextPainter _tp(String text, TextStyle style) => TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
      )..layout();

  void _label(Canvas canvas, _IslandInfo info, TextStyle style) {
    final tp = _tp(info.name, style);
    final x = switch (info.anchor) {
      TextAlign.center => info.label.dx - tp.width / 2,
      TextAlign.right => info.label.dx - tp.width,
      _ => info.label.dx,
    };
    // `y` del tablero es la línea base.
    tp.paint(
        canvas,
        Offset(
            x,
            info.label.dy -
                tp.computeDistanceToActualBaseline(TextBaseline.alphabetic)));
  }

  void _selLabel(Canvas canvas, _IslandInfo info) {
    final tp = _tp(
        info.name,
        TextStyle(
            fontSize: 33, fontWeight: FontWeight.w700, color: mc.onAccent));
    final tw = tp.width + 40;
    final x0 = switch (info.anchor) {
      TextAlign.center => info.label.dx - tw / 2,
      TextAlign.right => info.label.dx - tw,
      _ => info.label.dx,
    };
    final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(x0, info.label.dy - 34, tw, 48),
        const Radius.circular(24));
    canvas.drawRRect(r, Paint()..color = gm.accent);
    tp.paint(canvas, Offset(x0 + 20, r.center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _MapPainter o) =>
      o.t != t ||
      o.gm != gm ||
      o.selected != selected ||
      o.fresh != fresh ||
      o.labels != labels ||
      o.owned.length != owned.length ||
      !o.owned.containsAll(owned);
}
