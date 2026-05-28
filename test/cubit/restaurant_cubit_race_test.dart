import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_state.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/data/model/restaurant_response.dart';

/// Fake repository that serves futures from a queue, so each call to
/// getFilterRestaurants returns the next scheduled future.
class _FakeRemoteRepo extends Fake implements RemoteRepository {
  final _queue = <Future<List<Restaurant>>>[];

  void enqueue(Future<List<Restaurant>> f) => _queue.add(f);

  @override
  Future<List<Restaurant>> getFilterRestaurants(
    String categorias,
    String municipalities,
    String types,
    String nombre,
    String islandId,
  ) {
    return _queue.removeAt(0);
  }

  @override
  Future<RestaurantResponse> getAllRestaurants(int number,
      [String islandId = '']) async {
    return RestaurantResponse(restaurants: []);
  }
}

Restaurant _r(String id, {bool open = true}) => Restaurant(id: id, open: open);

void main() {
  group('RestaurantCubit sequence guard', () {
    test(
        'three rapid calls — only the last RestaurantFilterAdvanced emitted contains the last request result',
        () async {
      final repo = _FakeRemoteRepo();
      final cubit = RestaurantCubit(repo);

      final completerA = Completer<List<Restaurant>>();
      final completerAb = Completer<List<Restaurant>>();
      final completerAbc = Completer<List<Restaurant>>();

      // Enqueue futures: 'a' resolves last (300ms), 'ab' first (50ms), 'abc' second (100ms)
      repo.enqueue(completerA.future);
      repo.enqueue(completerAb.future);
      repo.enqueue(completerAbc.future);

      final emittedFilter = <RestaurantFilterAdvanced>[];
      final sub = cubit.stream.listen((s) {
        if (s is RestaurantFilterAdvanced) emittedFilter.add(s);
      });

      // Fire all three without awaiting — each increments _requestSeq
      final fa = cubit.getFilterRestaurantsAdvance(
          categories: [], municipalities: [], types: [], text: 'a', islandId: 'id');
      final fab = cubit.getFilterRestaurantsAdvance(
          categories: [], municipalities: [], types: [], text: 'ab', islandId: 'id');
      final fabc = cubit.getFilterRestaurantsAdvance(
          categories: [], municipalities: [], types: [], text: 'abc', islandId: 'id');

      // Resolve in order: ab (fast) → abc → a (slowest)
      completerAb.complete([_r('ab-result')]);
      await Future.delayed(const Duration(milliseconds: 50));

      completerAbc.complete([_r('abc-result')]);
      await Future.delayed(const Duration(milliseconds: 100));

      completerA.complete([_r('a-result')]);
      await Future.delayed(const Duration(milliseconds: 300));

      await Future.wait([fa, fab, fabc]);
      await sub.cancel();

      // Only one RestaurantFilterAdvanced should have been emitted
      expect(emittedFilter.length, 1,
          reason: 'stale responses for "a" and "ab" must be discarded');
      expect(
        emittedFilter.first.restaurantFilterAdvanced.first.id,
        'abc-result',
        reason: 'the emitted state must contain the result for the last request',
      );
    });

    test('isOpen=true: final state contains only open restaurants', () async {
      final repo = _FakeRemoteRepo();
      final cubit = RestaurantCubit(repo);

      repo.enqueue(Future.value([
        _r('open-1', open: true),
        _r('closed-1', open: false),
        _r('open-2', open: true),
      ]));

      await cubit.getFilterRestaurantsAdvance(
        categories: [],
        municipalities: [],
        types: [],
        text: '',
        islandId: 'id',
        isOpen: true,
      );

      final state = cubit.state as RestaurantFilterAdvanced;
      expect(state.restaurantFilterAdvanced.length, 2);
      expect(state.restaurantFilterAdvanced.every((r) => r.open), isTrue);
    });
  });
}
