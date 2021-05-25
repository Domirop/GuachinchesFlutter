import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/user_cubit.dart';
import 'package:guachinches/home/home.dart';
import 'package:guachinches/login/login.dart';
import 'package:guachinches/profile.dart';
import 'package:guachinches/valoraciones/valoraciones.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'menu_presenter.dart';

class Menu extends StatefulWidget {
  List<Widget> screens;

  Menu(this.screens);

  @override
  _ProfileState createState() => _ProfileState(screens);
}

class _ProfileState extends State<Menu> implements MenuView{
  int selectedItem = 0;
  int aux;
  List<Widget> screens;
  MenuPresenter _presenter;

  _ProfileState(this.screens);

  @override
  void initState() {
    final userCubit = context.read<UserCubit>();
    _presenter = MenuPresenter(this, userCubit);
    _presenter.getUserInfo();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return screens.length == 0
        ? SpinKitPulse(
            color: Colors.black,
          )
        : Scaffold(
            body: screens[selectedItem],
            bottomNavigationBar: Theme(
              data: Theme.of(context).copyWith(
                canvasColor: Colors.white,
                textTheme: Theme.of(context).textTheme.copyWith(
                      caption: TextStyle(color: Colors.white),
                    ),
              ),
              child: BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  items: [
                    BottomNavigationBarItem(
                      icon: Icon(
                        Icons.home,
                        color: Colors.black,
                      ),
                      label: "",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(
                        Icons.star_half,
                        color: Colors.black,
                      ),
                      label: "",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(
                        Icons.account_circle_outlined,
                        color: Colors.black,
                      ),
                      label: "",
                    ),
                  ],
                  currentIndex: selectedItem,
                  onTap: showScreen),
            ),
          );
  }

  @override
  showScreen(int index) {
    setState(() {
      selectedItem = index;
    });
  }

  @override
  loginError() {
    setState(() {
      screens = [Home(), Login("Para ver tus valoraciones debes iniciar sesión."), Login("Para ver tu perfíl debes iniciar sesión.")];
    });
  }

  @override
  loginSuccess() {
    screens = [Home(), Valoraciones(), Profile()];
  }
}
