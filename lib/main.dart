import 'dart:ui';
import 'package:app_links/app_links.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:guachinches/l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/core/connectivity/connectivity_cubit.dart';
import 'package:guachinches/data/cubit/banners/banners_cubit.dart';
import 'package:guachinches/data/cubit/cupones/cupones_cubit.dart';
import 'package:guachinches/data/cubit/favorites/favorites_cubit.dart';
import 'package:guachinches/data/cubit/favorites/http_favorites_repository.dart';
import 'package:guachinches/data/cubit/filter/filter_cubit.dart';
import 'package:guachinches/data/cubit/filter/filter_map_cubit.dart';
import 'package:guachinches/data/cubit/location/location_cubit.dart';
import 'package:guachinches/data/cubit/menu/menu_cubit.dart';
import 'package:guachinches/data/cubit/new_home/curated_lists_cubit.dart';
import 'package:guachinches/data/cubit/new_home/islands_cubit.dart';
import 'package:guachinches/data/cubit/new_home/new_home_filters_cubit.dart';
import 'package:guachinches/data/cubit/new_home/weather_cubit.dart';
import 'package:guachinches/data/cubit/new_home/visits_cubit.dart';
import 'package:guachinches/data/cubit/search/dish_search_cubit.dart';
import 'package:guachinches/data/cubit/onboarding/onboarding_cubit.dart';
import 'package:guachinches/data/cubit/visits/user_visits_cubit.dart';
import 'package:guachinches/data/cubit/new_home/zone_weather_cubit.dart';
import 'package:guachinches/data/cubit/new_home/zones_cubit.dart';
import 'package:guachinches/data/cubit/theme/theme_cubit.dart';
import 'package:guachinches/data/local/favorites_local_store.dart';
import 'package:guachinches/data/local/http_cache_store.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/data/cubit/restaurants/map/restaurant_map_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/top/top_restaurants_cubit.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/core/remote_config/dcc_remote_config.dart';
import 'package:guachinches/data/local/db_provider.dart';
import 'package:guachinches/services/http_weather_service.dart';
import 'package:guachinches/ui/pages/maintenance/maintenance_screen.dart';
import 'package:http/http.dart';
import 'data/cubit/restaurants/basic/restaurant_cubit.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'ui/pages/splash_screen/splash_screen.dart';


const bool _kReleaseMode = const bool.fromEnvironment("dart.vm.product");

/// Feature flag: ENABLE_NEW_HOME=true en debug.env activa NewHomeTabScaffold.
bool get enableNewHome =>
    (dotenv.env['ENABLE_NEW_HOME'] ?? 'false').toLowerCase() == 'true';

Future<void> main() async{
  String file = _kReleaseMode == true ? 'env_files/release.env' : 'env_files/debug.env';
  await dotenv.load(fileName: file);
  await Firebase.initializeApp();
  await DccRemoteConfig.instance.init();
  FlutterError.onError = (details) {
    if (kDebugMode) {
      FlutterError.presentError(details);
    } else {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    }
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
    return true;
  };
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
  debugPaintBaselinesEnabled = false; // asegúrate de no activarlo
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializar SDK de AdMob
  await MobileAds.instance.initialize();
  final initialThemeMode = await ThemeCubit.hydrate();

  runApp(MyApp(initialThemeMode: initialThemeMode));
}

class MyApp extends StatefulWidget {
  final ThemeMode initialThemeMode;

