import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/model/TopRestaurants.dart';
import 'package:guachinches/data/model/curated_list.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/advance_search/list_theme.dart';
import 'package:guachinches/ui/pages/listas/listas_logic.dart';

CuratedList _g(
  String id, {
  String title = 'Lista',
  String subtitle = '',
  String eyebrow = '',
  String location = '',
  String? islandId,
  int position = 0,
  int count = 0,
  bool enabled = true,
}) =>
    CuratedList(
      id: id,
      title: title,
      subtitle: subtitle,
      eyebrow: eyebrow,
      location: location,
      islandId: islandId,
      position: position,
      count: count,
      enabled: enabled,
      accent: const Color(0xFF000000),
    );

TopRestaurants _top(String id, {required int n, required double avg}) =>
    TopRestaurants(id: id, nombre: id, avg: avg, counter: '${n * avg}');

void main() {
  group('listasGuidesForIsland', () {
    final all = [
      _g('gc', islandId: 'GC', position: 1),
      _g('global', position: 3),
      _g('tf', islandId: 'TF', position: 2),
      _g('off', islandId: 'TF', position: 0, enabled: false),
    ];

    test('isla + globales, activas y por posición', () {
      expect(listasGuidesForIsland(all, 'TF').map((l) => l.id),
          ['tf', 'global']);
    });

    test('sin isla, todas las activas', () {
      expect(listasGuidesForIsland(all, null).map((l) => l.id),
          ['gc', 'tf', 'global']);
    });
  });

  group('listasSearchGuides', () {
    final guides = [
      _g('a', title: 'Terrazas con vistas', eyebrow: 'Jonay'),
      _g('b', title: 'Japoneses', location: 'La Laguna'),
      _g('c', title: 'Cenas', subtitle: 'Para celebrar un cumpleaños'),
    ];

    test('todas las palabras, sin tildes ni mayúsculas', () {
      expect(listasSearchGuides(guides, 'JONAY terrazas').map((l) => l.id),
          ['a']);
      expect(listasSearchGuides(guides, 'cumpleanos').map((l) => l.id), ['c']);
      expect(listasSearchGuides(guides, 'laguna').map((l) => l.id), ['b']);
    });

    test('vacía devuelve todo; sin coincidencias, nada', () {
      expect(listasSearchGuides(guides, '  ').length, 3);
      expect(listasSearchGuides(guides, 'pizza'), isEmpty);
    });
  });

  test('listasThemeForGuide por palabras clave', () {
    expect(listasThemeForGuide(_g('x', title: 'Mejores bocadillos cochino')),
        ListThemeKind.tasca);
    expect(listasThemeForGuide(_g('x', title: 'Japoneses en Tenerife')),
        ListThemeKind.lounge);
    expect(listasThemeForGuide(_g('sushi-tf')), ListThemeKind.lounge);
    expect(listasThemeForGuide(_g('x', title: 'Ocasiones ESPECIALES')),
        ListThemeKind.experiencia);
    expect(listasThemeForGuide(_g('x', title: 'Aniversario')),
        ListThemeKind.experiencia);
    expect(listasThemeForGuide(_g('x', title: 'Brunch')), ListThemeKind.bar);
    expect(listasThemeForGuide(_g('x', title: 'Terrazas')),
        ListThemeKind.categoria);
  });

  test('listasSentence solo toca lo que viene en mayúsculas', () {
    expect(listasSentence('TOP'), 'Top');
    expect(listasSentence('Cenas especiales'), 'Cenas especiales');
    expect(listasSentence('  '), '');
  });

  test('antetítulos de guía', () {
    expect(
        listasFeaturedEyebrow(
            _g('a', eyebrow: 'TOP', location: 'Toda la isla')),
        'Top · Toda la isla');
    expect(listasFeaturedEyebrow(_g('a', location: 'Tenerife')), 'Tenerife');
    expect(listasRowEyebrow(_g('a', eyebrow: 'Guía', count: 6)),
        'Guía · 6 sitios');
    expect(listasRowEyebrow(_g('a', eyebrow: 'Guía', count: 1)),
        'Guía · 1 sitio');
    expect(listasRowEyebrow(_g('a', count: 3)), '3 sitios');
  });

  test('«Para ahora»: antetítulo y subtítulo', () {
    // 2026-10-14 es miércoles.
    expect(listasParaAhoraEyebrow(DateTime(2026, 10, 14, 9, 5)),
        'Para ahora · miércoles, 9:05');
    expect(
        listasParaAhoraSubtitle(
            ListThemeKind.desayuno, DateTime(2026, 10, 17, 9)),
        'Barraquito, bocadillo y sin prisa, que es sábado.');
    expect(listasParaAhoraSubtitle(ListThemeKind.cena, DateTime(2026, 10, 14)),
        'Mesa para esta noche.');
  });

  test('guardados: título y fotos del pool', () {
    expect(listasSavedTitle(1), '1 sitio guardado');
    expect(listasSavedTitle(5), '5 sitios guardados');
    final pool = [
      Restaurant(id: 'a')..mainFoto = 'https://x/a.jpg',
      Restaurant(id: 'b'),
      Restaurant(id: 'c')..mainFoto = 'https://x/c.jpg',
      Restaurant(id: 'd')..mainFoto = 'https://x/d.jpg',
      Restaurant(id: 'e')..mainFoto = 'https://x/e.jpg',
    ];
    expect(listasSavedPhotos({'a', 'b', 'c'}, pool),
        ['https://x/a.jpg', 'https://x/c.jpg']);
    expect(listasSavedPhotos({'a', 'c', 'd', 'e'}, pool).length, 3);
    expect(listasSavedPhotos({'z'}, pool), isEmpty);
  });

  group('listasTopRated', () {
    test('reseñas = counter / media', () {
      expect(listasTopReviewCount(_top('a', n: 12, avg: 4.5)), 12);
      expect(listasTopReviewCount(TopRestaurants(id: 'x')), 0);
    });

    test('solo ≥ 10 reseñas, de la isla y con orden ponderado', () {
      final top = [
        _top('pocas', n: 3, avg: 5.0),
        _top('muchas', n: 80, avg: 4.6),
        _top('justas', n: 10, avg: 4.9),
        _top('otra-isla', n: 50, avg: 4.9),
      ];
      final r = listasTopRated(top, {'pocas', 'muchas', 'justas'});
      // muchas: (43 + 368) / 90 = 4,57; justas: (43 + 49) / 20 = 4,6.
      expect(r.map((t) => t.id), ['justas', 'muchas']);
    });

    test('sin sitios cargados no filtra por isla', () {
      final r = listasTopRated([_top('a', n: 20, avg: 4.5)], const {});
      expect(r.map((t) => t.id), ['a']);
    });
  });
}
