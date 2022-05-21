import 'package:flutter/material.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/main/login/login.dart';
import 'package:guachinches/ui/main/menu/menu.dart';
import 'package:guachinches/ui/main/register/register_presenter.dart';
import 'package:guachinches/ui/sub_menu_pages/home/home.dart';
import 'package:guachinches/ui/main/splash_screen/splash_screen.dart';
import 'package:guachinches/ui/sub_menu_pages/search_page/search_page.dart';
import 'package:http/http.dart';

class Register extends StatefulWidget {
  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> implements RegisterView{
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _mainPassword = TextEditingController();
  final TextEditingController _nombre = TextEditingController();
  final TextEditingController _apellidos = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _telefono = TextEditingController();
  RegisterPresenter presenter;
  RemoteRepository _remoteRepository;
  String errorText = "";

  @override
  void initState() {
    _remoteRepository = HttpRemoteRepository(Client());
    presenter = RegisterPresenter(_remoteRepository, this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.0),
        color: Colors.white,
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: 40.0,
              ),
              GestureDetector(
                onTap: () => GlobalMethods().removePagesAndGoToNewScreen(
                    context,
                    Menu([
                      Home(),
                      SearchPage(),
                      Login("Para ver tus valoraciones debes iniciar sesión."),
                      Login("Para ver tu perfíl debes iniciar sesión.")
                    ])),
                child: Container(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    Icons.close,
                    color: Colors.grey,
                    size: 40.0,
                  ),
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
                "Registrar usuario",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18.0,
                ),
              ),
              SizedBox(
                height: 15.0,
              ),
              errorText == null || errorText.isEmpty ? Container() : Text(
                errorText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 18.0,
                ),
              ),
              SizedBox(
                height: 15.0,
              ),
              Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      controller: _nombre,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Campo obligatorio";
                        }
                      },
                      keyboardType: TextInputType.text,
                      style: TextStyle(
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        labelText: "Nombre",
                      ),
                    ),
                    SizedBox(
                      height: 10.0,
                    ),
                    TextFormField(
                      controller: _apellidos,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Campo obligatorio";
                        }
                      },
                      keyboardType: TextInputType.text,
                      style: TextStyle(
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        labelText: "Apellidos",
                      ),
                    ),
                    SizedBox(
                      height: 10.0,
                    ),
                    TextFormField(
                      controller: _telefono,
                      validator: (value) {
                        String pattern = r'^[6,7]{1}[0-9]{8}$';
                        RegExp regExp = new RegExp(pattern);
                        if (value == null || !regExp.hasMatch(value)) {
                          return "Teléfono inválido";
                        }
                      },
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        labelText: "Teléfono",
                      ),
                    ),
                    SizedBox(
                      height: 10.0,
                    ),
                    TextFormField(
                      controller: _email,
                      validator: (value) {
                        String pattern =
                            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+";
                        RegExp regExp = new RegExp(pattern);
                        if (value == null || !regExp.hasMatch(value)) {
                          return "Email invalido";
                        }
                      },
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        labelText: "Email",
                      ),
                    ),
                    SizedBox(
                      height: 10.0,
                    ),
                    TextFormField(
                      controller: _mainPassword,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.length < 8) {
                          return "Debe tener al menos 8 caracteres";
                        }
                      },
                      keyboardType: TextInputType.text,
                      style: TextStyle(
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        labelText: "Contraseña",
                      ),
                    ),
                    SizedBox(
                      height: 10.0,
                    ),
                    TextFormField(
                      validator: (value) {
                        if (value == null || value.length < 8) {
                          return "Debe tener al menos 8 caracteres";
                        }
                        if (value != _mainPassword.text) {
                          return "Las contraseñas no coinciden";
                        }
                      },
                      keyboardType: TextInputType.text,
                      obscureText: true,
                      style: TextStyle(
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        labelText: "Repetir contraseña",
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 30.0,
              ),
              GestureDetector(
                onTap: () {
                  if (_formKey.currentState.validate()) {
                    Map data = Map<String, String>();
                    data.putIfAbsent("nombre", () => _nombre.text);
                    data.putIfAbsent("apellidos", () => _apellidos.text);
                    data.putIfAbsent("email", () => _email.text.toLowerCase());
                    data.putIfAbsent("telefono", () => _telefono.text.toString());
                    data.putIfAbsent("password", () => _mainPassword.text.toString());
                    presenter.register(data);
                  }
                },
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
                    "Registrarse",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16.0),
                  ),
                ),
              ),
              SizedBox(
                height: 30.0,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  correctInsert() {
    GlobalMethods().removePagesAndGoToNewScreen(context, SplashScreen());
  }

  @override
  errorInsert(String error) {
    setState(() {
      errorText = error;
    });
  }
}
