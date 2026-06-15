import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Identidad de los 7 quesitos = 7 categorías = 7 islas (orden fijo del diseño).
/// Se usan como fallback de color cuando aún no hay categorías del backend
/// (p.ej. el banner del Home antes de cargar).
const List<Color> kQuizWedgeColors = [
  Color(0xFFE5484D), // historia · El Hierro
  Color(0xFFF2811D), // arte_literatura · La Gomera
  Color(0xFFF5B700), // folclore · Tenerife
  Color(0xFF6B7280), // ciencia_natura · La Palma
  Color(0xFF7C3AED), // deporte · Gran Canaria
  Color(0xFF0085C4), // geografia · Lanzarote
  Color(0xFF00A878), // entretenimiento · Fuerteventura
];

/// Fila de 7 puntitos con los colores de las categorías. Los conseguidos van
/// encendidos; el resto, atenuados. Para el banner del Home y el HUD del juego.
class QuizWedgesDots extends StatelessWidget {
  /// Colores en orden (si null, usa [kQuizWedgeColors]).
  final List<Color>? colors;

  /// Cuántos/ cuáles están encendidos: lista de índices o un set de bools.
  final List<bool> owned;
  final double size;
  final double gap;

  const QuizWedgesDots({
    super.key,
    this.colors,
    required this.owned,
    this.size = 9,
    this.gap = 6,
  });

  @override
  Widget build(BuildContext context) {
    final cols = colors ?? kQuizWedgeColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < cols.length; i++)
          Padding(
            padding: EdgeInsets.only(right: i == cols.length - 1 ? 0 : gap),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (i < owned.length && owned[i])
                    ? cols[i]
                    : Colors.white.withValues(alpha: 0.16),
                boxShadow: (i < owned.length && owned[i])
                    ? [
                        BoxShadow(
                          color: cols[i].withValues(alpha: 0.6),
                          blurRadius: 7,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}

/// Anillo de 7 quesitos estilo Trivial: sectores en color, encendidos los
/// conseguidos. Para el lobby y la pantalla de victoria.
class QuizWedgesRing extends StatelessWidget {
  final List<Color> colors;
  final List<bool> owned;
  final double size;
  final Widget? center;

  const QuizWedgesRing({
    super.key,
    required this.colors,
    required this.owned,
    this.size = 200,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _WedgesPainter(colors: colors, owned: owned),
          ),
          if (center != null) center!,
        ],
      ),
    );
  }
}

class _WedgesPainter extends CustomPainter {
  final List<Color> colors;
  final List<bool> owned;
  _WedgesPainter({required this.colors, required this.owned});

  @override
  void paint(Canvas canvas, Size size) {
    final n = colors.length;
    if (n == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final inner = radius * 0.42; // agujero central (donut)
    final sweep = 2 * math.pi / n;
    const gap = 0.045; // hueco entre quesitos (rad)

    for (var i = 0; i < n; i++) {
      final start = -math.pi / 2 + i * sweep + gap / 2;
      final isOwned = i < owned.length && owned[i];
      final col = isOwned
          ? colors[i]
          : Color.alphaBlend(
              colors[i].withValues(alpha: 0.18), const Color(0xFF111820));

      final path = Path()
        ..addArc(Rect.fromCircle(center: center, radius: radius), start,
            sweep - gap)
        ..arcTo(Rect.fromCircle(center: center, radius: inner),
            start + sweep - gap, -(sweep - gap), false)
        ..close();

      canvas.drawPath(path, Paint()..color = col);

      if (isOwned) {
        // Brillo sutil en los conseguidos.
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = Colors.white.withValues(alpha: 0.30),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_WedgesPainter old) =>
      old.owned != owned || old.colors != colors;
}
