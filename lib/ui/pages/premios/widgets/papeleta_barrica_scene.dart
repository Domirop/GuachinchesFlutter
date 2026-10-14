import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guachinches/ui/pages/advance_search/widgets/looping_scene.dart';
import 'package:guachinches/ui/pages/premios/premios_models.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart' show GmGinghamPainter;

/// «F · La papeleta a la barrica» (tablero EncuestaEntrada): la cabecera de
/// 370 de la encuesta. Banda vino, mesa de madera con mantel de cuadros en
/// trapecio y un lápiz quieto; la barrica de roble con el año en tiza y la
/// escarapela de oro llega rodando una vez; la papeleta entra en arco, se
/// dobla, se agacha y cae por el hueco; la barrica se aplasta, salta una
/// chispa dorada y aparece «¡Ese es el mío!». Bucle de 10 s.
///
/// Mismo patrón que «Mesa con brindis» y «El barraquito» ([LoopingScene]):
/// - capa quieta (banda, mesa, mantel, lápiz, velo de noche y difuminado)
///   en su RepaintBoundary: se pinta una vez;
/// - barrica grabada en un `Picture` por tema y año (solo se escala desde la
///   base);
/// - el reloj duerme en el reposo (3,8–8,8 s) y se para fuera de pantalla;
/// - «reducir movimiento»: barrica quieta, etiqueta visible y sin papeleta
///   (ya está dentro).
class PapeletaBarricaScene extends LoopingScene {
  static const double designWidth = 402;
  static const double designHeight = 370;

  const PapeletaBarricaScene({super.key, super.active});

  static double heightFor(double width) => designHeight * width / designWidth;

  @override
  State<PapeletaBarricaScene> createState() => PapeletaBarricaSceneState();
}

@visibleForTesting
class PapeletaBarricaSceneState
    extends LoopingSceneState<PapeletaBarricaScene> {
  @override
  double get designHeight => PapeletaBarricaScene.designHeight;

  @override
  double quietRemaining(double t) => papeletaQuietRemaining(t);

  @override
  Widget buildLayers(
          BuildContext context, double scale, double? time, bool dark) =>
      _withEditionYear((year) =>
          _layers(PremiosSceneColors.of(dark, year: year), scale, time));

  Widget _layers(PremiosSceneColors colors, double scale, double? time) {
    final q = time == null ? null : (time % _kLoop) / _kLoop * 100;
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: CustomPaint(
              painter: PremiosTablePainter(
                  colors: colors, scale: scale, pencil: true),
            ),
          ),
          RepaintBoundary(
            child: CustomPaint(
              painter: PapeletaActionPainter(
                  colors: colors, scale: scale, time: time),
            ),
          ),
          _DesignBox(
            scale: scale,
            child: _SceneLabel(q: q),
          ),
        ],
      ),
    );
  }
}

// ── Tiempos (notas del lienzo, `encuestaMotion`) ───────────────────────────

const double _kLoop = 10;
const double _kRollStart = 0.3;
const double _kRollDur = 1.1;
const double _kRollEnd = _kRollStart + _kRollDur; // 1,4 s

/// Tramos con movimiento dentro del bucle (s): la papeleta entra, se dobla
/// y cae, la barrica se aplasta y sale la etiqueta (1,5–3,8); la etiqueta se
/// desvanece (8,8–9,15). El resto es reposo.
const _kActive = [(1.5, 3.8), (8.8, 9.15)];

@visibleForTesting
double papeletaQuietRemaining(double t) => loopQuietRemaining(t,
    loop: _kLoop, active: _kActive, entranceEnd: _kRollEnd);

// ── Colores ────────────────────────────────────────────────────────────────

@immutable
class PremiosSceneColors {
  /// Banda vino (de noche un punto más honda).
  final Color band;

  /// Velo de banda sobre la mesa (0 de día, 0,5 de noche).
  final double veil;

  /// Brillo de la barrica (0,84 de noche).
  final double barDim;
  final bool dark;

  /// El año de la edición en tiza sobre la barrica (vacío sin edición).
  final String chalk;

  const PremiosSceneColors._(this.band, this.veil, this.barDim, this.dark,
      [this.chalk = '']);

  static const day = PremiosSceneColors._(Color(0xFF2A0E14), 0, 1, false);
  static const night = PremiosSceneColors._(Color(0xFF1E0A0F), 0.5, 0.84, true);

  static PremiosSceneColors of(bool dark, {int? year}) {
    final base = dark ? night : day;
    if (year == null) return base;
    return PremiosSceneColors._(
        base.band, base.veil, base.barDim, base.dark, '$year');
  }

  @override
  bool operator ==(Object other) =>
      other is PremiosSceneColors && other.dark == dark && other.chalk == chalk;

  @override
  int get hashCode => Object.hash(dark, chalk);
}

/// Construye con el año de la edición en curso (para la tiza de la
/// barrica), al día si la edición cambia.
Widget _withEditionYear(Widget Function(int? year) builder) =>
    ValueListenableBuilder<PremiosEdition>(
      valueListenable: PremiosEditionStore.instance,
      builder: (_, e, __) => builder(e.year),
    );

// ── Geometría (tablero 402 × 370) ──────────────────────────────────────────

const double _cx = 318; // centro de la barrica
const double _base = 314;
const double _top = _base - 92; // tapa (222)
const double _clipY = _top + 1; // la papeleta se recorta aquí
const Offset _papCenter = Offset(_cx, 188);
const Offset _papFoldOrigin = Offset(_cx, 168);
const Offset _barrelFoot = Offset(_cx, 316);
const Offset _medalHook = Offset(_cx + 27, _top + 23);
const Offset _sparkFoot = Offset(_cx + 3, _top - 2);

