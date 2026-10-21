import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/model/Category.dart';
import 'package:guachinches/data/model/CategoryRestaurant.dart';
import 'package:guachinches/data/model/Review.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/advance_search/list_logic.dart';
import 'package:guachinches/ui/pages/advance_search/list_theme.dart';
import 'package:guachinches/utils/contextual_pool.dart';
import 'package:guachinches/utils/open_state.dart';

Restaurant _r(String id,
    {List<String> ratings = const [],
    List<String> cats = const [],
    String municipio = '',
    Map<String, dynamic>? hours,
    bool open = false}) {
  final r = Restaurant(
    id: id,
    open: open,
    valoraciones: [for (final x in ratings) Review(id: '$id-$x', rating: x)],
    municipio: municipio,
    categoriaRestaurantes: [
      for (final c in cats)
        CategoryRestaurant(
          id: c,
          categoriasRestauranteId: id,
          categoriaId: c,
          categorias: ModelCategory(id: c, nombre: c, iconUrl: '', foto: ''),
        ),
    ],
  );
  r.horariosJson = hours;
  return r;
}

Map<String, dynamic> _daily(String open, String close) => {
      'periods': [
        for (var d = 0; d <= 6; d++)
          {
            'open': {'day': d, 'time': open},
            'close': {'day': d, 'time': close},
          }
      ]
    };

final _sat915 = DateTime(2026, 10, 10, 9, 15);

