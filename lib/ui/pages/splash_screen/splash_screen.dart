import 'dart:io';

import 'package:flutter/material.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/pages/menu/menu.dart';
import 'package:guachinches/ui/pages/onBoarding/on_boarding.dart';
import 'package:guachinches/ui/pages/splash_screen/splash_screen_presenter.dart';
import 'package:guachinches/ui/pages/update_app/update_app_screen.dart';
import 'package:http/http.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    implements SplashScreenView {
  RemoteRepository remoteRepository;
  SplashScreenPresenter presenter;


  @override
  void initState() {
    final userCubit = context.read<UserCubit>();
    remoteRepository = HttpRemoteRepository(Client());
    presenter = SplashScreenPresenter(this, remoteRepository, userCubit);
    presenter.getUserInfo();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
      child: Container(
        color: Colors.white,
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        padding: EdgeInsets.symmetric(horizontal: 40.0),
        alignment: Alignment.center,
        child: Image(
          image: AssetImage("assets/images/logoGrande.png"),
          fit: BoxFit.cover,
          height: MediaQuery.of(context).size.width - 80,
        ),
      ),
    ));
  }

  @override
  goToMenu(List<Widget> screens) {
    GlobalMethods().pushAndReplacement(context, Menu(screens));
  }

  @override
  goToUpdateScreen() {
    GlobalMethods().pushAndReplacement(context, UpdateAppScreen());
  }
  @override
  goToOnBoarding() {
    GlobalMethods().pushAndReplacement(context, OnBoarding());
  }
}