Path _clothPath() => Path()
  ..moveTo(30, 208)
  ..quadraticBezierTo(115, 204, 201, 206)
  ..quadraticBezierTo(286, 208, 372, 208)
  ..lineTo(432, 372)
  ..quadraticBezierTo(320, 376, 201, 374)
  ..quadraticBezierTo(80, 372, -30, 372)
  ..close();

/// Rojo del mantel de la escena (rgba(200,32,44,.55)).
const Color kPremiosClothRed = Color(0x8CC8202C);

// ── Capa quieta ────────────────────────────────────────────────────────────

/// Banda, mesa de madera, mantel en trapecio con sombra de profundidad,
/// lápiz, velo de noche y el difuminado del color de la banda (alfa 1 hasta
/// y 236, 0,55 en 266 y 0 en 290).
class PremiosTablePainter extends CustomPainter {
  final PremiosSceneColors colors;
  final double scale;
  final bool pencil;

  const PremiosTablePainter({
    required this.colors,
    required this.scale,
    this.pencil = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(scale);
    final band = colors.band;
    canvas.drawRect(const Rect.fromLTWH(0, 0, 402, 370), Paint()..color = band);
    canvas.drawRect(const Rect.fromLTWH(0, 200, 402, 170),
        Paint()..color = const Color(0xFF6B3F24));
    canvas.drawPath(
      Path()
        ..moveTo(0, 214)
        ..quadraticBezierTo(120, 210, 230, 216)
        ..quadraticBezierTo(340, 222, 402, 212),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0x2E000000),
    );
    final cloth = _clothPath();
    // Vichy de 16 desplazado 9 px, como el `pattern` del tablero.
    GmGinghamPainter.paintCells(canvas, const Rect.fromLTRB(-30, 204, 432, 376),
        cell: 8,
        stripe: kPremiosClothRed,
        phase: const Offset(9, 0),
        clip: cloth);
    canvas.drawPath(
      cloth,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 204),
          const Offset(0, 376),
          const [Color(0x4D3C0A10), Color(0x003C0A10)],
          const [0, 0.5],
        ),
    );
    if (pencil) _pencil(canvas);
    if (colors.veil > 0) {
      canvas.drawRect(const Rect.fromLTWH(0, 200, 402, 170),
          Paint()..color = band.withValues(alpha: colors.veil));
    }
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 402, 370),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          const Offset(0, 370),
          [band, band, band.withValues(alpha: 0.55), band.withValues(alpha: 0)],
          const [0, 0.6378, 0.7189, 0.7838],
        ),
    );
    canvas.restore();
  }

  void _pencil(Canvas canvas) {
    canvas.save();
    canvas.translate(46, 298);
    canvas.rotate(-12 * math.pi / 180);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(0, 6, 52, 3), const Radius.circular(1.5)),
        Paint()..color = const Color(0x383C0A10));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(0, 0, 52, 6), const Radius.circular(1.6)),
        Paint()..color = const Color(0xFFE9B23B));
    canvas.drawPath(
        Path()
          ..moveTo(52, 0)
          ..lineTo(61, 3)
          ..lineTo(52, 6)
          ..close(),
        Paint()..color = const Color(0xFFE9C9A0));
    canvas.drawPath(
        Path()
          ..moveTo(57.5, 1.8)
          ..lineTo(61, 3)
          ..lineTo(57.5, 4.2)
          ..close(),
        Paint()..color = const Color(0xFF2A0E14));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-6, 0, 6, 6), const Radius.circular(1.2)),
        Paint()..color = const Color(0xFFD8828E));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PremiosTablePainter old) =>
      old.colors != colors || old.scale != scale || old.pencil != pencil;
}

// ── Barrica grabada (una vez por tema y año) ───────────────────────────────

class _Barrel {
  final ui.Picture body;
  final ui.Picture medal;
  const _Barrel(this.body, this.medal);

  static final Map<PremiosSceneColors, _Barrel> _cache = {};

  static _Barrel of(PremiosSceneColors c) =>
      _cache.putIfAbsent(c, () => _Barrel(_body(c), _medal(c)));

  /// Brillo de la barrica (filtro `brightness(.84)` de noche).
  static void _dim(Canvas canvas, double k) {
    if (k == 1) return;
    canvas.saveLayer(
      null,
      Paint()
        ..colorFilter = ColorFilter.matrix(<double>[
          k, 0, 0, 0, 0, //
          0, k, 0, 0, 0, //
          0, 0, k, 0, 0, //
          0, 0, 0, 1, 0,
        ]),
    );
  }

