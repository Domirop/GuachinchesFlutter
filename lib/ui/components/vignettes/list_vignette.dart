import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:guachinches/ui/pages/advance_search/widgets/looping_scene.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:path_parsing/path_parsing.dart';

/// Viñetas con personaje de las cabeceras de lista (tableros «Lista, brunch»,
/// «bocadillos de cochino», «japoneses» y «ocasiones especiales»). Cada una
/// es una pequeña historia de 8 s en un lienzo de 180×180 que se repite:
///
/// - [ListVignetteKind.brunch]: el huevo frito salta de la tostada, aterriza
///   aplastándose (la clara tiembla) y una fresa llega rodando a empujarlo.
/// - [ListVignetteKind.bocadillo]: el pan abre la boca, sale el olor, muerde
///   con migas en arco y cae una gota de mojo.
/// - [ListVignetteKind.japones]: los palillos van a por el nigiri de atún,
///   que se asusta y se escurre; el de salmón lo celebra.
/// - [ListVignetteKind.celebracion]: la llama de la vela aguanta un soplido,
///   se apaga y vuelve a encenderse con chispa y confeti.
///
/// Reglas del sistema (ver `.claude/skills/animaciones-pixar`): anticipación
/// antes de cada gesto, aplastar y estirar con volumen constante, seguimiento
/// en lo blando, trayectorias en arco, parpadeos y miradas como acción
/// secundaria, y reposo largo al final del bucle. Con «reducir movimiento» se
/// pinta el fotograma de reposo (q = 0) y el reloj no corre.
enum ListVignetteKind { brunch, bocadillo, japones, celebracion }

/// Escena para una lista a partir de su id y título (sin tildes, minúsculas).
/// `null` si no hay viñeta para ese tema: la cabecera queda sin ilustración.
ListVignetteKind? listVignetteFor(String idAndTitle) {
  const from = 'áéíóúüñ';
  const to = 'aeiouun';
  var s = idAndTitle.toLowerCase();
  for (var i = 0; i < from.length; i++) {
    s = s.replaceAll(from[i], to[i]);
  }
  if (s.contains('brunch')) return ListVignetteKind.brunch;
  if (s.contains('bocadillo')) return ListVignetteKind.bocadillo;
  if (s.contains('japon') || s.contains('sushi')) return ListVignetteKind.japones;
  if (s.contains('especial') ||
      s.contains('aniversario') ||
      s.contains('celebra') ||
      s.contains('cumple')) {
    return ListVignetteKind.celebracion;
  }
  return null;
}

class ListVignette extends LoopingScene {
  final ListVignetteKind kind;

  /// Lado del lienzo de diseño (viewBox 0 0 180 180 del tablero).
  static const double designSize = 180;

  const ListVignette({super.key, super.active, required this.kind});

  @override
  State<ListVignette> createState() => ListVignetteState();
}

@visibleForTesting
class ListVignetteState extends LoopingSceneState<ListVignette> {
  @override
  double get designWidth => ListVignette.designSize;

  @override
  double get designHeight => ListVignette.designSize;

  @override
  double quietRemaining(double t) => vignetteQuietRemaining(widget.kind, t);

  @override
  Widget buildLayers(
      BuildContext context, double scale, double? time, bool dark) {
    // q = progreso del bucle en % (como los @keyframes del tablero).
    final q = time == null ? 0.0 : (time % _kLoop) / _kLoop * 100;
    final secs = time ?? 0;
    // Recortada a su caja: lo que entra de fuera (fresa, palillos) aparece
    // por el borde y en reposo no asoma.
    return ClipRect(
      child: CustomPaint(
        painter: switch (widget.kind) {
          ListVignetteKind.brunch => _BrunchPainter(scale, q, secs),
          ListVignetteKind.bocadillo => _BocadilloPainter(scale, q),
          ListVignetteKind.japones => _JaponesPainter(scale, q, secs),
          ListVignetteKind.celebracion => _CelebracionPainter(scale, q),
        },
      ),
    );
  }
}

// ── Tiempos ───────────────────────────────────────────────────────────────

const double _kLoop = 8;

/// Tramos con movimiento (segundos dentro del bucle). Fuera de ellos la
/// escena está en su pose de reposo y el reloj duerme.
const Map<ListVignetteKind, List<(double, double)>> _kActive = {
  ListVignetteKind.brunch: [(0.45, 6.6), (7.0, 8.0)],
  ListVignetteKind.bocadillo: [(0.45, 6.45)],
  ListVignetteKind.japones: [(0.7, 6.6)],
  ListVignetteKind.celebracion: [(0.0, 6.3)],
};

