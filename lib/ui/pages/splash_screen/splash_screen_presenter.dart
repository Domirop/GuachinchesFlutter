import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/data/cubit/user/user_state.dart';
import 'package:guachinches/data/model/version.dart';
import 'package:guachinches/ui/pages/login/login.dart';
import 'package:guachinches/ui/pages/map/map_search.dart';
import 'package:guachinches/ui/pages/listas/listas_screen.dart';
import 'package:guachinches/ui/pages/new_home/new_home_screen.dart';
import 'package:guachinches/ui/pages/discover/discover_screen.dart';
import 'package:guachinches/ui/pages/profile/profile_v2.dart';

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


  Future<List<Widget>> _buildScreens() async {
    Widget profileTab =
        Login("Para ver tu perfíl debes iniciar sesión.");
    try {
      String? userId = await storage.read(key: "userId");
      if (userId != null && userId.isNotEmpty) {
        // Sesión persistida: mostramos el perfil sin gatear en el cubit.
        // Si el fetch falla (timeout, red), Profilev2 reintenta por su cuenta;
        // NO borramos el userId — eso causaba "logout" al hacer hot restart
        // con red lenta.
        profileTab = Profilev2();
        if (_userCubit.state is UserInitial) {
          // Disparamos el fetch en background para precargar el cubit.
          // ignore: unawaited_futures
          _userCubit.getUserInfo(userId);
        }
      }
    } catch (_) {}
    return [
      const NewHomeScreen(),
      const ListasScreen(),
      MapSearch(),
      const DiscoverScreen(),
      profileTab,
    ];
  }

  mainFunction() async {
    final screens = await _buildScreens();
    _view.goToMenu(screens);
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
      if(key==null|| key.length==0){
        await storage.write(key: 'onBoardingFinished',value: 'false');
        _view.goToOnBoarding();
      }else{
        if(key == 'true'){
          // Premios Donde Comer Canarias 2026 — pausado.
          // Restaurar leyendo 'surveyOnboarding2026Shown' y llamando a
          // goToSurveyOnboarding() cuando esté vacío, como antes.
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
  goToSurveyOnboarding(List<Widget> screens);
}

