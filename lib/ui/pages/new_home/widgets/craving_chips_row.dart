import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_shapes.dart';
import 'package:guachinches/config/app_spacing.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/domain/cravings/craving.dart';

/// Fila "¿Qué te apetece ahora?" — bandeja *liquid glass* con círculos de
/// antojo. El ranking cambia según hora + clima + día (`rankCravings`); el
/// primero es la recomendación destacada. Tocar abre la búsqueda filtrada.
///
/// Rendimiento: un único [BackdropFilter] (la bandeja) hace el frost; los
/// círculos son cristal pintado (gradiente + brillo + sombra), sin blur por
/// círculo, para no multiplicar difuminados en cada frame de scroll.
class CravingChipsRow extends StatelessWidget {
  final List<Craving> cravings;
  final ValueChanged<Craving> onTap;

  const CravingChipsRow({
    super.key,
    required this.cravings,
    required this.onTap,
  });

  static const double _circle = 82;

  /// Tinte de acento muy sutil por familia (da vida sin romper el cristal).
  static const Map<String, Color> _accents = {
    'cafe': Color(0xFFB07A3C),
    'terraza': Color(0xFF4FA35A),
    'mar': Color(0xFF1E88C7),
    'cuchara': Color(0xFFD2762E),
    'tradicion': Color(0xFF8E3B46),
    'tapeo': Color(0xFFC44A3D),
    'carne': Color(0xFF7A4A35),
    'vistas': Color(0xFF2E9C9C),
    'cena': Color(0xFF3A4E8C),
    'tasca': Color(0xFFC79A2E),
    'copas': Color(0xFF7A4FB0),
  };

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
                AppSpacing.gutter, 0, AppSpacing.gutter, 12),
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
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(13, 13, 13, 13),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    // Lámina de cristal: brillo arriba, hairline claro, sombra.
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.34),
                        Colors.white.withValues(alpha: 0.12),
                      ],
                    ),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
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
                        accent: _accents[cravings[i].family] ?? AppColors.atlantico,
                        featured: i == 0,
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

/// Círculo de cristal con curvatura: tinte de acento sutil, brillo especular
/// superior, borde claro y sombra doble (ambiente + contacto). El destacado
/// añade un anillo + halo de acento. Pulsación con micro-escala.
class _GlassCircle extends StatefulWidget {
  final Craving craving;
  final double diameter;
  final Color accent;
  final bool featured;
  final VoidCallback onTap;

  const _GlassCircle({
    required this.craving,
    required this.diameter,
    required this.accent,
    required this.featured,
    required this.onTap,
  });

  @override
  State<_GlassCircle> createState() => _GlassCircleState();
}

class _GlassCircleState extends State<_GlassCircle> {
  bool _pressed = false;
  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final accent = widget.accent;
    final d = widget.diameter;
    return Semantics(
      identifier: 'home-craving-${widget.craving.id}',
      button: true,
      label: widget.craving.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) {
          _setPressed(false);
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.93 : 1.0,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: SizedBox(
            width: d,
            height: d,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  // Sombra de ambiente (suave y amplia).
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                  // Sombra de contacto (fina, da nitidez).
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                  // Halo de acento solo en el destacado.
                  if (widget.featured)
                    BoxShadow(
                      color: accent.withValues(alpha: 0.35),
                      blurRadius: 16,
                    ),
                ],
              ),
              child: ClipOval(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Cuerpo de cristal: blanco translúcido con un punto de tinte.
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color.alphaBlend(
                                accent.withValues(alpha: 0.06),
                                Colors.white.withValues(alpha: 0.62)),
                            Color.alphaBlend(
                                accent.withValues(alpha: 0.20),
                                Colors.white.withValues(alpha: 0.22)),
                          ],
                        ),
                      ),
                    ),
                    // Brillo especular superior (sheen).
                    Align(
                      alignment: const Alignment(0, -1.25),
                      child: Container(
                        width: d * 0.95,
                        height: d * 0.62,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.75),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Contenido.
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(widget.craving.emoji,
                              style: const TextStyle(fontSize: 29)),
                          const SizedBox(height: 2),
                          Text(
                            widget.craving.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.ui(
                              size: 11,
                              weight: FontWeight.w800,
                              color: brand.textPrimary,
                            ).copyWith(shadows: const [
                              Shadow(color: Color(0x80FFFFFF), blurRadius: 2),
                            ]),
                          ),
                        ],
                      ),
                    ),
                    // Anillo de borde (más marcado y de acento en el destacado).
                    DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.featured
                              ? accent.withValues(alpha: 0.7)
                              : Colors.white.withValues(alpha: 0.7),
                          width: widget.featured ? 1.6 : 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
