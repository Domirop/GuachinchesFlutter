import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/cubit/onboarding/onboarding_cubit.dart';
import 'package:guachinches/data/cubit/theme/theme_cubit.dart';
import 'package:guachinches/services/app_storage.dart';

/// B1 (QA Android): con `flutter_secure_storage` 9.2.4 en Android no se
/// pueden mezclar dos configuraciones; todo pasa por [AppStorage.instance] y
/// al arrancar se migra lo que quede en el almacén por defecto. La prueba en
/// el emulador está en el informe; aquí, la lógica y que nadie se salte la
/// puerta.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('migración desde el almacén por defecto (4.5.4)', () {
    test('copia lo que falta, no pisa lo que hay y vacía el antiguo', () async {
      final from = _MapStorage({'onBoardingFinished': 'true', 'userId': 'u-2'});
      final to = _MapStorage({'userId': 'u-nuevo', 'themeMode': 'dark'});
      await AppStorage.migrateLegacy(android: true, from: from, to: to);
      expect(to.values, {
        'onBoardingFinished': 'true',
        'userId': 'u-nuevo',
        'themeMode': 'dark',
      });
      expect(from.values, isEmpty);
    });

    test('sin nada que migrar no toca el almacén cifrado', () async {
      final from = _MapStorage({});
      final to = _MapStorage({'userId': 'u-1'});
      await AppStorage.migrateLegacy(android: true, from: from, to: to);
      expect(to.values, {'userId': 'u-1'});
      expect(to.writes, 0);
    });

    test('en iOS no hay nada que mover', () async {
      final from = _MapStorage({'a': '1'});
      final to = _MapStorage({});
      await AppStorage.migrateLegacy(android: false, from: from, to: to);
      expect(to.values, isEmpty);
      expect(from.values, {'a': '1'});
    });
  });

  test('arranque en frío: conserva onBoardingFinished, userId y el tema',
      () async {
    FlutterSecureStorage.setMockInitialValues({});
    // Primer arranque: onboarding hecho, sesión iniciada y tema oscuro.
    final first = OnboardingCubit();
    await first.hydrate();
    await first.markFinished();
    await AppStorage.instance.write(key: 'userId', value: 'u-test-1');
    await ThemeCubit(ThemeMode.light).setMode(ThemeMode.dark);
    await first.close();

    // Arranque en frío, en el orden de main(): migración, tema y onboarding.
    await AppStorage.migrateLegacy();
    expect(await ThemeCubit.hydrate(), ThemeMode.dark);
    final again = OnboardingCubit();
    await again.hydrate();
    expect(again.isFinished, isTrue);
    expect(await AppStorage.instance.read(key: 'userId'), 'u-test-1');
    await again.close();
  });

  test('nada usa FlutterSecureStorage salvo AppStorage y la identidad de la '
      'encuesta', () {
    final hits = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      if (f.path.endsWith('services/app_storage.dart') ||
          f.path.endsWith('survey_integrity/survey_integrity.dart')) {
        continue;
      }
      if (RegExp(r'FlutterSecureStorage\s*\(').hasMatch(f.readAsStringSync())) {
        hits.add(f.path);
      }
    }
    expect(hits, isEmpty);
    // La identidad de la encuesta va al mismo almacén cifrado en Android.
    final survey = File('lib/services/survey_integrity/survey_integrity.dart')
        .readAsStringSync();
    expect(survey, contains('aOptions: AppStorage.androidOptions'));
  });
}

/// Almacén en memoria para ver la copia de [AppStorage.migrateLegacy].
class _MapStorage implements FlutterSecureStorage {
  final Map<String, String> values;
  int writes = 0;
  _MapStorage(Map<String, String> v) : values = {...v};

  @override
  Future<Map<String, String>> readAll(
          {IOSOptions? iOptions,
          AndroidOptions? aOptions,
          LinuxOptions? lOptions,
          WebOptions? webOptions,
          MacOsOptions? mOptions,
          WindowsOptions? wOptions}) async =>
      {...values};

  @override
  Future<String?> read(
          {required String key,
          IOSOptions? iOptions,
          AndroidOptions? aOptions,
          LinuxOptions? lOptions,
          WebOptions? webOptions,
          MacOsOptions? mOptions,
          WindowsOptions? wOptions}) async =>
      values[key];

  @override
  Future<void> write(
      {required String key,
      required String? value,
      IOSOptions? iOptions,
      AndroidOptions? aOptions,
      LinuxOptions? lOptions,
      WebOptions? webOptions,
      MacOsOptions? mOptions,
      WindowsOptions? wOptions}) async {
    writes++;
    if (value != null) values[key] = value;
  }

  @override
  Future<void> delete(
      {required String key,
      IOSOptions? iOptions,
      AndroidOptions? aOptions,
      LinuxOptions? lOptions,
      WebOptions? webOptions,
      MacOsOptions? mOptions,
      WindowsOptions? wOptions}) async {
    values.remove(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
