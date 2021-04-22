import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.0),
        color: Colors.white,
        height: MediaQuery
            .of(context)
            .size
            .height,
        width: MediaQuery
            .of(context)
            .size
            .width,
        child: Column(
          children: [
            SizedBox(
              height: 40.0,
            ),
            Container(
              alignment: Alignment.centerRight,
              child: Icon(
                Icons.close,
                color: Colors.grey,
                size: 40.0,
              ),
            ),
            Image.asset(
              "assets/images/logo.png",
              height: 132,
              width: 129,
            ),
            SizedBox(
              height: 30.0,
            ),
            Text(
              "Los mejores sitios para disfrutar",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 18.0,
              ),
            ),
            SizedBox(
              height: 30.0,
            ),
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(
                color: Colors.black,
              ),
              decoration: InputDecoration(
                labelText: "Email",
              ),
            ),
            SizedBox(
              height: 30.0,
            ),
            TextField(
              controller: password,
              keyboardType: TextInputType.text,
              style: TextStyle(
                color: Colors.black,
              ),
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Contraseña",
              ),
            ),
            SizedBox(
              height: 30.0,
            ),
            Container(
              alignment: Alignment.centerRight,
              child: Text(
                "Has olvidado la contraseña?",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12.0,
                ),
              ),
            ),
            SizedBox(
              height: 30.0,
            ),
            Container(
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
                style: TextStyle(fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16.0),
              ),
            ),
            SizedBox(
              height: 30.0,
            ),
            Text(
              "Registrate",
              style: TextStyle(fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 16.0),
            ),
          ],
        ),
      ),
    );
  }
}
