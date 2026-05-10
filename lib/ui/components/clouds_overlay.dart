import 'dart:math' as math;

import 'package:flutter/material.dart';

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  for (final cloud in _clouds)
                    _CloudView(
                      cloud: cloud,
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
}

class _CloudView extends StatelessWidget {
  final _Cloud cloud;
  final double width;
  final double height;
  final double progress;
  final double baseOpacity;

  const _CloudView({
    required this.cloud,
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
      left: dx,
      top: dy,
      child: IgnorePointer(
        child: Opacity(
          opacity: (baseOpacity * cloud.opacity).clamp(0.0, 1.0),
          child: SizedBox(
            width: cloudWidth,
            height: cloudHeight,
            child: const RepaintBoundary(child: _CloudPainter()),
          ),
        ),
      ),
    );
  }
}

class _CloudPainter extends StatelessWidget {
  const _CloudPainter();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _CloudShape());
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
