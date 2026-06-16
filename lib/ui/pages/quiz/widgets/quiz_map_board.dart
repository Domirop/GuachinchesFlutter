import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_shapes.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';

/// Posición relativa (0..1) de cada isla en el mapa, ~geográfica oeste→este.
class QuizMapIsland {
  final String slug;
  final String name;
  final double dx;
  final double dy;
  const QuizMapIsland(this.slug, this.name, this.dx, this.dy);
}

const List<QuizMapIsland> kQuizMapIslands = [
  QuizMapIsland('la_palma', 'La Palma', 0.14, 0.26),
  QuizMapIsland('el_hierro', 'El Hierro', 0.10, 0.74),
  QuizMapIsland('la_gomera', 'La Gomera', 0.29, 0.58),
  QuizMapIsland('tenerife', 'Tenerife', 0.43, 0.44),
  QuizMapIsland('gran_canaria', 'Gran Canaria', 0.58, 0.64),
  QuizMapIsland('fuerteventura', 'Fuerteventura', 0.77, 0.44),
  QuizMapIsland('lanzarote', 'Lanzarote', 0.89, 0.20),
];

/// Mapa de conquista de Canarias: las 7 islas posicionadas ~geográficamente,
/// encendidas en [tierColor] al conquistarlas. Si [onTapIsland] no es null, las
/// islas SIN conquistar son tocables (modo "elige qué isla conquistar") y
/// laten para invitar al toque.
class QuizMapBoard extends StatelessWidget {
  final Set<String> owned;
  final Color tierColor;
  final ValueChanged<String>? onTapIsland;

  const QuizMapBoard({
    super.key,
    required this.owned,
    required this.tierColor,
    this.onTapIsland,
  });

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return AspectRatio(
      aspectRatio: 16 / 11,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.alphaBlend(
                  AppColors.atlantico.withValues(alpha: 0.12), brand.surface),
              brand.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: brand.border),
        ),
        child: LayoutBuilder(
          builder: (context, c) {
            return Stack(
              children: [
                for (final isl in kQuizMapIslands)
                  Positioned(
                    left: isl.dx * c.maxWidth - 44,
                    top: isl.dy * c.maxHeight - 24,
                    child: SizedBox(
                      width: 88,
                      child: _IslandToken(
                        name: isl.name,
                        conquered: owned.contains(isl.slug),
                        color: tierColor,
                        selectable:
                            onTapIsland != null && !owned.contains(isl.slug),
                        onTap: onTapIsland == null || owned.contains(isl.slug)
                            ? null
                            : () => onTapIsland!(isl.slug),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _IslandToken extends StatefulWidget {
  final String name;
  final bool conquered;
  final bool selectable;
  final Color color;
  final VoidCallback? onTap;

  const _IslandToken({
    required this.name,
    required this.conquered,
    required this.selectable,
    required this.color,
    required this.onTap,
  });

  @override
  State<_IslandToken> createState() => _IslandTokenState();
}

class _IslandTokenState extends State<_IslandToken>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  );

  @override
  void initState() {
    super.initState();
    if (widget.selectable) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_IslandToken old) {
    super.didUpdateWidget(old);
    if (widget.selectable && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.selectable && _pulse.isAnimating) {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final conquered = widget.conquered;
    final color = widget.color;
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, child) {
              final t = widget.selectable ? _pulse.value : 0.0;
              return Container(
                width: 30 + t * 4,
                height: 30 + t * 4,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: conquered
                      ? color
                      : (widget.selectable
                          ? color.withValues(alpha: 0.22)
                          : brand.glass),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: conquered
                        ? Colors.white.withValues(alpha: 0.6)
                        : (widget.selectable ? color : brand.borderStrong),
                    width: 1.5,
                  ),
                  boxShadow: conquered || widget.selectable
                      ? [
                          BoxShadow(
                              color: color.withValues(
                                  alpha: conquered ? 0.6 : 0.3 + t * 0.4),
                              blurRadius: 10 + t * 6)
                        ]
                      : null,
                ),
                child: child,
              );
            },
            child: Icon(
              conquered
                  ? Icons.flag_rounded
                  : (widget.selectable
                      ? Icons.add_rounded
                      : Icons.location_on_outlined),
              size: 16,
              color: conquered
                  ? Colors.white
                  : (widget.selectable ? color : brand.textMuted),
            ),
          ),
          const SizedBox(height: 3),
          Text(widget.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.ui(
                  size: 10,
                  weight: FontWeight.w700,
                  color: (conquered || widget.selectable)
                      ? brand.textPrimary
                      : brand.textMuted)),
        ],
      ),
    );
  }
}