  static ui.Picture _body(PremiosSceneColors c) {
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);
    _dim(canvas, c.barDim);
    const l = _cx - 32, r = _cx + 32;
    final body = Path()
      ..moveTo(l, _top + 10)
      ..cubicTo(l - 11, _top + 34, l - 11, _base - 26, l, _base - 4)
      ..quadraticBezierTo(_cx, _base + 4, r, _base - 4)
      ..cubicTo(r + 11, _base - 26, r + 11, _top + 34, r, _top + 10)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(l - 8, 0),
          const Offset(r + 8, 0),
          const [
            Color(0xFF7A4524),
            Color(0xFFC98D52),
            Color(0xFFB57A43),
            Color(0xFF7A4524),
          ],
          const [0, 0.32, 0.55, 1],
        ),
    );
    canvas.drawPath(
        body,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeJoin = StrokeJoin.round
          ..color = const Color(0xFF4A2812));
    final stave = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = const Color(0x6B46240E);
    for (final dx in const [-22.0, -11.0, 0.0, 11.0, 22.0]) {
      canvas.drawPath(
          Path()
            ..moveTo(_cx + dx, _top + 12)
            ..quadraticBezierTo(
                _cx + dx * 1.24, (_top + _base) / 2, _cx + dx, _base - 2),
          stave);
    }
    void hoop(double y, double w) {
      canvas.drawPath(
          Path()
            ..moveTo(_cx - w, y)
            ..quadraticBezierTo(_cx, y + 8, _cx + w, y),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5.5
            ..strokeCap = StrokeCap.round
            ..color = const Color(0xFF2B211C));
      canvas.drawPath(
          Path()
            ..moveTo(_cx - w + 3, y - 1.6)
            ..quadraticBezierTo(_cx, y + 5.6, _cx + w - 3, y - 1.6),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = const Color(0x52FFF0DC));
    }

    hoop(_top + 20, 35);
    hoop(_base - 18, 36);

    // El año de la edición en tiza, girado −4° (sin edición, sin año).
    if (c.chalk.isNotEmpty) {
      final tp = TextPainter(
        text: TextSpan(
          text: c.chalk,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
            color: Color(0xEBFFF3DE),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.save();
      canvas.translate(_cx - 8, (_top + _base) / 2 + 7);
      canvas.rotate(-4 * math.pi / 180);
      tp.paint(
          canvas,
          Offset(-tp.width / 2,
              6 - tp.computeDistanceToActualBaseline(TextBaseline.alphabetic)));
      tp.dispose();
      canvas.restore();
    }

    // Tapa con el hueco.
    final lid = Rect.fromCenter(
        center: const Offset(_cx, _top + 8), width: 64, height: 15);
    canvas.drawOval(lid, Paint()..color = const Color(0xFFD9A066));
    canvas.drawOval(
        lid,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const Color(0xFF4A2812));
    canvas.drawOval(
        Rect.fromCenter(
            center: const Offset(_cx, _top + 8.6), width: 53, height: 10.8),
        Paint()..color = const Color(0xFFC2884F));
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(_cx - 13, _top + 6.2, 26, 5),
            const Radius.circular(2.5)),
        Paint()..color = const Color(0xFF2A0E14));
    if (c.barDim != 1) canvas.restore();
    return rec.endRecording();
  }

  /// Escarapela de oro colgada del aro (se balancea en la celebración).
  static ui.Picture _medal(PremiosSceneColors c) {
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);
    _dim(canvas, c.barDim);
    paintPremiosMedal(canvas, const Offset(_cx + 27, _top + 45));
    if (c.barDim != 1) canvas.restore();
    return rec.endRecording();
  }
}

/// Escarapela pequeña: dos cintas vino y disco de oro con estrella crema.
/// [center] = centro del disco (radio 9).
void paintPremiosMedal(Canvas canvas, Offset center) {
  final x = center.dx, y = center.dy - 45;
  canvas.drawPath(
      Path()
        ..moveTo(x - 2, y + 23)
        ..lineTo(x - 6, y + 44)
        ..lineTo(x - 2, y + 40)
        ..lineTo(x + 1, y + 44)
        ..close(),
      Paint()..color = const Color(0xFF7A1E2C));
  canvas.drawPath(
      Path()
        ..moveTo(x, y + 23)
        ..lineTo(x + 6, y + 43)
        ..lineTo(x + 2, y + 41)
        ..lineTo(x - 1, y + 44)
        ..close(),
      Paint()..color = const Color(0xFFA02A3C));
  final disc = Rect.fromCircle(center: center, radius: 9);
  canvas.drawCircle(center, 9, Paint()..shader = premiosGoldShader(disc));
  canvas.drawCircle(
      center,
      9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFF8A6A2E));
  canvas.drawPath(premiosStarPath(Offset(center.dx, center.dy - 5.2), 1),
      Paint()..color = GmColors.creamHi);
}

/// Degradado de oro de las escarapelas (cx .35, cy .3, r .8 del tablero).
Shader premiosGoldShader(Rect r) => ui.Gradient.radial(
      Offset(r.left + r.width * 0.35, r.top + r.height * 0.3),
      r.width * 0.8,
      const [Color(0xFFF7E6B5), Color(0xFFD6B675), Color(0xFFA9823F)],
      const [0, 0.55, 1],
    );

/// Estrella de cinco puntas del tablero (`l1.5 3.1 3.4.5…`) con la punta
/// en [tip], escalada por [k].
Path premiosStarPath(Offset tip, double k) {
  const d = [
    (1.5, 3.1), (3.4, 0.5), (-2.5, 2.4), (0.6, 3.4), (-3.0, -1.6), //
    (-3.0, 1.6), (0.6, -3.4), (-2.5, -2.4), (3.4, -0.5),
  ];
  final p = Path()..moveTo(tip.dx, tip.dy);
  var x = tip.dx, y = tip.dy;
  for (final (dx, dy) in d) {
    x += dx * k;
    y += dy * k;
    p.lineTo(x, y);
  }
  return p..close();
}

// ── Papeleta y chispa ──────────────────────────────────────────────────────

void _paintPapeleta(Canvas canvas, double crease) {
  const x0 = _cx - 16, y0 = 168.0;
  final card = RRect.fromRectAndRadius(
      const Rect.fromLTWH(x0, y0, 32, 40), const Radius.circular(3));
  canvas.drawRRect(card, Paint()..color = const Color(0xFFFFFDF8));
  canvas.drawRRect(
      card,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0x472A0E14));
  canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(x0 + 6, y0 + 6, 18, 3),
          const Radius.circular(1.5)),
      Paint()..color = GmColors.gold);
  canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(x0 + 5, y0 + 14, 9, 9),
          const Radius.circular(1.6)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFF7A1E2C));
  canvas.drawPath(
      Path()
        ..moveTo(x0 + 6.6, y0 + 18.4)
        ..relativeLineTo(2.2, 2.2)
        ..relativeLineTo(4.4, -5.2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF7A1E2C));
  canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(x0 + 17, y0 + 16, 8, 2.2),
          const Radius.circular(1.1)),
      Paint()..color = const Color(0x472A0E14));
  canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(x0 + 5, y0 + 28, 20, 2.2),
          const Radius.circular(1.1)),
      Paint()..color = const Color(0x332A0E14));
  if (crease > 0.01) {
    canvas.drawRect(const Rect.fromLTWH(x0, y0 + 18, 32, 2),
        Paint()..color = Color.fromRGBO(42, 14, 20, 0.30 * crease));
  }
}

