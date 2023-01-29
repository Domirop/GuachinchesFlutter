import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/pages/login/login.dart';
import 'package:guachinches/ui/pages/menu/menu.dart';
import 'package:guachinches/ui/pages/home/home.dart';
import 'package:guachinches/ui/pages/register/register_presenter.dart';
import 'package:guachinches/ui/pages/search_page/search_page.dart';
import 'package:guachinches/ui/pages/splash_screen/splash_screen.dart';
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool checkedValue = false;
  bool showErrorText = false;
  @override
  void initState() {
    _remoteRepository = HttpRemoteRepository(Client());
    presenter = RegisterPresenter(_remoteRepository, this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          image: DecorationImage(
              fit: BoxFit.cover,
              image: AssetImage("assets/images/loginBg.png"))
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          color: Colors.transparent,
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
                SizedBox(
                  height: 30.0,
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    "Registrar usuario",
                    textAlign: TextAlign.start,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 40.0,
                      ),
                  ),
                ),
                SizedBox(
                  height: 15.0,
                ),
                errorText == null || errorText.isEmpty ? Container() : Text(
                  errorText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
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
                      Container(
                        height: 62,
                        padding: const EdgeInsets.only(left: 8.0),
                        decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(width: 3.0, color: Colors.white),
                            )
                        ),
                        child: TextFormField(
                          controller: _nombre,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Campo obligatorio";
                            }
                          },
                          keyboardType: TextInputType.text,
                          style: TextStyle(
                              color: Color.fromRGBO(255, 255, 255, 1),
                              fontSize: 24.0
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.transparent),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.transparent),
                            ),
                            labelText: "Nombre",
                            labelStyle: TextStyle(
                              color: Color.fromRGBO(255, 255, 255, 0.7),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 10.0,
                      ),
                      Container(
                        height: 62,
                        padding: const EdgeInsets.only(left: 8.0),
                        decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(width: 3.0, color: Colors.white),
                            )
                        ),
                        child: TextFormField(
                          controller: _apellidos,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Campo obligatorio";
                            }
                          },
                          keyboardType: TextInputType.text,
                          style: TextStyle(
                              color: Color.fromRGBO(255, 255, 255, 1),
                              fontSize: 24.0
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.transparent),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.transparent),
                            ),
                            labelText: "Apellidos",
                            labelStyle: TextStyle(
                              color: Color.fromRGBO(255, 255, 255, 0.7),
                            ),
                          ),

                        ),
                      ),
                      SizedBox(
                        height: 10.0,
                      ),
                      Container(
                        height: 62,
                        padding: const EdgeInsets.only(left: 8.0),
                        decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(width: 3.0, color: Colors.white),
                            )
                        ),
                        child: TextFormField(
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
                              color: Color.fromRGBO(255, 255, 255, 1),
                              fontSize: 24.0
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.transparent),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.transparent),
                            ),
                            labelText: "Teléfono",
                            labelStyle: TextStyle(
                              color: Color.fromRGBO(255, 255, 255, 0.7),
                            ),
                          ),

                        ),
                      ),
                      SizedBox(
                        height: 10.0,
                      ),
                      Container(
                        height: 62,
                        padding: const EdgeInsets.only(left: 8.0),
                        decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(width: 3.0, color: Colors.white),
                            )
                        ),
                        child: TextFormField(
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
                              color: Color.fromRGBO(255, 255, 255, 1),
                              fontSize: 24.0
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.transparent),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.transparent),
                            ),
                            labelText: "Email",
                            labelStyle: TextStyle(
                              color: Color.fromRGBO(255, 255, 255, 0.7),
                            ),
                          ),

                        ),
                      ),
                      SizedBox(
                        height: 10.0,
                      ),
                      Container(
                        height: 62,
                        padding: const EdgeInsets.only(left: 8.0),
                        decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(width: 3.0, color: Colors.white),
                            )
                        ),
                        child: TextFormField(
                          controller: _mainPassword,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.length < 8) {
                              return "Debe tener al menos 8 caracteres";
                            }
                          },
                          keyboardType: TextInputType.text,
                          style: TextStyle(
                              color: Color.fromRGBO(255, 255, 255, 1),
                              fontSize: 24.0
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.transparent),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.transparent),
                            ),
                            labelText: "Contraseña",
                            labelStyle: TextStyle(
                              color: Color.fromRGBO(255, 255, 255, 0.7),
                            ),
                          ),

                        ),
                      ),
                      SizedBox(
                        height: 10.0,
                      ),
                      Container(
                        height: 62,
                        padding: const EdgeInsets.only(left: 8.0),
                        decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(width: 3.0, color: Colors.white),
                            )
                        ),
                        child: TextFormField(
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
                              color: Color.fromRGBO(255, 255, 255, 1),
                              fontSize: 24.0
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.transparent),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.transparent),
                            ),
                            labelText: "Repetir contraseña",
                            labelStyle: TextStyle(
                              color: Color.fromRGBO(255, 255, 255, 0.7),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(

                  children: [
                    Container(
                      height: 60,
                      width: 30,
                      child: CheckboxListTile(
                        side: BorderSide(color: Colors.white),
                        value: checkedValue,
                        onChanged: (newValue) {
                          setState(() {
                            checkedValue = newValue;
                            showErrorText = !newValue;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,  //  <-- leading Checkbox
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.6,
                      child: RichText(

                        text: TextSpan(children: [
                          TextSpan(
                            text: "Acepto la  ",
                            style: new TextStyle(color: Colors.white),

                          ),
                          TextSpan(text: " protección de datos  ",    style: new TextStyle(color: Colors.white,),
                              recognizer: TapGestureRecognizer()..onTap = (){
                                launch('https://www.guachinchesmodernos.com/data/dataPolicy/');
                              }
                          ),
                          TextSpan(text: "y los ",style: new TextStyle(color: Colors.white)),
                          TextSpan(text: "términos y condiciones de uso  ",
                              recognizer: TapGestureRecognizer()..onTap = (){
                                launch('https://www.guachinchesmodernos.com/data/terms/');
                              },
                              style: new TextStyle(color: Colors.blue,decoration: TextDecoration.underline)),

                        ]),
                      ),
                    )
                  ],
                ),
                showErrorText ?Text("Debes aceptar los terminos y condiciones",style: TextStyle(color: Colors.white),):Container(),
                SizedBox(
                  height: 30.0,
                ),
                GestureDetector(
                  onTap: () {
                    if(checkedValue==false){
                      setState(() {
                        showErrorText = true;
                      });
                    }
                    if (_formKey.currentState.validate()&&checkedValue) {
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
                      color: Color.fromRGBO(0, 189, 195, 1),
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
      ),
    );
  }

  @override
  correctInsert() {
    GlobalMethods().pushAndReplacement(context, Login('Registro con exito, inicia sesión'));
  }

  @override
  errorInsert(String error) {
    setState(() {
      errorText = error;
    });
  }
}
