import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/utils/eyebrow_format.dart';

class _BannerState {
  final String icon;
  final String label;
  final String title;
  final String subtitle;

  const _BannerState({
    required this.icon,
    required this.label,
    required this.title,
    required this.subtitle,
  });
}

/// Modo del banner. `openNow` (default) usa el copy original "X lugares
/// para almorzar/cenar/…". `openingSoon` es el fallback para islas donde
/// la cocina arranca más tarde — anuncia restaurantes que abren hoy en
/// las próximas horas en lugar de mentir con "lugares abiertos".
enum HourBannerMode { openNow, openingSoon }

/// Genera el título a partir del count real (`count`) y un nombre con
/// pluralización simple (`singular` / `plural`).
String _titleFor(int? count, String singular, String plural) {
  if (count == null) return plural[0].toUpperCase() + plural.substring(1);
  if (count == 1) return '1 $singular';
  return '$count $plural';
}

/// Variante del state para el modo `openingSoon`. Mantiene el eyebrow
/// (`12:00 · MEDIODÍA · HOY EN EL HIERRO`) que sigue siendo cierto, pero
/// cambia el título y el subtítulo a algo culturalmente aware: en islas
/// pequeñas la cocina arranca un poco más tarde, no es un fallo.
_BannerState _openingSoonState(int hour, int? count, String? zoneLabel) {
  // Icono: reloj — comunica "es cuestión de minutos" sin gritar.
  const icon = '⏱';
  final label = '$hour:00 · EN ${(zoneLabel ?? '').toUpperCase()}'.trim();
  final title = _titleFor(count, 'lugar abre pronto', 'lugares abren pronto');
  // Subtítulo geo-aware: si tenemos zona/isla la nombramos, si no copy
  // genérico. La idea es educar al turista, no disculparse.
  final subtitle = (zoneLabel != null && zoneLabel.trim().isNotEmpty)
      ? '"En ${zoneLabel} la cocina arranca un poco más tarde"'
      : '"La cocina arranca enseguida — apunta estos sitios"';
  return _BannerState(
    icon: icon,
    label: label.isEmpty ? '$hour:00' : label,
    title: title,
    subtitle: subtitle,
  );
}

_BannerState _stateForHour(int hour, int? count) {
  if (hour >= 7 && hour <= 11) {
    return _BannerState(
      icon: '☀️',
      label: '$hour:00 · MAÑANA',
      title: _titleFor(count, 'bar para desayunar', 'bares para desayunar'),
      subtitle: '"Empieza el día con un buen café"',
    );
  }
  if (hour == 12) {
    return _BannerState(
      icon: '🍽',
      label: '12:00 · MEDIODÍA',
      title: _titleFor(count, 'lugar para almorzar', 'lugares para almorzar'),
      subtitle: '"A esta hora se llena todo"',
    );
  }
  if (hour == 13) {
    return _BannerState(
      icon: '🍽',
      label: '13:00 · ALMUERZO',
      title: _titleFor(count, 'lugar para almorzar', 'lugares para almorzar'),
      subtitle: '"Hora punta del almuerzo canario"',
    );
  }
  if (hour >= 14 && hour <= 16) {
    return _BannerState(
      icon: '🍽',
      label: '$hour:00 · SOBREMESA',
      title: _titleFor(count, 'todavía sirviendo', 'todavía sirviendo comidas'),
      subtitle: '"Todavía hay mesa para ti"',
    );
  }
  if (hour >= 17 && hour <= 19) {
    return _BannerState(
      icon: '🌇',
      label: '$hour:00 · GOLDEN HOUR',
      title: _titleFor(count, 'terraza con atardecer', 'terrazas con atardecer'),
      subtitle: '"El sol pinta el Atlántico de naranja"',
    );
  }
  if (hour >= 20) {
    return _BannerState(
      icon: '🌙',
      label: '$hour:00 · NOCHE',
      title: _titleFor(count, 'cena abierta', 'cenas abiertas'),
      subtitle: '"La noche canaria empieza aquí"',
    );
  }
  return _BannerState(
    icon: '🌙',
    label: '$hour:00 · MADRUGADA',
    title: _titleFor(count, 'local abierto ahora', 'locales abiertos ahora'),
    subtitle: '"La isla nunca duerme del todo"',
  );
}

/// Encabezado contextual por hora que actúa como cabecera de la sección
/// "HOY EN ...". El banner y los restaurantes que aparecen debajo son
/// el mismo bloque conceptual: el banner anuncia y las cards responden.
class HourAwareBanner extends StatelessWidget {
  final int hour;
  final String? zoneLabel;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Número real de restaurantes que pasaron el filtro contextual. Si es
  /// `null` (estado de carga) el banner usa un título genérico sin cifra.
  final int? count;

  /// Modo del banner. Ver [HourBannerMode].
  final HourBannerMode mode;

  const HourAwareBanner({
    super.key,
    required this.hour,
    this.zoneLabel,
    this.actionLabel,
    this.onAction,
    this.count,
    this.mode = HourBannerMode.openNow,
  });

  @override
  Widget build(BuildContext context) {
    final s = mode == HourBannerMode.openingSoon
        ? _openingSoonState(hour, count, zoneLabel)
        : _stateForHour(hour, count);
    final eyebrowColor = context.brand.textSecondary;
    // En modo openingSoon el label ya incluye la zona; en openNow seguimos
    // el formato clásico `12:00 · MEDIODÍA · HOY EN TENERIFE`.
    final eyebrowText = (mode == HourBannerMode.openNow && zoneLabel != null)
        ? eyebrowJoin([s.label, 'HOY EN ${zoneLabel!.toUpperCase()}'])
        : s.label;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(s.icon, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        eyebrowText,
                        style: AppTextStyles.eyebrow(
                          size: 10,
                          color: eyebrowColor,
                        ),
                      ),
                    ),
                    if (actionLabel != null && onAction != null)
                      GestureDetector(
                        onTap: onAction,
                        behavior: HitTestBehavior.opaque,
                        child: Text(
                          '${actionLabel!} ›',
                          style: AppTextStyles.ui(
                            size: 11,
                            color: AppColors.atlanticoClaro,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  s.title,
                  style: AppTextStyles.displaySection(
                    size: AppTextStyles.sectionHeadlineSize,
                    color: context.brand.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s.subtitle,
                  style: AppTextStyles.editorial(
                    size: 11,
                    color: context.brand.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
