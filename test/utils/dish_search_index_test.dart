import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/utils/dish_search_index.dart';

Visit _visit(String restaurantId, List<String> dishNames) {
  return Visit(
    id: 'v-$restaurantId',
    restaurantId: restaurantId,
    dishes: dishNames.map((n) => VisitDish(name: n)).toList(),
  );
}

void main() {
  group('buildDishIndex', () {
    test('normalizes accents — "Carne de Cabra á" yields tokens [carne, cabra]',
        () {
      final visits = [_visit('r1', ['Carne de Cabra á'])];
      final index = buildDishIndex(visits);

      // 'de' is < 3 chars, 'a' (from 'á') is < 3 chars — both discarded
      expect(index.containsKey('carne'), isTrue);
      expect(index.containsKey('cabra'), isTrue);
      expect(index.containsKey('de'), isFalse);
      expect(index.containsKey('a'), isFalse);
    });

    test('visit without dishes adds nothing to index', () {
      final visits = [_visit('r1', [])];
      final index = buildDishIndex(visits);
      expect(index, isEmpty);
    });

    test('maps token to correct restaurantIds', () {
      final visits = [
        _visit('r1', ['Papas arrugadas']),
        _visit('r2', ['Papas con mojo']),
      ];
      final index = buildDishIndex(visits);
      expect(index['papas'], containsAll(['r1', 'r2']));
      expect(index['arrugadas'], equals({'r1'}));
      expect(index['mojo'], equals({'r2'}));
    });
  });

  group('matchRestaurantIds', () {
    test('query shorter than 3 chars returns empty set', () {
      final index = {'pa': {'r1'}};
      expect(matchRestaurantIds(index, 'pa'), isEmpty);
      expect(matchRestaurantIds(index, ''), isEmpty);
      expect(matchRestaurantIds(index, '  '), isEmpty);
    });

    test('strict intersection — both tokens must match', () {
      final index = {
        'carne': {'r1', 'r2'},
        'cabra': {'r1'},
      };
      final result = matchRestaurantIds(index, 'carne cabra');
      expect(result, equals({'r1'}));
    });

    test('fallback to union when 2-token query has empty intersection', () {
      final index = {
        'carne': {'r1'},
        'gofio': {'r2'},
      };
      final result = matchRestaurantIds(index, 'carne gofio');
      expect(result, containsAll(['r1', 'r2']));
    });

    test('no fallback for single-token query with no results', () {
      final index = <String, Set<String>>{};
      final result = matchRestaurantIds(index, 'carne');
      expect(result, isEmpty);
    });

    test('query with accents — "papás" matches token "papas"', () {
      final visits = [_visit('r1', ['Papas arrugadas'])];
      final index = buildDishIndex(visits);

      final result = matchRestaurantIds(index, 'papás');
      expect(result, contains('r1'));
    });
  });
}
