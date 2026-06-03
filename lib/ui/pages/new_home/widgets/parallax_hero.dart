import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/ui/components/weather_layer.dart';
import 'package:guachinches/utils/time_of_day_engine.dart';
import 'starfield_painter.dart';
import 'sun_moon_arc.dart';

/// Altura total del bloque hero (foto + contenido editorial).
const double kHeroHeight = 340.0;

/// Bloque hero con:
/// - Foto de zona con parallax
/// - Tinte RGBA según hora
/// - Starfield animado
/// - Sol/luna en arco
/// - Texto editorial (saludo, título, copy, count)
class ParallaxHero extends StatelessWidget {
  final double scrollOffset;
  final int hour;
  final String? photoUrl;   // URL remota de la foto de zona
  final String? assetImage; // Asset local fallback
  final String zona;
  final String islandLabel;
  final bool zoneIsSet;
  final int openCount;
  final VoidCallback onZoneChipTap;
  final VoidCallback onIslandChipTap;
  /// Frase editorial fija por isla. Si viene, sustituye a la copy por hora.
  final String? islandPhrase;

  const ParallaxHero({
    super.key,
    required this.scrollOffset,
    required this.hour,
    this.photoUrl,
    this.assetImage,
    required this.zona,
    required this.islandLabel,
    required this.zoneIsSet,
    required this.openCount,
    required this.onZoneChipTap,
    required this.onIslandChipTap,
    this.islandPhrase,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final heroW = size.width;
    const heroH = kHeroHeight;

    final tint = AppColors.tintForHour(hour);
    final starOpacity = AppColors.starsForHour(hour);
    final greeting = TimeOfDayEngine.greeting(DateTime.now(), context);
    final copy = (islandPhrase != null && islandPhrase!.isNotEmpty)
        ? islandPhrase!
        : TimeOfDayEngine.editorialCopy(DateTime.now(), zona: zona);

    return SizedBox(
      height: heroH,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Capas decorativas → IgnorePointer para que drags pasen al
          // CustomScrollView que está detrás (sigue scrolleando al
          // arrastrar sobre la foto). Solo el contenido editorial (chip)
          // captura taps.
          IgnorePointer(
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // Foto con parallax.
                // OJO: el Positioned debe ser hijo DIRECTO del Stack. El
                // RepaintBoundary va DENTRO del Positioned (no fuera): si
                // envuelve al Positioned, su parentData deja de ser
                // StackParentData y revienta todo el hero en release
                // ('type ParentData is not a subtype of StackParentData').
                Positioned(
                  top: -scrollOffset * 0.4,
                  left: 0, right: 0,
                  height: heroH + 40,
                  child: RepaintBoundary(child: _buildPhoto(context)),
                ),
                // Tinte de hora
                AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  color: tint,
                ),
                // Capa meteorológica: consulta tiempo real (Open-Meteo) y
                // compone nubes/lluvia según condición actual.
                const Positioned.fill(child: WeatherLayer()),
                // Degradado mínimo solo al final del hero
                Positioned(
                  bottom: 0, left: 0, right: 0, height: 30,
                  child: _buildFadeGradient(context),
                ),
                // Starfield
                if (starOpacity > 0)
                  StarfieldWidget(
                    opacity: starOpacity,
                    heroSize: Size(heroW, heroH),
                  ),
                // Sol / Luna
                SunMoonArc(
                    hour: hour, heroWidth: heroW, heroHeight: heroH),
              ],
            ),
          ),
          // Contenido editorial — fuera del IgnorePointer, así el chip
          // de zona/isla recibe taps.
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildEditorialContent(context, greeting, copy),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoto(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: photoUrl!,
        fit: BoxFit.cover,
        memCacheWidth: 800,
        placeholder: (_, __) => _localPhoto(context),
        errorWidget: (_, __, ___) => _localPhoto(context),
      );
    }
    return _localPhoto(context);
  }

  Widget _localPhoto(BuildContext context) {
    // Fondo de marca sólido SIEMPRE detrás de la foto: si el asset no decodifica
    // (p.ej. fallo de memoria/codec en release), el texto editorial blanco del
    // hero queda sobre un azul atlántico legible, nunca sobre gris.
    const fallback = AppColors.atlantico;
    if (assetImage != null) {
      return Container(
        color: fallback,
        child: Image.asset(
          assetImage!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => const ColoredBox(color: fallback),
        ),
      );
    }
    return Container(color: fallback);
  }

  Widget _buildFadeGradient(BuildContext context) {
    // Fade fino de 30px solo al borde inferior — transición foto → scaffold.
    // El resto del hero queda como foto pura.
    final tint = context.brand.base;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, tint],
        ),
      ),
    );
  }

  Widget _buildEditorialContent(BuildContext context, String greeting, String copy) {
    // Sombra sutil para legibilidad del texto blanco sobre la foto
    // (sustituye al overlay negro pesado).
    // Doble sombra para mejor contraste sobre cualquier zona de la foto
    final textShadows = [
      Shadow(
        color: Colors.black.withOpacity(0.7),
        blurRadius: 16,
        offset: const Offset(0, 2),
      ),
      Shadow(
        color: Colors.black.withOpacity(0.5),
        blurRadius: 4,
        offset: const Offset(0, 1),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Saludo
          Text(
            '${greeting.toUpperCase()} · ${islandLabel.toUpperCase()}',
            style: AppTextStyles.eyebrow(
              size: 12,
              color: Colors.white.withOpacity(0.9),
            ).copyWith(shadows: textShadows),
          ),
          const SizedBox(height: 10),
          // Título — primera línea (siempre blanco — texto editorial sobre foto)
          Text(
            '¿DÓNDE COMEMOS',
            style: AppTextStyles.displayHero(size: 32, color: Colors.white)
                .copyWith(shadows: textShadows),
          ),
          // Título — segunda línea con chip de zona alineado
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('HOY ',
                  style: AppTextStyles.displayHero(size: 32, color: Colors.white)
                      .copyWith(shadows: textShadows)),
              _ZoneChip(
                label: zona,
                onTap: zoneIsSet ? onZoneChipTap : onIslandChipTap,
              ),
              Text(' ?',
                  style: AppTextStyles.displayHero(size: 32, color: Colors.white)
                      .copyWith(shadows: textShadows)),
            ],
          ),
          const SizedBox(height: 8),
          // Copy editorial (frase por isla)
          Text(
            '"$copy"',
            style: AppTextStyles.editorial(size: 12, color: Colors.white.withOpacity(0.85))
                .copyWith(shadows: textShadows),
          ),
          const SizedBox(height: 4),
          // Count abiertos
          Text(
            '$openCount lugares abiertos · $zona',
            style: AppTextStyles.muted(size: 8, color: Colors.white.withOpacity(0.75))
                .copyWith(shadows: textShadows),
          ),
        ],
      ),
    );
  }
}

