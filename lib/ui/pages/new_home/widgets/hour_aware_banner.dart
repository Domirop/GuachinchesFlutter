import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';

class _BannerState {
  final String icon;
  final String label;
  final String title;
  final String subtitle;
  final bool urgent;

  const _BannerState({
    required this.icon,
    required this.label,
    required this.title,
    required this.subtitle,
    this.urgent = false,
  });
}

_BannerState _stateForHour(int hour) {
  if (hour >= 7 && hour <= 11) {
    return _BannerState(
      icon: '☀️',
      label: '$hour:00 · MAÑANA',
      title: 'Desayunos abiertos ahora',
      subtitle: '"Empieza el día con un buen café"',
    );
  }
  if (hour == 13) {
    return _BannerState(
      icon: '⏰',
      label: '13:00 · URGENTE',
      title: 'Menú del día · Cierra en 1 hora',
      subtitle: '"Date prisa o te quedas sin él"',
      urgent: true,
    );
  }
  if (hour >= 17 && hour <= 19) {
    return _BannerState(
      icon: '🌇',
      label: '$hour:00 · GOLDEN HOUR',
      title: 'Terrazas con atardecer',
      subtitle: '"El sol pinta el Atlántico de naranja"',
    );
  }
  if (hour >= 20) {
    return _BannerState(
      icon: '🌙',
      label: '$hour:00 · NOCHE',
      title: 'Cenas · Abierto ahora',
      subtitle: '"La noche canaria empieza aquí"',
    );
  }
  if (hour >= 14 && hour <= 16) {
    return _BannerState(
      icon: '🍽',
      label: '$hour:00 · SOBREMESA',
      title: 'Menús disponibles aún',
      subtitle: '"Todavía hay mesa para ti"',
    );
  }
  return _BannerState(
    icon: '🌙',
    label: '$hour:00 · MADRUGADA',
    title: 'Los que no cierran',
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

  const HourAwareBanner({
    super.key,
    required this.hour,
    this.zoneLabel,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final s = _stateForHour(hour);
    final eyebrowColor =
        s.urgent ? AppColors.mojo : context.brand.textSecondary;
    final eyebrowText = zoneLabel != null
        ? '${s.label}  ·  HOY EN ${zoneLabel!.toUpperCase()}'
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
                    size: 18,
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
