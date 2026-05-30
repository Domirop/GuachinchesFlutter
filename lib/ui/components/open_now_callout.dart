import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';

/// Callout "Abiertos AHORA" — entry point a [CercaAhoraScreen].
///
/// Diseño:
/// - Fondo `surface` del tema (theme-aware light/dark), no amarillo brillante:
///   evita el choque visual con la paleta atlántico y arregla el contraste
///   bajo del card antiguo (texto blanco sobre amarillo crema = ~1.8:1).
/// - Banda lateral izquierda gruesa (4px) en `laurisilva` (verde "abierto")
///   como indicador semántico — el ojo lee "estado en vivo" sin necesidad de
///   leer copy.
/// - LIVE dot pulsante (animación opacity 0.4 → 1.0 en loop) refuerza el
///   sentido de "ahora mismo".
/// - Jerarquía: eyebrow pequeño ("ABIERTOS AHORA · TENERIFE") sobre número
///   grande ("23 sitios cerca") en lugar de texto plano de 15pt.
/// - Si [count] == 0 cambia a tono `sol` (amarillo cálido) con copy "Sin
///   abiertos cerca · Abren pronto" — sigue siendo accionable.
class OpenNowCallout extends StatefulWidget {
  /// Número de restaurantes abiertos AHORA en el contexto actual.
  final int count;

  /// Nombre de isla / zona para el contexto ("Tenerife", "La Gomera"…).
  final String contextLabel;

  /// Acción al tap. Si null, el callout pierde la sombra y el chevron.
  final VoidCallback? onTap;

  const OpenNowCallout({
    super.key,
    required this.count,
    required this.contextLabel,
    this.onTap,
  });

  @override
  State<OpenNowCallout> createState() => _OpenNowCalloutState();
}

class _OpenNowCalloutState extends State<OpenNowCallout>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasOpen = widget.count > 0;
    // Color semántico: verde si hay abiertos, sol (cálido) si toca esperar.
    final accent = hasOpen ? AppColors.laurisilva : AppColors.sol;
    final eyebrowText = hasOpen
        ? 'ABIERTOS AHORA · ${widget.contextLabel.toUpperCase()}'
        : 'ABRE PRONTO · ${widget.contextLabel.toUpperCase()}';
    final headlineText = hasOpen
        ? _headlineForCount(widget.count)
        : 'Sin abiertos cerca';
    final supportText =
        hasOpen ? 'Toca para ver el listado' : 'Abren a lo largo del día';

    return Semantics(
      identifier: 'home-cerca-ahora-cta',
      button: widget.onTap != null,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          decoration: BoxDecoration(
            color: context.brand.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.brand.border, width: 1),
            boxShadow: widget.onTap == null
                ? null
                : [
                    BoxShadow(
                      color: accent.withOpacity(0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          clipBehavior: Clip.hardEdge,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Banda lateral: indicador semántico de "estado en vivo".
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  if (hasOpen) ...[
                                    _LiveDot(controller: _pulse, color: accent),
                                    const SizedBox(width: 6),
                                  ],
                                  Flexible(
                                    child: Text(
                                      eyebrowText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.eyebrow(
                                        size: 10,
                                        color: accent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                headlineText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.displayHero(
                                  size: 22,
                                  color: context.brand.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                supportText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.ui(
                                  size: 12,
                                  color: context.brand.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.onTap != null)
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: accent,
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Copy del headline en función del count. Singular vs plural y un fallback
  /// "Muchos sitios cerca" para > 99 que evita números desproporcionados en el
  /// hero (mantiene la composición tipográfica).
  String _headlineForCount(int n) {
    if (n == 1) return '1 sitio abierto cerca';
    if (n > 99) return 'Muchos abiertos cerca';
    return '$n sitios abiertos cerca';
  }
}

/// Punto verde pulsante. Animación rápida (opacity + scale) para comunicar
/// "live" sin distraer. Stateless por fuera — el [controller] lo gestiona el
/// padre, así evitamos múltiples controllers si el callout se reconstruye.
class _LiveDot extends StatelessWidget {
  final AnimationController controller;
  final Color color;

  const _LiveDot({required this.controller, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value; // 0 → 1 → 0
        final opacity = 0.45 + 0.55 * t;
        final scale = 0.85 + 0.15 * t;
        return SizedBox(
          width: 10,
          height: 10,
          child: Center(
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color.withOpacity(opacity),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.35 * t),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
