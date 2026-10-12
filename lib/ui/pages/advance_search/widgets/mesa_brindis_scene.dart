import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:guachinches/core/app_route_observer.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';

/// «C · Mesa con brindis» (tablero MotionCuarta): la cabecera animada de
/// «Guachinches tradicionales». Mantel de cuadros en perspectiva sobre la
/// madera, el salvamanteles de Tenerife que entra deslizando (solo la
/// primera vez) y dos vasos de vino que llegan de los lados, brindan
/// —chispa dorada, el vino se mece y «¡Salud!»— y se van. Bucle de 10 s.
///
/// Vectorial y nativo (CustomPainter + un único Ticker): sin vídeo ni
/// Lottie/Rive, nítido a cualquier escala y con los colores del tema.
/// - Lo estático (madera, mantel, sombra de profundidad y, cuando ya ha
///   entrado, el salvamanteles) va en su propia capa con RepaintBoundary:
///   se pinta una vez.
/// - El ticker solo corre en los tramos con movimiento; en los reposos se
///   para y un Timer lo despierta para el siguiente tiempo.
/// - Se para del todo si [active] es false (fuera de pantalla), si la ruta
///   queda tapada, si la app pasa a segundo plano o si TickerMode está
///   desactivado.
/// - «Reducir movimiento»: fotograma final quieto (salvamanteles, vasos
///   juntos y «¡Salud!»).
class MesaBrindisScene extends StatefulWidget {
  /// Está a la vista (la pantalla lo apaga al hacer scroll).
  final bool active;

  /// Medidas del tablero (la escena escala con el ancho).
  static const double designWidth = 402;
  static const double designHeight = 168;

  const MesaBrindisScene({super.key, this.active = true});

  /// Alto para un ancho dado.
  static double heightFor(double width) => designHeight * width / designWidth;

  @override
  State<MesaBrindisScene> createState() => MesaBrindisSceneState();
}

