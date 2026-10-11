import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:guachinches/data/cubit/location/location_cubit.dart';
import 'package:guachinches/data/cubit/location/location_state.dart';
import 'package:guachinches/data/local/local_repository.dart';
import 'package:guachinches/data/local/restaurant_sql_lite.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart';
import 'package:guachinches/ui/pages/visit/visit_dishes_screen.dart';
import 'package:guachinches/ui/theme/gm_favorites.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

// ── Dobles ──────────────────────────────────────────────────────────────────

class _MemRepo implements LocalRepository {
  final Set<String> ids;
  bool failWrites;
  _MemRepo(this.ids, {this.failWrites = false});

  @override
  Future<List<RestaurantSQLLite>> getRestaurants() async => [
        for (final id in ids)
          RestaurantSQLLite.fromMap({'id': 1, 'restaurantId': id}),
      ];

  @override
  Future<bool> insertRestaurant(String id) async {
    if (failWrites) return false;
    ids.add(id);
    return true;
  }

  @override
  Future<bool> removeRestaurant(String id) async {
    if (failWrites) return false;
    ids.remove(id);
    return true;
  }

  @override
  Future<bool> isFavorite(String id) async => ids.contains(id);

  @override
  Future<RestaurantSQLLite?> getRestaurant(String id) async => null;
}

class _FakeGeo extends GeolocatorPlatform {
  bool service;
  LocationPermission permission;
  _FakeGeo({this.service = true, this.permission = LocationPermission.denied});

  @override
  Future<bool> isLocationServiceEnabled() async => service;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async =>
      throw StateError('syncPermissionState no debe abrir el modal');

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) async =>
      Position(
        latitude: 28.4853,
        longitude: -16.3201,
        timestamp: DateTime(2026),
        accuracy: 10,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
}

