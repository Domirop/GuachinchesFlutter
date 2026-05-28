import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/cubit/new_home/zone_weather_cubit.dart';
import 'package:guachinches/data/model/zone.dart';
import 'package:guachinches/data/model/weather_data.dart';

class ZonePickerSheet extends StatelessWidget {
  final String islandLabel;
  final List<Zone> zones;
  final String? selectedZoneKey;
  final ValueChanged<Zone?> onSelect;

  const ZonePickerSheet({
    super.key,
    required this.islandLabel,
    required this.zones,
    this.selectedZoneKey,
    required this.onSelect,
  });

  static Future<void> show({
    required BuildContext context,
    required String islandLabel,
    required List<Zone> zones,
    String? selectedZoneKey,
    required ValueChanged<Zone?> onSelect,
  }) {
    final weatherCubit = context.read<ZoneWeatherCubit>();
    return showModalBottomSheet(
      context: context,
      backgroundColor: context.brand.elevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => BlocProvider.value(
        value: weatherCubit,
        child: ZonePickerSheet(
          islandLabel: islandLabel,
          zones: zones,
          selectedZoneKey: selectedZoneKey,
          onSelect: onSelect,
        ),
      ),
    );
  }

  String get _selectedKey => selectedZoneKey ?? 'all';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: context.brand.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '¿DÓNDE EN ${islandLabel.toUpperCase()}?',
              style: AppTextStyles.displaySection(size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              'Elige zona para descubrir dónde comer',
              style: AppTextStyles.muted(size: 12),
            ),
            const SizedBox(height: 16),
            BlocBuilder<ZoneWeatherCubit, ZoneWeatherState>(
              builder: (_, weatherState) {
                return Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: zones.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final zone = zones[i];
                      final active = _selectedKey == zone.key;
                      final zoneWeather = zone.id != null
                          ? (weatherState.byZoneId[zone.id] ??
                              const WeatherData.unknown())
                          : const WeatherData.unknown();
                      return _ZoneListCard(
                        zone: zone,
                        weather: zoneWeather,
                        active: active,
                        onTap: () {
                          Navigator.pop(context);
                          onSelect(zone.key == 'all' ? null : zone);
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoneListCard extends StatelessWidget {
  final Zone zone;
  final WeatherData weather;
  final bool active;
  final VoidCallback onTap;

  const _ZoneListCard({
    required this.zone,
    required this.weather,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final copy = _ZoneCopy.forKey(zone.key);
    return Semantics(
      identifier: 'zone-picker-row-${zone.key}',
      container: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.atlantico.withOpacity(0.12)
                  : context.brand.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: active
                    ? AppColors.atlantico.withOpacity(0.55)
                    : context.brand.border,
                width: active ? 1.5 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _IconTile(emoji: zone.emoji, gradient: copy.gradient),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              zone.label.toUpperCase(),
                              style: AppTextStyles.displaySection(size: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (active) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.check_circle,
                              size: 16,
                              color: AppColors.atlantico,
                            ),
                          ],
                        ],
                      ),
                      if (copy.description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          copy.description!,
                          style: AppTextStyles.muted(size: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      _TagRow(
                        weather: weather,
                        tagLabel: copy.tag ?? zone.label,
                        zoneKey: zone.key,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  size: 22,
                  color: context.brand.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  final String emoji;
  final List<Color> gradient;

  const _IconTile({required this.emoji, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 26)),
    );
  }
}

class _TagRow extends StatelessWidget {
  final WeatherData weather;
  final String tagLabel;
  final String zoneKey;

  const _TagRow({
    required this.weather,
    required this.tagLabel,
    required this.zoneKey,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (weather.isAvailable)
          Semantics(
            identifier: 'zone-picker-weather-$zoneKey',
            container: true,
            child: _Chip(text: '${weather.emoji} ${weather.displayTemp}'),
          ),
        _Chip(text: tagLabel),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.brand.elevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.brand.border),
      ),
      child: Text(
        text,
        style: AppTextStyles.muted(size: 11),
      ),
    );
  }
}

class _ZoneCopy {
  final String? description;
  final String? tag;
  final List<Color> gradient;

  const _ZoneCopy({
    this.description,
    this.tag,
    required this.gradient,
  });

  static const _fallbackGradient = [
    AppColors.atlantico,
    AppColors.atlanticoOscuro,
  ];

  static const _byKey = <String, _ZoneCopy>{
    'all': _ZoneCopy(
      description: 'Explora toda la isla sin filtros',
      tag: 'Toda la isla',
      gradient: [AppColors.atlanticoClaro, AppColors.atlantico],
    ),
    'norte': _ZoneCopy(
      description: 'Guachinches, viñedos y laurisilva',
      tag: 'Guachinches',
      gradient: [AppColors.laurisilva, Color(0xFF007A5A)],
    ),
    'sur': _ZoneCopy(
      description: 'Terrazas con sol y costa atlántica',
      tag: 'Terrazas',
      gradient: [AppColors.sol, Color(0xFFD49500)],
    ),
    'metro': _ZoneCopy(
      description: 'Santa Cruz, La Laguna y alrededores',
      tag: 'Área metro',
      gradient: [AppColors.mojo, Color(0xFFB23A0F)],
    ),
    'area-metro': _ZoneCopy(
      description: 'Santa Cruz, La Laguna y alrededores',
      tag: 'Área metro',
      gradient: [AppColors.mojo, Color(0xFFB23A0F)],
    ),
    'capital': _ZoneCopy(
      description: 'Santa Cruz, La Laguna y alrededores',
      tag: 'Área metro',
      gradient: [AppColors.mojo, Color(0xFFB23A0F)],
    ),
    'sureste': _ZoneCopy(
      description: 'Costa este: pueblos y playas',
      tag: 'Sureste',
      gradient: [AppColors.arena, Color(0xFFA37937)],
    ),
    'oeste': _ZoneCopy(
      description: 'Acantilados, Teno y atardeceres',
      tag: 'Oeste',
      gradient: [AppColors.tierra, Color(0xFF5D2E0C)],
    ),
  };

  static _ZoneCopy forKey(String key) =>
      _byKey[key] ??
      _ZoneCopy(
        description: null,
        tag: null,
        gradient: _fallbackGradient,
      );
}
