import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/new_home/visits_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_cubit.dart';
import 'package:guachinches/data/cubit/search/dish_search_cubit.dart';
import 'package:guachinches/data/model/Category.dart';
import 'package:guachinches/data/model/CategoryRestaurant.dart';
import 'package:guachinches/data/model/Types.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/data/model/restaurant_response.dart';
import 'package:guachinches/ui/pages/advance_search/advanced_search.dart';
import 'package:guachinches/utils/contextual_pool.dart';

class _Repo extends Fake implements RemoteRepository {
  @override
  Future<List<Restaurant>> getFilterRestaurants(
          String c, String m, String t, String n, String i) async =>
      [];
  @override
  Future<List<Restaurant>> getFilterRestaurantsChecked(
          String c, String m, String t, String n, String i) async =>
      // El servidor trae de más (sitios que la home no tiene): no deben
      // cambiar el recuento de la lista abierta desde «Hoy».
      [for (var i = 0; i < 9; i++) Restaurant(id: 'srv$i', open: true)];
  @override
  Future<RestaurantResponse> getAllRestaurants(int number,
          [String islandId = '']) async =>
      RestaurantResponse(restaurants: []);
  @override
  Future<List<Visit>> getAllVisits() async => [];
}

Map<String, dynamic> _always() => {
      'periods': [
        for (var d = 0; d <= 6; d++)
          {
            'open': {'day': d, 'time': '0000'},
            'close': {'day': (d + 1) % 7, 'time': '0000'},
          }
      ]
    };

Restaurant _r(String id, String type,
    {bool hours = false, bool open = false, List<String> cats = const []}) {
  final r = Restaurant(
    id: id,
    nombre: 'Sitio $id',
    open: open,
    categoriaRestaurantes: [
      for (final c in cats)
        CategoryRestaurant(
            id: c,
            categoriasRestauranteId: id,
            categoriaId: c,
            categorias:
                ModelCategory(id: c, nombre: c, iconUrl: '', foto: '')),
    ],
  )..type = type;
  if (hours) r.horariosJson = _always();
  return r;
}

void main() {
  testWidgets(
      'el mismo pool da el mismo número de abiertos en «Hoy» y en la lista',
      (tester) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(1206, 2622);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final hour = DateTime.now().hour;
    final cfg = contextualFilterFor(hour);
    final type = cfg.typeIds.isNotEmpty
        ? cfg.typeIds.first
        : RestaurantTypeIds.restaurantes;
    final cats = cfg.categoryIds.isNotEmpty ? [cfg.categoryIds.first] : <String>[];
    final pool = [
      _r('h1', type, hours: true, cats: cats), // abierto por horario
      _r('h2', type, hours: true, cats: cats),
      _r('f1', type, open: true, cats: cats), // sin horario, backend: abierto
      _r('c1', type, cats: cats), // sin horario ni open: sin confirmar
      _r('x1', 'otro-tipo', hours: true, cats: const ['otra']), // fuera
    ];
    final home = contextualOpenNow(pool, cfg, DateTime.now()).length;

    final visits = VisitsCubit(_Repo());
    await tester.pumpWidget(MaterialApp(
      theme: appLightTheme,
      home: MultiBlocProvider(
        providers: [
          BlocProvider<RestaurantCubit>(create: (_) => RestaurantCubit(_Repo())),
          BlocProvider<VisitsCubit>.value(value: visits),
          BlocProvider<DishSearchCubit>.value(value: DishSearchCubit(visits)),
        ],
        child: AdvancedSearch(
          categories: [
            for (final c in cfg.categoryIds)
              ModelCategory(id: c, nombre: c, iconUrl: '', foto: '')
          ],
          municipalities: const [],
          types: [
            for (final t in cfg.typeIds) Types(id: t, nombre: t),
          ],
          islandId: 'tf',
          pool: pool,
          fromToday: true,
          preSelectedTypes: [
            for (final t in cfg.typeIds) Types(id: t, nombre: t),
          ],
          preSelectedCategories: [
            for (final c in cfg.categoryIds)
              ModelCategory(id: c, nombre: c, iconUrl: '', foto: '')
          ],
          preSelectedOpenOnly: true,
        ),
      ),
    ));
    await tester.pump(const Duration(seconds: 1));

    expect(home, cfg.isEmpty ? 4 : 3);
    // El preset de la franja es UN chip y cuenta 1 en «Filtros».
    expect(find.bySemanticsLabel('Filtros, 1 activos'), findsOneWidget);
    expect(find.textContaining('$home abiertos ahora'), findsWidgets);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