void _paintSpark(Canvas canvas, double scale, double opacity) {
  if (opacity <= 0.01) return;
  canvas.save();
  canvas.translate(_sparkFoot.dx, _sparkFoot.dy);
  canvas.scale(scale);
  canvas.translate(-_sparkFoot.dx, -_sparkFoot.dy);
  final c = const Color(0xFFF2CF7E).withValues(alpha: opacity);
  final p = Paint()
    ..color = c
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;
  const o = Offset(_cx, _top - 4);
  for (final (a, b) in const [
    (Offset(0, -10), Offset(0, -22)),
    (Offset(9, -7), Offset(17, -15)),
    (Offset(-9, -7), Offset(-17, -15)),
    (Offset(13, 1), Offset(23, 1)),
    (Offset(-13, 1), Offset(-23, 1)),
  ]) {
    canvas.drawLine(o + a, o + b, p);
  }
  canvas.drawPath(
      Path()
        ..moveTo(_cx + 26, _top - 30)
        ..relativeLineTo(1.6, 3.4)
        ..relativeLineTo(3.4, 1.6)
        ..relativeLineTo(-3.4, 1.6)
        ..relativeLineTo(-1.6, 3.4)
        ..relativeLineTo(-1.6, -3.4)
        ..relativeLineTo(-3.4, -1.6)
        ..relativeLineTo(3.4, -1.6)
        ..close(),
      Paint()..color = c);
  canvas.restore();
}

/// Barrica (sombra, cuerpo y escarapela) con el aplastamiento desde la base.
void _paintBarrel(Canvas canvas, PremiosSceneColors colors,
    {double rollX = 0,
    double rollDeg = 0,
    double sx = 1,
    double sy = 1,
    double shadowSx = 1,
    double medalDeg = 0}) {
  final b = _Barrel.of(colors);
  canvas.save();
  if (rollX != 0 || rollDeg != 0) {
    canvas.translate(_barrelFoot.dx + rollX, _barrelFoot.dy);
    canvas.rotate(rollDeg * math.pi / 180);
    canvas.translate(-_barrelFoot.dx, -_barrelFoot.dy);
  }
  canvas.save();
  canvas.translate(_cx, _base + 1);
  canvas.scale(shadowSx, 1);
  canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 84, height: 13),
      Paint()..color = const Color(0x6128080E));
  canvas.restore();
  canvas.save();
  if (sx != 1 || sy != 1) {
    canvas.translate(_barrelFoot.dx, _barrelFoot.dy);
    canvas.scale(sx, sy);
    canvas.translate(-_barrelFoot.dx, -_barrelFoot.dy);
  }
  canvas.drawPicture(b.body);
  if (medalDeg != 0) {
    canvas.translate(_medalHook.dx, _medalHook.dy);
    canvas.rotate(medalDeg * math.pi / 180);
    canvas.translate(-_medalHook.dx, -_medalHook.dy);
  }
  canvas.drawPicture(b.medal);
  canvas.restore();
  canvas.restore();
}

/// Fotogramas clave en % (como los @keyframes del tablero).
double _k(double q, List<(double, double)> stops, Curve curve) =>
    gmKeyframes(q / 100, [for (final (p, v) in stops) (p / 100, v)],
        curve: curve);

const _kStd = Cubic(0.4, 0, 0.2, 1);
const _kRoll = Cubic(0.3, 0.7, 0.3, 1);
const _kDrop = Cubic(0.45, 0, 0.9, 0.55);

/// Papeleta, barrica y chispa del bucle. [time] `null` = fotograma final.
class PapeletaActionPainter extends CustomPainter {
  final PremiosSceneColors colors;
  final double scale;
  final double? time;

