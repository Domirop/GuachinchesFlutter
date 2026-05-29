import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/cubit/favorites/favorites_cubit.dart';
import 'package:guachinches/data/cubit/favorites/favorites_remote_repository.dart';
import 'package:guachinches/data/cubit/favorites/favorites_state.dart';
import 'package:guachinches/data/local/favorites_local_store.dart';

class _FakeRemote extends Fake implements FavoritesRemoteRepository {
  final List<String> favoritesToReturn;
  final bool shouldFail;
  final List<String> addedFavorites = [];
  final List<String> markedSynced = [];

  _FakeRemote({this.favoritesToReturn = const [], this.shouldFail = false});

  @override
  Future<List<String>> getFavorites(String userId) async {
    if (shouldFail) throw Exception('network error');
    return favoritesToReturn;
  }

  @override
  Future<void> addFavorite(String userId, String restaurantId) async {
    if (shouldFail) throw Exception('network error');
    addedFavorites.add(restaurantId);
  }

  @override
  Future<void> removeFavorite(String userId, String restaurantId) async {
    if (shouldFail) throw Exception('network error');
  }
}

FavoritesCubit _cubit(
  FavoritesRemoteRepository remote,
  FavoritesLocalStore local,
) =>
    FavoritesCubit(remote, local);

void main() {
  const userId = 'user-1';
  const restaurantId = 'resto-abc';

  group('FavoritesCubit', () {
    test('(a) loadFavorites con local hits emite FavoritesLoaded(fromCache:true) primero',
        () async {
      final local = InMemoryFavoritesLocalStore();
      await local.upsert(userId, restaurantId,
          ts: 1000, syncPending: 0);

      final remote = _FakeRemote(favoritesToReturn: [restaurantId]);
      final cubit = _cubit(remote, local);

      final states = <FavoritesState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.loadFavorites(userId);

      await sub.cancel();
      await cubit.close();

      // First emitted state (after Loading) must be fromCache:true
      final loadedStates = states.whereType<FavoritesLoaded>().toList();
      expect(loadedStates.isNotEmpty, isTrue);
      expect(loadedStates.first.fromCache, isTrue);
      expect(loadedStates.first.restaurantIds, contains(restaurantId));
    });

    test('(b) addFavorite con backend OK persiste local con sync_pending=0',
        () async {
      final local = InMemoryFavoritesLocalStore();
      final remote = _FakeRemote();
      final cubit = _cubit(remote, local);

      await cubit.addFavorite(userId, restaurantId);
      await cubit.close();

      final pending = await local.getPending(userId);
      expect(pending, isEmpty);

      final ids = await local.getByUser(userId);
      expect(ids, contains(restaurantId));
    });

    test('(c) addFavorite con backend KO persiste local con sync_pending=1 y no hace rollback',
        () async {
      final local = InMemoryFavoritesLocalStore();
      final remote = _FakeRemote(shouldFail: true);
      final cubit = _cubit(remote, local);

      final states = <FavoritesState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.addFavorite(userId, restaurantId);

      await sub.cancel();
      await cubit.close();

      // Local still has the item (no rollback)
      final ids = await local.getByUser(userId);
      expect(ids, contains(restaurantId));

      // sync_pending=1
      final pending = await local.getPending(userId);
      expect(pending.length, 1);
      expect(pending.first['restaurant_id'], restaurantId);

      // State still shows the item (no rollback in emitted state)
      final loadedState = states.whereType<FavoritesLoaded>().last;
      expect(loadedState.restaurantIds, contains(restaurantId));
    });

    test('(d) syncPending itera filas pendientes y las marca sincronizadas',
        () async {
      final local = InMemoryFavoritesLocalStore();
      await local.upsert(userId, restaurantId, ts: 1000, syncPending: 1);

      final remote = _FakeRemote(favoritesToReturn: []);
      final cubit = _cubit(remote, local);

      await cubit.syncPending(userId);
      await cubit.close();

      expect(remote.addedFavorites, contains(restaurantId));

      final pending = await local.getPending(userId);
      expect(pending, isEmpty);
    });
  });
}
