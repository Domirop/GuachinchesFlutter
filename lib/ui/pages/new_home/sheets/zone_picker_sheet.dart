import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/data/cubit/new_home/new_home_filters_cubit.dart';
import 'package:guachinches/data/cubit/new_home/zone_weather_cubit.dart';
import 'package:guachinches/data/cubit/new_home/zones_cubit.dart';
import 'package:guachinches/data/model/weather_data.dart';
import 'package:guachinches/data/model/zone.dart';
import 'package:guachinches/ui/pages/new_home/sheets/zone_picker_logic.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_state_card.dart';
import 'package:guachinches/ui/pages/new_home/widgets/island_silhouette.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

/// Hoja «¿Dónde en <isla>?» (tablero HojaZona): filas agrupadas en una
/// tarjeta con el glifo de cada zona, el tiempo ahora (chip con glifo propio)
/// y la marca en la elegida. Estados: lista, sin tiempo, cargando y error.
class ZonePickerSheet extends StatelessWidget {
  final String islandLabel;
  final List<Zone> zones;
  final String? selectedZoneKey;
  final ValueChanged<Zone?> onSelect;

  /// Cubit de zonas (opcional): da el estado cargando/error cuando [zones]
  /// llega vacío y permite reintentar.
  final ZonesCubit? zonesCubit;

  /// Tiempo por zona. Si no llega se busca en el contexto; sin él, la hoja
  /// se pinta «sin tiempo».
  final ZoneWeatherCubit? weatherCubit;

  /// Isla para «Reintentar».
  final String? islandId;

  const ZonePickerSheet({
    super.key,
    required this.islandLabel,
    required this.zones,
    this.selectedZoneKey,
    required this.onSelect,
    this.zonesCubit,
    this.weatherCubit,
    this.islandId,
  });

  static Future<void> show({
    required BuildContext context,
    required String islandLabel,
    required List<Zone> zones,
    String? selectedZoneKey,
    required ValueChanged<Zone?> onSelect,
    String? islandId,
  }) {
    final weather = _maybeRead<ZoneWeatherCubit>(context);
    final zonesCubit = _maybeRead<ZonesCubit>(context);
    final id =
        islandId ?? _maybeRead<NewHomeFiltersCubit>(context)?.state.islandId;
    if (zones.isEmpty &&
        zonesCubit != null &&
        zonesCubit.state is ZonesInitial &&
        id != null) {
      zonesCubit.loadForIsland(id);
    }
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x52000000),
      builder: (_) => ZonePickerSheet(
        islandLabel: islandLabel,
        zones: zones,
        selectedZoneKey: selectedZoneKey,
        onSelect: onSelect,
        zonesCubit: zonesCubit,
        weatherCubit: weather,
        islandId: id,
      ),
    );
  }

  /// Lee un cubit si está provisto (en tests o pantallas sueltas puede no
  /// estarlo: entonces la hoja funciona sin él).
  static T? _maybeRead<T>(BuildContext context) {
    try {
      return context.read<T>();
    } on ProviderNotFoundException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final weather = weatherCubit ?? _maybeRead<ZoneWeatherCubit>(context);
    final maxH = MediaQuery.sizeOf(context).height * 0.9;

    Widget list(List<Zone> zs, Map<String, WeatherData> byZoneId) => _ZoneList(
          zones: zs,
          weather: byZoneId,
          islandLabel: islandLabel,
          selectedKey: selectedZoneKey ?? 'all',
          onTap: (z) => _select(context, z),
        );

    Widget body(ZonesState? zonesState) {
      final zs = zoneSheetZones(zones, zonesState);
      switch (zoneSheetStatus(hasZones: zs.isNotEmpty, state: zonesState)) {
        case ZoneSheetStatus.loading:
          return const _ZoneSkeleton();
        case ZoneSheetStatus.error:
          final cubit = zonesCubit;
          final id = islandId;
          return _ZoneError(
            onRetry: cubit != null && id != null
                ? () => cubit.loadForIsland(id)
                : null,
          );
        case ZoneSheetStatus.list:
          if (weather == null) return list(zs, const {});
          return BlocBuilder<ZoneWeatherCubit, ZoneWeatherState>(
            bloc: weather,
            builder: (_, ws) => list(zs, ws.byZoneId),
          );
      }
    }

    final cubit = zonesCubit;
    return Semantics(
      identifier: 'zone-picker-sheet',
      container: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: gm.canvas,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x2E000000),
                  blurRadius: 30,
                  offset: Offset(0, -10)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Header(islandLabel: islandLabel),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                      bottom: 16 + MediaQuery.paddingOf(context).bottom),
                  child: cubit == null
                      ? body(null)
                      : BlocBuilder<ZonesCubit, ZonesState>(
                          bloc: cubit,
                          builder: (_, s) => body(s),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _select(BuildContext context, Zone zone) {
    Navigator.pop(context);
    onSelect(zone.key == 'all' ? null : zone);
  }
}