/// Chip de zona/isla con tratamiento *liquid-glass* (frosted material).
///
/// Por qué glass y no color sólido:
/// - El hero pinta una foto distinta por isla + tinte por hora del día + capa
///   meteorológica. Cualquier color fijo va a pelearse con ese fondo en algún
///   momento del día (azul vs sunset, blanco vs nube blanca, etc.).
/// - El glass *toma prestada* la paleta del fondo (blur 18px) y le suma un
///   velo blanco a 30% top → 14% bottom. Resultado: el chip siempre se lee
///   pero nunca se desentona del hero.
///
/// Detalles deliberados (no es solo "ponle blur"):
/// - `BackdropFilter` necesita `ClipRRect` por encima para no sangrar fuera
///   del radio del chip.
/// - El shadow va en el `Container` *exterior* al `ClipRRect`; si lo metes
///   dentro queda recortado por el clip y no se ve.
/// - Sombra sutil sobre el texto (no la del título global) para que las
///   letras se separen del propio cristal cuando la foto detrás es muy
///   uniforme.
/// - Hairline `Colors.white @ 45%` — 1px, no 1.5: a 32pt de texto, 1.5
///   parece "borde de botón Android". 1px es Apple.
/// - Chevron sigue siendo el affordance principal de "esto se abre".
class _ZoneChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ZoneChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        // Sombra fuera del clip para que se vea — separa el chip de la foto.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 2, 8, 2),
              decoration: BoxDecoration(
                // Velo glass: top más opaco para enganchar el ojo en el texto,
                // bottom más translúcido para que el blur respire.
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.30),
                    Colors.white.withOpacity(0.14),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.45),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: AppTextStyles.displayHero(size: 32).copyWith(
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.45),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Chevron en blanco para coherencia con el texto. El brand
                  // (atlántico) ya está presente en el resto de la app —
                  // no hace falta meterlo dentro del cristal.
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.white.withOpacity(0.95),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
