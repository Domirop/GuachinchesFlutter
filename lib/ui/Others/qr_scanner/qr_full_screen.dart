import 'package:flutter/material.dart';
import 'package:guachinches/data/model/Cupones.dart';
import 'package:guachinches/data/model/user_info.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrFullScreen extends StatefulWidget {
  final Cupones data;
  final UserInfo user;

  QrFullScreen(this.data, this.user);

  @override
  _QrFullScreenState createState() => _QrFullScreenState(data, user);
}

class _QrFullScreenState extends State<QrFullScreen> {
  final Cupones data;
  final UserInfo userInfo;

  _QrFullScreenState(this.data, this.userInfo);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Nombre: " + userInfo.nombre,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10,),
              Text(
                "Email: " + userInfo.email,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 30,),
              QrImage(
                data: "https://guachinchesmodernos.com/cupones/check/" + data.cuponesUsuarioId,
                version: QrVersions.auto,
                size: MediaQuery.of(context).size.width,
                padding: EdgeInsets.all(20.0),
                gapless: false,
              ),
              Text(
                "Escanea el código con fecha\n" +
                    data.date +
                    "\npara obtener todos sus beneficios",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  height: 1.5
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
