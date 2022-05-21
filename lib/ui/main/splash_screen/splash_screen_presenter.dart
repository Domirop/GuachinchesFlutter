import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/data/cubit/user_cubit.dart';
import 'package:guachinches/data/cubit/user_state.dart';
import 'package:guachinches/ui/main/login/login.dart';
import 'package:guachinches/ui/sub_menu_pages/home/home.dart';
import 'package:guachinches/ui/sub_menu_pages/profile/profile.dart';
import 'package:guachinches/ui/sub_menu_pages/search_page/search_page.dart';
import 'package:guachinches/ui/sub_menu_pages/valoraciones/valoraciones.dart';

class SplashScreenPresenter {
  final SplashScreenView _view;

  final RemoteRepository _remoteRepository;

  final UserCubit _userCubit;
  final storage = new FlutterSecureStorage();

  SplashScreenPresenter(this._view, this._remoteRepository, this._userCubit);

  addLocalStorage() async {
    var municipalityId = await storage.read(key: "municipalityIdArea");

    if (municipalityId == null) {
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

  checkVersion(String versionBD) async {
    String versionApp;
    if (Platform.isIOS == true) {
      versionApp = DotEnv().env['GET_IOS_VERSION'];
    } else {
      versionApp = DotEnv().env['GET_ANDROID_VERSION'];
    }

    return versionApp.split(".")[0] != versionBD.split(".")[0] ||
        versionApp.split(".")[1] != versionBD.split(".")[1];
  }

  mainFunction() async {
    List<Widget> screens = [
      Home(),
      SearchPage(),
      Login("Para ver tus valoraciones debes iniciar sesión."),
      Login("Para ver tu perfíl debes iniciar sesión.")
    ];
    try {
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
    } catch (e) {
      _view.goToMenu(screens);
    }
  }

  getUserInfo() async {
    String versionBD = "1.0.0";
    if (Platform.isIOS == true) {
      versionBD = "1.0.0";
    } else {
      versionBD = "1.0.0";
    }
    if(checkVersion(versionBD))_view.goToUpdateScreen();
    else mainFunction();
  }
}

abstract class SplashScreenView {
  goToMenu(List<Widget> screens);
  goToUpdateScreen();
}