// ─────────────────────────────────────────────────────────────────────
// Cabecera: asa, cerrar, título y subtítulo
// ─────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String islandLabel;
  const _Header({required this.islandLabel});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 7),
            Center(
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: gm.sep,
                  borderRadius: BorderRadius.circular(GmRadius.pill),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(70, 14, 70, 8),
              child: Semantics(
                header: true,
                child: Text(
                  zoneSheetTitle(islandLabel),
                  textAlign: TextAlign.center,
                  style: GmText.guideTitle(color: gm.label)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 0, 30, 18),
              child: Text(
                kZoneSheetSubtitle,
                textAlign: TextAlign.center,
                style: GmText.body(color: gm.label2),
              ),
            ),
          ],
        ),
        Positioned(
          left: 16,
          top: 14,
          child: GmToolbarButton(
            icon: GmIcons.close,
            light: true,
            semanticLabel: 'Cerrar',
            identifier: 'zone-picker-close',
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Lista
// ─────────────────────────────────────────────────────────────────────

class _ZoneList extends StatelessWidget {
  final List<Zone> zones;
  final Map<String, WeatherData> weather;
  final String islandLabel;
  final String selectedKey;
  final ValueChanged<Zone> onTap;

  const _ZoneList({
    required this.zones,
    required this.weather,
    required this.islandLabel,
    required this.selectedKey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final hasWeather = zoneSheetHasWeather(zones, weather);
    final rows = <Widget>[];
    for (var i = 0; i < zones.length; i++) {
      if (i > 0) {
        rows.add(Container(
          height: 1,
          margin: const EdgeInsets.only(left: 72),
          color: gm.sep,
        ));
      }
      final z = zones[i];
      rows.add(_ZoneRow(
        zone: z,
        islandLabel: islandLabel,
        weather: hasWeather ? zoneWeatherFor(z, weather) : null,
        active: z.key == selectedKey,
        onTap: () => onTap(z),
      ));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GmRise(
          trigger: GmTrigger.mount,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: GmSpace.gutter),
            child: GmCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(children: rows),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 12, 32, 0),
          child: Text(
            zoneSheetCaption(hasWeather: hasWeather),
            style: GmText.meta(color: gm.label2),
          ),
        ),
      ],
    );
  }
}

class _ZoneRow extends StatelessWidget {
  final Zone zone;
  final String islandLabel;

  /// `null` = la hoja está «sin tiempo» (no se pinta ningún chip).
  final WeatherData? weather;
  final bool active;
  final VoidCallback onTap;