void main() {
  group('Mejor valorados con peso', () {
    test('(10·4,3 + Σ) / (10 + n): un 5,0 con 1 reseña no adelanta a 4,8×9',
        () {
      final one = _r('uno', ratings: ['5']);
      final nine = _r('nueve', ratings: List.filled(9, '4.8'));
      expect(listWeightedRating(one), closeTo((43 + 5) / 11, 1e-9));
      expect(listWeightedRating(nine), closeTo((43 + 43.2) / 19, 1e-9));
      expect(listWeightedRating(_r('cero')), closeTo(4.3, 1e-9));
      final sorted = listSorted([one, nine], ListSort.topRated, _sat915);
      expect(sorted.map((r) => r.id), ['nueve', 'uno']);
    });
  });

  group('Orden', () {
    test('abiertos primero; los que cierran pronto al final de los abiertos',
        () {
      final soon = _r('pronto', hours: _daily('0700', '0930'));
      final open = _r('abierto', hours: _daily('0700', '1300'));
      final closed = _r('cerrado', hours: _daily('1200', '1600'));
      final unknown = _r('sin');
      final s = listSorted(
          [unknown, closed, soon, open], ListSort.openFirst, _sat915);
      expect(s.map((r) => r.id), ['abierto', 'pronto', 'cerrado', 'sin']);
    });

    test('sin ubicación «Cerca de ti» deja su sitio a «Cierran antes»', () {
      expect(listSortOptions(hasLocation: true).first, ListSort.nearby);
      expect(listSortOptions(hasLocation: false),
          isNot(contains(ListSort.nearby)));
      expect(listSortOptions(hasLocation: false),
          contains(ListSort.closesSoonest));
      expect(listSortCaption(ListSort.topRated), isNotNull);
      expect(listSortCaption(ListSort.nearby), isNull);
    });
  });

  group('Etiqueta de apertura', () {
    test('abierto, cierra en, cerrado con cuándo abre, sin confirmar', () {
      final now = _sat915;
      String label(Restaurant r) =>
          listOpenLabel(restaurantOpenState(r, now)).text;
      expect(label(_r('a', hours: _daily('0700', '1300'))),
          'Abierto hasta 13:00');
      expect(label(_r('b', hours: _daily('0700', '0935'))), 'Cierra en 20 min');
      expect(label(_r('c', hours: _daily('1200', '1600'))),
          'Cerrado · abre hoy 12:00');
      expect(label(_r('d')), 'Horario sin confirmar');
      expect(label(_r('e', open: true)), 'Abierto');
    });
  });

  group('«N más»', () {
    test('abren más tarde, ya no abren hoy y sin horario', () {
      final later = _r('l', hours: _daily('1200', '1600'));
      final gone = _r('g', hours: {
        'periods': [
          {
            'open': {'day': 1, 'time': '0700'},
            'close': {'day': 1, 'time': '1100'}
          }
        ]
      });
      final none = _r('n');
      final b = listLaterBreakdown([later, later, gone, none], _sat915);
      expect((b.laterToday, b.notToday, b.noHours), (2, 1, 1));
      expect(listLaterText(b, noun: 'cafeterías'), (
        '4 cafeterías más:',
        '2 abren más tarde, 1 ya no abre hoy y 1 sin horario confirmado.'
      ));
      expect(listLaterText(const LaterBreakdown(0, 0, 0), noun: 'x'), isNull);
    });
  });

  group('Filtros', () {
    test('categorías suman (O), municipio por nombre y «Abierto ahora»', () {
      final terraza = _r('t',
          cats: [CategoryIds.terraza],
          municipio: 'Santa Cruz de Tenerife',
          hours: _daily('0700', '1300'));
      final vistas =
          _r('v', cats: [CategoryIds.conVistas], municipio: 'Arafo');
      const f = LocalFilters(
          categoryIds: {CategoryIds.terraza, CategoryIds.conVistas});
      expect(listMatches(terraza, f, _sat915), isTrue);
      expect(listMatches(vistas, f, _sat915), isTrue);
      final muni = LocalFilters(
          municipalityKeys: {listMunicipalityKey(terraza)});
      expect(listMatches(terraza, muni, _sat915), isTrue);
      expect(listMatches(vistas, muni, _sat915), isFalse);
      expect(listMatches(vistas, const LocalFilters(openOnly: true), _sat915),
          isFalse);
      expect(
          listActiveFilterCount(
              types: 1, categories: 2, municipalities: 0, openOnly: true),
          4);
      expect(listCardChip(terraza), 'Terraza');
      expect(listCardChip(vistas), isNull);
    });
  });

  group('Cabecera', () {
    final bar = (RestaurantTypeIds.barCafeteria, 'Bar/Cafeteria');
    final trad =
        (RestaurantTypeIds.guachinchesTradicionales, 'Guachinches Tradicionales');

    test('desde «Hoy» manda la franja; el subtítulo del desayuno sabe el día',
        () {
      final h = resolveListHeader(
        context: contextThemeForHour(9),
        filtersArePreset: true,
        types: [bar],
        categoryLabels: const [],
        query: '',
        resultCount: 11,
        now: _sat915,
      );
      expect(h.title, 'Para desayunar');
      expect(h.eyebrow, 'Bar/Cafetería · de 7:00 a 11:00');
      expect(h.subtitle, contains('sábado'));
      expect(breakfastSubtitle(DateTime(2026, 10, 12)), contains('a currar'));
    });

    test('si el usuario cambia los filtros, el título pasa al tipo', () {
      final h = resolveListHeader(
        context: ListThemeKind.desayuno,
        filtersArePreset: false,
        types: [bar],
        categoryLabels: const [],
        query: '',
        resultCount: 26,
        typeTotal: 26,
        islandLabel: 'Tenerife',
        now: _sat915,
      );
      expect(h.title, 'Bar/Cafetería');
      expect(h.eyebrow, 'Tipo · 26 en Tenerife');
    });

    test('nunca «5 TIPOS»: varios tipos → «N resultados»', () {
      final h = resolveListHeader(
        filtersArePreset: false,
        types: [bar, trad],
        categoryLabels: const [],
        query: '',
        resultCount: 48,
        now: _sat915,
      );
      expect(h.title, '48 resultados');
      expect(h.title.toUpperCase() == h.title, isFalse);
    });

    test('tipo, categoría limpia y búsqueda', () {
      expect(
          resolveListHeader(
                  filtersArePreset: false,
                  types: [trad],
                  categoryLabels: const [],
                  query: '',
                  resultCount: 22,
                  now: _sat915)
              .title,
          'Guachinches tradicionales');
      expect(listCategoryLabel('CARNE CABRA'), 'Carne de cabra');
      expect(listCategoryLabel('Animales'), 'Con animales');
      expect(listCategoryLabel('Permite mascotas'), 'Admite mascotas');
      final cat = resolveListHeader(
          filtersArePreset: false,
          types: const [],
          categoryLabels: [listCategoryLabel('carne cabra')],
          query: '',
          resultCount: 12,
          now: _sat915);
      expect(cat.title, 'Carne de cabra');
      expect(
          resolveListHeader(
                  filtersArePreset: false,
                  types: const [],
                  categoryLabels: const [],
                  query: 'cabra',
                  resultCount: 12,
                  now: _sat915)
              .title,
          'Buscar');
      expect(
          listSectionEyebrow(
              openCount: 3, total: 12, openOnly: false, query: 'cabra'),
          '12 sitios · coincide «cabra»');
      expect(
          listSectionEyebrow(
              context: ListThemeKind.desayuno,
              openCount: 11,
              total: 26,
              openOnly: true),
          'Hora del desayuno · 11 abiertos ahora');
    });

    test('franjas por hora (las de contextual_pool)', () {
      expect(contextThemeForHour(7), ListThemeKind.desayuno);
      expect(contextThemeForHour(12), ListThemeKind.almuerzo);
      expect(contextThemeForHour(18), ListThemeKind.golden);
      expect(contextThemeForHour(21), ListThemeKind.cena);
      expect(contextThemeForHour(3), ListThemeKind.madrugada);
    });
  });

  group('Municipios por id', () {
    test('el id del municipio manda, aunque los nombres no coincidan', () {
      // findByFilter: municipio anidado con su id oficial.
      final r = Restaurant.fromJson({
        'id': 'a',
        'nombre': 'Guachinche El Chupete',
        'municipios': {
          'Id': '0b2a-laguna',
          'Nombre': 'San Cristóbal de La Laguna',
          'islandId': 'tf',
        },
        'categoriasRestaurantes': [],
        'fotos': [],
        'valoraciones': [],
      });
      expect(r.negocioMunicipioId, '0b2a-laguna');
      expect(listMunicipalityKey(r), '0b2a-laguna');
      // Elegido en «Dónde» por su clave: pasa aunque otra fuente lo llame
      // «La Laguna».
      final f = LocalFilters(municipalityKeys: {'0b2a-laguna'});
      expect(listMatches(r, f, _sat915), isTrue);
      expect(listMatches(r, const LocalFilters(municipalityKeys: {'otro'}),
              _sat915),
          isFalse);
    });

    test('sin id, cae al nombre normalizado', () {
      final r = _r('b', municipio: 'Güímar');
      expect(listMunicipalityKey(r), 'name:guimar');
    });

    test('filas de «Dónde»: recuento por id, nombres bonitos y elegidos', () {
      Restaurant at(String id, String mid, String name) =>
          _r(id, municipio: name)..negocioMunicipioId = mid;
      final rows = listMunicipalityRows([
        at('1', 'sc', 'Santa Cruz de Tenerife'),
        at('2', 'sc', 'Santa Cruz de Tenerife'),
        at('3', 'll', 'San Cristóbal de La Laguna'),
        at('4', 'ar', 'ARICO'),
      ], selected: ['gu'], names: {'gu': 'Güímar'});
      expect(rows, [
        ('ar', 'Arico', 1),
        ('gu', 'Güímar', 0),
        ('ll', 'San Cristóbal de La Laguna', 1),
        ('sc', 'Santa Cruz de Tenerife', 2),
      ]);
    });
  });

  group('Preset de franja', () {
    const lunch = ['rest', 'tasca', 'bodegon', 'trad', 'mod'];
    PresetSummary sum(
            {List<String> types = lunch,
            List<String> cats = const [],
            List<String> munis = const [],
            bool open = true,
            bool ctx = true}) =>
        listPresetSummary(
          hasContext: ctx,
          presetTypes: lunch,
          presetCategories: const [],
          presetOpenOnly: true,
          types: types,
          categories: cats,
          municipalities: munis,
          openOnly: open,
        );

    test('entero: un chip y cuenta como 1', () {
      final s = sum();
      expect(s.active, isTrue);
      expect(s.badge, 1);
    });

    test('con extras encima: 1 + extras', () {
      final s = sum(cats: ['terraza'], munis: ['sc']);
      expect(s.active, isTrue);
      expect(s.extraCategoryIds, ['terraza']);
      expect(s.badge, 3);
    });

    test('si se toca el preset deja de serlo (cuenta normal)', () {
      final s = sum(types: lunch.take(4).toList());
      expect(s.active, isFalse);
      expect(s.badge, 5);
      expect(sum(open: false).active, isFalse);
      expect(sum(ctx: false).active, isFalse);
    });
  });
}
