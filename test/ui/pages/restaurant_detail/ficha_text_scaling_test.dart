import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/location/location_cubit.dart';
import 'package:guachinches/data/cubit/location/location_state.dart';
import 'package:guachinches/data/model/Review.dart';
import 'package:guachinches/data/model/User.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/restaurant_detail/restaurant_detail_screen.dart';

Restaurant _restaurant() => Restaurant(
      id: 'd85d9fdb',
      nombre: 'GUACHINCHE CASA ANGELA',
      municipio: 'La Victoria de Acentejo',
      direccion:
          '📍Calle Pedro Hernández, 84, 38389 La Victoria de Acentejo, Santa Cruz de Tenerife',
      telefono: '922 58 07 49',
      avgRating: 5,
      valoraciones: [
        for (var i = 0; i < 4; i++)
          Review(
            id: '$i',
            rating: '5',
            title: 'Experiencia Guachinche Casa Angela',
            review: 'La comida es riquísima y el atendimiento fantástico.',
            usuario: User(nombre: 'Ana'),
          ),
      ],
    )..horariosJson = {
        'periods': [
          {
            'open': {'day': 0, 'time': '1200'},
            'close': {'day': 0, 'time': '1700'}
          },
        ],
        'weekday_text': [
          'lunes: Cerrado',
          'martes: Cerrado',
          'miércoles: 12:00–22:00',
          'jueves: 12:00–22:00',
          'viernes: 12:00–22:00',
          'sábado: 12:00–22:00',
          'domingo: 12:00–17:00',
        ],
      };

Visit _visit() => Visit(
      id: 'v1',
      restaurantId: 'd85d9fdb',
      videoPublishedAt: '2026-10-08T17:32:43.000Z',
      priceApprox: 36,
      overallSentiment: 'muy_positivo',
      services: const ['terraza', 'aparcamiento', 'acceso_pmr', 'reservas'],
      highlights: const ['Comida casera hecha en el propio local.'],
      lowlights: const ['Se llega por una subida empinada.'],
      quotes: const [VisitQuote(text: 'Pídanselo porque están superricos.')],
      dishes: const [
        VisitDish(name: 'Chuleta de palo con papas naturales', isTop: true),
        VisitDish(name: 'Favada'),
        VisitDish(name: 'Quesillo'),
      ],
    );

class _Repo implements RemoteRepository {
  @override
  Future<Restaurant> getRestaurantById(String id) async => _restaurant();

  @override
  Future<List<Visit>> getVisitsByRestaurant(String restaurantId) async =>
      [_visit()];

  @override
  Future<Visit> getVisitById(String id) async => _visit();

  @override
  dynamic noSuchMethod(Invocation i) => Future.value(null);
}

class _Loc extends LocationCubit {
  _Loc() {
    emit(LocationDenied());
  }
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  for (final scale in [1.0, 1.35, 2.0]) {
    testWidgets('la ficha no desborda con texto a ${scale}x', (tester) async {
      tester.view.physicalSize = const Size(1206, 2622);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        BlocProvider<LocationCubit>(
          create: (_) => _Loc(),
          child: MaterialApp(
            theme: appLightTheme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: RestaurantDetailScreen(id: 'd85d9fdb', repository: _Repo()),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull);
      expect(find.text('Guachinche Casa Angela'), findsOneWidget);

      // Recorre la ficha entera: ninguna sección debe desbordar.
      for (var i = 0; i < 12; i++) {
        await tester.drag(
            find.byType(CustomScrollView), const Offset(0, -600));
        await tester.pump(const Duration(milliseconds: 600));
        expect(tester.takeException(), isNull);
      }
    });
  }
}