  const _ZoneRow({
    required this.zone,
    required this.islandLabel,
    required this.weather,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final label = zoneDisplayLabel(zone.label);
    final desc = zoneDescription(zone.key, islandLabel);
    final w = weather;
    return Semantics(
      identifier: 'zone-picker-row-${zone.key}',
      container: true,
      button: true,
      selected: active,
      child: GmPressable(
        onTap: onTap,
        pressedScale: 0.98,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 16, 8),
            child: Row(
              children: [
                _ZoneTile(zoneKey: zone.key, islandLabel: islandLabel),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label, style: GmText.guideTitle(color: gm.label)),
                      if (desc != null)
                        Text(desc, style: GmText.meta(color: gm.label2)),
                    ],
                  ),
                ),
                if (w != null && w.isAvailable) ...[
                  const SizedBox(width: 10),
                  Semantics(
                    identifier: 'zone-picker-weather-${zone.key}',
                    container: true,
                    label: zoneWeatherSemantics(w),
                    excludeSemantics: true,
                    child: _WeatherChip(weather: w),
                  ),
                ],
                const SizedBox(width: 12),
                SizedBox(
                  width: 18,
                  child: active
                      ? GmIcon(GmIcons.check, size: 18, color: gm.accent)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ZoneTile extends StatelessWidget {
  final String zoneKey;
  final String islandLabel;
  const _ZoneTile({required this.zoneKey, required this.islandLabel});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final look = zoneLookFor(zoneKey);
    final (bg, ink) = switch (look.tone) {
      ZoneTone.band => (gm.band, gm.bandInk),
      ZoneTone.ok => (gm.okSoft, gm.greenText),
      ZoneTone.warn => (gm.warnSoft, gm.warnText),
      ZoneTone.neutral => (gm.fill, gm.label2),
    };
    final Widget glyph = look.glyph == ZoneGlyph.island
        ? IslandSilhouette(
            island: islandLabel,
            size: 34,
            color: ink,
            fallback: const GmGlyph(GmGlyphKind.volcan, size: 28),
          )
        : GmIcon(_ZoneGlyphs.svg(look.glyph), size: 22, color: ink);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(13),
      ),
      alignment: Alignment.center,
      child: ExcludeSemantics(child: glyph),
    );
  }
}

