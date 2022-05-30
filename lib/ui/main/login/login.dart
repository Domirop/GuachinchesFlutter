import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/main/login/login_presenter.dart';
import 'package:guachinches/ui/main/menu/menu.dart';
import 'package:guachinches/ui/main/register/register.dart';
import 'package:guachinches/ui/sub_menu_pages/home/home.dart';
import 'package:guachinches/ui/sub_menu_pages/search_page/search_page.dart';
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
    return Scaffold(
      body: ListView(children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          color: Colors.white,
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
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
                widget.mainText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18.0,
                ),
              ),
              Text(
                dataError == true ?"Email o contraseña incorrecta":"",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 18.0,
                ),
              ),
              SizedBox(
                height: 30.0,
              ),
              TextField(
                controller: emailController,
                scrollPadding: EdgeInsets.only(bottom: bottomInsets + 50),
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
                controller: passwordController,
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
              GestureDetector(
                onTap: () => _presenter.login(
                    emailController.text, passwordController.text),
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
              SizedBox(
                height: 30.0,
              ),
              GestureDetector(
                onTap: () => GlobalMethods().pushPage(context, Register()),
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
      ]),
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
