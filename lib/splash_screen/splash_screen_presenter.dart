import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/data/cubit/user_cubit.dart';
import 'package:guachinches/data/cubit/user_state.dart';
import 'package:guachinches/home/home.dart';
import 'package:guachinches/login/login.dart';
import 'package:guachinches/valoraciones/valoraciones.dart';

import '../profile/profile.dart';

class SplashScreenPresenter{
  final SplashScreenView _view ;
  final RemoteRepository _remoteRepository ;
  final UserCubit _userCubit;
  final storage = new FlutterSecureStorage();


  SplashScreenPresenter(this._view, this._remoteRepository, this._userCubit);

  getUserInfo() async {
    String userId = await storage.read(key: "userId");
    List<Widget> screens = [Home(), Valoraciones(), Profile()];
    if(userId != null){
      if (_userCubit.state is UserInitial) {
       await _userCubit.getUserInfo(userId);
      }
      screens = [Home(), Valoraciones(), Profile()];
    }else{
      screens = [Home(), Login("Para ver tus valoraciones debes iniciar sesión."), Login("Para ver tu perfíl debes iniciar sesión.")];
    }
    _view.goToMenu(screens);
  }
}
abstract class SplashScreenView{
  goToMenu(List<Widget> screens);
}
