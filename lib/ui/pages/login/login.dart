import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/pages/menu/menu.dart';
import 'package:guachinches/ui/pages/home/home.dart';
import 'package:guachinches/ui/pages/login/login_presenter.dart';
import 'package:guachinches/ui/pages/register/register.dart';
import 'package:guachinches/ui/pages/search_page/search_page.dart';
import 'package:http/http.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Login extends StatefulWidget {
  final String mainText;

  Login(this.mainText);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> implements LoginView {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  LoginPresenter _presenter;
  RemoteRepository _remoteRepository;
  bool dataError = false;

  @override
  void initState() {
    final userCubit = context.read<UserCubit>();
    _remoteRepository = HttpRemoteRepository(Client());
    _presenter = LoginPresenter(_remoteRepository, this, userCubit);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double bottomInsets = MediaQuery.of(context).viewInsets.bottom;
    return Container(
        decoration: BoxDecoration(
            image: DecorationImage(
                fit: BoxFit.cover,
                image: AssetImage("assets/images/loginBg.png"))),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: ListView(
          children: [
        Container(
        padding: EdgeInsets.symmetric(horizontal: 20.0),
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Column(
          children: [
            SizedBox(
              height: 20.0,
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
                  color: Colors.blueGrey,
                  size: 40.0,
                ),
              ),
            ),

            Align(
              alignment: Alignment.topLeft,
              child: Text(
                widget.mainText,
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 40.0,
                ),
              ),
            ),
            Text(
              dataError == true ?"Email o contraseña incorrecta":"",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.0,
              ),
            ),
            SizedBox(
              height: 30.0,
            ),
            Container(
              height: 62,
              padding: const EdgeInsets.only(left: 8.0),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(width: 3.0, color: Colors.white),
                )
              ),
              child: TextField(
                controller: emailController,
                scrollPadding: EdgeInsets.only(bottom: bottomInsets +10),
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
              height: 30.0,
            ),
            Container(
              height: 62,
              padding: const EdgeInsets.only(left: 8.0),
              decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(width: 3.0, color: Colors.white),
                  )
              ),
              child: TextField(
                controller: passwordController,
                keyboardType: TextInputType.text,
                style: TextStyle(
                  color: Colors.white,
                    fontSize: 24.0
                ),
                obscureText: true,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                        color: Colors.transparent),
                  ),
                  labelText: "Contraseña",
                  labelStyle: TextStyle(
                    color: Color.fromRGBO(255, 255, 255, 0.7),
                  ),

                ),
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
                  color: Colors.white,
                  fontSize: 12.0,
                ),
              ),
            ),
            SizedBox(
              height: 42,
            ),
            Container(
              width: MediaQuery.of(context).size.width*0.72,
              child: ElevatedButton(
                onPressed: () => _presenter.login(
                    emailController.text, passwordController.text),
                style: ButtonStyle(
                    shape: MaterialStateProperty.all(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // <-- Radius
                    ),),
                    minimumSize: MaterialStateProperty.all(Size.fromHeight(48)),
                    backgroundColor: MaterialStateProperty.all(Color.fromRGBO(0, 189, 195, 1))),

                child:Text(
                    "Iniciar sesión",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16.0),
                  ),
              ),
            ),
            SizedBox(
              height: 18.0,
            ),
            Container(
              width: MediaQuery.of(context).size.width*0.72,
              child: ElevatedButton(
                onPressed: () => GlobalMethods().pushPage(context, Register()),
                child: Text('Registrarse',style: TextStyle(
                    color: Color.fromRGBO(0, 189, 195, 1),
                    fontWeight: FontWeight.bold
                ),),
                  style: ButtonStyle(
              shape: MaterialStateProperty.all(RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // <-- Radius
      ),),
    minimumSize: MaterialStateProperty.all(Size.fromHeight(48)),
    backgroundColor: MaterialStateProperty.all(Colors.white))
              ),
            ),
          ],
        ),
          ),
          ]),
      ),
    );
  }

  @override
  loginError() {
  setState(() {
    dataError = true;
  });
  }

  @override
  loginSuccess(List<Widget> screens) {
    GlobalMethods().removePagesAndGoToNewScreen(context, Menu(screens));
  }
}
