import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/discover/discover_logic.dart';
import 'package:guachinches/ui/pages/discover/visit_sentiment.dart';
import 'package:guachinches/ui/pages/discover/widgets/sort_sheet.dart';
import 'package:guachinches/ui/pages/discover/widgets/visit_filter_sheet.dart';
import 'package:guachinches/utils/contextual_pool.dart';

const _tfId = 'tf-id';
const _gcId = 'gc-id';
const _idToKey = {_tfId: 'TF', _gcId: 'GC'};

Visit _v(
  String id, {
  String? islandId,
  double lat = 0,
  double lon = 0,
  String? date,
  String? restaurantId,
  String nombre = '',
  String municipio = '',
  String? type,
  List<String> dishes = const [],
  String? sentiment,
  String? zone,
}) {
  final r = Restaurant(id: restaurantId ?? 'r-$id', nombre: nombre);
  r.municipioIslandId = islandId;
  r.lat = lat;
  r.lon = lon;
  r.municipio = municipio;
  if (type != null) r.type = type;
  return Visit(
    id: id,
    restaurantId: restaurantId ?? 'r-$id',
    videoPublishedAt: date,
    overallSentiment: sentiment,
    zone: zone,
    dishes: [for (final d in dishes) VisitDish(name: d)],
  )..restaurant = r;
}

