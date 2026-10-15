import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/new_home/zone_weather_cubit.dart';
import 'package:guachinches/data/cubit/new_home/zones_cubit.dart';
import 'package:guachinches/data/model/weather_data.dart';
import 'package:guachinches/data/model/weather_zone_bundle.dart';
import 'package:guachinches/data/model/zone.dart';
import 'package:guachinches/services/weather_service.dart';
import 'package:guachinches/ui/pages/new_home/sheets/zone_picker_logic.dart';
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

  Future<WeatherZoneBundle> forIslandZones(String islandId) async {
    final entries = _zones.where((z) => z.id != null).map((z) {
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
    }).toList();
    return WeatherZoneBundle(
      islandId: islandId,
      generatedAt: '',
      zones: entries,
    );
  }
}

class _FakeRepo extends Fake implements RemoteRepository {}

/// Cubit de zonas con estado fijo; cuenta reintentos.
class _StubZonesCubit extends ZonesCubit {
  final List<String> loads = [];
  _StubZonesCubit(ZonesState s) : super(_FakeRepo()) {
    emit(s);
  }

  @override
  Future<void> loadForIsland(String islandId) async => loads.add(islandId);
}

Finder _byId(String id) => find
    .byWidgetPredicate((w) => w is Semantics && w.properties.identifier == id);