  const PapeletaActionPainter({
    required this.colors,
    required this.scale,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(scale);
    final t = time;
    if (t == null) {
      _paintBarrel(canvas, colors);
      canvas.restore();
      return;
    }
    final q = (t % _kLoop) / _kLoop * 100;

    // Papeleta: arco, pliegue, anticipación y caída por el hueco.
    if (t >= _kRollEnd && q < 33.05) {
      final tx = _k(q,
          const [(0, 124), (15, 124), (18.8, 52), (22.4, 0), (100, 0)], _kStd);
      final ty = _k(q,
          const [(0, -34), (15, -34), (18.8, -50), (22.4, 0), (100, 0)], _kStd);
      final rot = _k(
          q,
          const [
            (0, 28),
            (15, 28),
            (18.8, 12),
            (22.4, -7),
            (24, 3),
            (25.4, 0),
            (100, 0)
          ],
          _kStd);
      final fold = _k(
          q,
          const [
            (0, 1),
            (25.6, 1),
            (27.4, 0.5),
            (28.2, 0.57),
            (29, 0.52),
            (100, 0.52)
          ],
          GmMotion.spring);
      final crease =
          _k(q, const [(0, 0), (26.4, 0), (27.4, 1), (100, 1)], Curves.linear);
      final dy = _k(q,
          const [(0, 0), (28.6, 0), (29.8, -8), (31.6, 64), (100, 64)], _kDrop);
      final dsx = _k(
          q,
          const [(0, 1), (28.6, 1), (29.8, 1.1), (31.6, 0.74), (100, 0.74)],
          _kDrop);
      final dsy = _k(
          q,
          const [(0, 1), (28.6, 1), (29.8, 0.88), (31.6, 1.22), (100, 1.22)],
          _kDrop);
      canvas.save();
      canvas.clipRect(const Rect.fromLTWH(0, 0, 402, _clipY));
      canvas.translate(_papCenter.dx + tx, _papCenter.dy + ty);
      canvas.rotate(rot * math.pi / 180);
      canvas.translate(0, dy);
      canvas.scale(dsx, dsy);
      canvas.translate(-_papCenter.dx, -_papCenter.dy);
      canvas.translate(_papFoldOrigin.dx, _papFoldOrigin.dy);
      canvas.scale(1, fold);
      canvas.translate(-_papFoldOrigin.dx, -_papFoldOrigin.dy);
      _paintPapeleta(canvas, crease);
      canvas.restore();
    }

    // Barrica: llega rodando una vez; luego se aplasta al tragarse la papeleta.
    var rollX = 0.0, rollDeg = 0.0;
    if (t < _kRollEnd) {
      final p = ((t - _kRollStart) / _kRollDur).clamp(0.0, 1.0) * 100;
      rollX = _k(p, const [(0, 150), (55, -8), (78, 3), (100, 0)], _kRoll);
      rollDeg = _k(p, const [(0, 16), (55, -5), (78, 2), (100, 0)], _kRoll);
    }
    final inLoop = t >= _kRollEnd;
    final sx = inLoop
        ? _k(
            q,
            const [
              (0, 1),
              (31.2, 1),
              (32.3, 1.12),
              (33.7, 0.95),
              (35.1, 1.03),
              (36.6, 1),
              (100, 1)
            ],
            GmMotion.spring)
        : 1.0;
    final sy = inLoop
        ? _k(
            q,
            const [
              (0, 1),
              (31.2, 1),
              (32.3, 0.86),
              (33.7, 1.07),
              (35.1, 0.98),
              (36.6, 1),
              (100, 1)
            ],
            GmMotion.spring)
        : 1.0;
    final shSx = inLoop
        ? _k(
            q,
            const [
              (0, 1),
              (31.2, 1),
              (32.3, 1.16),
              (33.7, 0.94),
              (36.6, 1),
              (100, 1)
            ],
            GmMotion.spring)
        : 1.0;
    _paintBarrel(canvas, colors,
        rollX: rollX, rollDeg: rollDeg, sx: sx, sy: sy, shadowSx: shSx);

    // Chispa dorada del hueco.
    if (inLoop) {
      final sc = _k(
          q,
          const [(0, 0.2), (31.8, 0.2), (32.9, 1), (36.6, 1.5), (100, 1.5)],
          Curves.easeOut);
      final op = _k(
          q,
          const [(0, 0), (31.8, 0), (32.9, 1), (36.6, 0), (100, 0)],
          Curves.easeOut);
      _paintSpark(canvas, sc, op);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PapeletaActionPainter old) =>
      old.time != time || old.scale != scale || old.colors != colors;
}

// ── Etiqueta «¡Ese es el mío!» (widget nativo) ─────────────────────────────

/// Caja de 402 × 370 escalada al ancho real: los widgets nativos de la
/// escena se colocan en coordenadas del tablero.
class _DesignBox extends StatelessWidget {
  final double scale;
  final Widget child;
  const _DesignBox({required this.scale, required this.child});

  @override
  Widget build(BuildContext context) => OverflowBox(
        alignment: Alignment.topLeft,
        minWidth: 402,
        maxWidth: 402,
        minHeight: 370,
        maxHeight: 370,
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.topLeft,
          child: MediaQuery.withNoTextScaling(child: child),
        ),
      );
}

class _SceneLabel extends StatelessWidget {
  /// Progreso del bucle en % (`null` = movimiento reducido: visible).
  final double? q;
  const _SceneLabel({required this.q});

  @override
  Widget build(BuildContext context) {
    final q = this.q;
    double ty = 0, s = 1, rot = -6, op = 1;
    if (q != null) {
      const sp = GmMotion.spring;
      ty = _k(
          q, const [(0, 10), (33.6, 10), (35.8, -4), (37.6, 0), (100, 0)], sp);
      s = _k(q,
          const [(0, 0.6), (33.6, 0.6), (35.8, 1.08), (37.6, 1), (100, 1)], sp);
      rot = _k(q,
          const [(0, -12), (33.6, -12), (35.8, -3), (37.6, -6), (100, -6)], sp);
      op = _k(
              q,
              const [(0, 0), (33.6, 0), (35.8, 1), (88, 1), (91, 0), (100, 0)],
              sp)
          .clamp(0.0, 1.0);
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 126,
          top: 250,
          child: Opacity(
            opacity: op,
            child: Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.translationValues(0, ty, 0)
                ..multiply(Matrix4.rotationZ(rot * math.pi / 180))
                ..multiply(Matrix4.diagonal3Values(s, s, 1)),
              child: const PremiosTagLabel(text: '¡Ese es el mío!'),
            ),
          ),
        ),
      ],
    );
  }
}

