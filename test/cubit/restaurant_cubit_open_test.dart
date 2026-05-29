import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_state.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/data/model/restaurant_response.dart';

class _FakeRemoteRepo extends Fake implements RemoteRepository {
  final List<Restaurant> restaurants;

  _FakeRemoteRepo(this.restaurants);

  @override
  Future<List<Restaurant>> getFilterRestaurants(
    String categorias,
    String municipalities,
    String types,
    String nombre,
    String islandId,
  ) async =>
      restaurants;

  @override
  Future<RestaurantResponse> getAllRestaurants(
    int number, [
    String islandId = '',
  ]) async =>
      RestaurantResponse(restaurants: []);
}

Restaurant _r(String id, {bool open = false}) => Restaurant(id: id, open: open);

void main() {
  group('RestaurantCubit.getFilterRestaurants(isOpen: true)', () {
    test('emits RestaurantFilter containing only open restaurants', () async {
      final repo = _FakeRemoteRepo([
        _r('open-1', open: true),
        _r('closed-1', open: false),
        _r('open-2', open: true),
        _r('closed-2', open: false),
      ]);
      final cubit = RestaurantCubit(repo);

      await cubit.getFilterRestaurants(
        categories: [],
        municipalities: [],
        types: [],
        text: '',
        islandId: 'test-island',
        isOpen: true,
      );

      final state = cubit.state;
      expect(state, isA<RestaurantFilter>());
      final result = (state as RestaurantFilter).filtersRestaurants;
      expect(result.length, 2);
      expect(result.every((r) => r.open), isTrue);
      expect(result.map((r) => r.id), containsAll(['open-1', 'open-2']));
    });

    test('emits RestaurantFilter with all restaurants when isOpen is false',
        () async {
      final repo = _FakeRemoteRepo([
        _r('open-1', open: true),
        _r('closed-1', open: false),
      ]);
      final cubit = RestaurantCubit(repo);

      await cubit.getFilterRestaurants(
        categories: [],
        municipalities: [],
        types: [],
        text: '',
        islandId: 'test-island',
        isOpen: false,
      );

      final state = cubit.state as RestaurantFilter;
      expect(state.filtersRestaurants.length, 2);
    });

    test('emits empty RestaurantFilter when all restaurants are closed',
        () async {
      final repo = _FakeRemoteRepo([
        _r('closed-1', open: false),
        _r('closed-2', open: false),
      ]);
      final cubit = RestaurantCubit(repo);

      await cubit.getFilterRestaurants(
        categories: [],
        municipalities: [],
        types: [],
        text: '',
        islandId: 'test-island',
        isOpen: true,
      );

      final state = cubit.state as RestaurantFilter;
      expect(state.filtersRestaurants, isEmpty);
    });
  });
}
