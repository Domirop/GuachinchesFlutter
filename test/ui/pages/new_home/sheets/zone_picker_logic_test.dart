import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/cubit/new_home/zones_cubit.dart';
import 'package:guachinches/data/model/weather_data.dart';
import 'package:guachinches/data/model/zone.dart';
import 'package:guachinches/ui/pages/new_home/sheets/zone_picker_logic.dart';
import 'package:guachinches/ui/pages/new_home/widgets/island_silhouette.dart';

Zone _zone(String key, {String? id, String label = 'x'}) => Zone(
      id: id,
      key: key,
      label: label,
      emoji: '',
      islandId: 'i',
      centerLat: 0,
      centerLng: 0,
    );

void main() {
  group('zoneLookFor', () {
    test('real prod keys get their own glyph and tone', () {
      expect(
          zoneLookFor('all'), const ZoneLook(ZoneGlyph.island, ZoneTone.band));
      expect(zoneLookFor('norte'), const ZoneLook(ZoneGlyph.leaf, ZoneTone.ok));
      expect(zoneLookFor('sur'), const ZoneLook(ZoneGlyph.sun, ZoneTone.warn));
      expect(zoneLookFor('metro'),
          const ZoneLook(ZoneGlyph.city, ZoneTone.neutral));
      expect(zoneLookFor('interior'),
          const ZoneLook(ZoneGlyph.mountain, ZoneTone.band));
      expect(zoneLookFor('oeste'),
          const ZoneLook(ZoneGlyph.sunset, ZoneTone.warn));
    });

    test('unknown keys fall back to a pin', () {
      expect(zoneLookFor('sureste'),
          const ZoneLook(ZoneGlyph.pin, ZoneTone.neutral));
      expect(zoneLookFor(''), const ZoneLook(ZoneGlyph.pin, ZoneTone.neutral));
    });
  });

  group('zoneDisplayLabel', () {
    test('«Área Metro» becomes «Área metropolitana»', () {
      expect(zoneDisplayLabel('Área Metro'), 'Área metropolitana');
      expect(zoneDisplayLabel('AREA METRO'), 'Área metropolitana');
    });

    test('other labels (capitals of other islands) are kept', () {
      expect(zoneDisplayLabel('Las Palmas'), 'Las Palmas');
      expect(zoneDisplayLabel('Arrecife'), 'Arrecife');
      expect(zoneDisplayLabel('Puerto del Rosario'), 'Puerto del Rosario');
      expect(zoneDisplayLabel(' Norte '), 'Norte');
    });
  });

  group('zoneDescription', () {
    test('Tenerife copy', () {
      expect(zoneDescription('all', 'Tenerife'), 'Sin filtrar por zona');
      expect(zoneDescription('norte', 'Tenerife'),
          'Guachinches, viñedos y laurisilva');
      expect(zoneDescription('sur', 'Tenerife'),
          'Terrazas al sol y pueblos de costa');
      expect(zoneDescription('metro', 'Tenerife'),
          'Santa Cruz, La Laguna y alrededores');
      expect(zoneDescription('interior', 'Tenerife'),
          'Medianías y cumbre: La Esperanza, Vilaflor');
      expect(zoneDescription('oeste', 'Tenerife'), 'Acantilados y atardeceres');
    });

    test('other islands get generic copy', () {
      expect(zoneDescription('norte', 'Gran Canaria'),
          'Pueblos y costa del norte');
      expect(zoneDescription('metro', 'Lanzarote'), 'La capital y alrededores');
      expect(zoneDescription('interior', 'La Palma'), 'Medianías y cumbre');
      expect(
          zoneDescription('oeste', 'La Gomera'), 'Acantilados y atardeceres');
    });

    test('unknown key has no description', () {
      expect(zoneDescription('sureste', 'Tenerife'), isNull);
    });
  });

  test('title', () {
    expect(zoneSheetTitle('Tenerife'), '¿Dónde en Tenerife?');
  });

  group('weather chip', () {
    test('glyph per condition (no emoji)', () {
      expect(zoneWeatherGlyph('sunny'), ZoneWeatherGlyph.sun);
      expect(zoneWeatherGlyph('cloudy'), ZoneWeatherGlyph.partly);
      expect(zoneWeatherGlyph('fog'), ZoneWeatherGlyph.cloud);
      expect(zoneWeatherGlyph('rain'), ZoneWeatherGlyph.cloud);
      expect(zoneWeatherGlyph('storm'), ZoneWeatherGlyph.cloud);
      expect(zoneWeatherGlyph('unknown'), ZoneWeatherGlyph.partly);
    });

    test('text and semantics', () {
      const w = WeatherData(tempC: 19.5, condition: 'sunny', emoji: '☀️');
      expect(zoneWeatherText(w), '20°');
      expect(zoneWeatherSemantics(w), '20 grados, soleado');
      expect(
          zoneWeatherSemantics(
              const WeatherData(tempC: 1, condition: 'x', emoji: '')),
          '1 grado');
      expect(zoneWeatherText(const WeatherData.unknown()), isNull);
      expect(zoneWeatherSemantics(const WeatherData.unknown()), isNull);
    });

    test('sheet has weather only if some zone has a temperature', () {
      final zones = [_zone('all'), _zone('norte', id: 'n')];
      expect(zoneSheetHasWeather(zones, const {}), isFalse);
      expect(zoneSheetHasWeather(zones, const {'n': WeatherData.unknown()}),
          isFalse);
      expect(
          zoneSheetHasWeather(zones, const {
            'n': WeatherData(tempC: 20, condition: 'sunny', emoji: ''),
          }),
          isTrue);
      expect(zoneSheetCaption(hasWeather: true), kZoneSheetCaptionWeather);
      expect(zoneSheetCaption(hasWeather: false), kZoneSheetCaptionNoWeather);
    });
  });

  group('zoneSheetStatus', () {
    test('zones → list whatever the cubit says', () {
      expect(zoneSheetStatus(hasZones: true, state: ZonesFailure('x')),
          ZoneSheetStatus.list);
    });

    test('no zones: loading while loading/initial/no cubit', () {
      expect(zoneSheetStatus(hasZones: false, state: ZonesLoading()),
          ZoneSheetStatus.loading);
      expect(zoneSheetStatus(hasZones: false, state: ZonesInitial()),
          ZoneSheetStatus.loading);
      expect(zoneSheetStatus(hasZones: false, state: null),
          ZoneSheetStatus.loading);
    });

    test('no zones: error on failure or empty load', () {
      expect(zoneSheetStatus(hasZones: false, state: ZonesFailure('x')),
          ZoneSheetStatus.error);
      expect(zoneSheetStatus(hasZones: false, state: ZonesLoaded(const [])),
          ZoneSheetStatus.error);
    });

    test('cubit zones win over the passed snapshot', () {
      final passed = [_zone('all')];
      final live = [_zone('all'), _zone('norte')];
      expect(zoneSheetZones(passed, ZonesLoaded(live)), live);
      expect(zoneSheetZones(passed, ZonesLoaded(const [])), passed);
      expect(zoneSheetZones(passed, ZonesLoading()), passed);
    });
  });

  group('island silhouette', () {
    test('known islands by name or key', () {
      expect(islandCoastKey('Tenerife'), 'tenerife');
      expect(islandCoastKey('GC'), 'gran canaria');
      expect(islandCoastKey(' El Hierro '), 'el hierro');
      expect(islandCoastKey('Madeira'), isNull);
    });

    test('points fit the 24 grid with a 21 px box', () {
      final pts = islandSilhouettePoints('Tenerife')!;
      final xs = pts.map((p) => p.dx);
      final ys = pts.map((p) => p.dy);
      final w = xs.reduce((a, b) => a > b ? a : b) -
          xs.reduce((a, b) => a < b ? a : b);
      final h = ys.reduce((a, b) => a > b ? a : b) -
          ys.reduce((a, b) => a < b ? a : b);
      expect(w > h ? w : h, closeTo(21, 0.001));
      for (final p in pts) {
        expect(p.dx, inInclusiveRange(0, 24));
        expect(p.dy, inInclusiveRange(0, 24));
      }
      expect(islandSilhouettePoints('Atlántida'), isNull);
    });
  });
}