@visibleForTesting
double vignetteQuietRemaining(ListVignetteKind kind, double t) =>
    loopQuietRemaining(t, loop: _kLoop, active: _kActive[kind]!);

// ── Utilidades de dibujo ─────────────────────────────────────────────────

const _ink = Color(0xFF3A2418);
const _kSpring = Cubic(0.34, 1.56, 0.64, 1);
const _kAction = Cubic(0.45, 0, 0.25, 1);

/// Fotogramas clave en % del bucle (curva aplicada a cada tramo, como CSS).
double _k(double q, List<(double, double)> stops,
        [Curve curve = Curves.easeInOut]) =>
    gmKeyframes(q / 100, [for (final (p, v) in stops) (p / 100, v)],
        curve: curve);

class _PathProxy extends PathProxy {
  final Path path = Path();
  @override
  void moveTo(double x, double y) => path.moveTo(x, y);
  @override
  void lineTo(double x, double y) => path.lineTo(x, y);
  @override
  void cubicTo(
          double x1, double y1, double x2, double y2, double x3, double y3) =>
      path.cubicTo(x1, y1, x2, y2, x3, y3);
  @override
  void close() => path.close();
}

final Map<String, Path> _pathCache = {};

/// Trazado SVG del tablero tal cual (`d=`), cacheado.
Path _svg(String d) => _pathCache.putIfAbsent(d, () {
      final p = _PathProxy();
      writeSvgPathDataToPath(d, p);
      return p.path;
    });

Paint _fill(Color c) => Paint()..color = c;

Paint _line(Color c, double w) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

void _shape(Canvas c, Path p, Color fill, {double sw = 2.5, Color? stroke}) {
  c.drawPath(p, _fill(fill));
  if (sw > 0) c.drawPath(p, _line(stroke ?? _ink, sw));
}

void _oval(Canvas c, double cx, double cy, double rx, double ry, Color fill,
    {double sw = 0, Color? stroke}) {
  final r = Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2);
  c.drawOval(r, _fill(fill));
  if (sw > 0) c.drawOval(r, _line(stroke ?? _ink, sw));
}

void _rrect(Canvas c, double x, double y, double w, double h, double r,
    Color fill,
    {double sw = 2.5}) {
  final rr = RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r));
  c.drawRRect(rr, _fill(fill));
  if (sw > 0) c.drawRRect(rr, _line(_ink, sw));
}

/// Transforma alrededor de [o] en el orden de CSS: translate → rotate →
/// skewX → scale. Ángulos en grados.
void _xf(Canvas c, Offset o, void Function() draw,
    {double tx = 0,
    double ty = 0,
    double rot = 0,
    double skx = 0,
    double sx = 1,
    double sy = 1}) {
  c.save();
  c.translate(o.dx + tx, o.dy + ty);
  if (rot != 0) c.rotate(rot * math.pi / 180);
  if (skx != 0) c.skew(math.tan(skx * math.pi / 180), 0);
  if (sx != 1 || sy != 1) c.scale(sx, sy);
  c.translate(-o.dx, -o.dy);
  draw();
  c.restore();
}

/// Capa con opacidad (nada si es 0).
void _alpha(Canvas c, double a, void Function() draw) {
  if (a <= 0.001) return;
  if (a >= 0.999) {
    draw();
    return;
  }
  c.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, a));
  draw();
  c.restore();
}

/// Respiración de reposo (acción secundaria): 0→1→0 con periodo [period].
double _breath(double secs, double period, [double offset = 0]) =>
    (1 - math.cos(2 * math.pi * (secs + offset) / period)) / 2;

abstract class _VignettePainter extends CustomPainter {
  final double scale;
  final double q;
  const _VignettePainter(this.scale, this.q);

  void draw(Canvas c);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(scale);
    draw(canvas);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _VignettePainter old) =>
      old.q != q || old.scale != scale;
}

// ── Brunch: el huevo que se despierta ─────────────────────────────────────

class _BrunchPainter extends _VignettePainter {
  final double secs;
  const _BrunchPainter(super.scale, super.q, this.secs);

  @override
  bool shouldRepaint(covariant _BrunchPainter old) =>
      super.shouldRepaint(old) || old.secs != secs;

