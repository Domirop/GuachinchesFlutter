import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:guachinches/ui/pages/advance_search/widgets/looping_scene.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';

/// «E · Para desayunar · El barraquito» (tablero MotionDesayuno): la
/// cabecera animada de la lista de desayuno. Barra de madera en trapecio con
/// el plato de la pulga (entra deslizándose una vez) y un sobre de azúcar,
/// difuminado en el color de la banda y, encima, el vaso de barraquito que
/// se monta capa a capa (leche condensada → Licor 43 → café → leche →
/// espuma, cada una vertida con un chorro fino de su color), canela, piel de
/// limón, vapor, la cuchara que toca el vaso con una chispa dorada y
/// «¡Buenos días!». Bucle de 10 s.
///
/// Mismo patrón que «Mesa con brindis» ([LoopingScene]): la capa quieta
/// (barra, plato, sobre y difuminado) va en su propia RepaintBoundary y se
/// pinta una vez; el reloj solo corre en los tramos con movimiento.
/// Movimiento reducido: fotograma final (vaso completo, limón, canela y
/// «¡Buenos días!»).
class BarraquitoScene extends LoopingScene {
  /// Color de la banda y tinta del tema (vapor).
  final Color band;
  final Color ink;
  final bool dark;

  /// La escena empieza en y 186 de la cabecera de 370 del tablero (el
  /// vapor sube hasta y ≈ 188) y llega hasta abajo.
  static const double designWidth = 402;
  static const double designTop = 186;
  static const double designHeight = 370 - designTop;

  const BarraquitoScene({
    super.key,
    super.active,
    required this.band,
    required this.ink,
    required this.dark,
  });

  static double heightFor(double width) => designHeight * width / designWidth;

  @override
  State<BarraquitoScene> createState() => BarraquitoSceneState();
}

@visibleForTesting
class BarraquitoSceneState extends LoopingSceneState<BarraquitoScene> {
  @override
  double get designHeight => BarraquitoScene.designHeight;

  @override
  double quietRemaining(double t) => barraquitoQuietRemaining(t);

