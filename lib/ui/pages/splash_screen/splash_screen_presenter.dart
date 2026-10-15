import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/data/cubit/onboarding/onboarding_cubit.dart';
import 'package:guachinches/data/cubit/onboarding/onboarding_state.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/data/cubit/user/user_state.dart';
import 'package:guachinches/data/model/version.dart';
import 'package:guachinches/ui/pages/settings/settings_screen.dart';
import 'package:guachinches/utils/app_version.dart';
import 'package:guachinches/services/app_storage.dart';

class SplashScreenPresenter {
  final SplashScreenView _view;

  final RemoteRepository _remoteRepository;

  final UserCubit _userCubit;
  final OnboardingCubit _onboardingCubit;
  final storage = AppStorage.instance;

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

    // Antes comparaba el menor aunque el mayor fuera más alto (5.0 < 4.7 daba
    // «actualiza»). La encuesta v3 fuerza la actualización con esta pantalla.
    return compareAppVersions(versionApp, versionBD) < 0;
  }


  Future<List<Widget>> _buildScreens() async {
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
    // Las 5 pestañas de siempre; Perfil = SettingsScreen (con o sin sesión).
    return buildMainTabScreens();
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

