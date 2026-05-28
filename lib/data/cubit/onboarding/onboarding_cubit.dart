import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/data/cubit/onboarding/onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  static const _kFinished = 'onBoardingFinished';
  static const _kName = 'onb_name';
  static const _kIslandId = 'prefIslandId';
  static const _kTastes = 'prefTastes';
  static const _kLocationAsked = 'prefLocationAsked';
  static const _kSurveyShown = 'surveyOnboarding2026Shown';

  final FlutterSecureStorage _storage;

  OnboardingCubit({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  })  : _storage = storage,
        super(const OnboardingInitial());

  bool get isFinished {
    final s = state;
    return s is OnboardingLoaded && s.data.finished;
  }

  Future<void> hydrate() async {
    final finished = (await _storage.read(key: _kFinished)) == 'true';
    final nameRaw = await _storage.read(key: _kName);
    final islandIdRaw = await _storage.read(key: _kIslandId);
    final tastesRaw = await _storage.read(key: _kTastes);
    final tastes = (tastesRaw != null && tastesRaw.isNotEmpty)
        ? tastesRaw.split(',')
        : <String>[];
    final locationAsked =
        (await _storage.read(key: _kLocationAsked)) == 'true';
    final surveyShown =
        (await _storage.read(key: _kSurveyShown)) == 'true';

    emit(OnboardingLoaded(OnboardingData(
      finished: finished,
      name: (nameRaw == null || nameRaw.isEmpty) ? null : nameRaw,
      islandId:
          (islandIdRaw == null || islandIdRaw.isEmpty) ? null : islandIdRaw,
      tastes: List.unmodifiable(tastes),
      locationAsked: locationAsked,
      surveyShown: surveyShown,
    )));
  }

  Future<void> setName(String name) async {
    await _storage.write(key: _kName, value: name);
    _update((d) => OnboardingData(
          finished: d.finished,
          name: name.isEmpty ? null : name,
          islandId: d.islandId,
          tastes: d.tastes,
          locationAsked: d.locationAsked,
          surveyShown: d.surveyShown,
        ));
  }

  Future<void> setIsland(String islandId) async {
    await _storage.write(key: _kIslandId, value: islandId);
    _update((d) => OnboardingData(
          finished: d.finished,
          name: d.name,
          islandId: islandId,
          tastes: d.tastes,
          locationAsked: d.locationAsked,
          surveyShown: d.surveyShown,
        ));
  }

  Future<void> setTastes(List<String> tastes) async {
    await _storage.write(key: _kTastes, value: tastes.join(','));
    _update((d) => OnboardingData(
          finished: d.finished,
          name: d.name,
          islandId: d.islandId,
          tastes: List.unmodifiable(tastes),
          locationAsked: d.locationAsked,
          surveyShown: d.surveyShown,
        ));
  }

  Future<void> markLocationAsked() async {
    await _storage.write(key: _kLocationAsked, value: 'true');
    _update((d) => OnboardingData(
          finished: d.finished,
          name: d.name,
          islandId: d.islandId,
          tastes: d.tastes,
          locationAsked: true,
          surveyShown: d.surveyShown,
        ));
  }

  Future<void> markSurveyShown() async {
    await _storage.write(key: _kSurveyShown, value: 'true');
    _update((d) => OnboardingData(
          finished: d.finished,
          name: d.name,
          islandId: d.islandId,
          tastes: d.tastes,
          locationAsked: d.locationAsked,
          surveyShown: true,
        ));
  }

  Future<void> markFinished() async {
    await _storage.write(key: _kFinished, value: 'true');
    _update((d) => OnboardingData(
          finished: true,
          name: d.name,
          islandId: d.islandId,
          tastes: d.tastes,
          locationAsked: d.locationAsked,
          surveyShown: d.surveyShown,
        ));
  }

  Future<void> reset() async {
    await _storage.delete(key: _kFinished);
    await _storage.delete(key: _kName);
    await _storage.delete(key: _kIslandId);
    await _storage.delete(key: _kTastes);
    await _storage.delete(key: _kLocationAsked);
    await _storage.delete(key: _kSurveyShown);
    emit(const OnboardingLoaded(OnboardingData(
      finished: false,
      tastes: [],
      locationAsked: false,
      surveyShown: false,
    )));
  }

  void _update(OnboardingData Function(OnboardingData) fn) {
    final s = state;
    if (s is OnboardingLoaded) emit(OnboardingLoaded(fn(s.data)));
  }
}