  @override
  void draw(Canvas c) {
    _oval(c, 90, 163, 70, 8, const Color(0x1F3C280A));
    _oval(c, 90, 156, 74, 14, Colors.white, sw: 2.5);

    // Vapor (acción secundaria continua dentro del tramo activo).
    for (final off in [0.0, 1.6]) {
      final p = ((secs + off) % 3.2) / 3.2;
      final a = p < .3 ? p / .3 : 1 - (p - .3) / .7;
      final x = off == 0 ? 62.0 : 120.0;
      _alpha(c, a, () {
        _xf(c, Offset.zero, ty: 6 - 22 * p, () {
          c.drawPath(_svg('M$x ${off == 0 ? 96 : 94} c-6 -7 6 -12 0 -20'),
              _line(const Color(0x473A2418), 3));
        });
      });
    }

    // Tostada: se aplasta al recibir el huevo.
    _xf(c, const Offset(90, 152),
        sx: _k(q, [(0, 1), (31, 1), (33, 1.03), (37, 1), (100, 1)]),
        sy: _k(q, [(0, 1), (31, 1), (33, .95), (37, 1), (100, 1)]), () {
      _rrect(c, 36, 118, 108, 34, 14, const Color(0xFFD99A4E));
      _rrect(c, 44, 124, 92, 22, 9, const Color(0xFFF2C27E), sw: 0);
    });

    final b = _breath(secs, 2.8);
    _xf(c, const Offset(90, 121), sx: 1 + .015 * b, sy: 1 + .025 * b, () {
      // Clara: anticipación y gelatina al aterrizar (seguimiento).
      _xf(c, const Offset(90, 121),
          sx: _k(q, [(0, 1), (10, 1), (13, 1.04), (17, .98), (21, 1), (31, 1), (33, 1.1), (36, .95), (39, 1.04), (42, .99), (45, 1), (100, 1)]),
          sy: _k(q, [(0, 1), (10, 1), (13, .94), (17, 1.03), (21, 1), (31, 1), (33, .86), (36, 1.06), (39, .97), (42, 1.01), (45, 1), (100, 1)]),
          () => _shape(
              c,
              _svg('M46 121 C40 104 60 96 74 101 C82 90 106 90 114 100 '
                  'C128 95 144 106 136 121 Z'),
              const Color(0xFFFFFDF7)));

      // Destello del aterrizaje.
      final pop = _k(q, [(0, 0), (32, 0), (34, 1), (41, 0), (100, 0)], Curves.easeOut);
      _alpha(c, pop, () {
        final s = _k(q, [(0, .4), (32, .4), (34, 1), (41, 1.35), (100, 1.35)], Curves.easeOut);
        _xf(c, const Offset(90, 116), sx: s, sy: s, () {
          c.drawPath(
              _svg('M60 118 l-8 -4 M62 112 l-6 -8 M120 118 l8 -4 M118 112 l6 -8'),
              _line(const Color(0xFFF5B700), 2.5));
        });
      });

      // Yema: agacharse, saltar girando, aplastarse, rebotar.
      _xf(
        c,
        const Offset(90, 117),
        ty: _k(q, [(0, 0), (13, 0), (16, -6), (22, -44), (26, -46), (31, 0), (62, 0), (65, -5), (68, 0), (100, 0)], _kAction),
        rot: _k(q, [(0, 0), (16, 0), (22, -10), (26, 6), (31, 0), (100, 0)], _kAction),
        sx: _k(q, [(0, 1), (10, 1), (13, 1.18), (16, .86), (22, .95), (26, 1), (31, .9), (33, 1.28), (37, .94), (41, 1.04), (45, 1), (62, 1), (65, .96), (68, 1.06), (71, 1), (100, 1)], _kAction),
        sy: _k(q, [(0, 1), (10, 1), (13, .78), (16, 1.18), (22, 1.06), (26, 1), (31, 1.12), (33, .72), (37, 1.06), (41, .97), (45, 1), (62, 1), (65, 1.05), (68, .95), (71, 1), (100, 1)], _kAction),
        () {
          _oval(c, 90, 100, 17, 17, const Color(0xFFF5B700), sw: 2.5);
          _oval(c, 83, 93, 5, 3, const Color(0xFFFFE58A));
          final look = _k(q, [(0, 0), (58, 0), (62, 2.6), (78, 2.6), (82, 0), (100, 0)], _kSpring);
          final blink = _k(q, [(0, 1), (6, 1), (7.5, .1), (9, 1), (47, 1), (50, 1), (51.5, .1), (53, 1), (100, 1)], Curves.linear);
          _xf(c, const Offset(90, 100), tx: look, sy: blink, () {
            _oval(c, 84, 100, 2.2, 3, _ink);
            _oval(c, 96, 100, 2.2, 3, _ink);
          });
          c.drawPath(_svg('M85 107 q5 4 10 0'), _line(_ink, 2));
          _oval(c, 79, 106, 2.6, 2.6, const Color(0x8CF28C5B));
          _oval(c, 101, 106, 2.6, 2.6, const Color(0x8CF28C5B));
        },
      );
    });

    // Fresa que llega rodando, empuja y se va.
    const berryCurve = Cubic(0.3, 0.7, 0.3, 1);
    _xf(
      c,
      const Offset(150, 139),
      tx: _k(q, [(0, 70), (52, 70), (61, -4), (64, 0), (88, 0), (91, -4), (98, 70), (100, 70)], berryCurve),
      rot: _k(q, [(0, 220), (52, 220), (61, -8), (64, 0), (88, 0), (91, 0), (98, 220), (100, 220)], berryCurve),
      sx: _k(q, [(0, 1), (61, 1), (64, 1.14), (68, .95), (72, 1), (100, 1)]),
      sy: _k(q, [(0, 1), (61, 1), (64, .84), (68, 1.05), (72, 1), (100, 1)]),
      () {
        _shape(
            c,
            _svg('M150 128 c-8 0 -11 8 -6 15 c2 4 6 7 6 7 s4 -3 6 -7 '
                'c5 -7 2 -15 -6 -15z'),
            const Color(0xFFE8463A),
            sw: 2.2);
        c.drawPath(_svg('M144 129 l6 -5 l6 5'), _line(const Color(0xFF3E7A2E), 2.4));
        for (final (x, y) in [(147.0, 136.0), (153.0, 138.0), (150.0, 143.0)]) {
          _oval(c, x, y, .9, .9, const Color(0xFFFFE58A));
        }
      },
    );
  }
}