void main() {
  group('GmFavorites', () {
    test('carga los guardados y alterna (optimista + persistente)', () async {
      final repo = _MemRepo({'a'});
      final favs = GmFavorites.withRepository(repo);
      await favs.ensureLoaded();
      expect(favs.isSaved('a'), isTrue);

      expect(await favs.toggle('b'), isTrue);
      expect(repo.ids, containsAll(['a', 'b']));
      expect(await favs.toggle('a'), isFalse);
      expect(repo.ids, isNot(contains('a')));
    });

    test('si la BD falla deshace el cambio', () async {
      final favs = GmFavorites.withRepository(_MemRepo({}, failWrites: true));
      await favs.ensureLoaded();
      expect(await favs.toggle('x'), isFalse);
      expect(favs.isSaved('x'), isFalse);
    });

    test('ensureLoaded(force) resincroniza con cambios hechos fuera', () async {
      final repo = _MemRepo({});
      final favs = GmFavorites.withRepository(repo);
      await favs.ensureLoaded();
      repo.ids.add('z'); // p. ej. desde la ficha o Favoritos
      await favs.ensureLoaded();
      expect(favs.isSaved('z'), isFalse, reason: 'sin force no recarga');
      await favs.ensureLoaded(force: true);
      expect(favs.isSaved('z'), isTrue);
    });
  });

  group('Distancias', () {
    final r = Restaurant(id: 'r', lat: 28.4853, lon: -16.3201);

    test('sin ubicación o sin coordenadas → null', () {
      expect(gmDistanceLabel(r, null, null), isNull);
      expect(gmDistanceLabel(Restaurant(id: 'x'), 28.4, -16.3), isNull);
    });

    test('distancia normal se formatea', () {
      expect(gmDistanceLabel(r, 28.4853, -16.4001), endsWith('km'));
    });

    test('más de 200 km se oculta', () {
      // Madrid ↔ La Laguna ≈ 1.750 km.
      expect(gmDistanceLabel(r, 40.4168, -3.7038), isNull);
    });
  });

  group('Antetítulo de «Cerca de ti»', () {
    test('todo a menos de 2 km', () {
      expect(gmNearbyEyebrow(['850 m', '1,2 km', '2,0 km']), 'A menos de 2 km');
    });

    test('radio real redondeado hacia arriba', () {
      expect(gmNearbyEyebrow(['850 m', '2,8 km']), 'A menos de 3 km');
    });

    test('sin distancias creíbles', () {
      expect(gmNearbyEyebrow(['1.834,2 km']), 'Lo más cerca de ti');
      expect(gmNearbyEyebrow([]), 'Lo más cerca de ti');
    });
  });

  group('Nombres', () {
    test('mayúsculas → tipo título, respetando lo mixto y las siglas', () {
      expect(gmDisplayName('BAR RESTAURANTE TERRAZA RAUL'),
          'Bar Restaurante Terraza Raul');
      expect(gmDisplayName('BODEGON LA TABONA (Casa Luis)'),
          'Bodegon la Tabona (Casa Luis)');
      expect(gmDisplayName('GUACHINCHE BBQ'), 'Guachinche BBQ');
      expect(gmDisplayName('Casa Ángela'), 'Casa Ángela');
    });
  });

  testWidgets('valoración 0 no pinta nada', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Row(children: [GmRating(0), GmRating(4.7)])),
    ));
    expect(find.text('4,7'), findsOneWidget);
    expect(find.text('0,0'), findsNothing);
    expect(find.textContaining('—'), findsNothing);
  });

  group('«Si vas, pide»', () {
    String plain(List<InlineSpan>? spans) =>
        spans!.map((s) => (s as TextSpan).text).join();

    test('sin destacados → no hay tarjeta', () {
      expect(
          VisitDishesScreen.recommendation(
              const [VisitDish(name: 'Papas'), VisitDish(name: 'Mojo')]),
          isNull);
    });

    test('primer destacado en negrita y el resto enumerado', () {
      final spans = VisitDishesScreen.recommendation(const [
        VisitDish(name: 'Tomates rellenos', isTop: true),
        VisitDish(name: 'Favada', isTop: true),
        VisitDish(name: 'Churritos de pescado', isTop: true),
        VisitDish(name: 'Pan'),
      ]);
      expect(plain(spans), 'Tomates rellenos, favada y churritos de pescado.');
      expect((spans!.first as TextSpan).style?.fontWeight, FontWeight.w700);
    });
  });

  group('LocationCubit.syncPermissionState (sin modal)', () {
    late GeolocatorPlatform original;
    setUp(() => original = GeolocatorPlatform.instance);
    tearDown(() => GeolocatorPlatform.instance = original);

    test('permiso concedido → LocationLoaded con la posición', () async {
      GeolocatorPlatform.instance =
          _FakeGeo(permission: LocationPermission.whileInUse);
      final cubit = LocationCubit();
      await cubit.syncPermissionState();
      expect(cubit.state, isA<LocationLoaded>());
      expect((cubit.state as LocationLoaded).latitude, 28.4853);
    });

    test('denegado → LocationDenied (sin pedir permiso)', () async {
      GeolocatorPlatform.instance = _FakeGeo();
      final cubit = LocationCubit();
      await cubit.syncPermissionState();
      expect(cubit.state.runtimeType, LocationDenied);
    });

    test('denegado para siempre → LocationPermanentlyDenied', () async {
      GeolocatorPlatform.instance =
          _FakeGeo(permission: LocationPermission.deniedForever);
      final cubit = LocationCubit();
      await cubit.syncPermissionState();
      expect(cubit.state, isA<LocationPermanentlyDenied>());
    });

    test('servicio apagado → LocationServiceDisabled', () async {
      GeolocatorPlatform.instance = _FakeGeo(service: false);
      final cubit = LocationCubit();
      await cubit.syncPermissionState();
      expect(cubit.state, isA<LocationServiceDisabled>());
    });
  });
}