  const MyApp({Key? key, this.initialThemeMode = ThemeMode.light})
      : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _appLinks = AppLinks();
  final storage = new FlutterSecureStorage();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    DBProvider.db.initDB();
    // _initDeepLinks();
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  }
  // void _initDeepLinks() async {
  //   // Link cuando la app arranca desde cerrado
  //   final initialLink = await _appLinks.getInitialAppLink();
  //   if (initialLink != null) {
  //     _handleLink(initialLink);
  //   }
  //
  //   // Link cuando la app ya está abierta
  //   // _appLinks.uriLinkStream.listen((uri) {
  //   //   _handleLink(uri);
  //   // });
  // }
  // Future<String> generateDeviceBasedUuid() async {
  //
  //   // En caso de que no se pueda obtener (muy raro), usa fallback
  //   final input = deviceId ?? Uuid().v4();
  //
  //   // Genera UUID v5 basado en el ID del dispositivo
  //   final uuid = Uuid().v5(Uuid.NAMESPACE_URL, input);
  //
  //   return uuid;
  // }
  // void _handleLink(Uri uri) async {
  //   if (uri.path == '/encuesta/premios') {
  //     await Future.delayed(Duration(seconds: 2));
  //     String? surveyUserId = await storage.read(key: "surveyUserId");
  //
  //     if (surveyUserId == null || surveyUserId == '69a54c41-5ae3-5445-bea3-4e16ec8092fa') {
  //       String? userId = await storage.read(key: "userId");
  //
  //       if (userId != null) {
  //         await storage.write(key: "surveyUserId", value: userId);
  //       } else {
  //         try {
  //           final deviceId = await PlatformDeviceId.getDeviceId;
  //
  //           if (deviceId != null) {
  //             final generatedUuid = const Uuid().v5(Uuid.NAMESPACE_URL, deviceId);
  //             await storage.write(key: "surveyUserId", value: generatedUuid);
  //           } else {
  //             final fallbackUuid = const Uuid().v4();
  //             await storage.write(key: "surveyUserId", value: fallbackUuid);
  //           }
  //         } catch (e) {
  //           // En caso de error, se cae a UUID v4 también
  //           final fallbackUuid = const Uuid().v4();
  //           await storage.write(key: "surveyUserId", value: fallbackUuid);
  //         }
  //       }
  //     }
  //
  //     navigatorKey.currentState?.push(
  //       MaterialPageRoute(
  //         builder: (_) => WebViewPool(surveyUserId ?? "fallback-id", null,true),
  //       ),
  //     );
  //   }
  // }






  @override
  Widget build(BuildContext context) {
    RemoteRepository remoteRepository = HttpRemoteRepository(Client());
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: ((context) => RestaurantCubit(remoteRepository)),
        ),
        BlocProvider(
          create: ((context) => RestaurantMapCubit(remoteRepository)),
        ),
        BlocProvider(
          create: ((context) => FilterCubit()),
        ),
        BlocProvider(
          create: ((context) => FilterCubitMap()),
        ),
        BlocProvider(
          create: ((context) => CuponesCubit(remoteRepository)),
        ),
        BlocProvider(
          create: ((context) => TopRestaurantCubit(remoteRepository)),
        ),
        BlocProvider(
          create: ((context) => UserCubit(remoteRepository)),
        ),
        BlocProvider(
          create: ((context) => BannersCubit(remoteRepository)),
        ) ,
        BlocProvider(
          create: ((context) => MenuCubit()),
        ),
        BlocProvider(
          create: ((context) => LocationCubit()),
        ),
        BlocProvider(
          create: ((context) => NewHomeFiltersCubit()),
        ),
        BlocProvider(
          create: ((context) => WeatherCubit(HttpWeatherService(remoteRepository))),
        ),
        BlocProvider(
          create: ((context) => ZoneWeatherCubit(HttpWeatherService(remoteRepository))),
        ),
        BlocProvider(
          create: ((context) => CuratedListsCubit(remoteRepository)),
        ),
        BlocProvider(
          create: ((context) => ZonesCubit(remoteRepository)),
        ),
        BlocProvider(
          lazy: false,
          create: ((context) => IslandsCubit(remoteRepository)..load()),
        ),
        BlocProvider(
          create: ((context) => VisitsCubit(remoteRepository)),
        ),
        BlocProvider(
          create: ((context) => DishSearchCubit(context.read<VisitsCubit>())),
        ),
        BlocProvider(
          create: ((context) => UserVisitsCubit(remoteRepository, cache: HttpCacheStore.instance)),
        ),
        BlocProvider(
          create: ((context) => ThemeCubit(widget.initialThemeMode)),
        ),
        BlocProvider(
          lazy: false,
          create: ((context) => ConnectivityCubit()..init()),
        ),
        BlocProvider(
          create: ((context) => FavoritesCubit(
                HttpFavoritesRepository(Client()),
                SqliteFavoritesLocalStore(),
                connectivityStream: context.read<ConnectivityCubit>().stream,
              )),
        ),
        BlocProvider(
          lazy: false,
          create: ((context) => OnboardingCubit()..hydrate()),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (_, themeMode) => MaterialApp(
          title: 'Guachinches',
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: appLightTheme,
          darkTheme: appDarkTheme,
          themeMode: themeMode,
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          home: DccRemoteConfig.instance.maintenanceMode
              ? const MaintenanceScreen()
              : SplashScreen(),
        ),
      ),
    );
  }
}