/// Etiqueta de oro con cola (la de la escena; 32 de alto).
class PremiosTagLabel extends StatelessWidget {
  final String text;
  const PremiosTagLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: GmColors.gold,
              borderRadius: BorderRadius.circular(GmRadius.pill),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x73140408),
                    offset: Offset(0, 6),
                    blurRadius: 14),
              ],
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(GmRadius.pill),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x40FFFFFF), Color(0x00FFFFFF)],
                stops: [0, 0.12],
              ),
            ),
            child: Text(
              text,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 15,
                height: 1,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: GmColors.wine,
              ),
            ),
          ),
          Positioned(
            right: -11,
            top: -3,
            child: CustomPaint(
              size: const Size(16, 16),
              painter: _TailPainter(),
            ),
          ),
        ],
      );
}

class _TailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
        Path()
          ..moveTo(0, 7)
          ..lineTo(15, 1)
          ..lineTo(4, 15)
          ..close(),
        Paint()..color = GmColors.gold);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Celebración (Gracias): una sola vez ────────────────────────────────────

/// La misma escena en modo celebración (tablero EncuestaGracias, ≈ 3,2 s,
/// sin bucle): la barrica se aplasta y rebota, chispa, la escarapela se
/// balancea y 34 papelitos oro, vino y crema salen del hueco, suben a la
/// derecha del título y caen; 10 se quedan posados en el mantel (ese es el
/// fotograma final y el de movimiento reducido). Háptica ligera al final
/// del rebote.
class PapeletaBarricaCelebration extends StatelessWidget {
  static const Duration duration = Duration(milliseconds: 3200);

