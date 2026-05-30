import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/data/cubit/onboarding/onboarding_cubit.dart';
import 'package:guachinches/data/cubit/onboarding/onboarding_state.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/data/cubit/user/user_state.dart';
import 'package:guachinches/data/model/version.dart';
import 'package:guachinches/ui/pages/map/map_search.dart';
import 'package:guachinches/ui/pages/listas/listas_screen.dart';
import 'package:guachinches/ui/pages/new_home/new_home_screen.dart';
import 'package:guachinches/ui/pages/discover/discover_screen.dart';
import 'package:guachinches/ui/pages/settings/settings_screen.dart';

class SplashScreenPresenter {
  final SplashScreenView _view;

  final RemoteRepository _remoteRepository;

  final UserCubit _userCubit;
  final OnboardingCubit _onboardingCubit;
  final storage = FlutterSecureStorage();

  SplashScreenPresenter(
    this._view,
    this._remoteRepository,
    this._userCubit,
    this._onboardingCubit,
  );

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
    // SettingsScreen manages its own state via UserCubit —
    // shows logged-in view, not-logged-in view, and loading/error states.
    const Widget profileTab = SettingsScreen();
    try {
      String? userId = await storage.read(key: "userId");
      if (userId != null && userId.isNotEmpty) {
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
    // Si `getVersion` falla (timeout, offline, backend caído), seguimos
    // adelante con `versionBD = "1.0.0"`. Esto NO debe bloquear el arranque
    // de la app: en el peor caso saltamos la comprobación de versión y el
    // usuario ve el home igualmente. El check de "actualiza la app" se hará
    // la próxima vez que el backend responda.
    String versionBD = "1.0.0";
    try {
      final Version version = await _remoteRepository.getVersion();
      if (Platform.isIOS == true) {
        versionBD = version.iosVersion;
      } else {
        versionBD = version.androidVersion;
      }
    } catch (_) {
      // Continuamos con versionBD = "1.0.0" → check devuelve false → no
      // forzamos UpdateScreen y el flujo sigue.
    }

    bool check = false;
    try {
      check = await checkVersion(versionBD);
    } catch (_) {
      check = false;
    }

    if (check) {
      _view.goToUpdateScreen();
    } else {
      if (_onboardingCubit.state is OnboardingInitial) {
        await _onboardingCubit.hydrate();
      }
      if (_onboardingCubit.isFinished) {
        // Premios Donde Comer Canarias 2026 — pausado.
        // Restaurar leyendo surveyShown del cubit y llamando a
        // goToSurveyOnboarding() cuando sea false, como antes.
        mainFunction();
      } else {
        _view.goToOnBoarding();
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

