import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/model/weather_data.dart';

/// Cápsulas flotantes superiores: [🌋 Isla | Zona]   [☁ 22°]
/// Sin pill de municipio — el filtro de municipio va en la búsqueda avanzada.
class TopFilterBar extends StatelessWidget {
  final String islandLabel;
  final String? zoneLabel;
  final WeatherData weather;
  final VoidCallback onZoneTap;

  const TopFilterBar({
    super.key,
    required this.islandLabel,
    this.zoneLabel,
    required this.weather,
    required this.onZoneTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 12,
        right: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Cápsula izquierda: isla + zona
          _GlassCapsule(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Pill(
                    label: islandLabel.toUpperCase(),
                    icon: '🌋',
                    onTap: onZoneTap,
                  ),
                  const SizedBox(width: 10),
                  _Divider(),
                  const SizedBox(width: 10),
                  _Pill(
                    label: (zoneLabel ?? 'Zona').toUpperCase(),
                    onTap: onZoneTap,
                    faded: zoneLabel == null,
                  ),
                ],
              ),
            ),
          ),
          // Cápsula derecha: clima
          _GlassCapsule(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    weather.isAvailable ? weather.emoji : '—',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    weather.isAvailable ? weather.displayTemp : '— °',
                    style: AppTextStyles.ui(
                      size: 13,
                      weight: FontWeight.w700,
                      color: context.brand.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCapsule extends StatelessWidget {
  final Widget child;
  final Alignment alignment;
  const _GlassCapsule({required this.child, this.alignment = Alignment.center});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: IntrinsicWidth(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: context.brand.glass,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: context.brand.border,
                width: 0.6,
              ),
            ),
            alignment: alignment,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final String? icon;
  final VoidCallback onTap;
  final bool faded;

  const _Pill({
    required this.label,
    this.icon,
    required this.onTap,
    this.faded = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Text(icon!, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.ui(
                  size: 11,
                  weight: FontWeight.w700,
                  color: faded
                      ? context.brand.textMuted
                      : context.brand.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 16,
      color: context.brand.borderStrong,
    );
  }
}