// ── Bocadillo: el mordisco ────────────────────────────────────────────────

class _BocadilloPainter extends _VignettePainter {
  const _BocadilloPainter(super.scale, super.q);

  @override
  void draw(Canvas c) {
    _oval(c, 90, 160, 68, 8, const Color(0x1F3C280A));

    _xf(
      c,
      const Offset(90, 150),
      sx: _k(q, [(0, 1), (10, 1), (13, 1.06), (17, .97), (21, 1), (28, 1), (30, 1.12), (34, .95), (38, 1.03), (42, 1), (100, 1)]),
      sy: _k(q, [(0, 1), (10, 1), (13, .93), (17, 1.04), (21, 1), (28, 1), (30, .86), (34, 1.05), (38, .98), (42, 1), (100, 1)]),
      () {
        _shape(c, _svg('M24 130 C24 152 156 152 156 130 Z'), const Color(0xFFE3A65C));
        _shape(
            c,
            _svg('M22 130 q8 -8 17 0 t17 0 t17 0 t17 0 t17 0 t17 0 t17 0 t17 0 v4 H22z'),
            const Color(0xFF7DB53C),
            sw: 2);
        _shape(
            c,
            _svg('M28 125 q10 -7 21 0 t21 0 t21 0 t21 0 t21 0 t21 0 v6 H28z'),
            const Color(0xFF9A4A2A),
            sw: 2);

        // El olor sale mientras el pan está abierto.
        _alpha(c, _k(q, [(0, 0), (21, 0), (24, 1), (31, 0), (100, 0)], Curves.easeOut), () {
          _xf(c, Offset.zero,
              ty: _k(q, [(0, 4), (21, 4), (31, -14), (100, -14)], Curves.easeOut), () {
            c.drawPath(_svg('M70 114 c-5 -6 5 -10 0 -16 M100 112 c-5 -6 5 -10 0 -16'),
                _line(const Color(0x593A2418), 2.6));
          });
        });

        // Pan de arriba = boca: anticipa hacia abajo, abre, muerde, mastica.
        _xf(
          c,
          const Offset(28, 121),
          ty: _k(q, [(0, 0), (17, 0), (20, 2), (24, -20), (27, -22), (29, -1), (30, 0), (33, -4), (35, 0), (38, -3), (40, 0), (100, 0)], _kAction),
          rot: _k(q, [(0, 0), (17, 0), (20, 3), (24, -22), (27, -25), (29, 2), (30, 0), (33, -6), (35, 0), (38, -4), (40, 0), (100, 0)], _kAction),
          () {
            _shape(c, _svg('M22 122 C22 84 158 84 158 122 Z'), const Color(0xFFE8AE62));
            c.drawPath(_svg('M44 102 q20 -13 46 -11'), _line(const Color(0xFFFFE0A8), 4));
            for (final (x, y) in [(60.0, 97.0), (84.0, 91.0), (112.0, 92.0), (134.0, 100.0)]) {
              _oval(c, x, y, 2.6, 1.5, const Color(0xFFFFF3D6), sw: .8);
            }
            final wide = _k(q, [(0, 1), (21, 1), (24, 1.3), (28, 1.3), (31, 1), (100, 1)], _kSpring);
            final blink = _k(q, [(0, 1), (6, 1), (7.5, .1), (9, 1), (39, 1), (41, .35), (45, .35), (47, 1), (58, 1), (59.5, .1), (61, 1), (100, 1)], Curves.linear);
            _xf(c, const Offset(90, 109), sx: wide, sy: wide * blink, () {
              _oval(c, 76, 109, 3, 4, _ink);
              _oval(c, 104, 109, 3, 4, _ink);
            });
            _oval(c, 68, 115, 3, 3, const Color(0x80F28C5B));
            _oval(c, 112, 115, 3, 3, const Color(0x80F28C5B));
          },
        );
      },
    );

    // Migas en arco.
    void crumb(double cx, double r, Color fill, List<(double, double)> xs,
        List<(double, double)> ys, double end) {
      final a = _k(q, [(0, 0), (29, 0), (30, 1), (end, 1), (end + 2, 0), (100, 0)], Curves.linear);
      _alpha(c, a, () {
        _xf(c, Offset.zero, tx: _k(q, xs, Curves.linear), ty: _k(q, ys, Curves.linear), () {
          _oval(c, cx, 124, r, r, fill, sw: fill == const Color(0xFFE3A65C) ? 1 : 0);
        });
      });
    }

    crumb(90, 2.6, const Color(0xFFE3A65C),
        [(0, 0), (30, 0), (36, -22), (43, -34), (50, -40), (100, -40)],
        [(0, 0), (30, 0), (36, -20), (43, -4), (50, 30), (100, 30)], 50);
    crumb(96, 2.2, const Color(0xFFE3A65C),
        [(0, 0), (30, 0), (36, 24), (43, 38), (50, 46), (100, 46)],
        [(0, 0), (30, 0), (36, -24), (43, -6), (50, 30), (100, 30)], 50);
    crumb(84, 2, const Color(0xFF9A4A2A),
        [(0, 0), (30, 0), (35, -6), (41, -10), (48, -12), (100, -12)],
        [(0, 0), (30, 0), (35, -30), (41, -18), (48, 30), (100, 30)], 48);

    // Gota de mojo: se forma, se estira al caer y se aplasta.
    const fall = Cubic(0.55, 0, 0.8, 0.4);
    _alpha(c, _k(q, [(0, 0), (58, 0), (62, 1), (74, 1), (80, 0), (100, 0)], Curves.linear), () {
      final s = _k(q, [(0, 0), (58, 0), (62, 1), (100, 1)], fall);
      _xf(
        c,
        const Offset(150, 128),
        ty: _k(q, [(0, 0), (62, 0), (66, 3), (72, 24), (74, 26), (100, 26)], fall),
        sx: s * _k(q, [(0, 1), (72, 1), (74, 1.7), (100, 1.7)], fall),
        sy: s * _k(q, [(0, 1), (62, 1), (66, 1.3), (72, 1.45), (74, .3), (100, .3)], fall),
        () => _shape(
            c,
            _svg('M150 128 c-3 5 -4 8 -2 10 c1.4 1.4 4.6 1.4 6 0 c2 -2 1 -5 -2 -10z'),
            const Color(0xFF3E8E3A),
            sw: 1.4),
      );
    });
  }
}