  @override
  Widget buildLayers(
      BuildContext context, double scale, double? time, bool dark) {
    final plateDone = time == null || time >= _kPlateEnd;
    // Recorte abierto por arriba (el vapor sube por encima de la escena) y
    // cerrado abajo y a los lados (la barra no asoma bajo la cabecera).
    return ClipRect(
      clipper: const _OpenTopClipper(),
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          RepaintBoundary(
            child: CustomPaint(
              painter: BarraquitoBarPainter(
                band: widget.band,
                dark: widget.dark,
                scale: scale,
                plateDone: plateDone,
              ),
            ),
          ),
          RepaintBoundary(
            child: CustomPaint(
              painter: BarraquitoActionPainter(
                band: widget.band,
                ink: widget.ink,
                scale: scale,
                time: time,
                drawPlate: !plateDone,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpenTopClipper extends CustomClipper<Rect> {
  const _OpenTopClipper();

  @override
  Rect getClip(Size size) => Rect.fromLTRB(0, -40, size.width, size.height);

  @override
  bool shouldReclip(covariant CustomClipper<Rect> old) => false;
}

// ── Tiempos (nota del tablero, en segundos) ───────────────────────────────

const double _kLoop = 10;
const double _kPlateStart = 0.3;
const double _kPlateDur = 1.2;
const double _kPlateEnd = _kPlateStart + _kPlateDur; // 1,5 s

/// Tramos con movimiento dentro del bucle: el montaje del barraquito, la
/// canela, el limón, el vapor, la cuchara, la chispa y la etiqueta (0,43–5,6)
/// y la despedida (etiqueta y vaso que se vacía, 8,8–9,45).
const _kActive = [(0.43, 5.6), (8.8, 9.45)];

@visibleForTesting
double barraquitoQuietRemaining(double t) => loopQuietRemaining(t,
    loop: _kLoop, active: _kActive, entranceEnd: _kPlateEnd);

/// Fotogramas clave con el progreso [q] y los tiempos en % del bucle (como
/// los @keyframes del tablero).
double _k(double q, List<(double, double)> stops, Curve curve) =>
    gmKeyframes(q / 100, [for (final (p, v) in stops) (p / 100, v)],
        curve: curve);

const _kSpring = Cubic(0.34, 1.56, 0.64, 1);
const _kEaseOut = Curves.easeOut;
const _kPlateCurve = Cubic(0.3, 0.7, 0.3, 1);
const _kCanelaCurve = Cubic(0.3, 0.7, 0.4, 1);

/// Coordenadas del tablero (cabecera de 370) → escena (empieza en
/// [BarraquitoScene.designTop]).
void _toHeader(Canvas canvas, double scale) {
  canvas.scale(scale);
  canvas.translate(0, -BarraquitoScene.designTop);
}

/// Difuminado de la cabecera compacta: opaco hasta y 236, 0,55 en 266 y
/// nada en 290 (stops sobre los 370 de la cabecera).
Paint _fadePaint(Color band) => Paint()
  ..shader = ui.Gradient.linear(
    Offset.zero,
    const Offset(0, 370),
    [band, band, band.withValues(alpha: 0.55), band.withValues(alpha: 0)],
    const [0, 0.6378, 0.7189, 0.7838],
  );

const Rect _kHeaderRect = Rect.fromLTWH(-30, 0, 470, 372);

Path _barPath() => Path()
  ..moveTo(30, 208)
  ..quadraticBezierTo(115, 204, 201, 206)
  ..quadraticBezierTo(286, 208, 372, 208)
  ..lineTo(430, 370)
  ..quadraticBezierTo(320, 374, 201, 372)
  ..quadraticBezierTo(80, 370, -28, 370)
  ..close();

// ── Plato con la pulga ─────────────────────────────────────────────────────

Path _bunPath() => Path()
  ..moveTo(90, 296)
  ..cubicTo(92, 280, 112, 274, 128, 274)
  ..cubicTo(146, 274, 162, 280, 164, 294)
  ..cubicTo(164, 302, 150, 304, 128, 304)
  ..cubicTo(106, 304, 90, 303, 90, 296)
  ..close();

/// Silueta del plato (para recortar el difuminado mientras entra).
Path _plateOutline() => Path()
  ..addOval(
      Rect.fromCenter(center: const Offset(128, 304), width: 120, height: 30))
  ..addOval(
      Rect.fromCenter(center: const Offset(126, 300), width: 116, height: 30))
  ..addPath(_bunPath(), Offset.zero);

void _paintPlate(Canvas canvas) {
  canvas.drawOval(
      Rect.fromCenter(center: const Offset(128, 304), width: 120, height: 30),
      Paint()..color = const Color.fromRGBO(60, 30, 10, 0.16));
  final plate =
      Rect.fromCenter(center: const Offset(126, 300), width: 116, height: 30);
  canvas.drawOval(plate, Paint()..color = Colors.white);
  canvas.drawOval(
      plate,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0x14000000));
  canvas.drawOval(
      Rect.fromCenter(center: const Offset(126, 300), width: 88, height: 21),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0x0F000000));
  final bun = _bunPath();
  canvas.drawPath(bun, Paint()..color = const Color(0xFFD9A35F));
  canvas.drawPath(
      bun,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = const Color(0xFF8A5A2E));
  canvas.drawPath(
      Path()
        ..moveTo(98, 290)
        ..cubicTo(110, 284, 146, 284, 156, 290),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xCCF2D29A));
  final cut = Paint()
    ..strokeWidth = 1.6
    ..strokeCap = StrokeCap.round
    ..color = const Color(0xFF8A5A2E);
  canvas.drawLine(const Offset(112, 280), const Offset(108, 288), cut);
  canvas.drawLine(const Offset(128, 278), const Offset(124, 287), cut);
  canvas.drawLine(const Offset(144, 280), const Offset(140, 288), cut);
  canvas.drawPath(
      Path()
        ..moveTo(93, 297)
        ..cubicTo(110, 300, 146, 300, 161, 296),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFE9DCC2));
}

// ── Capa quieta: barra, plato, sobre de azúcar y difuminado ───────────────

class BarraquitoBarPainter extends CustomPainter {
  final Color band;
  final bool dark;
  final double scale;
  final bool plateDone;

  BarraquitoBarPainter({
    required this.band,
    required this.dark,
    required this.scale,
    required this.plateDone,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    _toHeader(canvas, scale);
    canvas.drawRect(const Rect.fromLTWH(0, 206, 402, 164),
        Paint()..color = const Color(0xFFB98A5C));
    final bar = _barPath();
    canvas.drawPath(bar, Paint()..color = const Color(0xFFD6A673));
    void grain(Path p, double w, double a) => canvas.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..color = Color.fromRGBO(120, 72, 30, a));
    grain(
        Path()
          ..moveTo(40, 236)
          ..cubicTo(110, 224, 150, 250, 230, 238)
          ..cubicTo(310, 226, 340, 222, 410, 240),
        1.6,
        0.30);
    grain(
        Path()
          ..moveTo(-10, 300)
          ..cubicTo(70, 284, 140, 312, 220, 298)
          ..cubicTo(300, 284, 330, 284, 420, 304),
        2.2,
        0.24);
    grain(
        Path()
          ..moveTo(120, 212)
          ..cubicTo(140, 230, 128, 260, 150, 286),
        1.2,
        0.22);
    canvas.drawPath(
      bar,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 204),
          const Offset(0, 374),
          const [
            Color.fromRGBO(90, 50, 20, 0.20),
            Color.fromRGBO(90, 50, 20, 0)
          ],
          const [0, 0.45],
        ),
    );
    // Noche: velo de banda al 55 % sobre la barra.
    if (dark) {
      canvas.drawPath(bar, Paint()..color = band.withValues(alpha: 0.55));
    }
    if (plateDone) _paintPlate(canvas);
    // Sobre de azúcar.
    canvas.save();
    canvas.translate(196, 318);
    canvas.rotate(-14 * math.pi / 180);
    final sachet = RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 30, 12), const Radius.circular(2));
    canvas.drawRRect(sachet, Paint()..color = const Color(0xFFFFF6E6));
    canvas.drawRRect(
        sachet,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = const Color(0x1F000000));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(0, 0, 7, 12), const Radius.circular(2)),
        Paint()..color = const Color(0xFFC8202C));
    canvas.restore();
    // Difuminado en la capa quieta: no cuesta por fotograma.
    canvas.drawRect(_kHeaderRect, _fadePaint(band));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BarraquitoBarPainter old) =>
      old.band != band ||
      old.dark != dark ||
      old.scale != scale ||
      old.plateDone != plateDone;
}

