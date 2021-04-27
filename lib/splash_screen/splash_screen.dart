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
    return Scaffold(body: Container());
  }

  @override
  goToMenu() {
    GlobalMethods().pushAndReplacement(context, Menu());
  }
}
