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

/// Minimal fake repository — only the methods exercised by the cubits under test.
class _FakeRemoteRepo extends Fake implements RemoteRepository {
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

/// Fake cubit that counts calls to getFilterRestaurantsAdvance.
class _FakeRestaurantCubit extends RestaurantCubit {
  final List<Map<String, dynamic>> calls = [];

  _FakeRestaurantCubit() : super(_FakeRemoteRepo());

  @override
  Future<void> getFilterRestaurantsAdvance({
    List<String>? categories,
    List<String>? municipalities,
    List<String>? types,
    String? text,
    String? islandId,
    bool isOpen = false,
  }) async {
    calls.add({'text': text, 'categories': categories, 'types': types});
    emit(RestaurantFilterAdvanced([]));
  }
}

Widget _wrap(_FakeRestaurantCubit cubit) {
  final visitsCubit = VisitsCubit(_FakeRemoteRepo());
  final dishSearchCubit = DishSearchCubit(visitsCubit);
  return MaterialApp(
    theme: appDarkTheme,
    home: MultiBlocProvider(
      providers: [
        BlocProvider<RestaurantCubit>.value(value: cubit),
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

void main() {
  group('AdvancedSearch debounce behaviour', () {
    testWidgets(
        'enterText triggers exactly one call after 350ms (debounce window)',
        (tester) async {
      final cubit = _FakeRestaurantCubit();
      await tester.pumpWidget(_wrap(cubit));
      await tester.pump();

      // No calls before any interaction
      expect(cubit.calls, isEmpty);

      // Type 'guachinches' — onChanged fires once, debouncer starts 300ms timer
      await tester.enterText(find.byType(TextField), 'guachinches');

      // Before the debounce window closes: no call yet
      expect(cubit.calls, isEmpty);

      // Advance past the 300ms debounce window
      await tester.pump(const Duration(milliseconds: 350));

      expect(cubit.calls.length, 1);
      expect(cubit.calls.first['text'], 'guachinches');
    });

    testWidgets('Enter key submits immediately without waiting for debounce',
        (tester) async {
      final cubit = _FakeRestaurantCubit();
      await tester.pumpWidget(_wrap(cubit));
      await tester.pump();

      // Type 'guach' — starts a 300ms debounce timer
      await tester.enterText(find.byType(TextField), 'guach');

      // Simulate pressing the search/Enter key — this should cancel the timer
      // and fire _runSearch() immediately
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      // At least one call must be registered without waiting 300ms
      expect(cubit.calls.length, greaterThanOrEqualTo(1));
    });
  });
}
