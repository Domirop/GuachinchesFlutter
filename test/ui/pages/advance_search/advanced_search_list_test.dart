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
import 'package:guachinches/ui/pages/advance_search/widgets/mesa_brindis_scene.dart';
import 'package:guachinches/utils/contextual_pool.dart';

class _Repo extends Fake implements RemoteRepository {
  @override
  Future<List<Restaurant>> getFilterRestaurants(String c, String m, String t,
          String n, String i) async =>
      [];

  @override
  Future<RestaurantResponse> getAllRestaurants(int number,
          [String islandId = '']) async =>
      RestaurantResponse(restaurants: []);

  @override
  Future<List<Visit>> getAllVisits() async => [];
}

/// Cubit que responde lo que le digamos (lista o error).
class _Cubit extends RestaurantCubit {
  _Cubit(this.answer) : super(_Repo());
  RestaurantState Function() answer;
  int calls = 0;

  @override
  Future<void> getFilterRestaurantsAdvance({
    List<String>? categories,
    List<String>? municipalities,
    List<String>? types,
    String? text,
    String? islandId,
    bool isOpen = false,
  }) async {
    calls++;
    emit(answer());
  }
}

final _trad = Types(
    id: RestaurantTypeIds.guachinchesTradicionales,
    nombre: 'Guachinches Tradicionales');

Widget _app(_Cubit cubit, {bool reduceMotion = false}) {
  final visits = VisitsCubit(_Repo());
  return MaterialApp(
    theme: appLightTheme,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: child!,
    ),
    home: MultiBlocProvider(
      providers: [
        BlocProvider<RestaurantCubit>.value(value: cubit),
        BlocProvider<VisitsCubit>.value(value: visits),
        BlocProvider<DishSearchCubit>.value(value: DishSearchCubit(visits)),
      ],
      child: AdvancedSearch(
        categories: const [],
        municipalities: const [],
        types: [_trad],
        islandId: 'tf',
        islandLabel: 'Tenerife',
        preSelectedTypes: [_trad],
      ),
    ),
  );
}

void main() {
  setUp(() {});

  testWidgets(
      'Guachinches tradicionales: cabecera temática con la mesa con brindis '
      'que se anima y se para fuera de pantalla', (tester) async {
    tester.view.physicalSize = const Size(1206, 2622);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final cubit = _Cubit(() => RestaurantFilterAdvanced([
          for (var i = 0; i < 12; i++)
            Restaurant(id: 'r$i', nombre: 'Guachinche $i')
        ]));
    await tester.pumpWidget(_app(cubit));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Guachinches tradicionales'), findsWidgets);
    expect(find.text('Tipo · 12 en Tenerife'), findsOneWidget);
    expect(find.text('Vino de la casa y mantel de cuadros.'), findsOneWidget);
    final scene = tester.state<MesaBrindisSceneState>(
        find.byType(MesaBrindisScene));
    expect(scene.isStatic, isFalse);
    expect(scene.isTicking, isTrue);

    // En reposo (de 3,65 s a 8,75 s) el reloj se duerme: no repinta.
    await tester.pump(const Duration(seconds: 5));
    expect(scene.isTicking, isFalse);

    // Fuera de pantalla: parado del todo.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pump(const Duration(milliseconds: 100));
    expect(scene.isTicking, isFalse);
    await tester.pump(const Duration(seconds: 6));
    expect(scene.isTicking, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('movimiento reducido: fotograma final quieto, sin reloj',
      (tester) async {
    final cubit = _Cubit(() => const RestaurantFilterAdvanced([]));
    await tester.pumpWidget(_app(cubit, reduceMotion: true));
    await tester.pump(const Duration(milliseconds: 300));
    final scene = tester.state<MesaBrindisSceneState>(
        find.byType(MesaBrindisScene));
    expect(scene.isStatic, isTrue);
    expect(scene.isTicking, isFalse);
    await tester.pump(const Duration(seconds: 3));
    expect(scene.isTicking, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('error real con Reintentar (no «sin resultados»)',
      (tester) async {
    tester.view.physicalSize = const Size(1206, 2622);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final cubit =
        _Cubit(() => const RestaurantFilterAdvancedError('SocketException'));
    await tester.pumpWidget(_app(cubit, reduceMotion: true));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('No pudimos cargar los resultados'), findsOneWidget);
    final before = cubit.calls;
    cubit.answer = () => const RestaurantFilterAdvanced([]);
    await tester.tap(find.text('Reintentar'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(cubit.calls, before + 1);
    expect(find.text('No pudimos cargar los resultados'), findsNothing);
    // Vacío temático con su línea.
    expect(find.textContaining('Ningún guachinche'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cargando: esqueleto sin errores de layout', (tester) async {
    tester.view.physicalSize = const Size(1206, 2622);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final cubit = _Cubit(() => RestaurantLoading());
    await tester.pumpWidget(_app(cubit, reduceMotion: true));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.bySemanticsIdentifier('advanced-search-loading'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
