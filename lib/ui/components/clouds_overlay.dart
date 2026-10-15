import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Margen alrededor de cada nube rasterizada: el desenfoque más ancho
/// (σ 22) se extiende ~3σ fuera de la caja de la nube.
const double _kBlurPad = 70;

/// Overlay decorativo de nubes blancas que se desplazan lentamente.
/// Pensado para ponerse dentro de un `Stack` que cubra solo la zona del
/// hero — recorta los hijos con `ClipRect` para que no se asomen.
class CloudsOverlay extends StatefulWidget {
  final int count;
  final double opacity;
  final Duration baseDuration;

  const CloudsOverlay({
    super.key,
    this.count = 4,
    this.opacity = 0.55,
    this.baseDuration = const Duration(seconds: 60),
  });

  @override
  State<CloudsOverlay> createState() => _CloudsOverlayState();
}

class _CloudsOverlayState extends State<CloudsOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Cloud> _clouds;

  /// Cada nube se pinta UNA vez a imagen (a la densidad de la pantalla) y en
  /// cada fotograma solo se mueve. Antes eran ~15 formas con MaskFilter.blur
  /// por nube y fotograma: con Impeller no hay caché de raster, así que eran
  /// decenas de pasadas de desenfoque en la GPU 60–120 veces por segundo.
  final Map<int, ui.Image> _sprites = {};
  double _spritesDpr = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.baseDuration)
      ..repeat();
    final rng = math.Random(42);
    _clouds = List.generate(widget.count, (i) {
      return _Cloud(
        yFrac: 0.05 + rng.nextDouble() * 0.55,
        scale: 0.6 + rng.nextDouble() * 0.9,
        speed: 0.55 + rng.nextDouble() * 0.55,
        offsetFrac: rng.nextDouble(),
        opacity: 0.55 + rng.nextDouble() * 0.45,
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _disposeSprites();
    super.dispose();
  }

  void _disposeSprites() {
    for (final img in _sprites.values) {
      img.dispose();
    }
    _sprites.clear();
  }

  ui.Image _sprite(int i, double dpr) {
    if (dpr != _spritesDpr) {
      _disposeSprites();
      _spritesDpr = dpr;
    }
    return _sprites[i] ??= _rasterizeCloud(_clouds[i].size, dpr);
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return ClipRect(
      child: LayoutBuilder(
        builder: (_, c) {
          final w = c.maxWidth;
          final h = c.maxHeight;
          return AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              return Stack(
                children: [
                  for (var i = 0; i < _clouds.length; i++)
                    _CloudView(
                      cloud: _clouds[i],
                      sprite: _sprite(i, dpr),
                      width: w,
                      height: h,
                      progress: _ctrl.value,
                      baseOpacity: widget.opacity,
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _Cloud {
  final double yFrac;
  final double scale;
  final double speed;
  final double offsetFrac;
  final double opacity;
  const _Cloud({
    required this.yFrac,
    required this.scale,
    required this.speed,
    required this.offsetFrac,
    required this.opacity,
  });

  Size get size => Size(180 * scale, 70 * scale);
}

/// Pinta [_CloudShape] en una imagen con [_kBlurPad] de margen.
ui.Image _rasterizeCloud(Size size, double dpr) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)
    ..scale(dpr)
    ..translate(_kBlurPad, _kBlurPad);
  _CloudShape().paint(canvas, size);
  final picture = recorder.endRecording();
  final image = picture.toImageSync(
    ((size.width + 2 * _kBlurPad) * dpr).ceil(),
    ((size.height + 2 * _kBlurPad) * dpr).ceil(),
  );
  picture.dispose();
  return image;
}

class _CloudView extends StatelessWidget {
  final _Cloud cloud;
  final ui.Image sprite;
  final double width;
  final double height;
  final double progress;
  final double baseOpacity;

  const _CloudView({
    required this.cloud,
    required this.sprite,
    required this.width,
    required this.height,
    required this.progress,
    required this.baseOpacity,
  });

  @override
  Widget build(BuildContext context) {
    final cloudWidth = 180 * cloud.scale;
    final cloudHeight = 70 * cloud.scale;
    // Phase wraps from 0 to 1; cloud drifts right→left across the viewport.
    final t = (progress * cloud.speed + cloud.offsetFrac) % 1.0;
    final dx = width - (width + cloudWidth) * t;
    final dy = cloud.yFrac * (height - cloudHeight);
    return Positioned(
      left: dx - _kBlurPad,
      top: dy - _kBlurPad,
      width: cloudWidth + 2 * _kBlurPad,
      height: cloudHeight + 2 * _kBlurPad,
      child: IgnorePointer(
        child: Opacity(
          opacity: (baseOpacity * cloud.opacity).clamp(0.0, 1.0),
          child: RawImage(image: sprite, fit: BoxFit.fill),
        ),
      ),
    );
  }
}

class _CloudShape extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Three layered passes with decreasing blur produce a soft, painterly
    // cloud rather than hard-edged circles.
    final passes = <Paint>[
      Paint()
        ..color = Colors.white.withOpacity(0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
      Paint()
        ..color = Colors.white.withOpacity(0.75)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      Paint()
        ..color = Colors.white.withOpacity(0.92)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    ];

    void puff(Offset c, double r, Paint p) => canvas.drawCircle(c, r, p);

    for (final p in passes) {
      puff(Offset(w * 0.22, h * 0.66), h * 0.40, p);
      puff(Offset(w * 0.40, h * 0.46), h * 0.50, p);
      puff(Offset(w * 0.58, h * 0.42), h * 0.55, p);
      puff(Offset(w * 0.78, h * 0.60), h * 0.42, p);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.16, h * 0.62, w * 0.66, h * 0.24),
          Radius.circular(h * 0.20),
        ),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CloudShape oldDelegate) => false;
}
