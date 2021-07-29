import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/data/cubit/user_cubit.dart';
import 'package:guachinches/data/cubit/user_state.dart';
import 'package:guachinches/home/home.dart';
import 'package:guachinches/login/login.dart';
import 'package:guachinches/valoraciones/valoraciones.dart';

import '../profile/profile.dart';

class SplashScreenPresenter {
  final SplashScreenView _view;

  final RemoteRepository _remoteRepository;

  final UserCubit _userCubit;
  final storage = new FlutterSecureStorage();

  SplashScreenPresenter(this._view, this._remoteRepository, this._userCubit);

  addLocalStorage() async {
    var municipalityId = await storage.read(key: "municipalityIdArea");

    if(municipalityId == null){
      await storage.delete(key: "municipalityIdArea");
      await storage.delete(key: "municipalityNameArea");
      await storage.delete(key: "useMunicipality");
      await storage.delete(key: "category");

      await storage.write(key: "municipalityIdArea", value: "");
      await storage.write(key: "municipalityNameArea", value: "");
      await storage.write(key: "useMunicipality", value: "Todos");
      await storage.write(key: "category", value: "Todas");
    }

  }
  getUserInfo() async {
    List<Widget> screens = [
      Home(),
      Login("Para ver tus valoraciones debes iniciar sesión."),
      Login("Para ver tu perfíl debes iniciar sesión.")
    ]; 
    try{
    await addLocalStorage();
    String userId = await storage.read(key: "userId");

    if (userId != null) {
      if (_userCubit.state is UserInitial) {
        var response = await _userCubit.getUserInfo(userId);
        if (response == true) {
          screens = [Home(), Valoraciones(), Profile()];
        } else {
          await storage.delete(key: "userId");
        }
      }
    } else {
      screens = [
        Home(),
        Login("Para ver tus valoraciones debes iniciar sesión."),
        Login("Para ver tu perfíl debes iniciar sesión.")
      ];
    }
    _view.goToMenu(screens);
    }catch(e){
      print(e);
      _view.goToMenu(screens);
    }
  }

}

abstract class SplashScreenView {
  goToMenu(List<Widget> screens);
}