// ── Japoneses: el nigiri que se escapa ────────────────────────────────────

class _JaponesPainter extends _VignettePainter {
  final double secs;
  const _JaponesPainter(super.scale, super.q, this.secs);

  @override
  bool shouldRepaint(covariant _JaponesPainter old) =>
      super.shouldRepaint(old) || old.secs != secs;

  void _nigiri(Canvas c, double x, Color fish, Color stripe,
      {required double look,
      required double wide,
      required double blink,
      required bool scared,
      required double blush}) {
    _rrect(c, x - 24, 112, 48, 28, 13, const Color(0xFFFFFDF7));
    _shape(
        c,
        _svg('M${x - 28} 112 C${x - 28} 98 ${x + 28} 98 ${x + 28} 112 '
            'C${x + 28} 118 ${x - 28} 118 ${x - 28} 112 Z'),
        fish);
    c.drawPath(
        _svg('M${x - 14} 103 q4 6 2 12 M$x 101 q4 7 2 14 M${x + 14} 103 q4 6 2 12'),
        _line(stripe, 2.4));
    _xf(c, Offset(x, 126), tx: look, sx: wide, sy: wide * blink, () {
      _oval(c, x - 8, 126, 2.2, 3, _ink);
      _oval(c, x + 8, 126, 2.2, 3, _ink);
    });
    if (scared) {
      _oval(c, x, 133, 2.4, 3, _ink);
    } else {
      c.drawPath(_svg('M${x - 4} 132 q4 3 8 0'), _line(_ink, 2));
    }
    final blushPaint = _fill(Color.fromRGBO(242, 140, 91, blush));
    c.drawCircle(Offset(x - 14, 131), 3, blushPaint);
    c.drawCircle(Offset(x + 14, 131), 3, blushPaint);
  }

