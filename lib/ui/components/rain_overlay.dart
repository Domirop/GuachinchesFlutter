import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Overlay decorativo de lluvia. Pensado para colocarse dentro de un
/// `Stack` con `Clip.hardEdge` (igual que `CloudsOverlay`) para que los
/// rayados no se asomen fuera del hero.
class RainOverlay extends StatefulWidget {
  /// Cantidad de gotas en pantalla. 80 → lluvia media.
  final int density;
  /// Inclinación en radianes (0 = vertical, ~0.25 = ligeramente diagonal).
  final double tilt;
  /// Opacidad global.
  final double opacity;
  /// Color base (por defecto blanco-azulado, tipo escena de día gris).
  final Color color;

  const RainOverlay({
    super.key,
    this.density = 80,
    this.tilt = 0.18,
    this.opacity = 0.55,
    this.color = const Color(0xFFE6F2FA),
  });

  @override
  State<RainOverlay> createState() => _RainOverlayState();
}

class _RainOverlayState extends State<RainOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Drop> _drops;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    final rng = math.Random(7);
    _drops = List.generate(widget.density, (i) {
      return _Drop(
        xFrac: rng.nextDouble(),
        offset: rng.nextDouble(),
        speed: 0.8 + rng.nextDouble() * 0.7,
        length: 14 + rng.nextDouble() * 16,
        thickness: 1.0 + rng.nextDouble() * 0.8,
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
      child: IgnorePointer(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => CustomPaint(
              size: Size.infinite,
              painter: _RainPainter(
                drops: _drops,
                progress: _ctrl.value,
                tilt: widget.tilt,
                color: widget.color.withOpacity(widget.opacity),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Drop {
  final double xFrac;
  final double offset;
  final double speed;
  final double length;
  final double thickness;
  final double opacity;
  const _Drop({
    required this.xFrac,
    required this.offset,
    required this.speed,
    required this.length,
    required this.thickness,
    required this.opacity,
  });
}

class _RainPainter extends CustomPainter {
  final List<_Drop> drops;
  final double progress;
  final double tilt;
  final Color color;

  _RainPainter({
    required this.drops,
    required this.progress,
    required this.tilt,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Travel distance per cycle: a bit more than viewport so drops loop
    // smoothly off-screen.
    final travel = h + 80;
    final dxPerY = math.tan(tilt);

    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    for (final d in drops) {
      final t = (progress * d.speed + d.offset) % 1.0;
      final yTop = -40 + travel * t;
      final yBottom = yTop + d.length;
      final xTop = d.xFrac * w + dxPerY * yTop;
      final xBottom = xTop + dxPerY * d.length;
      paint
        ..color = color.withOpacity(
            color.opacity * d.opacity.clamp(0.0, 1.0))
        ..strokeWidth = d.thickness;
      canvas.drawLine(Offset(xTop, yTop), Offset(xBottom, yBottom), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter old) =>
      old.progress != progress;
}
