import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/data/cubit/user/user_state.dart';
import 'package:guachinches/data/model/version.dart';
import 'package:guachinches/ui/pages/home/home.dart';
import 'package:guachinches/ui/pages/login/login.dart';
import 'package:guachinches/ui/pages/map/map_search.dart';
import 'package:guachinches/ui/pages/profile/profile.dart';
import 'package:guachinches/ui/pages/profile/profile_v2.dart';
import 'package:guachinches/ui/pages/search_page/search_page.dart';
import 'package:guachinches/ui/pages/valoraciones/valoraciones.dart';

import '../video/video.dart';

class SplashScreenPresenter {
  final SplashScreenView _view;

  final RemoteRepository _remoteRepository;

  final UserCubit _userCubit;
  final storage = new FlutterSecureStorage();

  SplashScreenPresenter(this._view, this._remoteRepository, this._userCubit);

  checkVersion(String versionBD) async {
    String versionApp;
    if (Platform.isIOS == true) {
      versionApp = dotenv.env['GET_IOS_VERSION']!;
    } else {
      versionApp = dotenv.env['GET_ANDROID_VERSION']!;
    }

    return int.parse(versionApp.split(".")[0]) < int.parse(versionBD.split(".")[0]) ||
        int.parse(versionApp.split(".")[1]) < int.parse(versionBD.split(".")[1]);
  }

  mainFunction() async {
    List<Widget> screens = [
      Home(),
      MapSearch(),
      Login("Para ver tus valoraciones debes iniciar sesión."),
      Login("Para ver tu perfíl debes iniciar sesión.")
    ];
    try {
      String? userId = await storage.read(key: "userId");

      if (userId != null) {
        if (_userCubit.state is UserInitial) {
          var response = await _userCubit.getUserInfo(userId);
          if (response == true) {
            screens = [Home(),MapSearch(),VideoScreen(index: 0), Profilev2()];
          } else {
            await storage.delete(key: "userId");
          }
        }else if(_userCubit.state is UserLoaded){
          screens = [Home(),MapSearch(), VideoScreen(index: 0), Profilev2()];
        }
      } else {
        screens = [
          Home(),
          MapSearch(),
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
    Version version = await _remoteRepository.getVersion();

    String versionBD = "1.0.0";

    if (Platform.isIOS == true) {
      versionBD = version.iosVersion;
    } else {
      versionBD = version.androidVersion;
    }
    bool check = await checkVersion(versionBD);
    if(check) {
      _view.goToUpdateScreen();
    }
    else {
      String? key = await storage.read(key: 'onBoardingFinished') ;
      // await storage.write(key: 'onBoardingFinished',value: 'false');
      if(key==null){
        await storage.write(key: 'onBoardingFinished',value: 'false');
        _view.goToOnBoarding();
      }else{
        if(key == 'true'){
          mainFunction();
        }else{
          _view.goToOnBoarding();
        }
      }
    }
  }
}

abstract class SplashScreenView {
  goToMenu(List<Widget> screens);
  goToUpdateScreen();
  goToOnBoarding();
}
