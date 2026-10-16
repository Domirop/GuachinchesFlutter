import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/location/location_cubit.dart';
import 'package:guachinches/data/cubit/location/location_state.dart';
import 'package:guachinches/data/cubit/new_home/islands_cubit.dart';
import 'package:guachinches/data/cubit/onboarding/onboarding_cubit.dart';
import 'package:guachinches/data/model/Island.dart';
import 'package:guachinches/ui/pages/location_denied/location_denied_screen.dart';
import 'package:guachinches/ui/pages/onboarding_flow/onboarding_flow_screen.dart';
import 'package:guachinches/ui/pages/onboarding_flow/widgets/onboarding_island_step.dart';
import 'package:guachinches/ui/pages/onboarding_flow/widgets/onboarding_location_step.dart';
import 'package:guachinches/ui/pages/onboarding_flow/widgets/onboarding_tastes_step.dart';

import 'onboarding_logic_test.dart' show kRealCategories;

/// QA multidispositivo (B1): en un Nexus S (320×533 dp) la bienvenida
/// desbordaba 155 px y «Empezar» quedaba fuera de pantalla, sin scroll. Cada
/// paso del onboarding y la pantalla de ubicación denegada, a 320×533 con el
/// texto a 1,0 y a 1,3: sin desbordes y con el botón principal en pantalla.

Finder _byId(String id) => find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.identifier == id,
    );

class _FakeRepo extends Fake implements RemoteRepository {}

class _StubIslandsCubit extends IslandsCubit {
  _StubIslandsCubit(IslandsState s) : super(_FakeRepo()) {
    emit(s);
  }
  @override
  Future<void> load() async {}
}

class _FakeLocationCubit extends Cubit<LocationState> implements LocationCubit {
  _FakeLocationCubit(super.initial);
  @override
  Future<void> requestPermissionOnly() async {}
  @override
  Future<void> requestLocation() async {}
  @override
  Future<void> checkLocationSilently() async {}
  @override
  Future<void> syncPermissionState() async {}
}

const _small = Size(320, 533);

Future<void> _pump(WidgetTester tester, Widget child, double scale) async {
  tester.view.physicalSize = _small * 1.5;
  tester.view.devicePixelRatio = 1.5;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MultiBlocProvider(
    providers: [
      BlocProvider<IslandsCubit>(
          create: (_) => _StubIslandsCubit(IslandsLoaded([
                Island('tf', '', 'Tenerife', key: 'TF', position: 1),
                Island('gc', '', 'Gran Canaria', key: 'GC', position: 2),
                Island('lz', '', 'Lanzarote', key: 'LZ', position: 3),
              ]))),
      BlocProvider<LocationCubit>(
          create: (_) => _FakeLocationCubit(LocationPermanentlyDenied())),
      BlocProvider<OnboardingCubit>(create: (_) => OnboardingCubit()),
    ],
    child: MaterialApp(
      theme: appLightTheme,
      builder: (ctx, c) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(
          disableAnimations: true,
          textScaler: TextScaler.linear(scale),
        ),
        child: c!,
      ),
      home: child,
    ),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// El widget [f] se ve entero dentro de la pantalla.
void _onScreen(WidgetTester tester, Finder f) {
  expect(f, findsOneWidget);
  final r = tester.getRect(f);
  expect(r.top, greaterThanOrEqualTo(0));
  expect(r.bottom, lessThanOrEqualTo(_small.height + 0.5),
      reason: 'el botón queda por debajo del borde: $r');
}

void main() {
  for (final scale in [1.0, 1.3]) {
    group('320×533 · texto ${scale}x', () {
      testWidgets('bienvenida: «Empezar» visible y el resto con scroll',
          (tester) async {
        await _pump(tester, const OnboardingFlow(), scale);
        expect(tester.takeException(), isNull);
        _onScreen(tester, _byId('onboarding-welcome-start'));
        _onScreen(tester, _byId('onboarding-welcome-login'));
        // El titular se alcanza con scroll.
        await tester.drag(
            find.byKey(const ValueKey('onboarding-welcome-scroll')),
            const Offset(0, -400));
        await tester.pump();
        expect(tester.takeException(), isNull);
      });

      testWidgets('paso 1 · isla', (tester) async {
        await _pump(
            tester,
            OnboardingIslandStep(
                selectedId: null, onBack: () {}, onContinue: (_) {}),
            scale);
        expect(tester.takeException(), isNull);
        _onScreen(tester, _byId('onboarding-continue'));
      });

      testWidgets('paso 2 · gustos', (tester) async {
        await _pump(
            tester,
            OnboardingTastesStep(
              selected: const {},
              loadCategories: () async => kRealCategories,
              onBack: () {},
              onContinue: (_) {},
            ),
            scale);
        await tester.pump();
        expect(tester.takeException(), isNull);
        _onScreen(tester, _byId('onboarding-continue'));
      });

      testWidgets('paso 3 · ubicación', (tester) async {
        await _pump(
            tester,
            OnboardingLocationStep(
                islandName: 'Tenerife', onBack: () {}, onContinue: () {}),
            scale);
        expect(tester.takeException(), isNull);
        _onScreen(tester, _byId('onboarding-continue'));
      });

      testWidgets('ubicación denegada', (tester) async {
        await _pump(
            tester, const LocationDeniedScreen(isIOSOverride: false), scale);
        expect(tester.takeException(), isNull);
        _onScreen(tester, _byId('location-denied-open-settings'));
      });
    });
  }
}
