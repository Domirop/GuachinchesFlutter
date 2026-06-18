import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:guachinches/config/app_shapes.dart';
import 'package:guachinches/config/app_spacing.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/domain/cravings/craving.dart';

/// Fila "¿Qué te apetece ahora?" — píldora *liquid glass* con círculos de
/// antojo. El ranking cambia según hora + clima + día (ver `rankCravings`);
/// tocar un círculo abre la búsqueda con su filtro temático.
///
/// Rendimiento: un único [BackdropFilter] (la píldora) hace el frost; los
/// círculos son cristal translúcido SIN blur propio, así no multiplicamos
/// difuminados en cada frame de scroll.
class CravingChipsRow extends StatelessWidget {
  final List<Craving> cravings;
  final ValueChanged<Craving> onTap;

  const CravingChipsRow({
    super.key,
    required this.cravings,
    required this.onTap,
  });

  static const double _circle = 80;

  @override
  Widget build(BuildContext context) {
    if (cravings.isEmpty) return const SizedBox.shrink();
    final brand = context.brand;
    return Semantics(
      identifier: 'home-section-cravings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter, 0, AppSpacing.gutter, 10),
            child: Text(
              '¿QUÉ TE APETECE AHORA?',
              style: AppTextStyles.eyebrow(size: 11, color: brand.textSecondary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: BackdropFilter(
                // Único frost de toda la píldora (liquid glass).
                filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.45), width: 1),
                    // Lámina de cristal: leve degradado claro arriba.
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.30),
                        Colors.white.withValues(alpha: 0.10),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    height: _circle,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      padding: EdgeInsets.zero,
                      itemCount: cravings.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => _GlassCircle(
                        craving: cravings[i],
                        diameter: _circle,
                        onTap: () => onTap(cravings[i]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Círculo de cristal: translúcido, con brillo superior, borde claro y sombra
/// suave. Emoji grande + etiqueta corta. Sin blur propio (lo aporta la píldora).
class _GlassCircle extends StatelessWidget {
  final Craving craving;
  final double diameter;
  final VoidCallback onTap;

  const _GlassCircle({
    required this.craving,
    required this.diameter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Semantics(
      identifier: 'home-craving-${craving.id}',
      button: true,
      label: craving.label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: diameter,
          height: diameter,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Cristal con curvatura: brillo arriba-izquierda → sombra abajo.
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.55),
                  Colors.white.withValues(alpha: 0.14),
                ],
              ),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.65), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(craving.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    craving.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.ui(
                      size: 10.5,
                      weight: FontWeight.w800,
                      color: brand.textPrimary,
                    ).copyWith(shadows: const [
                      Shadow(color: Color(0x66FFFFFF), blurRadius: 2),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
