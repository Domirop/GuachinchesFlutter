import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/location/location_cubit.dart';
import 'package:guachinches/data/cubit/location/location_state.dart';
import 'package:guachinches/data/cubit/new_home/new_home_filters_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_state.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/data/model/restaurant_response.dart';
import 'package:guachinches/l10n/app_localizations.dart';
import 'package:guachinches/ui/components/cards/nearby_restaurant_card.dart';
import 'package:guachinches/ui/pages/cerca_abiertos/cerca_ahora_screen.dart';

// ── Fake helpers ──────────────────────────────────────────────────────────────

class _FakeRepo extends Fake implements RemoteRepository {
  @override
  Future<RestaurantResponse> getAllRestaurants(
    int number, [
    String islandId = '',
  ]) async =>
      RestaurantResponse(restaurants: []);
}

class _FakeLocationCubit extends LocationCubit {
  _FakeLocationCubit(LocationState initial) : super() {
    // ignore: invalid_use_of_protected_member
    emit(initial);
  }

  @override
  Future<void> requestLocation() async {}

  @override
  Future<void> checkLocationSilently() async {}
}

class _SpyRestaurantCubit extends RestaurantCubit {
  final List<Restaurant> _restaurants;
  int getFilterRestaurantsCalls = 0;

  _SpyRestaurantCubit(this._restaurants) : super(_FakeRepo());

  @override
  Future<void> getFilterRestaurants({
    List<String>? categories,
    List<String>? municipalities,
    List<String>? types,
    String? text,
    String? islandId,
    bool isOpen = false,
  }) async {
    getFilterRestaurantsCalls++;
    emit(RestaurantFilter(_restaurants));
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Finder _findBySemanticsId(String id) => find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.identifier == id,
    );

Widget _wrap({
  required LocationState locationState,
  required RestaurantCubit restaurantCubit,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<LocationCubit>.value(
        value: _FakeLocationCubit(locationState),
      ),
      BlocProvider<RestaurantCubit>.value(value: restaurantCubit),
      BlocProvider<NewHomeFiltersCubit>.value(value: NewHomeFiltersCubit()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: const CercaAhoraScreen(),
    ),
  );
}

Restaurant _restaurant({
  required String id,
  double lat = 0.0,
  double lon = 0.0,
}) =>
    Restaurant(id: id, lat: lat, lon: lon, open: true);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('CercaAhoraScreen', () {
    testWidgets(
      '(a) LocationDenied shows cerca-ahora-location-required and activate-button',
      (tester) async {
        final spy = _SpyRestaurantCubit([]);

        await tester.pumpWidget(
          _wrap(locationState: LocationDenied(), restaurantCubit: spy),
        );
        await tester.pump(); // let addPostFrameCallback fire

        expect(_findBySemanticsId('cerca-ahora-location-required'), findsOneWidget);
        expect(
          _findBySemanticsId('cerca-ahora-activate-location-button'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '(b) LocationLoaded + 2 restaurants in radius shows cerca-ahora-list with 2 items',
      (tester) async {
        // Use a tall viewport so both cards are visible
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // Restaurants at user location (0,0) → within default 5km radius
        final spy = _SpyRestaurantCubit([
          _restaurant(id: 'r1', lat: 0.0, lon: 0.0),
          _restaurant(id: 'r2', lat: 0.001, lon: 0.001),
        ]);

        await tester.pumpWidget(
          _wrap(
            locationState: LocationLoaded(latitude: 0, longitude: 0),
            restaurantCubit: spy,
          ),
        );
        await tester.pumpAndSettle();

        expect(_findBySemanticsId('cerca-ahora-list'), findsOneWidget);
        expect(find.byType(NearbyRestaurantCard), findsNWidgets(2));
      },
    );

    testWidgets(
      '(c) Backend returns empty list shows cerca-ahora-empty with Nada abierto cerca ahora',
      (tester) async {
        final spy = _SpyRestaurantCubit([]);

        await tester.pumpWidget(
          _wrap(
            locationState: LocationLoaded(latitude: 0, longitude: 0),
            restaurantCubit: spy,
          ),
        );
        await tester.pumpAndSettle();

        expect(_findBySemanticsId('cerca-ahora-empty'), findsOneWidget);
        expect(find.textContaining('Nada abierto cerca ahora'), findsOneWidget);
      },
    );

    testWidgets(
      '(d) Backend has results but none in radius shows cerca-ahora-empty with Aumentar radio; tap duplicates radius without re-calling backend',
      (tester) async {
        // Restaurant at lat=90 (North Pole) → ~10,000 km from user at (0,0)
        final spy = _SpyRestaurantCubit([
          _restaurant(id: 'far', lat: 90.0, lon: 0.0),
        ]);

        await tester.pumpWidget(
          _wrap(
            locationState: LocationLoaded(latitude: 0, longitude: 0),
            restaurantCubit: spy,
          ),
        );
        await tester.pumpAndSettle();

        // Empty state with Aumentar radio shown
        expect(_findBySemanticsId('cerca-ahora-empty'), findsOneWidget);
        expect(find.textContaining('Aumentar radio'), findsOneWidget);

        // Initial backend call count
        final callsBefore = spy.getFilterRestaurantsCalls;

        // Tap the Aumentar radio button
        await tester.tap(find.text('Aumentar radio'));
        await tester.pump();

        // Still shows empty state (restaurant still out of range even at 10km)
        expect(_findBySemanticsId('cerca-ahora-empty'), findsOneWidget);

        // Backend was NOT called again
        expect(
          spy.getFilterRestaurantsCalls,
          callsBefore,
          reason: 'Aumentar radio must not trigger a backend re-fetch',
        );
      },
    );
  });
}
