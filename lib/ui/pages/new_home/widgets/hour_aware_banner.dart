import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';

class _BannerState {
  /// Eyebrow contextual, ej. `AHORA · HORA DEL ALMUERZO`.
  final String label;

  /// Título grande, ej. `34 SITIOS PARA ALMORZAR`.
  final String title;
  final String subtitle;

  const _BannerState({
    required this.label,
    required this.title,
    required this.subtitle,
  });
}

/// Modo del banner. `openNow` (default) usa el copy original "X sitios
/// para almorzar/cenar/…". `openingSoon` es el fallback para islas donde
/// la cocina arranca más tarde — anuncia restaurantes que abren hoy en
/// las próximas horas en lugar de mentir con "sitios abiertos".
enum HourBannerMode { openNow, openingSoon }

/// Genera el título a partir del count real (`count`) y un nombre con
/// pluralización simple (`singular` / `plural`). Devuelve mayúsculas para
/// el look editorial de la card contextual ("34 SITIOS PARA ALMORZAR").
String _titleFor(int? count, String singular, String plural) {
  if (count == null) return plural;
  if (count == 1) return '1 $singular';
  return '$count $plural';
}

/// Variante del state para el modo `openingSoon`. El eyebrow comunica
/// "pronto" en vez de "ahora", y el copy es culturalmente aware: en islas
/// pequeñas la cocina arranca un poco más tarde, no es un fallo.
_BannerState _openingSoonState(int hour, int? count, String? zoneLabel) {
  final label = (zoneLabel != null && zoneLabel.trim().isNotEmpty)
      ? 'EN BREVE · EN ${zoneLabel.toUpperCase()}'
      : 'EN BREVE · ABREN PRONTO';
  final title = _titleFor(count, 'SITIO ABRE PRONTO', 'SITIOS ABREN PRONTO');
  final subtitle = (zoneLabel != null && zoneLabel.trim().isNotEmpty)
      ? '"En ${zoneLabel} la cocina arranca un poco más tarde"'
      : '"La cocina arranca enseguida — apunta estos sitios"';
  return _BannerState(label: label, title: title, subtitle: subtitle);
}

_BannerState _stateForHour(int hour, int? count) {
  if (hour >= 7 && hour <= 11) {
    return _BannerState(
      label: 'AHORA · HORA DEL DESAYUNO',
      title: _titleFor(count, 'SITIO PARA DESAYUNAR', 'SITIOS PARA DESAYUNAR'),
      subtitle: '"Empieza el día con un buen café"',
    );
  }
  if (hour == 12) {
    return _BannerState(
      label: 'AHORA · HORA DEL ALMUERZO',
      title: _titleFor(count, 'SITIO PARA ALMORZAR', 'SITIOS PARA ALMORZAR'),
      subtitle: '"A esta hora se llena todo"',
    );
  }
  if (hour == 13) {
    return _BannerState(
      label: 'AHORA · HORA DEL ALMUERZO',
      title: _titleFor(count, 'SITIO PARA ALMORZAR', 'SITIOS PARA ALMORZAR'),
      subtitle: '"Hora punta del almuerzo canario"',
    );
  }
  if (hour >= 14 && hour <= 16) {
    return _BannerState(
      label: 'AHORA · TODAVÍA ABIERTOS',
      title: _titleFor(count, 'SITIO PARA ALMORZAR', 'SITIOS PARA ALMORZAR'),
      subtitle: '"Todavía hay mesa para ti"',
    );
  }
  if (hour >= 17 && hour <= 19) {
    return _BannerState(
      label: 'AHORA · GOLDEN HOUR',
      title: _titleFor(count, 'TERRAZA AL ATARDECER', 'TERRAZAS AL ATARDECER'),
      subtitle: '"El sol pinta el Atlántico de naranja"',
    );
  }
  if (hour >= 20) {
    return _BannerState(
      label: 'AHORA · HORA DE LA CENA',
      title: _titleFor(count, 'SITIO PARA CENAR', 'SITIOS PARA CENAR'),
      subtitle: '"La noche canaria empieza aquí"',
    );
  }
  return _BannerState(
    label: 'AHORA · DE MADRUGADA',
    title: _titleFor(count, 'SITIO ABIERTO AHORA', 'SITIOS ABIERTOS AHORA'),
    subtitle: '"La isla nunca duerme del todo"',
  );
}

/// Encabezado contextual por hora que actúa como cabecera de la sección
/// "HOY EN ...". Estilo editorial: punto "live" + eyebrow contextual + título
/// grande + subtítulo. El banner y las cards de debajo son el mismo bloque:
/// el banner anuncia y las cards responden.
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
    final brand = context.brand;
    // Punto "live": verde laurisilva cuando hay sitios abiertos AHORA; ámbar
    // sol en modo "abren pronto" (nada abierto todavía, pero es inminente).
    final dotColor =
        mode == HourBannerMode.openNow ? AppColors.laurisilva : AppColors.sol;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Eyebrow: punto live + contexto + VER TODO ────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _LiveDot(color: dotColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.label,
                  style: AppTextStyles.eyebrow(
                    size: 11,
                    color: brand.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
          const SizedBox(height: 8),
          // ── Título grande editorial ──────────────────────────────────
          Text(
            s.title,
            style: AppTextStyles.displaySection(
              size: 20,
              color: brand.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          // ── Subtítulo italic ─────────────────────────────────────────
          Text(
            s.subtitle,
            style: AppTextStyles.editorial(
              size: 12,
              color: brand.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Punto "live" del eyebrow: círculo relleno con un halo más tenue del mismo
/// color. Estático (sin animación) para no añadir un controller al banner.
class _LiveDot extends StatelessWidget {
  final Color color;
  const _LiveDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.22),
      ),
      child: Center(
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      ),
    );
  }
}
