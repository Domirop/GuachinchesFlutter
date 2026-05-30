import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/onboarding/onboarding_cubit.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/pages/new_home/new_home_tab_scaffold.dart';
import 'package:guachinches/ui/pages/onboarding_flow/onboarding_flow_screen.dart';
import 'package:guachinches/ui/pages/splash_screen/splash_screen_presenter.dart';
import 'package:guachinches/ui/pages/surveyDetails/surveyDetails.dart';
import 'package:guachinches/ui/pages/survey_onboarding/surveyOnboarding.dart';
import 'package:guachinches/ui/pages/update_app/update_app_screen.dart';
import 'package:http/http.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    implements SplashScreenView {
  late RemoteRepository remoteRepository;
  late SplashScreenPresenter presenter;
  Timer? _watchdog;
  bool _navigated = false;


  @override
  void initState() {
    final userCubit = context.read<UserCubit>();
    final onboardingCubit = context.read<OnboardingCubit>();
    remoteRepository = HttpRemoteRepository(Client());
    presenter = SplashScreenPresenter(
        this, remoteRepository, userCubit, onboardingCubit);
    presenter.getUserInfo();

    // Watchdog: si en 12s no se ha navegado, forzamos el flujo principal
    // para evitar que el splash quede colgado por una respuesta del
    // backend que no llega. El presenter ya tiene timeouts en getVersion,
    // pero esto cubre cualquier futuro await sin timeout en la cadena.
    _watchdog = Timer(const Duration(seconds: 12), () {
      if (_navigated || !mounted) return;
      AppLogger.warn('splash', 'watchdog_fired forcing_main_function');
      presenter.mainFunction();
    });

    super.initState();
  }

  @override
  void dispose() {
    _watchdog?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
      child: Container(
        color: Colors.white,
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        padding: EdgeInsets.symmetric(horizontal: 40.0),
        alignment: Alignment.center,
        child: Image(
          image: AssetImage("assets/images/logoGrande.png"),
          fit: BoxFit.cover,
          height: MediaQuery.of(context).size.width - 80,
        ),
      ),
    ));
  }

  @override
  goToMenu(List<Widget> screens) {
    if (_navigated || !mounted) return;
    _navigated = true;
    _watchdog?.cancel();
    GlobalMethods().pushAndReplacement(
      context,
      NewHomeTabScaffold(screens: screens),
    );
  }

  @override
  goToUpdateScreen() {
    if (_navigated || !mounted) return;
    _navigated = true;
    _watchdog?.cancel();
    GlobalMethods().pushAndReplacement(context, UpdateAppScreen());
  }
  @override
  goToOnBoarding() {
    if (_navigated || !mounted) return;
    _navigated = true;
    _watchdog?.cancel();
    GlobalMethods().pushAndReplacement(context, const OnboardingFlow());
  }

  @override
  goToSurveyOnboarding(List<Widget> screens) {
    if (_navigated || !mounted) return;
    _navigated = true;
    _watchdog?.cancel();
    GlobalMethods().pushAndReplacement(context, SurveyOnboarding(screens: screens));
  }
}