  @override
  void draw(Canvas c) {
    _oval(c, 90, 164, 70, 7, const Color(0x1F3C280A));
    _rrect(c, 16, 140, 148, 14, 5, const Color(0xFFC99A6A));
    _rrect(c, 30, 154, 14, 8, 2, const Color(0xFFA87C50), sw: 2);
    _rrect(c, 136, 154, 14, 8, 2, const Color(0xFFA87C50), sw: 2);

    final blush = _k(q, [(0, .35), (46, .35), (52, .9), (72, .9), (80, .35), (100, .35)]);

    // Salmón (A): sigue al atún con la mirada y celebra.
    final ba = _breath(secs, 2.6);
    _xf(c, const Offset(56, 140), sx: 1 + .02 * ba, sy: 1 + .03 * ba, () {
      _xf(
        c,
        const Offset(56, 140),
        ty: _k(q, [(0, 0), (51, 0), (54, -18), (57, 0), (100, 0)], _kAction),
        rot: _k(q, [(0, 0), (51, 0), (54, -7), (57, 0), (100, 0)], _kAction),
        sx: _k(q, [(0, 1), (49, 1), (51, 1.1), (54, .92), (57, 1.14), (60, .97), (63, 1), (100, 1)], _kAction),
        sy: _k(q, [(0, 1), (49, 1), (51, .9), (54, 1.1), (57, .86), (60, 1.03), (63, 1), (100, 1)], _kAction),
        () => _nigiri(c, 56, const Color(0xFFF2885A), const Color(0xFFFFD2BC),
            look: _k(q, [(0, 0), (21, 0), (24, 2.6), (44, 2.6), (47, 0), (100, 0)], _kSpring),
            wide: 1,
            blink: _k(q, [(0, 1), (9, 1), (10.5, .1), (12, 1), (69, 1), (70.5, .1), (72, 1), (100, 1)], Curves.linear),
            scared: false,
            blush: blush),
      );
    });

    // Atún (B): se echa atrás, salta, lo pellizcan, se escurre y cae.
    final bb = _breath(secs, 2.6, .9);
    _xf(c, const Offset(124, 140), sx: 1 + .02 * bb, sy: 1 + .03 * bb, () {
      _xf(
        c,
        const Offset(124, 140),
        tx: _k(q, [(0, 0), (20, 0), (23, 5), (26, 0), (100, 0)], _kAction),
        ty: _k(q, [(0, 0), (23, 0), (26, -6), (29, 0), (32, -14), (35, -16), (39, 0), (42, -5), (45, 0), (100, 0)], _kAction),
        rot: _k(q, [(0, 0), (32, 0), (35, 9), (39, 0), (100, 0)], _kAction),
        sx: _k(q, [(0, 1), (20, 1), (23, .92), (26, .88), (29, .84), (32, .86), (35, 1), (39, 1.22), (42, .94), (45, 1.04), (48, 1), (100, 1)], _kAction),
        sy: _k(q, [(0, 1), (20, 1), (23, 1.08), (26, 1.12), (29, 1.1), (32, 1.12), (35, 1), (39, .8), (42, 1.06), (45, .97), (48, 1), (100, 1)], _kAction),
        () => _nigiri(c, 124, const Color(0xFFC8323C), const Color(0xFFE87A80),
            look: 0,
            wide: _k(q, [(0, 1), (21, 1), (23, 1.4), (40, 1.4), (44, 1), (100, 1)], _kSpring),
            blink: _k(q, [(0, 1), (13, 1), (14.5, .1), (16, 1), (79, 1), (80.5, .1), (82, 1), (100, 1)], Curves.linear),
            scared: q >= 22 && q < 42,
            blush: blush),
      );
    });

    // Gota de sudor.
    _alpha(c, _k(q, [(0, 0), (24, 0), (27, 1), (37, 1), (39, 0), (100, 0)], Curves.easeIn), () {
      _xf(c, Offset.zero,
          ty: _k(q, [(0, 0), (27, 0), (37, 9), (100, 9)], Curves.easeIn), () {
        _shape(
            c,
            _svg('M150 104 c-2 4 -3 6 -1.6 7.6 c1 1 3.2 1 4.2 0 c1.4 -1.6 .4 -3.6 -2.6 -7.6z'),
            const Color(0xFF8FD0EE),
            sw: 1.2);
      });
    });

    // Palillos: cogen impulso hacia atrás, bajan, pellizcan y se van.
    _xf(
      c,
      Offset.zero,
      tx: _k(q, [(0, 70), (12, 70), (15, 78), (22, 0), (27, 0), (32, 2), (35, 4), (40, 34), (47, 70), (100, 70)], _kAction),
      ty: _k(q, [(0, -92), (12, -92), (15, -100), (22, 0), (27, 5), (32, -10), (35, -14), (40, -54), (47, -92), (100, -92)], _kAction),
      () {
        final stick = _line(const Color(0xFF5A3820), 4.5);
        c.drawLine(const Offset(182, -14), const Offset(128, 98), stick);
        c.drawLine(const Offset(194, -8), const Offset(138, 100), stick);
        final tip = _line(const Color(0xFFC8323C), 5);
        c.drawLine(const Offset(182, -14), const Offset(170, 11), tip);
        c.drawLine(const Offset(194, -8), const Offset(182, 16), tip);
      },
    );
  }
}

