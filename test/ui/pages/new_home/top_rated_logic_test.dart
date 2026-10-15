import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/model/TopRestaurants.dart';
import 'package:guachinches/ui/pages/new_home/top_rated_logic.dart';

/// Sitio del ranking del servidor: `counter` = Σ notas = n · media.
TopRestaurants top(String id, double avg, int n,
        {String muni = 'La Orotava'}) =>
    TopRestaurants(
      id: id,
      nombre: id,
      avg: avg,
      counter: (avg * n).toString(),
      municipio: muni,
    );

void main() {
  group('topRatedScore', () {
    test('weighted (10·4,3 + Σ) / (10 + n)', () {
      expect(topRatedScore(top('a', 5, 18)), closeTo(133 / 28, 1e-9));
      expect(topRatedScore(top('b', 5, 3)), closeTo(58 / 13, 1e-9));
    });
  });

  group('topRatedSplit', () {
    final data = [
      top('E', 3.455, 11),
      top('A', 5.0, 18),
      top('few-H', 4.0, 9),
      top('C', 4.815, 46),
      top('few-G', 5.0, 3),
      top('B', 4.847, 36),
      top('few-I', 5.0, 1),
      top('D', 5.0, 14),
      top('few-F', 5.0, 7),
      top('zero', 0, 0),
      top('few-J', 4.6, 5),
    ];

    test('ranked: only ≥ 10 reviews, weighted order', () {
      final s = topRatedSplit(data);
      expect(s.ranked.map((t) => t.id), ['A', 'B', 'C', 'D', 'E']);
      expect(s.isEmpty, isFalse);
    });

    test('few: 1–9 reviews, same order, none without reviews', () {
      final s = topRatedSplit(data);
      expect(s.few.map((t) => t.id),
          ['few-F', 'few-G', 'few-J', 'few-I', 'few-H']);
    });

    test('a 5,0 with 3 reviews never beats a 4,8 with 36', () {
      final s = topRatedSplit([top('tiny', 5, 3), top('solid', 4.8, 36)]);
      expect(s.ranked.map((t) => t.id), ['solid']);
      expect(s.few.map((t) => t.id), ['tiny']);
    });

    test('nobody reaches 10 → empty ranking', () {
      final s = topRatedSplit([top('x', 5, 9)]);
      expect(s.isEmpty, isTrue);
      expect(s.few, hasLength(1));
    });
  });

  group('topRatedIslandOf', () {
    test('official names, any spelling', () {
      expect(topRatedIslandOf('La Orotava'), 'TF');
      expect(topRatedIslandOf('OROTAVA'), 'TF');
      expect(topRatedIslandOf('LA LAGUNA'), 'TF');
      expect(topRatedIslandOf('San Cristóbal de La Laguna'), 'TF');
      expect(topRatedIslandOf('GUIMAR'), 'TF');
      expect(topRatedIslandOf('Güímar'), 'TF');
      expect(topRatedIslandOf('Arona'), 'TF');
      expect(topRatedIslandOf('El Sauzal'), 'TF');
      expect(topRatedIslandOf('Telde'), 'GC');
      expect(topRatedIslandOf('Valle Gran Rey'), 'GO');
      expect(topRatedIslandOf('Arrecife'), 'LZ');
    });

    test('strongest match wins across islands', () {
      // «SANTA CRUZ» (barrio de Tenerife) no se lleva Santa Cruz de La Palma.
      expect(
          topRatedIslandOf('Santa Cruz de La Palma', extra: {
            'TF': ['SANTA CRUZ']
          }),
          'LP');
      expect(topRatedIslandOf('Santa Cruz de Tenerife'), 'TF');
      expect(topRatedIslandOf('San Bartolomé de Tirajana'), 'GC');
      expect(topRatedIslandOf('San Bartolomé'), 'LZ');
    });

    test('localities need the island areas', () {
      expect(topRatedIslandOf('LOS CRISTIANOS'), isNull);
      expect(
          topRatedIslandOf('LOS CRISTIANOS', extra: {
            'TF': ['LOS CRISTIANOS']
          }),
          'TF');
      expect(
          topRatedIslandOf('ANAGA.', extra: {
            'TF': ['ANAGA.']
          }),
          'TF');
      expect(topRatedIslandOf(''), isNull);
      expect(topRatedIslandOf('Madrid'), isNull);
    });

    test('topRatedForIsland keeps only that island', () {
      final all = [
        top('tf1', 5, 12, muni: 'La Orotava'),
        top('tf2', 5, 12, muni: 'LOS CRISTIANOS'),
        top('gc1', 5, 12, muni: 'Telde'),
        top('lp1', 5, 12, muni: 'Santa Cruz de La Palma'),
      ];
      expect(
          topRatedForIsland(all, 'TF',
              areaNames: ['LOS CRISTIANOS', 'SANTA CRUZ']).map((t) => t.id),
          ['tf1', 'tf2']);
      expect(topRatedForIsland(all, 'gc').map((t) => t.id), ['gc1']);
      expect(topRatedForIsland(all, 'LP').map((t) => t.id), ['lp1']);
      expect(topRatedForIsland(all, 'EH'), isEmpty);
    });

    test('normalization', () {
      expect(topRatedNormalizePlace('  La Esperanza -LA LAGUNA '),
          'la esperanza la laguna');
      expect(topRatedNormalizePlace('ANAGA.'), 'anaga');
    });
  });

  test('display name undoes the model capitalize()', () {
    expect(topRatedDisplayName('Guachinche el fogon'), 'Guachinche El Fogon');
    expect(topRatedDisplayName('La huerta de ana y eva'),
        'La Huerta de Ana y Eva');
    expect(topRatedDisplayName('Restaurante el canario (ravelo)'),
        'Restaurante El Canario (Ravelo)');
    expect(topRatedDisplayName("McDonald's"), "McDonald's");
    expect(topRatedDisplayName('De tapas'), 'De Tapas');
    expect(topRatedDisplayName(''), '');
  });

  group('copy', () {
    test('labels', () {
      expect(topRatedReviewsLabel(1), '1 reseña');
      expect(topRatedReviewsLabel(18), '18 reseñas');
      expect(topRatedRatingLabel(4.847), '4,8');
      expect(topRatedFewMoreLabel(118), 'Ver los 118 con pocas reseñas');
      expect(topRatedEmptyTitle('Gran Canaria'),
          'Todavía nadie llega a 10 reseñas en Gran Canaria');
      expect(
          topRatedEmptyText('Gran Canaria'),
          'En cuanto un sitio de la isla tenga 10 reseñas, entra aquí. '
          'Mientras, mira todos los sitios de Gran Canaria.');
      expect(
          topRatedSeeIslandCta('Gran Canaria'), 'Ver sitios de Gran Canaria');
      expect(
          topRatedBackToRankingCta('Tenerife'), 'Ver el ranking de Tenerife');
    });

    test('row semantics', () {
      expect(
        topRatedRowSemantics(
            rank: 1,
            name: 'Rincón del Marinero',
            place: 'Arico',
            avg: 5,
            reviews: 18),
        'Número 1, Rincón del Marinero, Arico, 5,0 estrellas, 18 reseñas',
      );
      expect(
        topRatedRowSemantics(name: 'Brasas', place: '', avg: 4.0, reviews: 7),
        'Brasas, 4,0 estrellas, 7 reseñas',
      );
    });
  });
}
