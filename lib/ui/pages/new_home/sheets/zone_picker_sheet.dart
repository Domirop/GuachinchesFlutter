import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/model/zone.dart';
import 'package:guachinches/data/model/weather_data.dart';

/// Bottom sheet para seleccionar zona dentro de una isla.
class ZonePickerSheet extends StatelessWidget {
  final String islandLabel;
  final List<Zone> zones;
  final String? selectedZoneKey;
  final WeatherData weather;
  final ValueChanged<Zone?> onSelect; // null → "Toda la isla" (clear)

  const ZonePickerSheet({
    super.key,
    required this.islandLabel,
    required this.zones,
    this.selectedZoneKey,
    required this.weather,
    required this.onSelect,
  });

  static Future<void> show({
    required BuildContext context,
    required String islandLabel,
    required List<Zone> zones,
    String? selectedZoneKey,
    required WeatherData weather,
    required ValueChanged<Zone?> onSelect,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: context.brand.elevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => ZonePickerSheet(
        islandLabel: islandLabel,
        zones: zones,
        selectedZoneKey: selectedZoneKey,
        weather: weather,
        onSelect: onSelect,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 32,
              height: 3,
              margin: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              '¿DÓNDE EN ${islandLabel.toUpperCase()}?',
              style: AppTextStyles.eyebrow(
                size: 10,
                color: context.brand.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.4,
              ),
              itemCount: zones.length,
              itemBuilder: (_, i) {
                final zone = zones[i];
                final active = selectedZoneKey == zone.key;
                return _ZoneCard(
                  zone: zone,
                  weather: weather,
                  active: active,
                  onTap: () {
                    Navigator.pop(context);
                    onSelect(zone.key == 'all' ? null : zone);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoneCard extends StatelessWidget {
  final Zone zone;
  final WeatherData weather;
  final bool active;
  final VoidCallback onTap;

  const _ZoneCard({
    required this.zone,
    required this.weather,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.atlantico.withOpacity(0.25) : context.brand.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active
                ? AppColors.atlantico.withOpacity(0.6)
                : context.brand.border,
          ),
        ),
        child: Row(
          children: [
            Text(zone.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    zone.label,
                    style: AppTextStyles.displaySection(size: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    weather.isAvailable
                        ? '${weather.emoji} ${weather.displayTemp}'
                        : '—',
                    style: AppTextStyles.muted(size: 9),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