  const PapeletaBarricaCelebration({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = GmColors.of(context).isDark;
    return _withEditionYear(
        (year) => _build(PremiosSceneColors.of(dark, year: year)));
  }

  Widget _build(PremiosSceneColors colors) {
    return LayoutBuilder(builder: (context, c) {
      final s = c.maxWidth / PapeletaBarricaScene.designWidth;
      return ExcludeSemantics(
        child: SizedBox(
          width: c.maxWidth,
          height: PapeletaBarricaScene.designHeight * s,
          child: ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                RepaintBoundary(
                  child: CustomPaint(
                    painter: PremiosTablePainter(
                        colors: colors, scale: s, pencil: false),
                  ),
                ),
                RepaintBoundary(
                  child: GmOnce(
                    duration: duration,
                    trigger: GmTrigger.mount,
                    builder: (_, t, __) => CustomPaint(
                      painter:
                          CelebrationPainter(colors: colors, scale: s, t: t),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// Un papelito del confeti (datos del tablero: `scene.confetti()`, semilla
/// fija 11). Desplazamientos relativos al hueco (318, 222).
class _Conf {
  final Color c;
  final double w, h, dx, ax, peak, land, rot, frot, delay, dur;
  final bool stay;
  const _Conf(this.c, this.w, this.h, this.dx, this.ax, this.peak, this.land,
      this.rot, this.frot, this.delay, this.dur, this.stay);
}

const _kConfetti = [
  _Conf(Color(0xFFC9A96B), 5, 12, -97.1, -12.6, -116.7, 81.7, -266.5, 20.8,
      0.280, 2.176, true),
  _Conf(Color(0xFFFFF6E6), 5, 12, 49.0, 28.4, -99.5, 56.7, -414.4, 74.4, 0.298,
      2.092, true),
  _Conf(Color(0xFFB23A4C), 6, 11, -83.1, -22.2, -113.6, 54.5, -212.8, 15.9,
      0.316, 2.167, true),
  _Conf(Color(0xFFF2CF7E), 7, 10, 56.4, 43.9, -128.3, 59.9, 379.9, -6.8, 0.334,
      1.867, true),
  _Conf(Color(0xFFF2E8D5), 8, 8, -50.2, -2.1, -104.6, 79.2, 472.9, -75.2, 0.352,
      2.038, true),
  _Conf(Color(0xFF7A1E2C), 7, 10, 49.5, 17.8, -136.7, 62.7, -505.0, -45.8,
      0.370, 2.256, true),
  _Conf(Color(0xFFC9A96B), 8, 8, -131.5, -17.0, -119.0, 75.3, -480.3, -26.1,
      0.388, 1.887, true),
  _Conf(Color(0xFFFFF6E6), 5, 12, 46.5, 34.1, -133.3, 81.7, -203.9, 47.5, 0.406,
      1.807, true),
  _Conf(Color(0xFFB23A4C), 5, 12, -87.9, -15.3, -103.4, 59.7, -350.9, -61.4,
      0.424, 1.952, true),
  _Conf(Color(0xFFF2CF7E), 7, 10, 52.8, 26.6, -99.8, 83.1, 559.2, -46.3, 0.442,
      1.937, true),
  _Conf(Color(0xFFF2E8D5), 7, 10, -62.5, -10.6, -90.5, 57.0, -359.0, 43.6,
      0.460, 1.897, false),
  _Conf(Color(0xFF7A1E2C), 8, 8, 55.5, 16.0, -110.9, 56.7, -205.6, -20.5, 0.478,
      1.972, false),
  _Conf(Color(0xFFC9A96B), 8, 8, -53.5, -14.4, -96.7, 71.2, -425.8, 65.3, 0.496,
      2.191, false),
  _Conf(Color(0xFFFFF6E6), 5, 12, 54.0, 22.2, -93.0, 76.2, -447.3, 61.2, 0.514,
      2.062, false),
  _Conf(Color(0xFFB23A4C), 5, 12, -99.8, -23.5, -91.9, 55.2, -466.3, -38.9,
      0.532, 2.194, false),
  _Conf(Color(0xFFF2CF7E), 5, 12, 65.1, 27.8, -104.0, 59.3, -245.5, 9.5, 0.550,
      2.211, false),
  _Conf(Color(0xFFF2E8D5), 5, 12, -83.2, -19.3, -129.8, 81.5, -224.9, -8.7,
      0.568, 1.736, false),
  _Conf(Color(0xFF7A1E2C), 5, 12, 51.6, 31.9, -133.4, 71.2, 249.8, 76.9, 0.586,
      2.094, false),
  _Conf(Color(0xFFC9A96B), 8, 8, -76.6, -12.0, -138.2, 58.2, -370.9, 32.2,
      0.604, 2.278, false),
  _Conf(Color(0xFFFFF6E6), 7, 10, 46.7, 46.4, -103.5, 68.5, 249.2, -68.0, 0.622,
      2.028, false),
  _Conf(Color(0xFFB23A4C), 5, 12, -72.6, -4.4, -104.8, 76.1, 326.7, 64.1, 0.640,
      2.223, false),
  _Conf(Color(0xFFF2CF7E), 7, 10, 59.3, 54.7, -111.4, 79.9, 336.5, 17.4, 0.658,
      1.748, false),
  _Conf(Color(0xFFF2E8D5), 5, 12, -81.0, -2.2, -103.6, 80.4, 536.3, -9.5, 0.676,
      2.203, false),
  _Conf(Color(0xFF7A1E2C), 7, 10, 48.7, 52.5, -109.9, 54.9, 208.0, -0.4, 0.694,
      2.069, false),
  _Conf(Color(0xFFC9A96B), 8, 8, -56.8, -19.9, -124.9, 54.3, -386.6, 25.6,
      0.712, 1.965, false),
  _Conf(Color(0xFFFFF6E6), 6, 11, 74.5, 29.7, -130.1, 74.0, 489.3, 60.8, 0.730,
      1.931, false),
  _Conf(Color(0xFFB23A4C), 8, 8, -85.9, -18.4, -115.2, 58.1, -456.0, 51.5,
      0.748, 1.768, false),
  _Conf(Color(0xFFF2CF7E), 5, 12, 61.1, 62.0, -120.9, 78.9, 442.0, -28.7, 0.766,
      2.197, false),
  _Conf(Color(0xFFF2E8D5), 7, 10, -112.1, -11.4, -125.9, 74.3, 311.3, 22.6,
      0.784, 1.943, false),
  _Conf(Color(0xFF7A1E2C), 7, 10, 52.1, 53.5, -101.0, 62.0, -554.2, -8.6, 0.802,
      2.078, false),
  _Conf(Color(0xFFC9A96B), 8, 8, -79.7, -6.6, -105.8, 82.8, -496.6, -51.4,
      0.820, 1.706, false),
  _Conf(Color(0xFFFFF6E6), 6, 11, 61.1, 50.6, -126.4, 59.4, 394.3, -17.0, 0.838,
      2.175, false),
  _Conf(Color(0xFFB23A4C), 6, 11, -58.1, -23.9, -103.9, 82.0, -362.2, 20.1,
      0.856, 2.246, false),
  _Conf(Color(0xFFF2CF7E), 6, 11, 58.1, 42.7, -100.2, 80.4, 366.9, -64.2, 0.874,
      2.220, false),
];

/// Número de papelitos que se quedan posados (fotograma final).
@visibleForTesting
int get confettiRestingCount => _kConfetti.where((p) => p.stay).length;

/// Barrica, escarapela, chispa y confeti de la celebración. [t] = 0…1 de
/// [PapeletaBarricaCelebration.duration]; con movimiento reducido llega 1.
class CelebrationPainter extends CustomPainter {
  final PremiosSceneColors colors;
  final double scale;
  final double t;

  const CelebrationPainter(
      {required this.colors, required this.scale, required this.t});

  static const _confCurve = Cubic(0.2, 0.7, 0.4, 1);

  @override
  void paint(Canvas canvas, Size size) {
    final sec = t * PapeletaBarricaCelebration.duration.inMilliseconds / 1000;
    canvas.save();
    canvas.scale(scale);

    final bp = ((sec - 0.12) / 0.7).clamp(0.0, 1.0) * 100;
    final sx = _k(
        bp,
        const [(0, 1), (22, 1.1), (48, 0.94), (72, 1.03), (100, 1)],
        GmMotion.spring);
    final sy = _k(
        bp,
        const [(0, 1), (22, 0.86), (48, 1.08), (72, 0.98), (100, 1)],
        GmMotion.spring);
    final mp = ((sec - 0.2) / 1.4).clamp(0.0, 1.0) * 100;
    final medal = _k(
        mp,
        const [(0, 0), (25, 20), (50, -13), (72, 6), (88, -2), (100, 0)],
        Curves.easeInOut);
    _paintBarrel(canvas, colors, sx: sx, sy: sy, medalDeg: medal);

    canvas.save();
    canvas.translate(_cx, _top);
    for (final p in _kConfetti) {
      final local = (sec - p.delay) / p.dur;
      if (local < 0) continue;
      final k = local.clamp(0.0, 1.0) * 100;
      final x = _k(k, [(0, 0), (34, p.ax), (100, p.dx)], _confCurve);
      final y = _k(k, [(0, 0), (34, p.peak), (100, p.land)], _confCurve);
      final r = _k(k, [(0, 0), (34, p.rot * 0.4), (100, p.frot)], _confCurve);
      final s = _k(k, const [(0, 0.4), (34, 1), (100, 1)], _confCurve);
      final op = p.stay
          ? 1.0
          : _k(k, const [(0, 1), (80, 1), (100, 0)], _confCurve)
              .clamp(0.0, 1.0);
      if (op <= 0.01) continue;
      // Revoloteo: 5 vueltas de 0,42 s (scaleX 1 → −0,2 → −1 → 0,3 → 1).
      final fl = (sec - p.delay) / 0.42;
      final flut = fl >= 5
          ? 1.0
          : gmKeyframes(fl % 1,
              const [(0, 1), (0.25, -0.2), (0.5, -1), (0.75, 0.3), (1, 1)],
              curve: Curves.linear);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(r * math.pi / 180);
      canvas.scale(s * flut, s);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset.zero, width: p.w, height: p.h),
              const Radius.circular(1)),
          Paint()..color = p.c.withValues(alpha: op));
      canvas.restore();
    }
    canvas.restore();

    final spk = ((sec - 0.2) / 0.8).clamp(0.0, 1.0) * 100;
    if (spk > 0 && spk < 100) {
      _paintSpark(
          canvas,
          _k(spk, const [(0, 0.2), (30, 1), (100, 1.6)], Curves.easeOut),
          _k(spk, const [(0, 0), (30, 1), (100, 0)], Curves.easeOut));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CelebrationPainter old) =>
      old.t != t || old.scale != scale || old.colors != colors;
}

// ── Barrica pequeña (tarjeta del Inicio y hoja) ────────────────────────────

/// La barrica de la tarjeta: la papeleta entra una vez y se queda medio
/// metida (tablero EncuestaInicioTarjeta, `mini_barrel`). Recorte del
/// tablero: viewBox 272 150 100 176.
class PremiosMiniBarrel extends StatelessWidget {
  final double width;

  /// En una hoja (sin scroll) hay que arrancar al montarse.
  final GmTrigger trigger;
  const PremiosMiniBarrel(
      {super.key, this.width = 86, this.trigger = GmTrigger.visible});

  static const Rect _view = Rect.fromLTWH(272, 150, 100, 176);

  @override
  Widget build(BuildContext context) {
    final dark = GmColors.of(context).isDark;
    final s = width / _view.width;
    return _withEditionYear((year) {
      final colors = PremiosSceneColors.of(dark, year: year);
      return ExcludeSemantics(
        child: SizedBox(
          width: width,
          height: _view.height * s,
          child: GmOnce(
            duration: const Duration(milliseconds: 1900),
            delay: const Duration(milliseconds: 400),
            trigger: trigger,
            builder: (_, t, __) => CustomPaint(
              painter: _MiniBarrelPainter(
                  colors: colors, scale: s, t: t, view: _view),
            ),
          ),
        ),
      );
    });
  }
}

/// La barrica pequeña como glifo (antetítulo de la card del Inicio): el
/// fotograma final, con la papeleta medio metida; sin animación.
class PremiosBarrelGlyph extends StatelessWidget {
  final double width;
  const PremiosBarrelGlyph({super.key, this.width = 18});

  static const Rect _view = Rect.fromLTWH(278, 192, 80, 130);

  @override
  Widget build(BuildContext context) {
    final dark = GmColors.of(context).isDark;
    final s = width / _view.width;
    return _withEditionYear((year) {
      final colors = PremiosSceneColors.of(dark, year: year);
      return ExcludeSemantics(
        child: SizedBox(
          width: width,
          height: _view.height * s,
          child: CustomPaint(
            painter:
                _MiniBarrelPainter(colors: colors, scale: s, t: 1, view: _view),
          ),
        ),
      );
    });
  }
}

class _MiniBarrelPainter extends CustomPainter {
  final PremiosSceneColors colors;
  final double scale;
  final double t;
  final Rect view;
  const _MiniBarrelPainter(
      {required this.colors,
      required this.scale,
      required this.t,
      required this.view});

  @override
  void paint(Canvas canvas, Size size) {
    // Duraciones: 1,5 s papeleta/barrica/chispa y 1,9 s la escarapela.
    final q = (t * 1.9 / 1.5).clamp(0.0, 1.0) * 100;
    final mq = t * 100;
    canvas.save();
    canvas.scale(scale);
    canvas.translate(-view.left, -view.top);

    final ty = _k(
        q, const [(0, -34), (45, -6), (62, -12), (82, 34), (100, 30)], _kStd);
    final rot = _k(q, const [(0, -10), (45, 4), (62, 0), (100, 0)], _kStd);
    final psx =
        _k(q, const [(0, 1), (45, 1), (62, 1.06), (82, 0.8), (100, 1)], _kStd);
    final psy = _k(
        q, const [(0, 1), (45, 0.9), (62, 0.92), (82, 1.16), (100, 1)], _kStd);
    canvas.save();
    canvas.clipRect(const Rect.fromLTWH(0, 0, 402, _clipY));
    canvas.translate(_papCenter.dx, _papCenter.dy + ty);
    canvas.rotate(rot * math.pi / 180);
    canvas.scale(psx, psy);
    canvas.translate(-_papCenter.dx, -_papCenter.dy);
    _paintPapeleta(canvas, 0);
    canvas.restore();

    final sx = _k(q, const [(0, 1), (78, 1), (86, 1.1), (94, 0.96), (100, 1)],
        GmMotion.spring);
    final sy = _k(q, const [(0, 1), (78, 1), (86, 0.88), (94, 1.05), (100, 1)],
        GmMotion.spring);
    final medal = _k(mq, const [(0, 0), (82, 0), (88, 16), (94, -9), (100, 0)],
        Curves.easeInOut);
    _paintBarrel(canvas, colors, sx: sx, sy: sy, medalDeg: medal);

    if (q > 80 && q < 100) {
      _paintSpark(
          canvas,
          _k(q, const [(80, 0.2), (88, 1), (100, 1.4)], Curves.easeOut),
          _k(q, const [(80, 0), (88, 1), (100, 0)], Curves.easeOut));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MiniBarrelPainter old) =>
      old.t != t ||
      old.scale != scale ||
      old.colors != colors ||
      old.view != view;
}

/// Háptica ligera (se usa al caer el sello de Gracias).
void premiosLightHaptic() => HapticFeedback.lightImpact();
