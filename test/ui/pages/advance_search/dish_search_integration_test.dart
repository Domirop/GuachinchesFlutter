import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/new_home/visits_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_state.dart';
import 'package:guachinches/data/cubit/search/dish_search_cubit.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/data/model/restaurant_response.dart';
import 'package:guachinches/ui/pages/advance_search/advanced_search.dart';

// ── Stubs ────────────────────────────────────────────────────────────────────

class _FakeRepo extends Fake implements RemoteRepository {
  @override
  Future<List<Restaurant>> getFilterRestaurants(
    String categorias,
    String municipalities,
    String types,
    String nombre,
    String islandId,
  ) async =>
      [];

  @override
  Future<RestaurantResponse> getAllRestaurants(int number,
          [String islandId = '']) async =>
      RestaurantResponse(restaurants: []);

  @override
  Future<List<Visit>> getAllVisits() async => [];
}

class _FakeRestaurantCubit extends RestaurantCubit {
  _FakeRestaurantCubit() : super(_FakeRepo());

  @override
  Future<void> getFilterRestaurantsAdvance({
    List<String>? categories,
    List<String>? municipalities,
    List<String>? types,
    String? text,
    String? islandId,
    bool isOpen = false,
  }) async {
    emit(const RestaurantFilterAdvanced([]));
  }
}

class _FakeVisitsCubit extends VisitsCubit {
  _FakeVisitsCubit() : super(_FakeRepo());

  void emitLoaded(List<Visit> visits) => emit(VisitsLoaded(visits));
}

// ── Test widget builder ───────────────────────────────────────────────────────

const _kRestaurantId = 'rest-efigenia';

Restaurant _makeRestaurant() => Restaurant(
      id: _kRestaurantId,
      nombre: 'Casa Efigenia',
      municipio: 'Valsequillo',
    );

Widget _wrap({
  required _FakeRestaurantCubit restaurantCubit,
  required _FakeVisitsCubit visitsCubit,
  required DishSearchCubit dishSearchCubit,
}) {
  return MaterialApp(
    theme: appDarkTheme,
    home: MultiBlocProvider(
      providers: [
        BlocProvider<RestaurantCubit>.value(value: restaurantCubit),
        BlocProvider<VisitsCubit>.value(value: visitsCubit),
        BlocProvider<DishSearchCubit>.value(value: dishSearchCubit),
      ],
      child: const AdvancedSearch(
        categories: [],
        municipalities: [],
        types: [],
        islandId: 'island-test',
      ),
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('AdvancedSearch — dish search integration', () {
    testWidgets(
        'dish chip appears and shows dish name after query with matching visit',
        (tester) async {
      final visitsCubit = _FakeVisitsCubit();
      final restaurantCubit = _FakeRestaurantCubit();

      // Emit visits before constructing DishSearchCubit so the index is
      // computed immediately in its constructor.
      visitsCubit.emitLoaded([
        Visit(
          id: 'v-1',
          restaurantId: _kRestaurantId,
          dishes: [VisitDish(name: 'Carne de cabra')],
          restaurant: _makeRestaurant(),
        ),
      ]);

      final dishSearchCubit = DishSearchCubit(visitsCubit);

      await tester.pumpWidget(_wrap(
        restaurantCubit: restaurantCubit,
        visitsCubit: visitsCubit,
        dishSearchCubit: dishSearchCubit,
      ));
      await tester.pump();

      // Type in the search field identified as 'advanced-search-input'.
      await tester.enterText(find.byType(TextField), 'carne cabra');

      // Advance past the 300ms debounce window.
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // (a) Dish chip Semantics identifier exists.
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.identifier ==
                  'advanced-search-dish-chip-$_kRestaurantId',
        ),
        findsOneWidget,
      );

      // (b) Visible text includes the dish name.
      expect(find.textContaining('Carne de cabra'), findsOneWidget);
    });
  });
}
