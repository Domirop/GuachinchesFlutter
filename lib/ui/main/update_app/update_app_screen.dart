import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateAppScreen extends StatefulWidget {
  @override
  _UpdateAppScreenState createState() => _UpdateAppScreenState();
}

class _UpdateAppScreenState extends State<UpdateAppScreen> {
  launchStore() {
    if (Platform.isIOS) {
      launch('https://apps.apple.com/es/app/guachinches-modernos/id1575882373');
    } else {
      launch('https://play.google.com/store/apps/details?id=com.jonay.guachinches&gl=ES');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(300, 300, 300, 1),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(bottom: 20.0),
              decoration: BoxDecoration(
                color: Color.fromRGBO(230, 73, 90, 1),
                borderRadius: BorderRadius.circular(50.0),
              ),
              child: Icon(
                Icons.refresh,
                color: Colors.white,
                size: 150,
              ),
            ),
            Flexible(child: Text("¡Vaya! Han llegado nuevas funcionalidades.", style: TextStyle(fontSize: 14))),
            Flexible(child: Text("Actualiza tu app y disfrútalas.", style: TextStyle(fontSize: 14))),
            Padding(
              padding: EdgeInsets.only(top: 20.0),
              child: GestureDetector(
                onTap: launchStore,
                child: Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  margin: EdgeInsets.symmetric(horizontal: 40.0),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(5, 73, 155, 1),
                    borderRadius: BorderRadius.circular(11.0),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 15.0),
                  child: Text(
                    "Iniciar sesión",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16.0),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}