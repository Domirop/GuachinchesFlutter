import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:guachinches/core/connectivity/connectivity_state.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/data/cubit/favorites/favorites_remote_repository.dart';
import 'package:guachinches/data/cubit/favorites/favorites_state.dart';
import 'package:guachinches/data/local/favorites_local_store.dart';

class FavoritesCubit extends Cubit<FavoritesState> {
  final FavoritesRemoteRepository _remote;
  final FavoritesLocalStore _local;
  StreamSubscription<ConnectivityState>? _connectivitySub;
  String? _currentUserId;

  FavoritesCubit(
    this._remote,
    this._local, {
    Stream<ConnectivityState>? connectivityStream,
  }) : super(const FavoritesInitial()) {
    _connectivitySub = connectivityStream?.listen((state) {
      if (state is ConnectivityOnline && _currentUserId != null) {
        syncPending(_currentUserId!);
      }
    });
  }

  @override
  Future<void> close() {
    _connectivitySub?.cancel();
    return super.close();
  }

  Future<void> loadFavorites(String userId) async {
    _currentUserId = userId;
    emit(const FavoritesLoading());

    final localIds = await _local.getByUser(userId);
    emit(FavoritesLoaded(localIds, fromCache: true));

    try {
      final remoteIds = await _remote.getFavorites(userId);
      for (final id in remoteIds) {
        await _local.upsert(
          userId,
          id,
          ts: DateTime.now().millisecondsSinceEpoch,
          syncPending: 0,
        );
      }
      emit(FavoritesLoaded(remoteIds, fromCache: false));
    } catch (e) {
      if (localIds.isEmpty) {
        AppLogger.warn('favorites-cubit', 'loadFavorites: backend failed, no cache — $e');
        emit(FavoritesError(e.toString()));
      }
      // else: keep cached state already emitted
    }
  }

  Future<void> addFavorite(String userId, String restaurantId) async {
    _currentUserId = userId;
    final ts = DateTime.now().millisecondsSinceEpoch;

    await _local.upsert(userId, restaurantId, ts: ts, syncPending: 0);
    final localIds = await _local.getByUser(userId);
    emit(FavoritesLoaded(localIds, fromCache: true));

    try {
      await _remote.addFavorite(userId, restaurantId);
      // sync_pending already 0 — nothing more to do
    } catch (e) {
      await _local.upsert(userId, restaurantId, ts: ts, syncPending: 1);
      // No rollback of local state
    }
  }

  Future<void> removeFavorite(String userId, String restaurantId) async {
    _currentUserId = userId;

    await _local.delete(userId, restaurantId);
    final localIds = await _local.getByUser(userId);
    emit(FavoritesLoaded(localIds, fromCache: true));

    try {
      await _remote.removeFavorite(userId, restaurantId);
    } catch (e) {
      AppLogger.warn('favorites-cubit', 'removeFavorite backend failed for $restaurantId — $e');
    }
  }

  Future<void> syncPending(String userId) async {
    _currentUserId = userId;
    final pending = await _local.getPending(userId);
    for (final row in pending) {
      final restaurantId = row['restaurant_id'] as String;
      try {
        await _remote.addFavorite(userId, restaurantId);
        await _local.markSynced(userId, restaurantId);
      } catch (e) {
        AppLogger.warn('favorites-cubit', 'syncPending failed for $restaurantId — $e');
      }
    }
  }
}
