import 'package:flutter/material.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/user_cubit.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/menu.dart';
import 'package:guachinches/splash_screen/splash_screen_presenter.dart';
import 'package:http/http.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> implements SplashScreenView{
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
    return Scaffold(body:Container(
      color: Colors.white,
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      alignment: Alignment.center,
      child: Image.asset("assets/images/logo.png", height: 298, width: 293,),
    ));
  }

  @override
  goToMenu() {
    GlobalMethods().pushAndReplacement(context, Menu());
  }
}