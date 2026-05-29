import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/data/cubit/new_home/visits_cubit.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/utils/dish_search_index.dart';

abstract class DishSearchState {}

class DishSearchIdle extends DishSearchState {}

class DishSearchReady extends DishSearchState {
  final Map<String, Set<String>> index;
  DishSearchReady(this.index);
}

class DishSearchEmpty extends DishSearchState {}

class DishSearchCubit extends Cubit<DishSearchState> {
  final VisitsCubit _visitsCubit;
  late final StreamSubscription<VisitsState> _sub;

  DishSearchCubit(this._visitsCubit) : super(DishSearchIdle()) {
    // If visits already loaded at construction time, compute immediately.
    final current = _visitsCubit.state;
    if (current is VisitsLoaded) {
      _computeIndex(current.visits);
    }
    _sub = _visitsCubit.stream.listen((state) {
      if (state is VisitsLoaded) {
        Future.microtask(() => _computeIndex(state.visits));
      }
    });
  }

  void _computeIndex(List<Visit> visits) {
    final idx = buildDishIndex(visits);
    // Diagnóstico — útil mientras se valida que el índice se construye
    // efectivamente con las visitas que el backend devuelve.
    final visitsWithDishes = visits.where((v) => v.dishes.isNotEmpty).length;
    AppLogger.info(
      'dish-search-cubit',
      'visits=${visits.length} with_dishes=$visitsWithDishes '
          'index_tokens=${idx.length}',
    );
    if (idx.isEmpty) {
      emit(DishSearchEmpty());
    } else {
      emit(DishSearchReady(idx));
    }
  }

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
