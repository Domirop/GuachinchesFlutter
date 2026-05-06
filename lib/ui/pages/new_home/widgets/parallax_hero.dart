import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
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
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final heroW = size.width;
    const heroH = kHeroHeight;

    final tint = AppColors.tintForHour(hour);
    final starOpacity = AppColors.starsForHour(hour);
    final greeting = TimeOfDayEngine.greeting(DateTime.now());
    final copy = TimeOfDayEngine.editorialCopy(DateTime.now(), zona: zona);

    return SizedBox(
      height: heroH,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Foto con parallax
          RepaintBoundary(
            child: Positioned(
              top: -scrollOffset * 0.4,
              left: 0, right: 0,
              height: heroH + 40,
              child: _buildPhoto(context),
            ),
          ),
          // Tinte de hora
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            color: tint,
          ),
          // Degradado mínimo solo al final del hero (transición foto → scaffold)
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
          SunMoonArc(hour: hour, heroWidth: heroW, heroHeight: heroH),
          // Contenido editorial
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
    if (assetImage != null) {
      return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(assetImage!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return Container(color: context.brand.surface);
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
          // Copy editorial
          Text(
            '"$copy"',
            style: AppTextStyles.editorial(size: 10, color: Colors.white.withOpacity(0.85))
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

class _ZoneChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ZoneChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.atlantico.withOpacity(0.22),
          border: Border.all(
            color: AppColors.atlantico.withOpacity(0.50),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: AppTextStyles.displayHero(size: 32).copyWith(
                color: AppColors.atlanticoClaro,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.atlanticoClaro, size: 22),
          ],
        ),
      ),
    );
  }
}
