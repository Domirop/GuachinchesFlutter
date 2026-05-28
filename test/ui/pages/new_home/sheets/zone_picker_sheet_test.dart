import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/data/cubit/new_home/zone_weather_cubit.dart';
import 'package:guachinches/data/model/weather_data.dart';
import 'package:guachinches/data/model/weather_zone_bundle.dart';
import 'package:guachinches/data/model/zone.dart';
import 'package:guachinches/services/weather_service.dart';
import 'package:guachinches/ui/pages/new_home/sheets/zone_picker_sheet.dart';

class _StubWeatherService implements WeatherService {
  final Map<String, WeatherData> _data;
  final List<Zone> _zones;
  _StubWeatherService(this._data, this._zones);

  @override
  Future<WeatherData> forZone(String zoneId) async =>
      _data[zoneId] ?? const WeatherData.unknown();

  @override
  Future<WeatherData> forIsland(String islandId) async =>
      const WeatherData.unknown();

  @override
  Future<WeatherData> forMunicipality(String municipalityId) async =>
      const WeatherData.unknown();

  @override
  Future<WeatherZoneBundle> bundleForIsland(String islandId) =>
      forIslandZones(islandId);

  @override
  Future<WeatherZoneBundle> forIslandZones(String islandId) async {
    final entries = _zones
        .where((z) => z.id != null)
        .map((z) {
          final wd = _data[z.id] ?? const WeatherData.unknown();
          return WeatherZoneEntry(
            id: z.id!,
            key: z.key,
            label: z.label,
            weather: WeatherZoneWeather(
              tempC: wd.tempC,
              condition: wd.condition,
              emoji: wd.emoji,
              updatedAt: '',
              source: 'stub',
            ),
          );
        })
        .toList();
    return WeatherZoneBundle(
      islandId: islandId,
      generatedAt: '',
      zones: entries,
    );
  }
}

void main() {
  const northId = 'id-norte';
  const surId = 'id-sur';
  const metroId = 'id-metro';

  final zones = [
    const Zone(
      id: northId,
      key: 'norte',
      label: 'Norte',
      emoji: '🌲',
      islandId: 'island1',
      centerLat: 0,
      centerLng: 0,
    ),
    const Zone(
      id: surId,
      key: 'sur',
      label: 'Sur',
      emoji: '☀️',
      islandId: 'island1',
      centerLat: 0,
      centerLng: 0,
    ),
    const Zone(
      id: metroId,
      key: 'metro',
      label: 'Metro',
      emoji: '🏙️',
      islandId: 'island1',
      centerLat: 0,
      centerLng: 0,
    ),
  ];

  late ZoneWeatherCubit cubit;

  setUp(() {
    cubit = ZoneWeatherCubit(
      _StubWeatherService(
        {
          northId: const WeatherData(tempC: 20, condition: 'sunny', emoji: '☀️'),
          surId: const WeatherData(tempC: 26, condition: 'sunny', emoji: '☀️'),
          metroId: const WeatherData(tempC: 22, condition: 'cloudy', emoji: '⛅'),
        },
        zones,
      ),
    );
  });

  tearDown(() => cubit.close());

  Widget _wrap(Widget child) {
    return BlocProvider.value(
      value: cubit,
      child: MaterialApp(
        theme: appLightTheme,
        darkTheme: appDarkTheme,
        themeMode: ThemeMode.dark,
        home: Scaffold(body: child),
      ),
    );
  }

  group('ZonePickerSheet', () {
    testWidgets(
      'each row shows its own zone temperature from ZoneWeatherCubit',
      (tester) async {
        // Preload the cubit with per-zone weather
        await cubit.loadForIsland('island1');

        await tester.pumpWidget(
          _wrap(
            ZonePickerSheet(
              islandLabel: 'Tenerife',
              zones: zones,
              onSelect: (_) {},
            ),
          ),
        );
        await tester.pump();

        // Norte: 20°C ☀️
        expect(find.text('☀️ 20°'), findsOneWidget);
        // Sur: 26°C ☀️
        expect(find.text('☀️ 26°'), findsOneWidget);
        // Metro: 22°C ⛅
        expect(find.text('⛅ 22°'), findsOneWidget);

        // Verify each chip sits under its zone's Semantics identifier
        final norteWeather = find.ancestor(
          of: find.text('☀️ 20°'),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                w.properties.identifier == 'zone-picker-weather-norte',
          ),
        );
        expect(norteWeather, findsOneWidget);

        final surWeather = find.ancestor(
          of: find.text('☀️ 26°'),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                w.properties.identifier == 'zone-picker-weather-sur',
          ),
        );
        expect(surWeather, findsOneWidget);

        final metroWeather = find.ancestor(
          of: find.text('⛅ 22°'),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                w.properties.identifier == 'zone-picker-weather-metro',
          ),
        );
        expect(metroWeather, findsOneWidget);
      },
    );

    testWidgets(
      'rows show WeatherData.unknown fallback while cubit map is empty',
      (tester) async {
        // cubit has empty map (initial state, no loadForZones called)
        await tester.pumpWidget(
          _wrap(
            ZonePickerSheet(
              islandLabel: 'Tenerife',
              zones: zones,
              onSelect: (_) {},
            ),
          ),
        );
        await tester.pump();

        // No temperature chips should be visible (weather.isAvailable == false)
        expect(find.text('☀️ 20°'), findsNothing);
        expect(find.text('☀️ 26°'), findsNothing);
        expect(find.text('⛅ 22°'), findsNothing);
      },
    );
  });
}