// ── Ocasiones especiales: la vela que no se rinde ─────────────────────────

class _CelebracionPainter extends _VignettePainter {
  const _CelebracionPainter(super.scale, super.q);

  static const _confetti = [
    (-46.0, -34.0, 120.0, Color(0xFFE8463A)),
    (-24.0, -48.0, -90.0, Color(0xFFF5B700)),
    (-6.0, -56.0, 200.0, Color(0xFF0085C4)),
    (18.0, -50.0, -160.0, Color(0xFF3E8E3A)),
    (38.0, -40.0, 90.0, Color(0xFFC9A96B)),
    (54.0, -24.0, -120.0, Color(0xFFE8463A)),
  ];

  @override
  void draw(Canvas c) {
    _oval(c, 90, 163, 66, 7, const Color(0x1F3C280A));
    _oval(c, 90, 156, 68, 11, Colors.white, sw: 2.5);

    // Tarta: respingo al reencenderse.
    _xf(
      c,
      const Offset(90, 154),
      sx: _k(q, [(0, 1), (47, 1), (50, 1.04), (53, .98), (56, 1), (100, 1)]),
      sy: _k(q, [(0, 1), (47, 1), (50, .96), (53, 1.02), (56, 1), (100, 1)]),
      () {
        _rrect(c, 34, 118, 112, 36, 9, const Color(0xFFF6C9D2));
        for (final x in [52.0, 76.0, 104.0, 128.0]) {
          _oval(c, x, 136, 3.4, 3.4, const Color(0xFFE8463A), sw: 1.2);
        }
        _rrect(c, 52, 90, 76, 30, 8, const Color(0xFFFBE3E8));
        _shape(
            c,
            _svg('M52 98 q0 -8 8 -8 h60 q8 0 8 8 v3 q-5 6 -10 0 q-5 7 -11 0 '
                'q-5 6 -11 0 q-5 7 -11 0 q-5 6 -11 0 q-5 6 -13 0z'),
            Colors.white,
            sw: 2);
        _rrect(c, 86, 62, 8, 28, 3, const Color(0xFF8FC3E8), sw: 2);
        c.drawPath(_svg('M86 70 l8 -4 M86 78 l8 -4 M86 86 l8 -4'), _line(Colors.white, 2));
        c.drawPath(_svg('M90 62 v-5'), _line(_ink, 2));
      },
    );

    // Soplido.
    _alpha(c, _k(q, [(0, 0), (15, 0), (18, 1), (26, 1), (29, 0), (100, 0)], Curves.easeOut), () {
      _xf(c, Offset.zero,
          tx: _k(q, [(0, -10), (15, -10), (18, 0), (26, 12), (29, 16), (100, 16)], Curves.easeOut), () {
        c.drawPath(
            _svg('M14 40 q12 -6 24 0 t18 0 M8 50 q12 -6 24 0 t22 0 M16 60 q10 -5 20 0 t14 0'),
            _line(const Color(0x613A2418), 2.6));
      });
    });

    // Humo cuando se apaga.
    _alpha(c, _k(q, [(0, 0), (26, 0), (30, 1), (44, 0), (100, 0)], Curves.easeOut), () {
      _xf(c, Offset.zero,
          ty: _k(q, [(0, 0), (26, 0), (44, -18), (100, -18)], Curves.easeOut), () {
        c.drawPath(_svg('M90 54 c-6 -6 6 -12 0 -18 c-6 -6 6 -12 0 -18'),
            _line(const Color(0x593A2418), 3));
      });
    });

    // Llama: baila, resiste el soplido, se apaga y vuelve con rebote.
    final s = _k(q, [(0, 1), (25, 1), (27, 0), (46, 0), (49, 1.35), (52, 1), (100, 1)]);
    if (s > 0.01) {
      _xf(
        c,
        const Offset(90, 57),
        tx: _k(q, [(0, 0), (15, 0), (18, 3), (21, 6), (23, 0), (25, 10), (27, 0), (100, 0)]),
        skx: _k(q, [(0, 0), (4, -4), (8, 3), (12, -2), (15, 0), (18, 16), (21, 24), (23, -10), (25, 30), (27, 0), (58, 0), (62, -4), (66, 3), (70, 0), (100, 0)]),
        sx: s * _k(q, [(0, 1), (15, 1), (18, .95), (21, .9), (23, 1.05), (25, .6), (27, 1), (49, 1), (52, .9), (55, 1.05), (58, 1), (100, 1)]),
        sy: s * _k(q, [(0, 1), (4, 1.04), (8, .97), (12, 1), (15, 1), (18, 1.1), (21, 1.18), (23, .95), (25, 1.3), (27, 1), (49, 1), (52, 1.08), (55, .97), (58, 1), (62, 1.04), (66, .97), (70, 1), (100, 1)]),
        () {
          _shape(
              c,
              _svg('M90 20 C101 34 104 45 99 52 C95 58 85 58 81 52 C76 45 79 34 90 20 Z'),
              const Color(0xFFFFB21E),
              sw: 2,
              stroke: const Color(0xFFD9700E));
          c.drawPath(
              _svg('M90 34 C95 42 96 49 93 53 C91 55 89 55 87 53 C84 49 85 42 90 34Z'),
              _fill(const Color(0xFFFFE58A)));
          final blink = _k(q, [(0, 1), (6, 1), (7.5, .1), (9, 1), (16, 1), (18, .3), (22, .3), (24, 1), (59, 1), (60, .1), (61, 1), (100, 1)], Curves.linear);
          _xf(c, const Offset(90, 45), sy: blink, () {
            c.drawCircle(const Offset(86.5, 45), 1.6, _fill(_ink));
            c.drawCircle(const Offset(93.5, 45), 1.6, _fill(_ink));
          });
          c.drawPath(_svg('M87.5 49.5 q2.5 2 5 0'), _line(_ink, 1.4));
        },
      );
    }

    // Chispa del reencendido.
    _alpha(c, _k(q, [(0, 0), (44, 0), (47, 1), (51, 0), (100, 0)], Curves.easeOut), () {
      final ss = _k(q, [(0, .2), (44, .2), (47, 1.2), (51, .5), (100, .5)], Curves.easeOut);
      _xf(c, const Offset(90, 54),
          rot: _k(q, [(0, 0), (44, 0), (47, 20), (51, 40), (100, 40)]), sx: ss, sy: ss, () {
        c.drawPath(
            _svg('M90 44 v-10 M90 64 v10 M80 54 h-10 M100 54 h10 M83 47 l-6 -6 M97 47 l6 -6'),
            _line(const Color(0xFFF5B700), 2.6));
      });
    });

    // Confeti en arco.
    const arc = Cubic(0.2, 0.7, 0.4, 1);
    for (final (dx, dy, r, color) in _confetti) {
      _alpha(c, _k(q, [(0, 0), (48, 0), (50, 1), (74, 1), (78, 0), (100, 0)], Curves.linear), () {
        _xf(
          c,
          const Offset(90.5, 57.5),
          tx: _k(q, [(0, 0), (50, 0), (58, dx), (74, dx * 1.4), (100, dx * 1.4)], arc),
          ty: _k(q, [(0, 0), (50, 0), (58, dy), (74, dy + 70), (100, dy + 70)], arc),
          rot: _k(q, [(0, 0), (50, 0), (58, r), (74, r * 3), (100, r * 3)], arc),
          () => c.drawRRect(
              RRect.fromRectAndRadius(
                  const Rect.fromLTWH(88, 56, 5, 3), const Radius.circular(1)),
              _fill(color)),
        );
      });
    }
  }
}
