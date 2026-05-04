import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/model/TopRestaurants.dart';

/// Card "Elección del Editor" — fondo gradiente Atlántico.
class CardEditorPick extends StatefulWidget {
  final TopRestaurants restaurant;
  final VoidCallback onTap;

  const CardEditorPick({
    super.key,
    required this.restaurant,
    required this.onTap,
  });

  @override
  State<CardEditorPick> createState() => _CardEditorPickState();
}

class _CardEditorPickState extends State<CardEditorPick> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.restaurant;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.profundo,
                AppColors.atlantico,
                AppColors.atlanticoClaro,
              ],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ELECCIÓN DEL EDITOR',
                      style: AppTextStyles.eyebrow(
                        size: 8,
                        color: context.brand.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      r.nombre.toUpperCase(),
                      style: AppTextStyles.displaySection(size: 20, color: Colors.white),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      r.municipio,
                      style: AppTextStyles.editorial(
                        size: 11,
                        color: AppColors.crema.withOpacity(0.65),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _GlassPill(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: AppColors.sol, size: 12),
                              const SizedBox(width: 3),
                              Text(
                                r.avg.toStringAsFixed(1),
                                style: AppTextStyles.ui(
                                  size: 11,
                                  weight: FontWeight.w600,
                                  color: AppColors.sol,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const _GlassPill(
                          child: Text(
                            '8–15€',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Número decorativo
              Text(
                '01',
                style: AppTextStyles.displayHero(size: 64)
                    .copyWith(color: Colors.white.withOpacity(0.12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  final Widget child;

  const _GlassPill({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: child,
    );
  }
}
