import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guachinches/categorias.dart';
import 'package:guachinches/perfil.dart';
import 'package:guachinches/valoraciones.dart';

import 'details.dart';
import 'home.dart';

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
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        buttonTheme:ButtonThemeData(minWidth:5),
        dividerColor: Colors.black,
        primarySwatch: Colors.blue,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      home: Perfil(),
    );
  }

}
