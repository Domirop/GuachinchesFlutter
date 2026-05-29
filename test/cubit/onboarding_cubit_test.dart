import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/cubit/onboarding/onboarding_cubit.dart';
import 'package:guachinches/data/cubit/onboarding/onboarding_state.dart';

/// In-memory fake for FlutterSecureStorage. No platform channel involved.
class _InMemoryStorage extends Fake implements FlutterSecureStorage {
  final map = <String, String>{};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      map[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      map[key] = value;
    } else {
      map.remove(key);
    }
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    map.remove(key);
  }
}

void main() {
  group('OnboardingCubit', () {
    test('(a) hydrate with empty storage → OnboardingLoaded with defaults',
        () async {
      final store = _InMemoryStorage();
      final cubit = OnboardingCubit(storage: store);

      await cubit.hydrate();

      final state = cubit.state as OnboardingLoaded;
      expect(state.data.finished, false);
      expect(state.data.name, null);
      expect(state.data.islandId, null);
      expect(state.data.tastes, isEmpty);
      expect(state.data.locationAsked, false);
      expect(state.data.surveyShown, false);
      expect(cubit.isFinished, false);
    });

    test('(b) hydrate with all 6 flags present → correct values including CSV',
        () async {
      final store = _InMemoryStorage()
        ..map['onBoardingFinished'] = 'true'
        ..map['onb_name'] = 'Ale'
        ..map['prefIslandId'] = 'island-abc'
        ..map['prefTastes'] = 'carne,pescado'
        ..map['prefLocationAsked'] = 'true'
        ..map['surveyOnboarding2026Shown'] = 'true';
      final cubit = OnboardingCubit(storage: store);

      await cubit.hydrate();

      final data = (cubit.state as OnboardingLoaded).data;
      expect(data.finished, true);
      expect(data.name, 'Ale');
      expect(data.islandId, 'island-abc');
      expect(data.tastes, ['carne', 'pescado']);
      expect(data.tastes.length, 2);
      expect(data.locationAsked, true);
      expect(data.surveyShown, true);
      expect(cubit.isFinished, true);
    });

    test('(c) setName writes to storage and emits state with name', () async {
      final store = _InMemoryStorage();
      final cubit = OnboardingCubit(storage: store);
      await cubit.hydrate();

      await cubit.setName('Jonay');

      expect(store.map['onb_name'], 'Jonay');
      final data = (cubit.state as OnboardingLoaded).data;
      expect(data.name, 'Jonay');
    });

    test(
        "(d) setTastes(['carne','pescado']) saves 'carne,pescado' in storage "
        'and emits state with 2 elements', () async {
      final store = _InMemoryStorage();
      final cubit = OnboardingCubit(storage: store);
      await cubit.hydrate();

      await cubit.setTastes(['carne', 'pescado']);

      expect(store.map['prefTastes'], 'carne,pescado');
      final data = (cubit.state as OnboardingLoaded).data;
      expect(data.tastes, ['carne', 'pescado']);
      expect(data.tastes.length, 2);
    });

    test('(e) markFinished sets finished=true in state and storage', () async {
      final store = _InMemoryStorage();
      final cubit = OnboardingCubit(storage: store);
      await cubit.hydrate();

      expect(cubit.isFinished, false);
      await cubit.markFinished();

      expect(store.map['onBoardingFinished'], 'true');
      expect((cubit.state as OnboardingLoaded).data.finished, true);
      expect(cubit.isFinished, true);
    });

    test('(f) reset deletes all 6 flags and emits OnboardingLoaded with defaults',
        () async {
      final store = _InMemoryStorage()
        ..map.addAll({
          'onBoardingFinished': 'true',
          'onb_name': 'Ale',
          'prefIslandId': 'island-1',
          'prefTastes': 'carne',
          'prefLocationAsked': 'true',
          'surveyOnboarding2026Shown': 'true',
        });
      final cubit = OnboardingCubit(storage: store);
      await cubit.hydrate();

      await cubit.reset();

      expect(store.map.containsKey('onBoardingFinished'), false);
      expect(store.map.containsKey('onb_name'), false);
      expect(store.map.containsKey('prefIslandId'), false);
      expect(store.map.containsKey('prefTastes'), false);
      expect(store.map.containsKey('prefLocationAsked'), false);
      expect(store.map.containsKey('surveyOnboarding2026Shown'), false);

      final data = (cubit.state as OnboardingLoaded).data;
      expect(data.finished, false);
      expect(data.name, null);
      expect(data.islandId, null);
      expect(data.tastes, isEmpty);
      expect(data.locationAsked, false);
      expect(data.surveyShown, false);
      expect(cubit.isFinished, false);
    });

    test(
        '(g) backwards-compat: only onBoardingFinished=true present → '
        'finished=true, all others default', () async {
      final store = _InMemoryStorage()
        ..map['onBoardingFinished'] = 'true';
      final cubit = OnboardingCubit(storage: store);

      await cubit.hydrate();

      final data = (cubit.state as OnboardingLoaded).data;
      expect(data.finished, true);
      expect(data.name, null);
      expect(data.islandId, null);
      expect(data.tastes, isEmpty);
      expect(data.locationAsked, false);
      expect(data.surveyShown, false);
    });
  });
}