void main() {
  group('isla de la visita', () {
    test('usa municipioIslandId traducido a key', () {
      expect(discoverVisitIslandKey(_v('a', islandId: _gcId), _idToKey), 'GC');
    });

    test('sin municipio usa lat/lon', () {
      // Santa Cruz de Tenerife.
      expect(
          discoverVisitIslandKey(
              _v('a', lat: 28.4636, lon: -16.2518), _idToKey),
          'TF');
    });

    test('id desconocido cae a lat/lon; sin nada → null', () {
      expect(
          discoverVisitIslandKey(
              _v('a', islandId: 'x', lat: 28.1, lon: -15.43), _idToKey),
          'GC');
      expect(discoverVisitIslandKey(_v('a', islandId: 'x'), _idToKey), isNull);
      expect(
          discoverVisitIslandKey(
              Visit(id: 'n', restaurantId: ''), _idToKey),
          isNull);
    });

    test('recuentos por isla y visitas de una isla', () {
      final visits = [
        _v('1', islandId: _tfId),
        _v('2', islandId: _tfId),
        _v('3', islandId: _gcId),
        _v('4'),
      ];
      expect(discoverIslandCounts(visits, _idToKey), {'TF': 2, 'GC': 1});
      expect(discoverVisitsOfIsland(visits, 'tf', _idToKey).map((v) => v.id),
          ['1', '2']);
    });
  });

  group('chips de isla', () {
    const islands = [
      DiscoverIsland(id: _tfId, key: 'TF', label: 'Tenerife'),
      DiscoverIsland(id: _gcId, key: 'GC', label: 'Gran Canaria'),
      DiscoverIsland(id: 'go', key: 'GO', label: 'La Gomera'),
      DiscoverIsland(id: 'eh', key: 'EH', label: 'El Hierro'),
    ];

    test('solo islas con visitas, de más a menos, y la elegida', () {
      final chips =
          discoverIslandChips(islands, {'GC': 22, 'TF': 297, 'GO': 5}, 'GO');
      expect(chips.map((c) => c.island.key), ['TF', 'GC', 'GO']);
      expect(chips.map((c) => c.selected), [false, false, true]);
      expect(chips.first.count, 297);
    });

    test('la elegida aparece aunque no tenga visitas', () {
      final chips = discoverIslandChips(islands, {'TF': 3}, 'EH');
      expect(chips.map((c) => c.island.key), ['TF', 'EH']);
      expect(chips.last.count, 0);
    });

    test('isla con más visitas distinta de la actual', () {
      expect(discoverTopIsland({'TF': 9, 'GC': 3}, 'TF'), 'GC');
      expect(discoverTopIsland({'TF': 9, 'GC': 3}, 'EH'), 'TF');
      expect(discoverTopIsland({'TF': 9}, 'TF'), isNull);
    });
  });

  group('cabecera', () {
    test('subtítulo con vídeos y sitios distintos', () {
      final visits = [
        _v('1', restaurantId: 'a'),
        _v('2', restaurantId: 'a'),
        _v('3', restaurantId: 'b'),
      ];
      expect(discoverSubtitle(visits, 'Tenerife'),
          '3 vídeos en 2 sitios de Tenerife');
      expect(discoverSubtitle([visits.first], 'El Hierro'),
          '1 vídeo en 1 sitio de El Hierro');
      expect(discoverSubtitle(const [], 'La Palma'), 'Aún sin vídeos en La Palma');
    });
  });

  group('fechas', () {
    final visits = [
      _v('a', date: '2026-10-08T10:00:00Z'),
      _v('b', date: '2026-10-07T10:00:00Z'),
      _v('c', date: '2026-09-28T10:00:00Z'),
      _v('d', date: '2025-10-15T10:00:00Z'),
      _v('e'),
    ];

    test('«Lo último»: las 3 más recientes', () {
      expect(discoverLatest(visits).map((v) => v.id), ['a', 'b', 'c']);
    });

    test('antetítulo: visitas del mes (y año) de la más reciente', () {
      expect(discoverLatestEyebrow(visits), '2 visitas en octubre');
      expect(discoverLatestEyebrow([visits.first]), '1 visita en octubre');
      expect(discoverLatestEyebrow([_v('x')]), isNull);
    });

    test('agrupado por mes con título y recuento', () {
      final sorted = discoverSort(visits, VisitSort.newest);
      final groups = discoverGroups(sorted, VisitSort.newest);
      expect(groups.map((g) => g.caption), [
        'Octubre de 2026 · 2 visitas',
        'Septiembre de 2026 · 1 visita',
        'Octubre de 2025 · 1 visita',
        'Sin fecha · 1 visita',
      ]);
      expect(groups.first.visits.map((v) => v.id), ['a', 'b']);
    });

    test('otros órdenes: un solo grupo sin título', () {
      final groups = discoverGroups(visits, VisitSort.alphaAsc);
      expect(groups, hasLength(1));
      expect(groups.single.caption, isNull);
      expect(discoverGroups(const [], VisitSort.newest), isEmpty);
    });
  });

  group('filas', () {
    test('línea de platos', () {
      expect(discoverDishLine(_v('a')), isNull);
      expect(discoverDishLine(_v('a', dishes: ['albóndigas'])), 'Albóndigas');
      expect(discoverDishLine(_v('a', dishes: ['Papas', 'Mojo'])),
          'Papas y Mojo');
      expect(discoverDishLine(_v('a', dishes: ['A', 'B', 'C'])), 'A, B y C');
      expect(
          discoverDishLine(_v('a', dishes: [
            'Churritos de pescado',
            'Favada',
            'C',
            'D',
            ' ',
            'E',
            'F'
          ])),
          'Churritos de pescado, Favada y 4 más');
    });

    test('municipio corto y en tipo título', () {
      expect(discoverShortMunicipio(_v('a', municipio: 'Santa Cruz de Tenerife')),
          'Santa Cruz');
      expect(
          discoverShortMunicipio(
              _v('a', municipio: 'SAN CRISTÓBAL DE LA LAGUNA')),
          'La Laguna');
      expect(discoverShortMunicipio(_v('a', municipio: 'TACORONTE')),
          'Tacoronte');
      expect(discoverShortMunicipio(_v('a', zone: 'Tegueste')), 'Tegueste');
      expect(discoverShortMunicipio(_v('a')), isNull);
    });

    test('tipo en singular; desconocido → null', () {
      expect(discoverTypeLabel(_v('a', type: RestaurantTypeIds.bodegones)),
          'Bodegón');
      expect(discoverTypeLabel(_v('a')), isNull);
      expect(
          discoverTypeLabel(
              _v('a', type: '00000000-0000-0000-0000-000000000000')),
          isNull);
    });

    test('nombre: el del negocio en tipo título, si no el de la visita', () {
      expect(discoverVisitName(_v('a', nombre: 'BODEGON EL PETUDO')),
          'Bodegon el Petudo');
      final v = _v('b')..name = 'Casa Ángela';
      expect(discoverVisitName(v), 'Casa Ángela');
    });
  });

  group('«Lo que más piden»', () {
    test('coincidencias sin tildes y con exclusiones', () {
      expect(discoverDishMatches(DiscoverDish.cabra, 'Carne de CABRA'), isTrue);
      expect(
          discoverDishMatches(DiscoverDish.cabra, 'Queso de cabra a la plancha'),
          isFalse);
      expect(discoverDishMatches(DiscoverDish.cochino, 'Costilla de cochino negro'),
          isTrue);
      expect(discoverDishMatches(DiscoverDish.vieja, 'Vieja sancochada'), isTrue);
      expect(discoverDishMatches(DiscoverDish.vieja, 'Ropa vieja'), isFalse);
      expect(discoverDishMatches(DiscoverDish.vieja, 'Viejas fritas'), isFalse);
      expect(discoverDishMatches(DiscoverDish.barraquito, 'Barraquito especial'),
          isTrue);
    });

    test('recuento = visitas con al menos un plato que coincide', () {
      final visits = [
        _v('1', dishes: ['Cabra en salsa', 'Carne de cabra']),
        _v('2', dishes: ['Queso de cabra']),
        _v('3', dishes: ['Barraquito']),
      ];
      expect(discoverDishCounts(visits), {
        DiscoverDish.cabra: 1,
        DiscoverDish.cochino: 0,
        DiscoverDish.vieja: 0,
        DiscoverDish.barraquito: 1,
      });
    });
  });

  group('búsqueda, filtros y orden', () {
    final visits = [
      _v('1',
          nombre: 'José el Cisco',
          municipio: 'Tegueste',
          dishes: ['Carne fiesta'],
          date: '2026-01-01T00:00:00Z',
          sentiment: 'muy_positivo'),
      _v('2', nombre: 'Añaza Bar', dishes: ['Pulpo'], date: '2026-02-01T00:00:00Z'),
    ];

    test('palabras en cualquier orden y sin tildes', () {
      const none = VisitFilterValues();
      expect(discoverMatches(visits[0], 'tegueste carne', none), isTrue);
      expect(discoverMatches(visits[0], 'jose', none), isTrue);
      expect(discoverMatches(visits[1], 'anaza', none), isTrue);
      expect(discoverMatches(visits[1], 'carne', none), isFalse);
    });

    test('filtros de ánimo y municipio', () {
      expect(
          discoverApply(visits,
                  query: '',
                  filters: const VisitFilterValues(moods: {VisitMood.loved}),
                  sort: VisitSort.newest)
              .map((v) => v.id),
          ['1']);
      expect(
          discoverApply(visits,
                  query: '',
                  filters: const VisitFilterValues(municipios: {'Tegueste'}),
                  sort: VisitSort.newest)
              .map((v) => v.id),
          ['1']);
      expect(discoverIsFiltering('', const VisitFilterValues()), isFalse);
      expect(discoverIsFiltering(' x ', const VisitFilterValues()), isTrue);
    });

    test('orden por fecha y alfabético', () {
      expect(discoverSort(visits, VisitSort.newest).map((v) => v.id), ['2', '1']);
      expect(discoverSort(visits, VisitSort.oldest).map((v) => v.id), ['1', '2']);
      expect(discoverSort(visits, VisitSort.alphaAsc).map((v) => v.id),
          ['2', '1']);
    });

    test('más cerca de ti: por distancia, sin coordenadas al final', () {
      final near = [
        _v('lejos', lat: 28.10, lon: -15.43, date: '2026-03-01T00:00:00Z'),
        _v('sin', date: '2026-04-01T00:00:00Z'),
        _v('cerca', lat: 28.46, lon: -16.25, date: '2026-01-01T00:00:00Z'),
      ];
      const sc = (lat: 28.4636, lon: -16.2518);
      expect(
          discoverSort(near, VisitSort.nearest, origin: sc).map((v) => v.id),
          ['cerca', 'lejos', 'sin']);
      // Sin ubicación se queda por fecha.
      expect(discoverSort(near, VisitSort.nearest).map((v) => v.id),
          ['sin', 'lejos', 'cerca']);
    });

    test('antetítulos', () {
      expect(discoverListEyebrow(VisitSort.newest), 'Por fecha del vídeo');
      expect(discoverResultsEyebrow(1), '1 resultado');
      expect(discoverResultsEyebrow(4), '4 resultados');
    });
  });

  group('estado vacío', () {
    final visits = [
      _v('1', islandId: _tfId, dishes: ['Pulpo a la gallega']),
      _v('2', islandId: _tfId, dishes: ['Pulpo frito']),
      _v('3', islandId: _gcId, dishes: ['Pulpo']),
      _v('4', islandId: _gcId, dishes: ['Cabra']),
    ];

    test('sugiere la otra isla con más coincidencias', () {
      final s = discoverEmptySuggestion(visits,
          currentKey: 'EH',
          query: 'pulpo',
          filters: const VisitFilterValues(),
          islandIdToKey: _idToKey);
      expect(s?.islandKey, 'TF');
      expect(s?.count, 2);
      final none = discoverEmptySuggestion(visits,
          currentKey: 'GC',
          query: 'cabra',
          filters: const VisitFilterValues(),
          islandIdToKey: _idToKey);
      expect(none, isNull);
    });

    test('textos', () {
      expect(discoverEmptyTitle('pulpo', 'El Hierro'),
          'Ninguna visita con «pulpo» en El Hierro');
      expect(discoverEmptyTitle('', 'El Hierro'),
          'Ninguna visita con estos filtros en El Hierro');
      expect(discoverSuggestionText('pulpo', 'Tenerife', 45),
          'En Tenerife hay 45 visitas con «pulpo».');
      expect(discoverSuggestionText('pulpo', 'Tenerife', 1),
          'En Tenerife hay 1 visita con «pulpo».');
    });
  });
}