// ── Capa animada ───────────────────────────────────────────────────────────

/// Capas del barraquito de abajo arriba: (y, alto, color, inicio %, 1,12 %,
/// 0,94 %, final %) — los @keyframes dl1…dl5 del tablero.
const _kLayers = <(double, double, Color, double, double, double, double)>[
  (307, 14.6, Color(0xFFF4EBD8), 4.5, 8.25, 9.5, 11),
  (297, 10.6, Color(0xFFE5A93F), 9.5, 12.87, 14, 15.5),
  (275, 22.6, Color(0xFF5A2E16), 14, 19.62, 21.5, 23),
  (259, 16.6, Color(0xFFE3C9A2), 21.5, 26, 27.5, 29),
  (252, 7.6, Color(0xFFFFF6E6), 27.5, 29.75, 30.5, 32),
];

/// Chorros: (empieza a caer %, deja de caer %, color).
const _kPours = <(double, double, Color)>[
  (4.3, 8.3, Color(0xFFF4EBD8)),
  (9.3, 12.8, Color(0xFFE5A93F)),
  (13.8, 20.3, Color(0xFF5A2E16)),
  (21.3, 26.3, Color(0xFFE3C9A2)),
];

Path _glassPath() => Path()
  ..moveTo(276, 232)
  ..lineTo(316, 232)
  ..lineTo(313, 318)
  ..quadraticBezierTo(296, 322, 279, 318)
  ..close();

class BarraquitoActionPainter extends CustomPainter {
  final Color band;
  final Color ink;
  final double scale;

  /// `null` = fotograma final quieto (movimiento reducido).
  final double? time;
  final bool drawPlate;

