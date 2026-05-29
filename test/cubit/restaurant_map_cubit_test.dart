// Covers the refresh() entry point invoked by the mapa-refresh-fab in
// lib/ui/pages/map/map_search.dart. A widget-level test would require
// mocking the google_maps_flutter platform channel and the location plugin,
// which is out of scope here. Cubit-level coverage validates the same
// behavior: refresh() must re-invoke the LAST query (all or filtered) with
// the LAST islandId, and be a no-op if no query has been made yet.

import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/restaurants/map/restaurant_map_cubit.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/data/model/restaurant_response.dart';

class _SpyRepo extends Fake implements RemoteRepository {
  int allCalls = 0;
  int filterCalls = 0;
  final List<String> allIslandIds = [];
  final List<String> filterIslandIds = [];

  @override
  Future<RestaurantResponse> getAllRestaurants(int number, [String islandId = '']) async {
    allCalls++;
    allIslandIds.add(islandId);
    // First call returns 0 to short-circuit the while-loop pagination
    return RestaurantResponse(count: 0, restaurants: const []);
  }

  @override
  Future<List<Restaurant>> getFilterRestaurants(
    String categories,
    String municipalities,
    String types,
    String text,
    String islandId,
  ) async {
    filterCalls++;
    filterIslandIds.add(islandId);
    return const <Restaurant>[];
  }
}

void main() {
  group('RestaurantMapCubit.refresh', () {
    test('(a) refresh is a no-op when no query has been made yet', () async {
      final repo = _SpyRepo();
      final cubit = RestaurantMapCubit(repo);

      await cubit.refresh();

      expect(repo.allCalls, 0,
          reason: 'refresh() must not hit the network before any query');
      expect(repo.filterCalls, 0);
    });

    test('(b) refresh re-invokes getAllRestaurants after a previous getAllRestaurants', () async {
      final repo = _SpyRepo();
      final cubit = RestaurantMapCubit(repo);

      await cubit.getAllRestaurants(0, 'island-tenerife');
      final callsBefore = repo.allCalls;

      await cubit.refresh();

      expect(repo.allCalls, greaterThan(callsBefore),
          reason: 'refresh() must re-invoke getAllRestaurants');
      expect(repo.allIslandIds.last, 'island-tenerife',
          reason: 'refresh() must use the last islandId');
      expect(repo.filterCalls, 0,
          reason: 'refresh() must NOT use the filter endpoint when last query was unfiltered');
    });

    test('(c) refresh re-invokes getFilterRestaurants after a previous filter query', () async {
      final repo = _SpyRepo();
      final cubit = RestaurantMapCubit(repo);

      await cubit.getFilterMapRestaurants(
        categories: ['cat-1'],
        municipalities: ['mun-1'],
        types: ['type-1'],
        text: 'pizza',
        islandId: 'island-gc',
        isOpen: true,
      );
      final filterCallsBefore = repo.filterCalls;

      await cubit.refresh();

      expect(repo.filterCalls, filterCallsBefore + 1,
          reason: 'refresh() must re-invoke getFilterRestaurants exactly once');
      expect(repo.filterIslandIds.last, 'island-gc',
          reason: 'refresh() must use the last islandId');
      expect(repo.allCalls, 0,
          reason: 'refresh() must NOT use the all-restaurants endpoint when last query was filtered');
    });
  });
}
