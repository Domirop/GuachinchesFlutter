import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/new_home/visits_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_state.dart';
import 'package:guachinches/data/cubit/search/dish_search_cubit.dart';
import 'package:guachinches/data/model/Types.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/data/model/restaurant_response.dart';
import 'package:guachinches/ui/pages/advance_search/advanced_search.dart';
import 'package:guachinches/ui/pages/advance_search/list_theme.dart';
import 'package:guachinches/ui/pages/advance_search/widgets/barraquito_scene.dart';
import 'package:guachinches/ui/pages/advance_search/widgets/mesa_brindis_scene.dart';
import 'package:guachinches/utils/contextual_pool.dart';

class _Repo extends Fake implements RemoteRepository {
  @override
  Future<RestaurantResponse> getAllRestaurants(int number,
          [String islandId = '']) async =>
      RestaurantResponse(restaurants: []);
  @override
  Future<List<Visit>> getAllVisits() async => [];
}

class _Cubit extends RestaurantCubit {
  _Cubit() : super(_Repo());
  @override
  Future<void> getFilterRestaurantsAdvance({
    List<String>? categories,
    List<String>? municipalities,
    List<String>? types,
    String? text,
    String? islandId,
    bool isOpen = false,
  }) async {
    emit(RestaurantFilterAdvanced([
      for (var i = 0; i < 12; i++) Restaurant(id: 'c$i', nombre: 'Cafetería $i')
    ]));
  }
}

Widget _scene({bool active = true, bool reduce = false}) => MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
        child: child!,
      ),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: BarraquitoScene(
            active: active,
            band: const Color(0xFFF3E6D6),
            ink: const Color(0xFF8A5A3A),
            dark: false,
          ),
        ),
      ),
    );

void main() {
  test('la escena de cada tema', () {
    expect(headerSceneFor(ListThemeKind.desayuno), HeaderSceneKind.barraquito);
    expect(headerSceneFor(ListThemeKind.bar), HeaderSceneKind.barraquito);
    expect(headerSceneFor(ListThemeKind.tradicional),
        HeaderSceneKind.mesaBrindis);
    expect(headerSceneFor(ListThemeKind.tasca), isNull);
  });

  test('reposo: duerme tras el montaje y se despierta para la despedida', () {
    expect(barraquitoQuietRemaining(1.0), 0); // entra el plato
    expect(barraquitoQuietRemaining(3.0), 0); // se monta el vaso
    expect(barraquitoQuietRemaining(6.0), closeTo(2.8, 1e-9));
    expect(barraquitoQuietRemaining(9.6), closeTo(0.83, 1e-9));
  });

  test('al despertar en el borde de un tramo no se vuelve a dormir', () {
    // 9,6 + 0,83 = 10,43 da 0,4299999… al dividir entre 10.
    final wake = 9.6 + barraquitoQuietRemaining(9.6);
    expect(barraquitoQuietRemaining(wake), 0);
    final mesaWake = 9.9 + mesaQuietRemaining(9.9);
    expect(mesaQuietRemaining(mesaWake), 0);
  });

  testWidgets('después del reposo vuelve a montar el vaso', (tester) async {
    await tester.pumpWidget(_scene());
    await tester.pump(const Duration(milliseconds: 16));
    final s = tester.state<BarraquitoSceneState>(find.byType(BarraquitoScene));
    // Hasta el reposo de después de la despedida (9,45 s)…
    for (var i = 0; i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    // …y pasado el inicio del siguiente bucle (10,43 s) vuelve a correr.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 16));
    expect(s.isTicking, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('se pinta y anima; duerme en el reposo', (tester) async {
    await tester.pumpWidget(_scene());
    await tester.pump(const Duration(milliseconds: 16));
    final s = tester.state<BarraquitoSceneState>(find.byType(BarraquitoScene));
    expect(s.isStatic, isFalse);
    expect(s.isTicking, isTrue);
    expect(find.byType(CustomPaint), findsWidgets);
    // Reposo de 5,6 s a 8,8 s: sin ticker.
    await tester.pump(const Duration(seconds: 6));
    expect(s.isTicking, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('movimiento reducido: fotograma final sin reloj', (tester) async {
    await tester.pumpWidget(_scene(reduce: true));
    await tester.pump(const Duration(milliseconds: 16));
    final s = tester.state<BarraquitoSceneState>(find.byType(BarraquitoScene));
    expect(s.isStatic, isTrue);
    expect(s.isTicking, isFalse);
    await tester.pump(const Duration(seconds: 2));
    expect(s.isTicking, isFalse);
  });

  testWidgets('fuera de pantalla no corre', (tester) async {
    await tester.pumpWidget(_scene(active: false));
    await tester.pump(const Duration(milliseconds: 16));
    final s = tester.state<BarraquitoSceneState>(find.byType(BarraquitoScene));
    expect(s.isTicking, isFalse);
    await tester.pumpWidget(_scene(active: true));
    await tester.pump(const Duration(milliseconds: 16));
    expect(s.isTicking, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'Bar/Cafetería lleva el barraquito y se para al salir de la pantalla',
      (tester) async {
    tester.view.physicalSize = const Size(1206, 2622);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final bar =
        Types(id: RestaurantTypeIds.barCafeteria, nombre: 'Bar/Cafeteria');
    final visits = VisitsCubit(_Repo());
    await tester.pumpWidget(MaterialApp(
      theme: appLightTheme,
      home: MultiBlocProvider(
        providers: [
          BlocProvider<RestaurantCubit>(create: (_) => _Cubit()),
          BlocProvider<VisitsCubit>.value(value: visits),
          BlocProvider<DishSearchCubit>.value(value: DishSearchCubit(visits)),
        ],
        child: AdvancedSearch(
          categories: const [],
          municipalities: const [],
          types: [bar],
          islandId: 'tf',
          preSelectedTypes: [bar],
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(BarraquitoScene), findsOneWidget);
    expect(find.byType(MesaBrindisScene), findsNothing);
    expect(find.text('Bar/Cafetería'), findsWidgets);
    final s = tester.state<BarraquitoSceneState>(find.byType(BarraquitoScene));
    expect(s.isTicking, isTrue);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pump(const Duration(milliseconds: 100));
    expect(s.isTicking, isFalse);
    await tester.pump(const Duration(seconds: 3));
    expect(s.isTicking, isFalse);
    expect(tester.takeException(), isNull);
  });
}