class _WeatherChip extends StatelessWidget {
  final WeatherData weather;
  const _WeatherChip({required this.weather});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.4,
      child: Container(
        constraints: const BoxConstraints(minHeight: 28),
        padding: const EdgeInsets.fromLTRB(6, 2, 9, 2),
        decoration: BoxDecoration(
          color: gm.fill,
          borderRadius: BorderRadius.circular(GmRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GmIcon(
              _ZoneGlyphs.weather(zoneWeatherGlyph(weather.condition)),
              size: 18,
              color: gm.label2,
            ),
            const SizedBox(width: 4),
            Text(
              zoneWeatherText(weather) ?? '',
              style: TextStyle(
                fontSize: 14,
                height: 18 / 14,
                fontWeight: FontWeight.w600,
                color: gm.label,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Glifos de zona y del tiempo (copiados del tablero HojaZona; el sol del
/// tiempo es ámbar fijo, la nube usa `currentColor`).
class _ZoneGlyphs {
  _ZoneGlyphs._();

  static String _stroke(String inner, {double width = 2.2}) =>
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
      'stroke="currentColor" stroke-width="$width" stroke-linecap="round" '
      'stroke-linejoin="round">$inner</svg>';

  static final leaf = _stroke(
      '<path d="M5 19c0-8 5-13 14-14-1 9-6 14-14 14z"/><path d="M5 19l8-8"/>');
  static final sun = _stroke(
      '<circle cx="12" cy="12" r="4.2"/><path d="M12 2.8v2.4M12 18.8v2.4M2.8 12h2.4M18.8 12h2.4M5.5 5.5l1.7 1.7M16.8 16.8l1.7 1.7M5.5 18.5l1.7-1.7M16.8 7.2l1.7-1.7"/>');
  static final city = _stroke(
      '<path d="M3.5 20.5h17"/><path d="M5 20.5V10l5-2.5v13"/><path d="M10 20.5V5l7 3v12.5"/><path d="M17 12h2.5v8.5"/><path d="M12.5 9.5h2M12.5 13h2M12.5 16.5h2M7 13h1M7 16.5h1"/>',
      width: 2);
  static final mountain = _stroke(
      '<path d="M2.5 19.5l6.6-10.2a1.6 1.6 0 012.7 0l1.4 2.1 1.3-1.6a1.6 1.6 0 012.5.1l4.5 9.6z"/><path d="M9.6 9.6l1.6 1.8 1.5-1"/>',
      width: 2);

  /// Atardecer: medio sol sobre el horizonte con rayos (propio).
  static final sunset = _stroke(
      '<path d="M2.8 17.5h18.4"/><path d="M6.5 21h11"/><path d="M7.5 17.5a4.5 4.5 0 019 0"/><path d="M12 7.2v2.4M4.6 10.4l1.7 1.7M19.4 10.4l-1.7 1.7M2.8 14h1.6M19.6 14h1.6"/>');
  static final pin = _stroke(
      '<path d="M12 21.5s-7-6.6-7-12a7 7 0 0114 0c0 5.4-7 12-7 12z"/><circle cx="12" cy="9.5" r="2.6"/>',
      width: 2);

  static String svg(ZoneGlyph g) => switch (g) {
        ZoneGlyph.leaf => leaf,
        ZoneGlyph.sun => sun,
        ZoneGlyph.city => city,
        ZoneGlyph.mountain => mountain,
        ZoneGlyph.sunset => sunset,
        ZoneGlyph.pin || ZoneGlyph.island => pin,
      };

  static const _amber = '#E9A100';

  static const wSun =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><circle cx="12" cy="12" r="4.4" fill="$_amber"/>'
      '<path d="M12 2.5v2.6M12 18.9v2.6M2.5 12h2.6M18.9 12h2.6M5.3 5.3l1.8 1.8M16.9 16.9l1.8 1.8M5.3 18.7l1.8-1.8M16.9 7.1l1.8-1.8" '
      'stroke="$_amber" stroke-width="2" stroke-linecap="round"/></svg>';
  static const wPartly =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><circle cx="9" cy="9" r="3.8" fill="$_amber"/>'
      '<path d="M9 2.4v1.8M2.4 9h1.8M4.3 4.3l1.3 1.3M13.7 4.3l-1.3 1.3" stroke="$_amber" stroke-width="1.8" stroke-linecap="round"/>'
      '<path d="M8.5 19.5h9.2a3.6 3.6 0 00.4-7.2 5 5 0 00-9.4 1.4 2.9 2.9 0 00-.2 5.8z" fill="currentColor"/></svg>';
  static const wCloud =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
      '<path d="M7 19h10.5a4 4 0 00.5-8 5.6 5.6 0 00-10.6 1.6A3.2 3.2 0 007 19z" fill="currentColor"/></svg>';

  static String weather(ZoneWeatherGlyph g) => switch (g) {
        ZoneWeatherGlyph.sun => wSun,
        ZoneWeatherGlyph.partly => wPartly,
        ZoneWeatherGlyph.cloud => wCloud,
      };
}

// ─────────────────────────────────────────────────────────────────────
// Cargando y error
// ─────────────────────────────────────────────────────────────────────

class _ZoneSkeleton extends StatelessWidget {
  const _ZoneSkeleton();

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    Widget block(double w, double h, double r) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: gm.fill,
            borderRadius: BorderRadius.circular(r),
          ),
        );
    final rows = <Widget>[];
    for (var i = 0; i < 5; i++) {
      if (i > 0) {
        rows.add(Container(
            height: 1, margin: const EdgeInsets.only(left: 72), color: gm.sep));
      }
      rows.add(SizedBox(
        height: 70,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 16, 0),
          child: Row(
            children: [
              block(44, 44, 13),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    block(80.0 + (i * 41) % 60, 14, 7),
                    const SizedBox(height: 7),
                    block(130.0 + (i * 29) % 50, 11, 6),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              block(54, 28, GmRadius.pill),
            ],
          ),
        ),
      ));
    }
    return Semantics(
      identifier: 'zone-picker-loading',
      label: 'Cargando zonas',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: GmSpace.gutter),
          child: GmCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(children: rows),
          ),
        ),
      ),
    );
  }
}

class _ZoneError extends StatelessWidget {
  final VoidCallback? onRetry;
  const _ZoneError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return GmRise(
      trigger: GmTrigger.mount,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: GmSpace.gutter),
        child: GmStateCard(
          identifier: 'zone-picker-error',
          liveRegion: true,
          art: const GmSadVolcano(),
          title: kZoneSheetErrorTitle,
          text: kZoneSheetErrorText,
          action: onRetry == null
              ? null
              : GmCapsuleButton(
                  label: 'Reintentar',
                  identifier: 'zone-picker-retry',
                  onTap: onRetry,
                ),
        ),
      ),
    );
  }
}
