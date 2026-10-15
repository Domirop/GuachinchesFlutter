import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/theme/theme_cubit.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/data/cubit/user/user_state.dart';
import 'package:guachinches/data/local/local_repository.dart';
import 'package:guachinches/data/local/restaurant_sql_lite.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/data/model/user_info.dart';
import 'package:guachinches/l10n/app_localizations.dart';

/// Arnés compartido de los tests del grupo Perfil (no es un test).

/// Repositorio falso: perfil, fichas y newsletter en memoria.
class FakePerfilRepo extends Fake implements RemoteRepository {
  UserInfo? user;
  bool failUser;
  final Map<String, Restaurant> restaurants;
  bool failRestaurants;
  int userCalls = 0;

  FakePerfilRepo({
    this.user,
    this.failUser = false,
    Map<String, Restaurant>? restaurants,
    this.failRestaurants = false,
  }) : restaurants = restaurants ?? {};

  @override
  Future<UserInfo> getUserInfo(String userId) async {
    userCalls++;
    if (failUser || user == null) throw Exception('offline');
    return user!;
  }

  @override
  Future<Restaurant> getRestaurantById(String id) async {
    final r = restaurants[id];
    if (failRestaurants || r == null) throw Exception('offline');
    return r;
  }

  @override
  Future<bool> getNewsletterConsent(String userId) async => false;
}

/// Tabla `fav` en memoria con `Id` autoincremental (orden de guardado).
class OrderedFavRepo implements LocalRepository {
  final List<String> ids;
  int _next;
  final Map<String, int> _rowIds = {};

  OrderedFavRepo(List<String> oldestFirst)
      : ids = [...oldestFirst],
        _next = oldestFirst.length + 1 {
    for (var i = 0; i < ids.length; i++) {
      _rowIds[ids[i]] = i + 1;
    }
  }

  @override
  Future<List<RestaurantSQLLite>> getRestaurants() async => [
        for (final id in ids)
          RestaurantSQLLite.fromMap({'Id': _rowIds[id], 'restaurantId': id}),
      ];

  @override
  Future<RestaurantSQLLite?> getRestaurant(String restaurantId) async =>
      ids.contains(restaurantId)
          ? RestaurantSQLLite.fromMap(
              {'Id': _rowIds[restaurantId], 'restaurantId': restaurantId})
          : null;

  @override
  Future<bool> isFavorite(String restaurantId) async =>
      ids.contains(restaurantId);

  @override
  Future<bool> insertRestaurant(String restaurantId) async {
    ids.add(restaurantId);
    _rowIds[restaurantId] = _next++;
    return true;
  }

  @override
  Future<bool> removeRestaurant(String restaurantId) async {
    _rowIds.remove(restaurantId);
    return ids.remove(restaurantId);
  }
}

/// UserCubit con un estado inicial fijo.
class SeededUserCubit extends UserCubit {
  SeededUserCubit(super.repo, UserState seed) {
    emit(seed);
  }
}

/// App mínima con los cubits que usan las pantallas del Perfil.
Widget perfilApp(
  Widget home, {
  required UserCubit userCubit,
  ThemeCubit? themeCubit,
  ThemeMode mode = ThemeMode.light,
}) =>
    MultiBlocProvider(
      providers: [
        BlocProvider<UserCubit>.value(value: userCubit),
        BlocProvider<ThemeCubit>(create: (_) => themeCubit ?? ThemeCubit(mode)),
      ],
      child: MaterialApp(
        theme: appLightTheme,
        darkTheme: appDarkTheme,
        themeMode: mode,
        locale: const Locale('es'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: home,
      ),
    );

/// Pantalla alta para que quepa todo el Perfil.
void useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 4200);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Finder byIdentifier(String id) => find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.identifier == id,
    );