void main() {
  const allId = 'id-all';
  const northId = 'id-norte';
  const surId = 'id-sur';
  const metroId = 'id-metro';

  Zone zone(String id, String key, String label) => Zone(
        id: id,
        key: key,
        label: label,
        emoji: '🌲',
        islandId: 'island1',
        centerLat: 0,
        centerLng: 0,
      );

  final zones = [
    zone(allId, 'all', 'Toda la isla'),
    zone(northId, 'norte', 'Norte'),
    zone(surId, 'sur', 'Sur'),
    zone(metroId, 'metro', 'Área Metro'),
  ];

  late ZoneWeatherCubit cubit;

  setUp(() {
    cubit = ZoneWeatherCubit(
      _StubWeatherService(
        {
          northId:
              const WeatherData(tempC: 20, condition: 'sunny', emoji: '☀️'),
          surId: const WeatherData(tempC: 26, condition: 'sunny', emoji: '☀️'),
          metroId:
              const WeatherData(tempC: 22.4, condition: 'cloudy', emoji: '⛅'),
        },
        zones,
      ),
    );
  });

  tearDown(() => cubit.close());

  Widget wrap(Widget child, {ThemeMode mode = ThemeMode.dark}) {
    return BlocProvider.value(
      value: cubit,
      child: MaterialApp(
        theme: appLightTheme,
        darkTheme: appDarkTheme,
        themeMode: mode,
        home: Scaffold(body: child),
      ),
    );
  }

  group('ZonePickerSheet', () {
    testWidgets('each row shows its own temperature chip (no emoji)',
        (tester) async {
      await cubit.loadForIsland('island1');
      await tester.pumpWidget(wrap(ZonePickerSheet(
        islandLabel: 'Tenerife',
        zones: zones,
        onSelect: (_) {},
      )));
      await tester.pumpAndSettle();

      for (final (key, text) in [
        ('norte', '20°'),
        ('sur', '26°'),
        ('metro', '22°'),
      ]) {
        expect(
          find.descendant(
              of: _byId('zone-picker-weather-$key'), matching: find.text(text)),
          findsOneWidget,
          reason: key,
        );
      }
      // «all» no tiene tiempo en el stub: sin chip.
      expect(_byId('zone-picker-weather-all'), findsNothing);
      // Nada de emoji.
      expect(find.textContaining('☀'), findsNothing);
      expect(find.textContaining('⛅'), findsNothing);

      final sem = tester.widget<Semantics>(_byId('zone-picker-weather-norte'));
      expect(sem.properties.label, '20 grados, soleado');

      expect(find.text(kZoneSheetCaptionWeather), findsOneWidget);
      expect(find.text('¿Dónde en Tenerife?'), findsOneWidget);
      expect(find.text(kZoneSheetSubtitle), findsOneWidget);
    });

    testWidgets('copy: descriptions and «Área metropolitana»', (tester) async {
      await tester.pumpWidget(wrap(
        ZonePickerSheet(
          islandLabel: 'Tenerife',
          zones: zones,
          onSelect: (_) {},
        ),
        mode: ThemeMode.light,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Área metropolitana'), findsOneWidget);
      expect(find.text('Área Metro'), findsNothing);
      expect(find.text('Sin filtrar por zona'), findsOneWidget);
      expect(find.text('Guachinches, viñedos y laurisilva'), findsOneWidget);
      expect(_byId('zone-picker-row-all'), findsOneWidget);
      expect(_byId('zone-picker-row-metro'), findsOneWidget);
    });

    testWidgets('without weather: no chips and the «sin tiempo» caption',
        (tester) async {
      await tester.pumpWidget(wrap(ZonePickerSheet(
        islandLabel: 'Tenerife',
        zones: zones,
        onSelect: (_) {},
      )));
      await tester.pumpAndSettle();

      for (final key in ['all', 'norte', 'sur', 'metro']) {
        expect(_byId('zone-picker-weather-$key'), findsNothing);
      }
      expect(find.text('20°'), findsNothing);
      expect(find.text(kZoneSheetCaptionNoWeather), findsOneWidget);
    });

    testWidgets('selected row is marked; tapping a row pops and selects',
        (tester) async {
      Zone? picked;
      var calls = 0;
      await tester.pumpWidget(wrap(Builder(
        builder: (context) => TextButton(
          onPressed: () => ZonePickerSheet.show(
            context: context,
            islandLabel: 'Tenerife',
            zones: zones,
            selectedZoneKey: 'sur',
            onSelect: (z) {
              calls++;
              picked = z;
            },
          ),
          child: const Text('open'),
        ),
      )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final sur = tester.widget<Semantics>(_byId('zone-picker-row-sur'));
      expect(sur.properties.selected, isTrue);
      final norte = tester.widget<Semantics>(_byId('zone-picker-row-norte'));
      expect(norte.properties.selected, isFalse);

      await tester.tap(_byId('zone-picker-row-norte'));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(picked?.key, 'norte');
      expect(_byId('zone-picker-sheet'), findsNothing);

      // «Toda la isla» → null.
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(_byId('zone-picker-row-all'));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(picked, isNull);
    });

    testWidgets('loading: skeleton while the zones cubit loads',
        (tester) async {
      final zc = _StubZonesCubit(ZonesLoading());
      addTearDown(zc.close);
      await tester.pumpWidget(wrap(ZonePickerSheet(
        islandLabel: 'Tenerife',
        zones: const [],
        zonesCubit: zc,
        islandId: 'island1',
        onSelect: (_) {},
      )));
      await tester.pump();
      expect(_byId('zone-picker-loading'), findsOneWidget);
      expect(_byId('zone-picker-error'), findsNothing);
    });

    testWidgets('error: sad volcano copy and retry reloads the island',
        (tester) async {
      final zc = _StubZonesCubit(ZonesFailure('boom'));
      addTearDown(zc.close);
      await tester.pumpWidget(wrap(ZonePickerSheet(
        islandLabel: 'Tenerife',
        zones: const [],
        zonesCubit: zc,
        islandId: 'island1',
        onSelect: (_) {},
      )));
      await tester.pumpAndSettle();

      expect(_byId('zone-picker-error'), findsOneWidget);
      expect(find.text(kZoneSheetErrorTitle), findsOneWidget);
      expect(find.text(kZoneSheetErrorText), findsOneWidget);
      await tester.tap(_byId('zone-picker-retry'));
      await tester.pump();
      expect(zc.loads, ['island1']);
    });
  });
}
