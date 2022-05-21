import 'package:flutter/material.dart';

class Inicio extends StatefulWidget {
  @override
  _InicioState createState() => _InicioState();
}

class _InicioState extends State<Inicio> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        alignment: Alignment.bottomCenter,
        decoration: BoxDecoration(
          color: Colors.white,
          image: DecorationImage(
            repeat: ImageRepeat.noRepeat,
            alignment: Alignment.center,
            fit: BoxFit.cover,
            image: AssetImage('assets/images/init.png'),
          ),
        ),
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Stack(
          clipBehavior: Clip.none, children: [
            Positioned(
              top: -(MediaQuery.of(context).size.height / 3),
              child: Container(
                width: MediaQuery.of(context).size.width,
                alignment: Alignment.center,
                child: Text(
                  "Guachinches modernos de Tenerife",
                  style: TextStyle(
                    fontSize: 20.0,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topRight:
                  Radius.elliptical(MediaQuery.of(context).size.width, 150.0),
                  topLeft:
                  Radius.elliptical(MediaQuery.of(context).size.width, 150.0),
                ),
              ),
              height: MediaQuery.of(context).size.height / 1.8,
              width: MediaQuery.of(context).size.width,
              child: Column(
                children: [
                  SizedBox(
                    height: 10.0,
                  ),
                  Image.asset(
                    "assets/images/logo.png",
                    height: 132,
                    width: 129,
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                  Container(
                    width: double.maxFinite,
                    alignment: Alignment.center,
                    margin: EdgeInsets.symmetric(horizontal: 40.0),
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(5, 73, 155, 1),
                      borderRadius: BorderRadius.circular(11.0),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 10.0,
                        ),
                        Icon(
                          Icons.email_outlined,
                          color: Colors.white,
                          size: 30.0,
                        ),
                        SizedBox(
                          width: 10.0,
                        ),
                        Text(
                          "Iniciar sesión con tu email",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 16.0),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                  Container(
                    width: double.maxFinite,
                    alignment: Alignment.center,
                    margin: EdgeInsets.symmetric(horizontal: 40.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(11.0),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 10.0,
                        ),
                        Image.asset("assets/images/facebook.png"),
                        SizedBox(
                          width: 10.0,
                        ),
                        Text(
                          "Iniciar sesión con tu Facebook",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              fontSize: 16.0),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                  Container(
                    width: double.maxFinite,
                    alignment: Alignment.center,
                    margin: EdgeInsets.symmetric(horizontal: 40.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(11.0),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 10.0,
                        ),
                        Image.asset("assets/images/gmail.png"),
                        SizedBox(
                          width: 10.0,
                        ),
                        Text(
                          "Iniciar sesión con Google",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              fontSize: 16.0),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                  Container(
                    width: double.maxFinite,
                    alignment: Alignment.center,
                    margin: EdgeInsets.symmetric(horizontal: 40.0),
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(242, 247, 252, 1),
                      borderRadius: BorderRadius.circular(11.0),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: Text(
                      "Registrate",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 16.0),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
