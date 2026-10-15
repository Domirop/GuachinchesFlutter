import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/data/cubit/location/location_cubit.dart';
import 'package:guachinches/data/cubit/location/location_state.dart';
import 'package:guachinches/ui/pages/location_denied/location_denied_logic.dart';
import 'package:guachinches/ui/pages/location_denied/location_denied_screen.dart';

Finder _byId(String id) => find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.identifier == id,
    );

class _FakeLocationCubit extends Cubit<LocationState> implements LocationCubit {
  _FakeLocationCubit(super.initial);

  void set(LocationState s) => emit(s);

  @override
  Future<void> requestPermissionOnly() async {}

  @override
  Future<void> requestLocation() async {}

  @override
  Future<void> checkLocationSilently() async {}

  @override
  Future<void> syncPermissionState() async {}
}

Future<void> _pump(WidgetTester tester, _FakeLocationCubit cubit,
    {required bool isIOS, ThemeData? theme}) async {
  tester.view.physicalSize = const Size(402 * 3, 874 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(BlocProvider<LocationCubit>.value(
    value: cubit,
    child: MaterialApp(
      theme: theme ?? appLightTheme,
      builder: (ctx, c) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(disableAnimations: true),
        child: c!,
      ),
      home: Builder(
        builder: (ctx) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(ctx).push(MaterialPageRoute<void>(
                builder: (_) => LocationDeniedScreen(isIOSOverride: isIOS),
              )),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

void main() {
  group('lógica', () {
    test('variante según el estado', () {
      expect(locationDeniedVariantFor(LocationServiceDisabled()),
          LocationDeniedVariant.service);
      expect(locationDeniedVariantFor(LocationPermanentlyDenied()),
          LocationDeniedVariant.permission);
      expect(locationDeniedVariantFor(LocationDenied()),
          LocationDeniedVariant.permission);
    });

    test('iOS: «Localización» y los pasos del tablero', () {
      final p =
          locationDeniedCopy(LocationDeniedVariant.permission, isIOS: true);
      expect(p.steps.map((s) => s.label), [
        'Toca «Localización»',
        'Elige «Cuando se use la app»',
        'Activa «Ubicación exacta»',
      ]);
      expect(p.footnote, isNotNull);
      final s = locationDeniedCopy(LocationDeniedVariant.service, isIOS: true);
      expect(s.steps.map((x) => x.label), [
        'Abre Ajustes',
        'Privacidad y seguridad',
        'Localización',
        'Activa «Localización»',
      ]);
      expect(s.steps.last.toggle, isTrue);
      // En iOS nunca «Servicios de Ubicación» ni «Ubicación» a secas en los
      // pasos de servicio.
      expect(s.eyebrow, contains('Localización'));
    });

    test('Android: nunca «iPhone»', () {
      for (final v in LocationDeniedVariant.values) {
        final c = locationDeniedCopy(v, isIOS: false);
        final all = [c.eyebrow, c.title, c.text, ...c.steps.map((s) => s.label)]
            .join(' ');
        expect(all, isNot(contains('iPhone')));
      }
    });
  });

  group('pantalla', () {
    testWidgets('permiso (iOS): pasos en lista agrupada y botones',
        (tester) async {
      final cubit = _FakeLocationCubit(LocationPermanentlyDenied());
      await _pump(tester, cubit, isIOS: true);
      expect(_byId('location-denied-screen'), findsOneWidget);
      expect(find.text('Deja que veamos dónde estás'), findsOneWidget);
      expect(find.text('Toca «Localización»'), findsOneWidget);
      expect(_byId('location-denied-open-settings'), findsOneWidget);
      expect(find.text('Ahora no'), findsOneWidget);
      await cubit.close();
    });

    testWidgets('servicio (Android, noche): sin «iPhone»', (tester) async {
      final cubit = _FakeLocationCubit(LocationServiceDisabled());
      await _pump(tester, cubit, isIOS: false, theme: appDarkTheme);
      expect(find.text('Activa la ubicación'), findsOneWidget);
      expect(find.textContaining('iPhone'), findsNothing);
      await cubit.close();
    });

    testWidgets('«Ahora no» cierra y con permiso concedido se cierra sola',
        (tester) async {
      final cubit = _FakeLocationCubit(LocationPermanentlyDenied());
      await _pump(tester, cubit, isIOS: true);
      await tester.tap(_byId('location-denied-later'));
      await tester.pumpAndSettle();
      expect(_byId('location-denied-screen'), findsNothing);

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(_byId('location-denied-screen'), findsOneWidget);
      cubit.set(LocationLoaded(latitude: 28.4, longitude: -16.3));
      await tester.pumpAndSettle();
      expect(_byId('location-denied-screen'), findsNothing);
      await cubit.close();
    });
  });
}
