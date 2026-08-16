import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_shapes.dart';
import 'package:guachinches/config/app_spacing.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/domain/occasions/occasion.dart';
import 'package:guachinches/ui/components/section_header.dart';

/// Banner "DESCUBRE PLANES" — la recomendación anticipada del home, firmada por
/// los personajes de Jonay & Joana. Ilustración multi-personaje arriba + banda
/// de color con el plan de la ocasión (eyebrow + titular + subcopy) y botón
/// circular. El copy lo decide el motor (`domain/occasions/`); aquí solo se
/// pinta. Tap (banner, flecha o "Ver todos") → búsqueda filtrada al plan.
class OccasionPlannerCard extends StatelessWidget {
  final Occasion occasion;
  final VoidCallback onTap;

  /// Si se pasa, se pinta una × para que el usuario cierre el banner.
  final VoidCallback? onDismiss;

  const OccasionPlannerCard({
    super.key,
    required this.occasion,
    required this.onTap,
    this.onDismiss,
  });

  /// Ilustración del banner (multi-personaje, fondo cielo claro).
  static const String _bannerAsset = 'assets/images/new-home/banner_all_plan.png';

  /// Color de la banda por clave de ocasión (el dominio solo guarda la clave).
  static const Map<String, Color> _accents = {
    'festivo': AppColors.mojo, // fiesta
    'brunch': Color(0xFFE0883C), // naranja cálido
    'finde': AppColors.atlantico, // azul plan
    'tradicion': Color(0xFF8E3B46), // vino guachinche
  };

  @override
  Widget build(BuildContext context) {
    final accent = _accents[occasion.accentKey] ?? AppColors.atlantico;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Descubre planes',
          actionLabel: 'Ver todos',
          onAction: onTap,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter, 0, AppSpacing.gutter, 8),
          child: Semantics(
            identifier: 'home-section-occasion',
            button: true,
            label: '${occasion.headline}. ${occasion.tagline}',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              // Sombra en el Container exterior; el ClipRRect (interior) solo
              // recorta el contenido, no la sombra.
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: AppShadows.soft(),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: Stack(
                    children: [
                      Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Ilustración (escena con fondo propio: Teide + mar) ─
                      // Franja ancha + alineación ARRIBA: conserva el Teide y el
                      // cielo, y la banda corta a los personajes por las piernas
                      // (no de cuerpo entero), que es como mejor queda.
                      AspectRatio(
                        aspectRatio: 2.05,
                        child: Image.asset(
                          _bannerAsset,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          // Se pinta a ~ancho de pantalla: downsample para no
                          // tener 1672px en memoria de más.
                          cacheWidth: 1080,
                          errorBuilder: (_, __, ___) =>
                              ColoredBox(color: accent.withValues(alpha: 0.25)),
                        ),
                      ),
                      // ── Banda del plan ────────────────────────────────────
                          _PlanBand(occasion: occasion, accent: accent),
                        ],
                      ),
                      if (onDismiss != null)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: _DismissButton(onDismiss: onDismiss!),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanBand extends StatelessWidget {
  final Occasion occasion;
  final Color accent;

  const _PlanBand({required this.occasion, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: accent,
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.sol,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        occasion.eyebrow,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.eyebrow(
                          size: 11,
                          color: Colors.white.withValues(alpha: 0.92),
                        ).copyWith(letterSpacing: 1.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  occasion.headline.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.displaySection(
                    size: 25,
                    color: Colors.white,
                  ).copyWith(height: 1.02, letterSpacing: 0.3),
                ),
                if (occasion.tagline.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    occasion.tagline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.editorial(size: 14).copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          _ArrowButton(accent: accent),
        ],
      ),
    );
  }
}

/// × para cerrar el banner. Chip oscuro translúcido sobre el cielo claro.
class _DismissButton extends StatelessWidget {
  final VoidCallback onDismiss;
  const _DismissButton({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'home-occasion-dismiss',
      button: true,
      label: 'Cerrar',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onDismiss,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.32),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

/// Botón circular blanco con la flecha en el color de la banda.
class _ArrowButton extends StatelessWidget {
  final Color accent;
  const _ArrowButton({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'home-occasion-cta',
      button: true,
      label: 'Ver plan',
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(Icons.arrow_forward_rounded, color: accent, size: 26),
      ),
    );
  }
}
