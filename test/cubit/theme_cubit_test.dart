import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/cubit/theme/theme_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  for (final mode in ThemeMode.values) {
    test('«${mode.name}» se guarda y vuelve igual al reabrir la app', () async {
      await ThemeCubit(ThemeMode.light).setMode(mode);
      expect(await ThemeCubit.hydrate(), mode);
    });
  }

  test('sin nada guardado arranca en claro', () async {
    expect(await ThemeCubit.hydrate(), ThemeMode.light);
  });
}