@visibleForTesting
class MesaBrindisSceneState extends State<MesaBrindisScene>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  late final Ticker _ticker = createTicker(_onTick);

  /// Segundos de animación transcurridos (sin contar las pausas).
  final ValueNotifier<double> _time = ValueNotifier(0);
  double _base = 0;
  Timer? _wake;
  bool _reduced = false;
  bool _appActive = true;
  bool _covered = false;
  bool _tickerMode = true;

  /// La escena no arranca hasta que termina la transición de entrada de la
  /// pantalla (si no, el salvamanteles entraría tapado por el deslizamiento).
  bool _routeReady = true;
  Animation<double>? _routeAnim;

  /// Para los tests: ¿está corriendo el ticker?
  @visibleForTesting
  bool get isTicking => _ticker.isActive;

  /// Para los tests: ¿pinta el fotograma final quieto?
  @visibleForTesting
  bool get isStatic => _reduced;

  bool get _shouldRun =>
      !_reduced &&
      widget.active &&
      _appActive &&
      !_covered &&
      _tickerMode &&
      _routeReady;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = GmMotion.reduced(context);
    _tickerMode = TickerMode.valuesOf(context).enabled;
    final route = ModalRoute.of(context);
    if (route is PageRoute) appRouteObserver.subscribe(this, route);
    final anim = route?.animation;
    if (anim != _routeAnim) {
      _routeAnim?.removeStatusListener(_onRouteStatus);
      _routeAnim = anim;
      _routeReady = anim == null || anim.status == AnimationStatus.completed;
      anim?.addStatusListener(_onRouteStatus);
    }
    _sync();
  }

  void _onRouteStatus(AnimationStatus status) {
    final ready = status == AnimationStatus.completed;
    if (ready != _routeReady) {
      _routeReady = ready;
      _sync();
    }
  }

  @override
  void didUpdateWidget(MesaBrindisScene old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
    _sync();
  }

  @override
  void didPushNext() {
    _covered = true;
    _sync();
  }

  @override
  void didPopNext() {
    _covered = false;
    _sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    appRouteObserver.unsubscribe(this);
    _routeAnim?.removeStatusListener(_onRouteStatus);
    _wake?.cancel();
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  /// Arranca o para el reloj según la visibilidad.
  void _sync() {
    if (_shouldRun) {
      if (!_ticker.isActive && _wake == null) _resume();
    } else {
      _pause();
    }
  }

  void _resume() {
    final t = _time.value;
    final quietFor = mesaQuietRemaining(t);
    if (quietFor > 0) {
      // En reposo: nada que pintar hasta el siguiente tiempo.
      _wake = Timer(Duration(milliseconds: (quietFor * 1000).ceil()), () {
        _wake = null;
        _time.value = t + quietFor;
        _base = _time.value;
        if (_shouldRun) _ticker.start();
      });
      return;
    }
    _base = t;
    _ticker.start();
  }

  void _pause() {
    _wake?.cancel();
    _wake = null;
    if (_ticker.isActive) {
      _ticker.stop();
      _base = _time.value;
    }
  }

  void _onTick(Duration elapsed) {
    final t = _base + elapsed.inMicroseconds / 1e6;
    final quietFor = mesaQuietRemaining(t);
    _time.value = t;
    if (quietFor > 0) {
      // Fotograma de reposo pintado: se duerme hasta el siguiente tiempo.
      _ticker.stop();
      _base = t;
      if (_shouldRun) {
        _wake = Timer(Duration(milliseconds: (quietFor * 1000).ceil()), () {
          _wake = null;
          _time.value = t + quietFor;
          _base = _time.value;
          if (_shouldRun) _ticker.start();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = GmColors.of(context).isDark;
    final colors = MesaColors.of(dark);
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final s = w / MesaBrindisScene.designWidth;
      return SizedBox(
        width: w,
        height: MesaBrindisScene.heightFor(w),
        child: ClipRect(
          child: ValueListenableBuilder<double>(
            valueListenable: _time,
            builder: (context, t, _) {
              final matDone = _reduced || t >= _kMatEnd;
              return Stack(
                fit: StackFit.expand,
                children: [
                  RepaintBoundary(
                    child: CustomPaint(
                      painter: MesaTablePainter(
                          colors: colors, scale: s, matDone: matDone),
                    ),
                  ),
                  RepaintBoundary(
                    child: CustomPaint(
                      painter: MesaActionPainter(
                        colors: colors,
                        scale: s,
                        time: _reduced ? null : t,
                        drawMat: !matDone,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    });
  }
}

// ── Tiempos (tablero: notas del lienzo) ─────────────────────────────────────

const double _kLoop = 10;
const double _kMatStart = 0.3;
const double _kMatDur = 1.2;
const double _kMatEnd = _kMatStart + _kMatDur; // 1,5 s

/// Tramos con movimiento dentro de cada bucle (s): entrada de los vasos,
/// brindis y «¡Salud!» (1,55–3,65) y despedida (8,75–9,8). El resto es
/// reposo y no hace falta repintar.
const _kActive = [(1.55, 3.65), (8.75, 9.8)];

/// Segundos de reposo que quedan desde [t] (0 si hay movimiento).
@visibleForTesting
double mesaQuietRemaining(double t) {
  if (t < _kMatEnd + 0.05) return 0; // entrada del salvamanteles
  final lt = t % _kLoop;
  for (final (a, b) in _kActive) {
    if (lt >= a && lt < b) return 0;
  }
  for (final (a, _) in _kActive) {
    if (lt < a) return a - lt;
  }
  return _kLoop - lt + _kActive.first.$1;
}

// ── Colores ────────────────────────────────────────────────────────────────

class MesaColors {
  final Color band;
  final Color wood;
  final Color paper;
  final Color ink;
  final double shade;
  final bool dark;

  const MesaColors({
    required this.band,
    required this.wood,
    required this.paper,
    required this.ink,
    required this.shade,
    required this.dark,
  });

  static const day = MesaColors(
    band: Color(0xFFF3DCDF),
    wood: Color(0xFFC99A6A),
    paper: Color(0xFFFBFAF6),
    ink: Color(0xFF2A45A0),
    shade: 0,
    dark: false,
  );
  static const night = MesaColors(
    band: Color(0xFF25141A),
    wood: Color(0xFF3A2A1E),
    paper: Color(0xFF14203A),
    ink: Color(0xFF9DB4F0),
    shade: 0.62,
    dark: true,
  );

  static MesaColors of(bool dark) => dark ? night : day;
}

// ── Geometría (coordenadas del tablero, y = 262 → 0) ───────────────────────

const _matPoly = [
  Offset(117, 51),
  Offset(289, 51),
  Offset(318, 122),
  Offset(88, 122)
];
const _matOrigin = Offset(203, 122);

Path _poly(List<Offset> pts) {
  final p = Path()..moveTo(pts.first.dx, pts.first.dy);
  for (final o in pts.skip(1)) {
    p.lineTo(o.dx, o.dy);
  }
  return p..close();
}

Path _clothPath() => Path()
  ..moveTo(30, 6)
  ..quadraticBezierTo(115, 2, 201, 4)
  ..quadraticBezierTo(286, 6, 372, 6)
  ..lineTo(430, 168)
  ..quadraticBezierTo(320, 172, 201, 170)
  ..quadraticBezierTo(80, 168, -28, 168)
  ..close();

const List<double> _coast = [
  17.2,
  103.9,
  25.8,
  107.3,
  30.7,
  113.9,
  33.6,
  118.2,
  36.3,
  122.1,
  37,
  126.6,
  39.5,
  128.6,
  43.2,
  134.1,
  41.5,
  135.8,
  41.1,
  138.2,
  42.2,
  140.5,
  42.9,
  142.9,
  43.8,
  145.9,
  46.3,
  151.9,
  47.6,
  154.9,
  50.3,
  159.2,
  52.6,
  160.4,
  55,
  167.7,
  58.6,
  173.9,
  61.1,
  178.3,
  62.2,
  179.4,
  64.1,
  181,
  65.7,
  182.2,
  67,
  183.9,
  68.6,
  186.1,
  69.9,
  187.8,
  73.1,
  190.1,
  73,
  193,
  74,
  196,
  73.3,
  200.8,
  74.3,
  202,
  77.1,
  201.8,
  78.9,
  202.5,
  81.6,
  208.2,
  82,
  215.2,
  86.1,
  219.5,
  92.7,
  217.8,
  94.9,
  216.4,
  98.8,
  216.6,
  102.7,
  217.2,
  104.9,
  216,
  106.5,
  213.1,
  110.1,
  213,
  126.7,
  208.8,
  132,
  208.2,
  131.5,
  205.1,
  134.4,
  202.6,
  137.6,
  199.3,
  139.5,
  197.8,
  142.6,
  193.8,
  144.8,
  195.1,
  144.6,
  193.4,
  145.3,
  194.1,
  147.5,
  195.3,
  147.5,
  195.3,
  146.4,
  191.8,
  151.9,
  184.1,
  154.5,
  181.7,
  159,
  175.7,
  161.1,
  173.7,
  163.6,
  171.7,
  163.3,
  166.4,
  165.6,
  163.9,
  164.5,
  160.7,
  165.4,
  155.7,
  166.2,
  150.3,
  171.4,
  140,
  177.3,
  130,
  178.4,
  123.2,
  184.9,
  116.5,
  182.6,
  99.7,
  185.3,
  91.2,
  193.2,
  84.1,
  198.5,
  82.4,
  212.2,
  68.3,
  216.9,
  67.2,
  218.4,
  65.9,
  220.1,
  62.5,
  220.3,
  61.3,
  219.3,
  64.1,
  220.5,
  62,
  222.4,
  57.6,
  219.2,
  60.3,
  224.3,
  55.6,
  227.1,
  54.1,
  225.5,
  56,
  232.2,
  50.8,
  234.3,
  51.7,
  238.5,
  47.1,
  238.8,
  47.8,
  246,
  42.8,
  252.2,
  39.1,
  255.1,
  39.7,
  254.8,
  34.3,
  256.8,
  30.5,
  255.2,
  27.7,
  252.6,
  25.6,
  253.1,
  23.1,
  242.4,
  22.2,
  235,
  26.1,
  231,
  27.3,
  220.1,
  26.3,
  211.4,
  24.2,
  210.1,
  26.4,
  206.8,
  26.5,
  201.1,
  25.4,
  197.9,
  24,
  193.1,
  26.3,
  193.1,
  31.1,
  187,
  33.7,
  183.1,
  34.5,
  180.2,
  34.2,
  174.2,
  37.5,
  170.3,
  41.3,
  167.6,
  46.3,
  166.3,
  50.3,
  160.4,
  57.2,
  159.2,
  59.2,
  158.1,
  58.2,
  156.7,
  61.1,
  157.2,
  63.2,
  155.8,
  64.7,
  153.4,
  65.6,
  152.7,
  67.9,
  147.5,
  71.6,
  144.6,
  71.3,
  140.2,
  77.6,
  131.8,
  78.6,
  130.9,
  77.2,
  127.5,
  77.9,
  124.1,
  80,
  121.6,
  83,
  120.5,
  82.6,
  114.8,
  84.2,
  105.9,
  85.5,
  100.9,
  84.8,
  98.4,
  85.7,
  95.7,
  84.7,
  93,
  84.6,
  92,
  83.6,
  91.1,
  85.3,
  90,
  87.5,
  86.1,
  85.7,
  83.9,
  89.8,
  78.6,
  88.4,
  77.1,
  89.9,
  76.7,
  91.1,
  75.2,
  92,
  68.9,
  94.2,
  65,
  92.5,
  62.3,
  92.9,
  58.3,
  92.6,
  56.3,
  92.1,
  52.1,
  92.3,
  47,
  86.9,
  42.4,
  87.4,
  40,
  88.3,
  36.7,
  92.5,
  33.2,
  94.2,
  29.2,
  94.8,
  25.7,
  97,
  19.6,
  97.5,
  18.7,
  103.6
];

Path _coastPath() {
  final p = Path()..moveTo(_coast[0], _coast[1]);
  for (var i = 2; i < _coast.length; i += 2) {
    p.lineTo(_coast[i], _coast[i + 1]);
  }
  return p..close();
}

// ── Capa estática ──────────────────────────────────────────────────────────

/// Madera, mantel de cuadros en perspectiva, sombra de profundidad, velo de
/// noche y —ya posado— el salvamanteles.
class MesaTablePainter extends CustomPainter {
  final MesaColors colors;
  final double scale;
  final bool matDone;

  MesaTablePainter(
      {required this.colors, required this.scale, required this.matDone});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(scale);
    canvas.drawRect(
        const Rect.fromLTWH(0, 0, 402, 168), Paint()..color = colors.wood);

    final cloth = _clothPath();
    canvas.save();
    canvas.clipPath(cloth);
    canvas.drawRect(const Rect.fromLTWH(-30, 0, 470, 175),
        Paint()..color = const Color(0xFFFFF7EC));
    final red = Paint()..color = const Color(0x8CC8202C);
    // Patrón de 16 px en el espacio de la cabecera (y = 262 arriba).
    for (double x = 0; x < 440; x += 16) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 8, 175), red);
    }
    for (double y = -6; y < 175; y += 16) {
      canvas.drawRect(Rect.fromLTWH(-30, y, 470, 8), red);
    }
    canvas.drawRect(
      const Rect.fromLTWH(-30, 2, 470, 172),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x383C0A10), Color(0x003C0A10)],
          stops: [0, 0.45],
        ).createShader(const Rect.fromLTWH(-30, 2, 470, 172)),
    );
    if (colors.shade > 0) {
      canvas.drawRect(const Rect.fromLTWH(-30, 0, 470, 175),
          Paint()..color = colors.band.withValues(alpha: colors.shade * 0.7));
    }
    canvas.restore();

    if (matDone) {
      paintMatShadow(canvas, 1);
      canvas.drawPicture(_MatPicture.of(colors));
    }
    // El difuminado va en esta capa quieta (encima de mesa y salvamanteles,
    // debajo de los vasos): se rasteriza una vez y no cuesta por fotograma.
    canvas.drawRect(_kSceneRect, mesaFadePaint(colors.band));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant MesaTablePainter old) =>
      old.colors != colors || old.scale != scale || old.matDone != matDone;
}

/// Difuminado de la cabecera compacta (tablero MotionCuarta, «cabecera
/// compacta con difuminado»): el color de la banda tapa el fondo de la mesa
/// y se desvanece hacia delante (opaco hasta y 236, 0,55 en 266 y nada en
/// 290 sobre los 370 de la cabecera). La escena empieza en y 202 de la
/// cabecera, así que en coordenadas de la escena va de −202 a 168.
Paint mesaFadePaint(Color band) => Paint()
  ..shader = ui.Gradient.linear(
    const Offset(0, -202),
    const Offset(0, 168),
    [
      band,
      band,
      band.withValues(alpha: 0.55),
      band.withValues(alpha: 0),
    ],
    const [0, 0.6378, 0.7189, 0.7838],
  );

const Rect _kSceneRect = Rect.fromLTWH(-30, -2, 470, 175);

void paintMatShadow(Canvas canvas, double opacity) {
  canvas.drawPath(
    _poly(_matPoly).shift(const Offset(2, 5)),
    Paint()..color = Color.fromRGBO(60, 10, 16, 0.18 * opacity),
  );
}

/// El salvamanteles grabado una vez por tema (la costa tiene 163 puntos).
class _MatPicture {
  static final Map<bool, ui.Picture> _cache = {};

  static ui.Picture of(MesaColors c) =>
      _cache.putIfAbsent(c.dark, () => _record(c));

  static ui.Picture _record(MesaColors c) {
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);
    final mat = _poly(_matPoly);
    canvas.drawPath(mat, Paint()..color = c.paper);
    canvas.drawPath(
        mat,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0x1A000000));
    canvas.save();
    canvas.clipPath(mat);
    // matrix(1.05 0 -0.08 0.52 108 54): el papel visto en perspectiva.
    canvas.transform(Float64List.fromList(
        [1.05, 0, 0, 0, -0.08, 0.52, 0, 0, 0, 0, 1, 0, 108, 54, 0, 1]));
    canvas.save();
    canvas.translate(78, 22);
    canvas.scale(0.42);
    final coast = _coastPath();
    canvas.drawPath(
        coast,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.4
          ..strokeJoin = StrokeJoin.round
          ..color = c.ink);
    canvas.drawPath(
        coast.shift(const Offset(4, 4)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = c.ink.withValues(alpha: 0.5));
    canvas.restore();
    void text(String s, double x, double baseline, TextStyle st) {
      final tp = TextPainter(
          text: TextSpan(text: s, style: st), textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(
          canvas,
          Offset(
              x,
              baseline -
                  tp.computeDistanceToActualBaseline(TextBaseline.alphabetic)));
    }

    text(
        'TENERIFE',
        10,
        26,
        TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            color: c.ink));
    text(
        'La Isla Amable',
        10,
        44,
        TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            color: c.ink));
    void stripes(Rect r) {
      canvas.save();
      canvas.clipRect(r);
      // Patrón del tablero: franjas de 3,5 cada 7 girado 45° → en
      // horizontal se repiten cada 7·√2.
      final p = Paint()
        ..color = c.ink
        ..strokeWidth = 3.5;
      const step = 7 * math.sqrt2;
      for (double k = -r.height; k < r.width + r.height; k += step) {
        canvas.drawLine(Offset(r.left + k, r.bottom),
            Offset(r.left + k + r.height, r.top), p);
      }
      canvas.restore();
    }

    stripes(const Rect.fromLTWH(128, 8, 56, 10));
    stripes(const Rect.fromLTWH(8, 112, 52, 10));
    canvas.restore();
    return rec.endRecording();
  }
}

// ── Capa animada ───────────────────────────────────────────────────────────

const _kStd = Cubic(0.4, 0, 0.2, 1);
const _kMatCurve = Cubic(0.3, 0.7, 0.3, 1);
const _kSpring = Cubic(0.34, 1.56, 0.64, 1);

/// Fotogramas clave con el progreso [q] y los tiempos de [stops] en % (como
/// los @keyframes del tablero).
double _k(double q, List<(double, double)> stops, Curve curve) =>
    gmKeyframes(q / 100, [for (final (p, v) in stops) (p / 100, v)],
        curve: curve);

/// Salvamanteles (entrada), sombras de contacto, vasos, chispa y «¡Salud!».
/// [time] `null` = fotograma final quieto (movimiento reducido).
class MesaActionPainter extends CustomPainter {
  final MesaColors colors;
  final double scale;
  final double? time;
  final bool drawMat;

  MesaActionPainter({
    required this.colors,
    required this.scale,
    required this.time,
    required this.drawMat,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(scale);
    final t = time;

    if (drawMat && t != null) {
      final p = ((t - _kMatStart) / _kMatDur).clamp(0.0, 1.0);
      final ty = _k(
          p * 100, const [(0, 120), (70, -6), (85, 2), (100, 0)], _kMatCurve);
      final shTy =
          _k(p * 100, const [(0, 120), (70, -6), (100, 0)], _kMatCurve);
      final shOp = _k(p * 100, const [(0, 0), (70, 1), (100, 1)], _kMatCurve);
      final rot =
          _k(p * 100, const [(0, -6), (70, -1), (85, 0), (100, 0)], _kMatCurve);
      final sx = _k(
          p * 100, const [(0, 1), (70, 1), (85, 1.02), (100, 1)], _kMatCurve);
      final sy = _k(
          p * 100, const [(0, 1), (70, 1), (85, 0.96), (100, 1)], _kMatCurve);
      canvas.save();
      canvas.translate(0, shTy);
      paintMatShadow(canvas, shOp);
      canvas.restore();
      final m = Matrix4.identity()
        ..translateByDouble(_matOrigin.dx, _matOrigin.dy + ty, 0, 1)
        ..rotateZ(rot * math.pi / 180)
        ..scaleByDouble(sx, sy, 1, 1)
        ..translateByDouble(-_matOrigin.dx, -_matOrigin.dy, 0, 1);
      canvas.save();
      canvas.transform(m.storage);
      canvas.drawPicture(_MatPicture.of(colors));
      canvas.restore();
      // Mientras entra, el salvamanteles va en esta capa: el difuminado
      // solo sobre él (la mesa ya lo lleva en la capa quieta).
      canvas.save();
      canvas.clipPath(_poly(_matPoly).transform(m.storage));
      canvas.drawRect(_kSceneRect, mesaFadePaint(colors.band));
      canvas.restore();
    }

    // Bucle de 10 s (en % del bucle, como los @keyframes del tablero).
    final q = t == null ? 50.0 : (t % _kLoop) / _kLoop * 100;
    final txL = t == null
        ? 0.0
        : _k(
            q,
            const [
              (0, -300),
              (16, -300),
              (17.8, -312),
              (24.5, 3),
              (26, 1),
              (29.5, -6),
              (33, 0),
              (90, 0),
              (97, -300),
              (100, -300)
            ],
            _kStd);
    final rotL = t == null
        ? 0.0
        : _k(
            q,
            const [
              (0, 0),
              (17.8, 0),
              (24.5, 8),
              (26, 10),
              (29.5, -2),
              (33, 0),
              (100, 0)
            ],
            _kStd);
    final sxG = t == null
        ? 1.0
        : _k(q, const [(0, 1), (24.5, 1), (26, 0.96), (29.5, 1), (100, 1)],
            _kStd);
    final syG = t == null
        ? 1.0
        : _k(q, const [(0, 1), (24.5, 1), (26, 1.03), (29.5, 1), (100, 1)],
            _kStd);
    final waveRot = t == null
        ? 0.0
        : _k(
            q,
            const [
              (0, 0),
              (25, 0),
              (26.5, -12),
              (29.5, 8),
              (32.5, -4),
              (36, 0),
              (100, 0)
            ],
            Curves.easeInOut);
    final waveTy = t == null
        ? 0.0
        : _k(q, const [(0, 0), (25, 0), (26.5, -2), (29.5, 0), (100, 0)],
            Curves.easeInOut);

    // Sombras de contacto (solo se desplazan).
    final shadow = Paint()..color = const Color.fromRGBO(60, 10, 16, 0.28);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(240 + txL, 111), width: 38, height: 8),
        shadow);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(286 - txL, 111), width: 38, height: 8),
        shadow);

    _glass(
        canvas, const Offset(240, 110), txL, rotL, sxG, syG, waveRot, waveTy);
    _glass(
        canvas, const Offset(286, 110), -txL, -rotL, sxG, syG, waveRot, waveTy);

    // Chispa dorada del brindis.
    if (t != null) {
      final sc = _k(
          q,
          const [(0, 0.2), (25.2, 0.2), (26.2, 1), (31, 1.5), (100, 1.5)],
          Curves.easeOut);
      final op = _k(q, const [(0, 0), (25.2, 0), (26.2, 1), (31, 0), (100, 0)],
          Curves.easeOut);
      if (op > 0.01) {
        canvas.save();
        canvas.translate(263, 58);
        canvas.scale(sc);
        final p = Paint()
          ..color = const Color(0xFFE3A21A).withValues(alpha: op)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(const Offset(0, -10), const Offset(0, -22), p);
        canvas.drawLine(const Offset(8, -8), const Offset(16, -16), p);
        canvas.drawLine(const Offset(-8, -8), const Offset(-16, -16), p);
        canvas.drawLine(const Offset(10, 0), const Offset(20, 0), p);
        canvas.drawLine(const Offset(-10, 0), const Offset(-20, 0), p);
        canvas.restore();
      }
    }

    // «¡Salud!»
    final sTy = t == null
        ? 0.0
        : _k(q, const [(0, 10), (26.5, 10), (29, -4), (31, 0), (100, 0)],
            _kSpring);
    final sSc = t == null
        ? 1.0
        : _k(q, const [(0, 0.6), (26.5, 0.6), (29, 1.08), (31, 1), (100, 1)],
            _kSpring);
    final sRot = t == null
        ? -6.0
        : _k(q, const [(0, -8), (26.5, -8), (29, -4), (31, -6), (100, -6)],
            _kSpring);
    final sOp = t == null
        ? 1.0
        : _k(q, const [(0, 0), (26.5, 0), (29, 1), (88, 1), (91, 0), (100, 0)],
                _kSpring)
            .clamp(0.0, 1.0);
    if (sOp > 0.01) _salud(canvas, sTy, sSc, sRot, sOp);

    canvas.restore();
  }

  void _glass(Canvas canvas, Offset base, double tx, double rotDeg, double sx,
      double sy, double waveRot, double waveTy) {
    if (tx.abs() > 260) return; // fuera de la escena
    canvas.save();
    canvas.translate(base.dx + tx, base.dy + 2);
    canvas.rotate(rotDeg * math.pi / 180);
    canvas.scale(sx, sy);
    canvas.translate(0, -2);

    final cup = Path()
      ..moveTo(-17, -60)
      ..lineTo(17, -60)
      ..lineTo(13, 0)
      ..lineTo(-13, 0)
      ..close();
    canvas.save();
    canvas.clipPath(cup);
    canvas.drawRect(const Rect.fromLTWH(-24, -30, 48, 32),
        Paint()..color = const Color(0xFF7A1626));
    canvas.save();
    canvas.translate(0, -30 + waveTy);
    canvas.rotate(waveRot * math.pi / 180);
    canvas.translate(0, 30);
    canvas.drawPath(
      Path()
        ..moveTo(-24, -30)
        ..quadraticBezierTo(-8, -35, 0, -30)
        ..quadraticBezierTo(8, -25, 24, -30)
        ..lineTo(24, -25)
        ..lineTo(-24, -25)
        ..close(),
      Paint()..color = const Color(0xFFA82A3C),
    );
    canvas.restore();
    canvas.restore();

    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF1F1A14)
      ..strokeJoin = StrokeJoin.round;
    final rim =
        Rect.fromCenter(center: const Offset(0, -60), width: 34, height: 6.4);
    canvas.drawOval(rim, Paint()..color = const Color(0x40FFFFFF));
    canvas.drawOval(rim, ink..strokeWidth = 2.2);
    final body = Path()
      ..moveTo(-17, -60)
      ..lineTo(-13, 0)
      ..quadraticBezierTo(0, 3.4, 13, 0)
      ..lineTo(17, -60);
    canvas.drawPath(body, Paint()..color = const Color(0x47FFFFFF));
    canvas.drawPath(body, ink..strokeWidth = 2.4);
    canvas.drawLine(
        const Offset(-11, -52),
        const Offset(-9, -8),
        Paint()
          ..color = const Color(0xD9FFFFFF)
          ..strokeWidth = 2.8
          ..strokeCap = StrokeCap.round);
    canvas.restore();
  }

  void _salud(Canvas canvas, double ty, double sc, double rotDeg, double op) {
    final tp = TextPainter(
      text: TextSpan(
        text: '¡Salud!',
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
    // Cabecera compacta: a la derecha de los vasos (x 306, y 242 de la
    // cabecera → 40 en la escena, que empieza en 202); origen abajo al
    // centro.
    final origin = Offset(306 + w / 2, 40 + h);
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
  bool shouldRepaint(covariant MesaActionPainter old) =>
      old.time != time ||
      old.colors != colors ||
      old.scale != scale ||
      old.drawMat != drawMat;
}
