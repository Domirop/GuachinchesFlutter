import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/details.dart';
import 'package:guachinches/inicio.dart';
import 'package:guachinches/login.dart';
import 'package:guachinches/menu.dart';
import 'package:guachinches/perfil.dart';
import 'package:guachinches/valoraciones.dart';
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
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown
    ]);
  }

  @override
  Widget build(BuildContext context) {
    RemoteRepository remoteRepository = HttpRemoteRepository(Client());
    return BlocProvider(
      create: ((context) => RestaurantCubit(remoteRepository)),
      child: MaterialApp(
        title: 'Guachinches',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          buttonTheme:ButtonThemeData(minWidth:5),
          dividerColor: Colors.black,
          primarySwatch: Colors.blue,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        home: Details(),
      ),
    );
  }

}
