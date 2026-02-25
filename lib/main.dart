import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/banners/banners_cubit.dart';
import 'package:guachinches/data/cubit/cupones/cupones_cubit.dart';
import 'package:guachinches/data/cubit/filter/filter_cubit.dart';
import 'package:guachinches/data/cubit/filter/filter_map_cubit.dart';
import 'package:guachinches/data/cubit/menu/menu_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/map/restaurant_map_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/top/top_restaurants_cubit.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/data/local/db_provider.dart';
import 'package:http/http.dart';
import 'data/cubit/restaurants/basic/restaurant_cubit.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'ui/pages/splash_screen/splash_screen.dart';


const bool _kReleaseMode = const bool.fromEnvironment("dart.vm.product");

Future<void> main() async{
  String file = _kReleaseMode == true ? 'env_files/release.env' : 'env_files/debug.env';
  await dotenv.load(fileName: file);
  await Firebase.initializeApp();
  debugPaintBaselinesEnabled = false; // asegúrate de no activarlo
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializar SDK de AdMob
  await MobileAds.instance.initialize();

  runApp(MyApp());
}

class MyApp extends StatefulWidget {

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
  //   print("LINK::"+uuid);
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
        )
      ],
      child: MaterialApp(
        title: 'Guachinches',
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'SF Pro Display',
          textTheme: TextTheme(
            displayLarge: TextStyle(color: Colors.white),
            displayMedium: TextStyle(color: Colors.white,fontFamily: 'SF Pro Display',fontSize: 18),
            displaySmall: TextStyle(color: Colors.white,fontFamily: 'SF Pro Display'),
            bodyLarge: TextStyle(color: Colors.white),
            bodyMedium: TextStyle(color: Colors.white,fontSize: 20,fontWeight: FontWeight.bold),
            bodySmall: TextStyle(color: Colors.white,fontFamily: 'SF Pro Display',fontSize:12),
          ),
          appBarTheme: AppBarTheme(
            color: Color.fromRGBO(25, 27, 32, 1),
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
            actionsIconTheme: IconThemeData(color: Colors.white),
          ),
          scaffoldBackgroundColor:  Color.fromRGBO(25, 27, 32, 1),
          buttonTheme: ButtonThemeData(minWidth: 5),
          dividerColor: Colors.black,
          primarySwatch: Colors.blue,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        home: SplashScreen(),
      ),
    );
  }
}
