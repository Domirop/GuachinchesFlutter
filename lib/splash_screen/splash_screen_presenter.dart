import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/data/cubit/user_cubit.dart';
import 'package:guachinches/home/home.dart';
import 'package:guachinches/valoraciones/valoraciones.dart';

import '../profile.dart';

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
      await _userCubit.getUserInfo(userId);

    }
    _view.goToMenu(screens);
  }
}
abstract class SplashScreenView{
  goToMenu(List<Widget> screens);
}