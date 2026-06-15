import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_shapes.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/model/quiz/quiz_models.dart';

/// Icono Material para el `icon` de cada categoría del backend.
IconData quizCategoryIcon(String key) {
  switch (key) {
    case 'landmark':
      return Icons.account_balance_rounded;
    case 'palette':
      return Icons.palette_rounded;
    case 'music':
      return Icons.music_note_rounded;
    case 'flask':
      return Icons.science_rounded;
    case 'trophy':
      return Icons.emoji_events_rounded;
    case 'map':
      return Icons.map_rounded;
    case 'confetti':
      return Icons.celebration_rounded;
    default:
      return Icons.help_rounded;
  }
}

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

/// Leyenda CLARA de los 7 quesitos: una fila por categoría con icono en su
/// color, nombre + isla, y estado inequívoco — ✓ verde si lo tienes, círculo
/// hueco si te falta. Resuelve "no se sabe qué quesitos tienes".
class QuizWedgesLegend extends StatelessWidget {
  final List<QuizCategory> categories;
  final Set<String> owned;
  const QuizWedgesLegend({
    super.key,
    required this.categories,
    required this.owned,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final c in categories)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _Row(category: c, has: owned.contains(c.slug)),
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final QuizCategory category;
  final bool has;
  const _Row({required this.category, required this.has});

  @override
  Widget build(BuildContext context) {
    final color = category.color;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: has
            ? Color.alphaBlend(
                color.withValues(alpha: 0.18), AppColors.glassDark)
            : AppColors.glassDark,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: has
              ? color.withValues(alpha: 0.55)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: has ? color : color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(quizCategoryIcon(category.icon),
                size: 18,
                color: has ? Colors.white : color.withValues(alpha: 0.7)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.name.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.displaySection(
                        size: 12,
                        color: has
                            ? AppColors.crema
                            : AppColors.crema.withValues(alpha: 0.55))),
                Text(category.island,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.ui(
                        size: 10,
                        color: AppColors.crema.withValues(alpha: 0.4))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (has)
            const Icon(Icons.check_circle_rounded,
                color: AppColors.laurisilva, size: 22)
          else
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.6),
              ),
            ),
        ],
      ),
    );
  }
}

/// Tira compacta de progreso para el HUD del juego: 7 iconos de categoría;
/// conseguido = color sólido + check pequeño, pendiente = contorno tenue.
class QuizWedgesStrip extends StatelessWidget {
  final List<QuizCategory> categories;
  final Set<String> owned;
  const QuizWedgesStrip({
    super.key,
    required this.categories,
    required this.owned,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final c in categories)
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: _Chip(category: c, has: owned.contains(c.slug)),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final QuizCategory category;
  final bool has;
  const _Chip({required this.category, required this.has});

  @override
  Widget build(BuildContext context) {
    final color = category.color;
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: has ? color : Colors.transparent,
        border: Border.all(
          color: has ? color : Colors.white.withValues(alpha: 0.22),
          width: 1.5,
        ),
      ),
      child: Icon(
        has ? Icons.check_rounded : quizCategoryIcon(category.icon),
        size: has ? 15 : 13,
        color: has ? Colors.white : Colors.white.withValues(alpha: 0.45),
      ),
    );
  }
}