  BarraquitoActionPainter({
    required this.band,
    required this.ink,
    required this.scale,
    required this.time,
    required this.drawPlate,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    _toHeader(canvas, scale);
    final t = time;

    // Plato que entra deslizándose (una vez).
    if (drawPlate && t != null) {
      final p = ((t - _kPlateStart) / _kPlateDur).clamp(0.0, 1.0) * 100;
      final tx =
          _k(p, const [(0, -160), (70, 6), (85, -2), (100, 0)], _kPlateCurve);
      final rot =
          _k(p, const [(0, -6), (70, 1), (85, 0), (100, 0)], _kPlateCurve);
      final sx =
          _k(p, const [(0, 1), (70, 1), (85, 1.02), (100, 1)], _kPlateCurve);
      final sy =
          _k(p, const [(0, 1), (70, 1), (85, 0.97), (100, 1)], _kPlateCurve);
      const origin = Offset(128, 319);
      final m = Matrix4.identity()
        ..translateByDouble(origin.dx + tx, origin.dy, 0, 1)
        ..rotateZ(rot * math.pi / 180)
        ..scaleByDouble(sx, sy, 1, 1)
        ..translateByDouble(-origin.dx, -origin.dy, 0, 1);
      canvas.save();
      canvas.transform(m.storage);
      _paintPlate(canvas);
      canvas.restore();
      // El difuminado solo sobre el plato (la barra ya lo lleva).
      canvas.save();
      canvas.clipPath(_plateOutline().transform(m.storage));
      canvas.drawRect(_kHeaderRect, _fadePaint(band));
      canvas.restore();
    }

    // En reposo y con movimiento reducido: el fotograma del 60 % (todo
    // montado, sin vapor ni chispa, con «¡Buenos días!»).
    final q = t == null ? 60.0 : (t % _kLoop) / _kLoop * 100;

    // Platillo.
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(298, 324), width: 76, height: 18),
        Paint()..color = const Color.fromRGBO(60, 30, 10, 0.18));
    final saucer =
        Rect.fromCenter(center: const Offset(296, 321), width: 72, height: 18);
    canvas.drawOval(saucer, Paint()..color = Colors.white);
    canvas.drawOval(
        saucer,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = const Color(0x1A000000));
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(296, 321), width: 48, height: 11),
        Paint()
          ..style = PaintingStyle.stroke
          ..color = const Color(0x12000000));

    // Cuchara: gira, toca el vaso y vuelve.
    final spoon = _k(
        q,
        const [
          (0, 0),
          (35.5, 0),
          (37.5, -16),
          (38.5, -24),
          (40.5, 3),
          (42.5, 0),
          (100, 0)
        ],
        Curves.easeInOut);
    canvas.save();
    canvas.translate(314, 324);
    canvas.rotate(spoon * math.pi / 180);
    canvas.rotate(-8 * math.pi / 180);
    final handle = RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, -1.6, 30, 3.2), const Radius.circular(1.6));
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = const Color(0xFF7E786F);
    canvas.drawRRect(handle, Paint()..color = const Color(0xFFB9B4AC));
    canvas.drawRRect(handle, edge);
    final bowl =
        Rect.fromCenter(center: const Offset(34, 0), width: 12, height: 7.2);
    canvas.drawOval(bowl, Paint()..color = const Color(0xFFC9C4BC));
    canvas.drawOval(bowl, edge);
    canvas.restore();

    // Chorro fino del color de la capa que se vierte.
    if (t != null) {
      for (final (a, b, color) in _kPours) {
        double sy, ty, op;
        if (q < a || q > b + 1) continue;
        if (q < a + 1) {
          sy = (q - a);
          ty = 0;
          op = 1;
        } else if (q <= b) {
          sy = 1;
          ty = 0;
          op = 1;
        } else {
          final k = q - b;
          sy = 1 - 0.8 * k;
          ty = -40 * k;
          op = 1 - k;
        }
        if (sy <= 0 || op <= 0) continue;
        // Rect 294,5 · 200 · 3 × 118, origen arriba; máscara que funde los
        // primeros 23 px (fija en la cabecera).
        final top = 200 + ty;
        final rect = Rect.fromLTWH(294.5, top, 3, 118 * sy);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(1.5)),
          Paint()
            ..shader = ui.Gradient.linear(
              const Offset(0, 200),
              const Offset(0, 223.4),
              [color.withValues(alpha: 0), color.withValues(alpha: op)],
            ),
        );
      }
    }

    // El vaso: cinco capas recortadas por la silueta y escaladas en Y
    // desde su base.
    final glass = _glassPath();
    canvas.save();
    canvas.clipPath(glass);
    for (final (y, h, color, a, peak, dip, end) in _kLayers) {
      final sy = _k(
          q,
          [
            (0, 0),
            (a, 0),
            (peak, 1.12),
            (dip, 0.94),
            (end, 1),
            (90, 1),
            (94.5, 1),
            (100, 0),
          ],
          _kSpring);
      final op = _k(q, const [(0, 1), (90, 1), (94.5, 0), (100, 0)], _kSpring)
          .clamp(0.0, 1.0);
      if (sy <= 0.001 || op <= 0.001) continue;
      final bottom = y + h;
      canvas.drawRect(Rect.fromLTRB(270, bottom - h * sy, 322, bottom),
          Paint()..color = color.withValues(alpha: op));
    }
    // Canela que cae sobre la espuma.
    final canTy = _k(
        q,
        const [
          (0, -14),
          (30.5, -14),
          (32.5, 1),
          (33.5, 0),
          (90, 0),
          (100, -14)
        ],
        _kCanelaCurve);
    final canOp = _k(
            q,
            const [(0, 0), (30.5, 0), (32.5, 1), (90, 1), (94.5, 0), (100, 0)],
            _kCanelaCurve)
        .clamp(0.0, 1.0);
    if (canOp > 0.01) {
      final dot = Paint()
        ..color = const Color(0xFF8A4A1E).withValues(alpha: canOp);
      for (final (x, y) in const [
        (287.0, 256.0),
        (292.0, 257.5),
        (297.0, 255.5),
        (302.0, 257.0),
        (306.0, 256.2),
        (295.0, 258.5),
      ]) {
        canvas.drawCircle(Offset(x, y + canTy), 1.1, dot);
      }
    }
    canvas.restore();

    // Cristal, borde y brillo.
    canvas.drawPath(glass, Paint()..color = const Color(0x38FFFFFF));
    canvas.drawPath(
        glass,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeJoin = StrokeJoin.round
          ..color = const Color(0xFF2A1A12));
    final rim =
        Rect.fromCenter(center: const Offset(296, 232), width: 40, height: 6);
    canvas.drawOval(rim, Paint()..color = const Color(0x4DFFFFFF));
    canvas.drawOval(
        rim,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFF2A1A12));
    canvas.drawLine(
        const Offset(283, 240),
        const Offset(285, 310),
        Paint()
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xBFFFFFFF));

    // Piel de limón en el borde, con rebote.
    final limTy = _k(
        q, const [(0, -30), (31, -30), (33.5, 2), (35, 0), (100, 0)], _kSpring);
    final limRot = _k(
        q, const [(0, -60), (31, -60), (33.5, 8), (35, 0), (100, 0)], _kSpring);
    final limOp = _k(
            q,
            const [(0, 0), (31, 0), (33.5, 1), (90, 1), (94.5, 0), (100, 0)],
            _kSpring)
        .clamp(0.0, 1.0);
    if (limOp > 0.01) {
      canvas.save();
      canvas.translate(316, 244 + limTy);
      canvas.rotate(limRot * math.pi / 180);
      canvas.translate(-316, -244);
      final lemon = Path()
        ..moveTo(308, 236)
        ..cubicTo(314, 224, 324, 226, 322, 238)
        ..cubicTo(320, 244, 314, 242, 312, 236)
        ..close();
      canvas.drawPath(lemon,
          Paint()..color = const Color(0xFFF5D33B).withValues(alpha: limOp));
      canvas.drawPath(
          lemon,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = const Color(0xFFC9A21A).withValues(alpha: limOp));
      canvas.restore();
    }

    // Voluta de vapor que se desvanece.
    if (t != null) {
      final stOp = _k(q, const [(0, 0), (33, 0), (39, 0.8), (56, 0), (100, 0)],
              _kEaseOut)
          .clamp(0.0, 1.0);
      if (stOp > 0.01) {
        final stTy =
            _k(q, const [(0, 6), (33, 6), (56, -20), (100, -20)], _kEaseOut);
        final stSx = _k(
            q, const [(0, 0.8), (33, 0.8), (56, 1.25), (100, 1.25)], _kEaseOut);
        canvas.save();
        canvas.translate(296, 228 + stTy);
        canvas.scale(stSx, 1);
        canvas.translate(-296, -228);
        Paint steam(double a) => Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = ink.withValues(alpha: a * stOp);
        canvas.drawPath(
            Path()
              ..moveTo(290, 226)
              ..relativeCubicTo(-6, -8, 6, -12, 0, -20)
              ..relativeCubicTo(-6, -8, 4, -12, 0, -18),
            steam(0.45));
        canvas.drawPath(
            Path()
              ..moveTo(302, 228)
              ..relativeCubicTo(-6, -8, 6, -12, 0, -20),
            steam(0.35));
        canvas.restore();
      }

      // Chispa dorada cuando la cuchara toca el vaso.
      final spOp = _k(
              q,
              const [(0, 0), (38.2, 0), (39, 1), (43.5, 0), (100, 0)],
              _kEaseOut)
          .clamp(0.0, 1.0);
      if (spOp > 0.01) {
        final spSc = _k(
            q,
            const [(0, 0.2), (38.2, 0.2), (39, 1), (43.5, 1.5), (100, 1.5)],
            _kEaseOut);
        canvas.save();
        canvas.translate(329.5, 298);
        canvas.scale(spSc);
        canvas.translate(-7.5, 2);
        final p = Paint()
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFFE3A21A).withValues(alpha: spOp);
        canvas.drawLine(const Offset(0, -8), const Offset(0, -16), p);
        canvas.drawLine(const Offset(6, -6), const Offset(12, -12), p);
        canvas.drawLine(const Offset(8, 0), const Offset(15, 0), p);
        canvas.drawLine(const Offset(6, 6), const Offset(12, 12), p);
        canvas.restore();
      }
    }

    // «¡Buenos días!» con rebote.
    final tagOp = _k(
            q,
            const [(0, 0), (39.5, 0), (42, 1), (88, 1), (91, 0), (100, 0)],
            _kSpring)
        .clamp(0.0, 1.0);
    if (tagOp > 0.01) {
      final ty = _k(q, const [(0, 10), (39.5, 10), (42, -4), (44, 0), (100, 0)],
          _kSpring);
      final sc = _k(
          q,
          const [(0, 0.6), (39.5, 0.6), (42, 1.08), (44, 1), (100, 1)],
          _kSpring);
      final rot = _k(q,
          const [(0, -8), (39.5, -8), (42, -3), (44, -5), (100, -5)], _kSpring);
      _tag(canvas, ty, sc, rot, tagOp);
    }
    canvas.restore();
  }

  void _tag(Canvas canvas, double ty, double sc, double rotDeg, double op) {
    final tp = TextPainter(
      text: TextSpan(
        text: '¡Buenos días!',
        style: TextStyle(
          fontSize: 15,
          height: 1,
          fontWeight: FontWeight.w800,
          color: const Color(0xFFE8CF9A).withValues(alpha: op),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final w = tp.width + 26;
    const h = 30.0;
    // left 136, top 238; origen abajo al centro.
    final origin = Offset(136 + w / 2, 238 + h);
    canvas.save();
    canvas.translate(origin.dx, origin.dy + ty);
    canvas.rotate(rotDeg * math.pi / 180);
    canvas.scale(sc);
    final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(-w / 2, -h, w, h), const Radius.circular(h / 2));
    canvas.drawRRect(
        r.shift(const Offset(0, 6)),
        Paint()
          ..color = Color.fromRGBO(42, 14, 20, 0.35 * op)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
    canvas.drawRRect(
        r, Paint()..color = const Color(0xFF2A0E14).withValues(alpha: op));
    tp.paint(canvas, Offset(-tp.width / 2, -h / 2 - tp.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BarraquitoActionPainter old) =>
      old.time != time ||
      old.band != band ||
      old.ink != ink ||
      old.scale != scale ||
      old.drawPlate != drawPlate;
}
