import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class Star {
  double x, y, r, phase, speed;

  Star({
    required this.x,
    required this.y,
    required this.r,
    required this.phase,
    required this.speed,
  });

  factory Star.random(Size size, Random rng) => Star(
        x: rng.nextDouble() * size.width,
        y: rng.nextDouble() * size.height * 0.75,
        r: rng.nextDouble() * 1.2 + 0.2,
        phase: rng.nextDouble() * pi * 2,
        speed: rng.nextDouble() * 0.04 + 0.01,
      );
}

class StarfieldPainter extends CustomPainter {
  final double opacity;
  final List<Star> stars;

  StarfieldPainter({required this.opacity, required this.stars});

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    final paint = Paint();
    for (final star in stars) {
      star.phase += star.speed;
      final alpha = (opacity * (0.4 + 0.6 * sin(star.phase))).clamp(0.0, 1.0);
      paint.color = Colors.white.withOpacity(alpha);
      canvas.drawCircle(Offset(star.x, star.y), star.r, paint);
    }
  }

  @override
  bool shouldRepaint(StarfieldPainter old) =>
      old.opacity != opacity;
}

/// Widget con Ticker propio. Pausa automáticamente con TickerMode.
class StarfieldWidget extends StatefulWidget {
  final double opacity;
  final Size heroSize;

  const StarfieldWidget({
    super.key,
    required this.opacity,
    required this.heroSize,
  });

  @override
  State<StarfieldWidget> createState() => _StarfieldWidgetState();
}

class _StarfieldWidgetState extends State<StarfieldWidget>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late final List<Star> _stars;
  final _rng = Random(42); // semilla fija para consistencia

  @override
  void initState() {
    super.initState();
    _stars = List.generate(
      80,
      (_) => Star.random(widget.heroSize, _rng),
    );
    _ticker = createTicker((_) {
      if (mounted) setState(() {});
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.opacity <= 0) return const SizedBox.shrink();
    return RepaintBoundary(
      child: CustomPaint(
        size: widget.heroSize,
        painter: StarfieldPainter(
          opacity: widget.opacity,
          stars: _stars,
        ),
      ),
    );
  }
}
