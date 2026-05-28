import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/visits/user_visits_state.dart';
import 'package:guachinches/data/local/http_cache_store.dart';
import 'package:guachinches/data/model/user_visit.dart';

class UserVisitsCubit extends Cubit<UserVisitsState> {
  final RemoteRepository _repository;
  final HttpCacheStore? _cache;

  UserVisitsCubit(this._repository, {HttpCacheStore? cache})
      : _cache = cache,
        super(const UserVisitsInitial());

  Future<void> load(String userId) async {
    emit(const UserVisitsLoading());

    List<UserVisit>? cachedVisits;

    if (_cache != null) {
      final cacheKey = 'visits:user:$userId';
      String? stale;
      try {
        stale = await _cache!.readStale(cacheKey);
      } catch (_) {}

      if (stale != null) {
        try {
          final decoded = json.decode(stale) as List<dynamic>;
          cachedVisits = decoded
              .whereType<Map<String, dynamic>>()
              .map(UserVisit.fromJson)
              .toList();
          if (cachedVisits.isEmpty) {
            emit(const UserVisitsEmpty());
          } else {
            emit(UserVisitsLoaded(cachedVisits));
          }
        } catch (_) {
          cachedVisits = null;
        }
      }
    }

    try {
      final visits = await _repository.getUserVisits(userId);
      if (_cache != null) {
        try {
          await _cache!.write(
            'visits:user:$userId',
            json.encode(visits.map((v) => v.toJson()).toList()),
          );
        } catch (_) {}
      }
      if (visits.isEmpty) {
        emit(const UserVisitsEmpty());
      } else {
        emit(UserVisitsLoaded(visits));
      }
    } catch (e) {
      if (cachedVisits != null) {
        AppLogger.warn('user-visits-cubit', 'Backend failed, keeping cached data: $e');
        // Stale state already emitted — do not emit error
      } else {
        AppLogger.warn('user-visits-cubit', 'Backend failed and no cache: $e');
        emit(UserVisitsError(e.toString()));
      }
    }
  }

  Future<void> refresh(String userId) async {
    emit(const UserVisitsLoading());
    try {
      final visits = await _repository.getUserVisits(userId);
      if (_cache != null) {
        try {
          await _cache!.write(
            'visits:user:$userId',
            json.encode(visits.map((v) => v.toJson()).toList()),
          );
        } catch (_) {}
      }
      if (visits.isEmpty) {
        emit(const UserVisitsEmpty());
      } else {
        emit(UserVisitsLoaded(visits));
      }
    } catch (e) {
      emit(UserVisitsError(e.toString()));
    }
  }
}
