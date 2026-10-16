import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/onboarding/onboarding_cubit.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/ui/pages/splash_screen/splash_screen_presenter.dart';

class _FakeRepo extends Fake implements RemoteRepository {}

class _View implements SplashScreenView {
  final calls = <String>[];
  @override
  goToMenu(List<Widget> screens) => calls.add('menu');
  @override
  goToOnBoarding() => calls.add('onboarding');
  @override
  goToSurveyOnboarding(List<Widget> screens) => calls.add('survey');
  @override
  goToUpdateScreen() => calls.add('update');
}

/// QA multidispositivo (I1): si el arranque pasaba de 12 s, el watchdog del
/// splash iba directo al Inicio y un usuario nuevo se saltaba el onboarding.
/// Ahora pasa por [SplashScreenPresenter.continueAfterVersion].
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  SplashScreenPresenter presenter(_View v, OnboardingCubit onb) =>
      SplashScreenPresenter(v, _FakeRepo(), UserCubit(_FakeRepo()), onb);

  test('watchdog con onboarding sin hacer → onboarding', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final v = _View();
    await presenter(v, OnboardingCubit()).continueAfterVersion();
    expect(v.calls, ['onboarding']);
  });

  test('watchdog con onboarding hecho → la app', () async {
    FlutterSecureStorage.setMockInitialValues({'onBoardingFinished': 'true'});
    final v = _View();
    await presenter(v, OnboardingCubit()).continueAfterVersion();
    expect(v.calls, ['menu']);
  });
}
