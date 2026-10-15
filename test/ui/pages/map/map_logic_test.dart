import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/model/Types.dart';
import 'package:guachinches/ui/pages/advance_search/list_theme.dart';
import 'package:guachinches/ui/pages/map/map_logic.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart'
    show gmPlaceName;
import 'package:guachinches/utils/contextual_pool.dart';
import 'package:guachinches/utils/open_state.dart';

import 'map_test_utils.dart';

void main() {
  group('tipo y sitios', () {
    test('el tipo sale del UUID; sin tipo o desconocido → null', () {
      expect(mapKindOf(place('a', type: RestaurantTypeIds.guachinchesModernos)),
          ListThemeKind.moderno);
      expect(mapKindOf(place('b', type: RestaurantTypeIds.cofradia)),
          ListThemeKind.cofradia);
      expect(mapKindOf(place('c', type: 'vacio')), isNull);
      expect(
          mapKindOf(place('d', type: '00000000-0000-0000-0000-000000000000')),
          isNull);
    });

    test('buildMapSites descarta sitios sin coordenadas y repetidos', () {
      final sites = buildMapSites([
        place('a'),
        place('a'),
        place('b', lat: 0, lon: 0),
        place('c', lat: 28.46, lon: -16.44),
      ], kWed1330, userLat: kUserLat, userLon: kUserLon);
      expect(sites.map((s) => s.id), ['a', 'c']);
      expect(sites.first.meters, closeTo(0, 1));
    });

    test('sin ubicación o a más de 200 km no hay distancia', () {
      final noLoc = buildMapSites([place('a')], kWed1330);
      expect(noLoc.single.meters, isNull);
      final far = buildMapSites([place('a', lat: 40.4, lon: -3.7)], kWed1330,
          userLat: kUserLat, userLon: kUserLon);
      expect(far.single.meters, isNull);
    });

    test('estado de apertura de la fuente única (open_state)', () {
      final s = buildMapSites([
        place('open', hours: wedHours('1200', '2200')),
        place('soon', hours: wedHours('1000', '1400')),
        place('closed', hours: wedHours('1800', '2300')),
        place('unknown'),
      ], kWed1330);
      expect(s[0].open.kind, OpenKind.open);
      expect(s[1].open.kind, OpenKind.closingSoon);
      expect(s[1].isOpen, isTrue);
      expect(s[2].closed, isTrue);
      expect(s[3].open.kind, OpenKind.unknown);
      expect(s[3].closed, isFalse, reason: 'sin horario nunca es cerrado');
    });
  });

  group('filtros', () {
    final sites = buildMapSites([
      place('open',
          name: 'Bodegón Ramón',
          type: RestaurantTypeIds.bodegones,
          hours: wedHours('1200', '2200')),
      place('soon',
          name: 'La Tasca',
          type: RestaurantTypeIds.tascas,
          hours: wedHours('1000', '1400')),
      place('closed',
          name: 'Cofradía de San Andrés',
          type: RestaurantTypeIds.cofradia,
          hours: wedHours('1800', '2300')),
      place('unknown', name: 'El Parralito'),
    ], kWed1330);

    test('«Abierto ahora» incluye «Cierra en N min» y excluye sin horario', () {
      final r = applyMapFilters(sites, const MapFilters(openNow: true));
      expect(r.map((s) => s.id), ['open', 'soon']);
    });

    test('por tipo (varios = O)', () {
      final r = applyMapFilters(
          sites,
          MapFilters(typeIds: {
            RestaurantTypeIds.tascas,
            RestaurantTypeIds.cofradia,
          }));
      expect(r.map((s) => s.id), ['soon', 'closed']);
    });

    test('búsqueda por nombre sin tildes ni mayúsculas', () {
      expect(
          applyMapFilters(sites, const MapFilters(query: 'ramon'))
              .map((s) => s.id),
          ['open']);
      expect(
          applyMapFilters(sites, const MapFilters(query: 'COFRADIA'))
              .map((s) => s.id),
          ['closed']);
    });

    test('toggleType añade y quita', () {
      var f = const MapFilters();
      f = f.toggleType('x');
      expect(f.typeIds, {'x'});
      expect(f.any, isTrue);
      f = f.toggleType('x');
      expect(f.any, isFalse);
    });
  });

  group('chips de tipo', () {
    final types = [
      Types(id: RestaurantTypeIds.restaurantes, nombre: 'Restaurantes'),
      Types(id: RestaurantTypeIds.cofradia, nombre: 'Cofradía'),
      Types(id: RestaurantTypeIds.guachinchesModernos, nombre: 'Guach. mod.'),
      Types(id: RestaurantTypeIds.tascas, nombre: 'Tascas'),
    ];

    test('títulos del tema en el orden del tablero', () {
      final chips = mapTypeChips(types);
      expect(chips.map((c) => c.label),
          ['Guachinches modernos', 'Tascas', 'Restaurantes', 'Cofradías']);
    });

    test('activos primero; sin sitios en la isla se ocultan', () {
      final chips = mapTypeChips(
        types,
        active: {RestaurantTypeIds.cofradia},
        presentTypeIds: {
          RestaurantTypeIds.tascas,
          RestaurantTypeIds.cofradia,
        },
      );
      expect(chips.map((c) => c.label), ['Cofradías', 'Tascas']);
    });
  });

  group('zona visible', () {
    test('MapBox y sitesIn', () {
      const box = MapBox(28.4, -16.5, 28.5, -16.4);
      final a = site('a', lat: 28.45, lon: -16.45);
      final b = site('b', lat: 28.6, lon: -16.45);
      expect(sitesIn([a, b], box).map((s) => s.id), ['a']);
      expect(box.centerLat, closeTo(28.45, 1e-9));
    });

    test('resumen y posición', () {
      final zone = [
        site('a'),
        site('b', open: const OpenState(OpenKind.closed)),
        site('c',
            open: const OpenState(OpenKind.closingSoon, minutesToClose: 20)),
      ];
      expect(zoneSummary(zone), '2 abiertos de 3 en esta zona');
      expect(zoneSummary([site('a')]), '1 abierto de 1 en esta zona');
      expect(zonePosition(20, 37, byDistance: true),
          '21 de 37 en esta zona · por cercanía');
      expect(zonePosition(0, 5, byDistance: false), '1 de 5 en esta zona');
    });

    test('anterior/siguiente es cíclico', () {
      expect(zoneStep(4, 1, 5), 0);
      expect(zoneStep(0, -1, 5), 4);
      expect(zoneStep(-1, 1, 5), 1);
      expect(zoneStep(0, 1, 0), -1);
    });

    test('orden por cercanía', () {
      final near = site('near', lat: kUserLat + 0.001, lon: kUserLon);
      final far = site('far', lat: kUserLat + 0.02, lon: kUserLon);
      expect(sortByProximity([far, near], kUserLat, kUserLon).map((s) => s.id),
          ['near', 'far']);
    });

    test('copia de carga', () {
      expect(loadingCopy('Tenerife'), 'Cargando sitios de Tenerife…');
    });
  });

  group('vacío con filtros', () {
    final cofs = [
      site('c1', type: RestaurantTypeIds.cofradia, municipio: 'San Andrés'),
      site('c2', type: RestaurantTypeIds.cofradia, municipio: 'Tajao'),
    ];

    test('tablero: «Ninguna cofradía abierta por aquí»', () {
      final c = emptyWithFiltersCopy(
        filters:
            MapFilters(openNow: true, typeIds: {RestaurantTypeIds.cofradia}),
        singleKind: ListThemeKind.cofradia,
        islandMatches: cofs,
        islandLabel: 'Tenerife',
        placeName: gmPlaceName,
      );
      expect(c.title, 'Ninguna cofradía abierta por aquí');
      expect(c.text,
          'El mar no se acaba: ahora hay 2 abiertas en Tenerife, una en San Andrés y otra en Tajao.');
      expect(c.showAllLabel, 'Ver las 2 en el mapa');
    });

    test('sin nada en la isla: solo «Quitar filtros»', () {
      final c = emptyWithFiltersCopy(
        filters: const MapFilters(openNow: true),
        singleKind: null,
        islandMatches: const [],
        islandLabel: 'Tenerife',
        placeName: gmPlaceName,
      );
      expect(c.title, 'Nada abierto por aquí');
      expect(c.showAllLabel, isNull);
      expect(c.text, contains('Tenerife'));
    });

    test('masculino y en singular', () {
      final c = emptyWithFiltersCopy(
        filters: MapFilters(typeIds: {RestaurantTypeIds.bodegones}),
        singleKind: ListThemeKind.bodegon,
        islandMatches: [
          site('b', type: RestaurantTypeIds.bodegones, municipio: 'Tacoronte')
        ],
        islandLabel: 'Tenerife',
        placeName: gmPlaceName,
      );
      expect(c.title, 'Ningún bodegón por aquí');
      expect(c.text, 'Hay uno en Tenerife, en Tacoronte.');
      expect(c.showAllLabel, 'Verlo en el mapa');
    });

    test('búsqueda', () {
      final c = emptyWithFiltersCopy(
        filters: const MapFilters(query: 'cabra'),
        singleKind: null,
        islandMatches: const [],
        islandLabel: 'Tenerife',
        placeName: gmPlaceName,
      );
      expect(c.title, 'Nada se llama «cabra» por aquí');
    });
  });

  group('«Cerca de ti»', () {
    test('a menos de 3 km, abiertos primero y luego por distancia', () {
      final sites = [
        site('closedNear', meters: 200, open: const OpenState(OpenKind.closed)),
        site('openFar', meters: 2500),
        site('unknownNear',
            meters: 300, open: const OpenState(OpenKind.unknown)),
        site('openNear', meters: 900),
        site('tooFar', meters: 3200),
        site('noLoc', meters: null),
      ];
      expect(nearbySites(sites).map((s) => s.id),
          ['openNear', 'openFar', 'unknownNear', 'closedNear']);
    });

    test('textos', () {
      expect(nearbyRangeLabel(19), '19 sitios a menos de 3 km');
      expect(nearbyRangeLabel(1), '1 sitio a menos de 3 km');
      expect(nearbyListSubtitle(19),
          '19 sitios a menos de 3 km · abiertos primero');
      expect(nearbyOpenEyebrow(7), '7 abiertos ahora');
      expect(nearbyOpenEyebrow(1), '1 abierto ahora');
      expect(nearbyOpenEyebrow(0), 'Nada abierto ahora');
    });
  });

  group('modo coche', () {
    test('minutos: 1,3 × línea recta a 40 km/h, mínimo 1', () {
      expect(driveEtaMinutes(1700), 4);
      expect(driveEtaMinutes(110), 1);
      expect(driveEtaMinutes(0), 1);
      expect(driveEtaMinutes(10000), 20);
    });

    test('«Estará cerrado al llegar» si cierra antes de llegar o en < 10 min',
        () {
      const soon = OpenState(OpenKind.closingSoon,
          minutesToClose: 3, closesAtMinute: 16 * 60);
      final s = driveStatus(soon, 4);
      expect(s.closedOnArrival, isTrue);
      expect(s.closesAt, '16:00');
      expect(
          driveStatus(
                  const OpenState(OpenKind.closingSoon,
                      minutesToClose: 8, closesAtMinute: 600),
                  2)
              .closedOnArrival,
          isTrue);
      expect(
          driveStatus(
                  const OpenState(OpenKind.closingSoon,
                      minutesToClose: 40, closesAtMinute: 600),
                  4)
              .closedOnArrival,
          isFalse);
      expect(driveStatus(const OpenState(OpenKind.unknown), 4).closedOnArrival,
          isFalse);
    });

    test('candidatos: solo abiertos o sin horario, por cercanía', () {
      final sites = [
        site('closed', meters: 100, open: const OpenState(OpenKind.closed)),
        site('open2', meters: 900),
        site('unknown', meters: 400, open: const OpenState(OpenKind.unknown)),
        site('open1', meters: 300),
        site('far', meters: 9000),
      ];
      expect(driveCandidates(sites).map((s) => s.id),
          ['open1', 'unknown', 'open2']);
      expect(driveOpenCount(driveCandidates(sites)), '2 abiertos cerca de ti');
    });

    test('si hay menos de 3 a 5 km, se amplía a 15 km', () {
      final sites = [site('a', meters: 1000), site('b', meters: 9000)];
      expect(driveCandidates(sites).map((s) => s.id), ['a', 'b']);
    });

    test('antetítulo de tarjeta', () {
      expect(driveCardEyebrow(0, 31), 'Más cerca');
      expect(driveCardEyebrow(11, 31), '12 de 31');
    });

    test('projectAhead: 1 km al norte sube ~0,009°', () {
      final (lat, lon) = projectAhead(28.45, -16.44, 0, 1000);
      expect(lat - 28.45, closeTo(0.00899, 0.0001));
      expect(lon, closeTo(-16.44, 1e-6));
    });

    test('hora', () {
      expect(clockText(7 * 60 + 5), '7:05');
      expect(clockText(22 * 60), '22:00');
    });
  });
}
