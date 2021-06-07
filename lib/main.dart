import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/banners_cubit.dart';
import 'package:guachinches/data/cubit/categories_cubit.dart';
import 'package:guachinches/data/cubit/user_cubit.dart';
import 'package:guachinches/data/local/db_provider.dart';
import 'package:guachinches/splash_screen/splash_screen.dart';
import 'package:http/http.dart';
import 'data/cubit/restaurant_cubit.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    DBProvider.db.initDB();
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  }

  @override
  Widget build(BuildContext context) {
    RemoteRepository remoteRepository = HttpRemoteRepository(Client());
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: ((context) => RestaurantCubit(remoteRepository)),
        ),
        BlocProvider(
          create: ((context) => UserCubit(remoteRepository)),
        ),
        BlocProvider(
          create: ((context) => CategoriesCubit(remoteRepository)),
        ),
        BlocProvider(
          create: ((context) => BannersCubit(remoteRepository)),
        )
      ],
      child: MaterialApp(
        title: 'Guachinches',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
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
