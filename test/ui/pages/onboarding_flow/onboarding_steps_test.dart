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
import 'package:guachinches/ui/pages/onboarding_flow/widgets/onboarding_island_step.dart';
import 'package:guachinches/ui/pages/onboarding_flow/widgets/onboarding_location_step.dart';
import 'package:guachinches/ui/pages/onboarding_flow/widgets/onboarding_tastes_step.dart';

import 'onboarding_logic_test.dart' show kRealCategories;

Finder _byId(String id) => find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.identifier == id,
    );

class _FakeRepo extends Fake implements RemoteRepository {}

class _StubIslandsCubit extends IslandsCubit {
  int loads = 0;
  _StubIslandsCubit(IslandsState s) : super(_FakeRepo()) {
    emit(s);
  }

  @override
  Future<void> load() async => loads++;
}

class _FakeLocationCubit extends Cubit<LocationState> implements LocationCubit {
  final LocationState after;
  _FakeLocationCubit(this.after) : super(LocationInitial());

  @override
  Future<void> requestPermissionOnly() async => emit(after);

  @override
  Future<void> requestLocation() async {}

  @override
  Future<void> checkLocationSilently() async {}

  @override
  Future<void> syncPermissionState() async {}
}

class _FakeOnboardingCubit extends OnboardingCubit {
  bool asked = false;
  @override
  Future<void> markLocationAsked() async => asked = true;
}

final _islands = [
  Island('tf', '', 'Tenerife', key: 'TF', position: 1),
  Island('gc', '', 'Gran Canaria', key: 'GC', position: 2),
  Island('lz', '', 'Lanzarote', key: 'LZ', position: 3),
];

/// Con «reducir movimiento» (GmOnce va al fotograma final, sin timers).
Future<void> _pump(WidgetTester tester, Widget child,
    {List<BlocProvider> providers = const [],
    ThemeData? theme,
    bool reduceMotion = true}) async {
  tester.view.physicalSize = const Size(402 * 3, 874 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  Widget app = MaterialApp(
    theme: theme ?? appLightTheme,
    builder: (ctx, c) => MediaQuery(
      data: MediaQuery.of(ctx).copyWith(disableAnimations: reduceMotion),
      child: c!,
    ),
    home: child,
  );
  if (providers.isNotEmpty) {
    app = MultiBlocProvider(providers: providers, child: app);
  }
  await tester.pumpWidget(app);
  await tester.pump();
}

void main() {
  group('paso 1 · isla', () {
    testWidgets('lista agrupada con insignias, radio y sin saludo por nombre',
        (tester) async {
      Island? picked;
      var called = false;
      await _pump(
        tester,
        OnboardingIslandStep(
          selectedId: null,
          onBack: () {},
          onContinue: (i) {
            called = true;
            picked = i;
          },
        ),
        providers: [
          BlocProvider<IslandsCubit>(
              create: (_) => _StubIslandsCubit(IslandsLoaded(_islands))),
        ],
      );
      expect(find.text('¿En qué isla estás?'), findsOneWidget);
      expect(find.text('Paso 1 de 4'), findsOneWidget);
      expect(find.text('TF'), findsOneWidget);
      expect(find.text('Gran Canaria'), findsOneWidget);
      // Sin isla elegida: botón deshabilitado «Elige una isla».
      expect(find.text('Elige una isla'), findsOneWidget);
      await tester.tap(_byId('onboarding-continue'));
      expect(called, isFalse);

      await tester.tap(_byId('onboarding-island-gc'));
      await tester.pump();
      expect(find.text('Continuar'), findsOneWidget);
      await tester.tap(_byId('onboarding-continue'));
      expect(picked?.id, 'gc');
    });

    testWidgets(
        'error: «Reintentar» recarga y el botón pasa a «Elegir más '
        'tarde»', (tester) async {
      final cubit = _StubIslandsCubit(IslandsFailure('x'));
      var called = false;
      Island? picked = _islands.first;
      await _pump(
        tester,
        OnboardingIslandStep(
          selectedId: null,
          onBack: () {},
          onContinue: (i) {
            called = true;
            picked = i;
          },
        ),
        providers: [BlocProvider<IslandsCubit>.value(value: cubit)],
      );
      expect(_byId('onboarding-island-error'), findsOneWidget);
      await tester.tap(_byId('onboarding-island-retry'));
      expect(cubit.loads, 1);
      expect(find.text('Elegir más tarde'), findsOneWidget);
      await tester.tap(_byId('onboarding-continue'));
      expect(called, isTrue);
      expect(picked, isNull);
    });

    testWidgets('cargando: esqueleto y «Continuar» deshabilitado',
        (tester) async {
      await _pump(
        tester,
        OnboardingIslandStep(
            selectedId: null, onBack: () {}, onContinue: (_) {}),
        providers: [
          BlocProvider<IslandsCubit>(
              create: (_) => _StubIslandsCubit(IslandsLoading())),
        ],
      );
      expect(_byId('onboarding-island-loading'), findsOneWidget);
      expect(find.text('Continuar'), findsOneWidget);
    });
  });

  group('paso 2 · gustos', () {
    testWidgets('tres grupos, mínimo 3 y contador', (tester) async {
      Set<String>? out;
      await _pump(
        tester,
        OnboardingTastesStep(
          selected: const {},
          loadCategories: () async => kRealCategories,
          onBack: () {},
          onContinue: (s) => out = s,
        ),
        theme: appDarkTheme,
      );
      await tester.pump();
      expect(find.text('Me gusta comer'), findsOneWidget);
      expect(find.text('Planes que me tiran'), findsOneWidget);
      expect(find.text('Servicios que valoro'), findsOneWidget);
      expect(find.text('Papas, piña y costillas'), findsOneWidget);
      expect(find.text('Elige 3 más'), findsOneWidget);

      for (final id in ['1', '2', '9']) {
        await tester.ensureVisible(_byId('onboarding-taste-$id'));
        await tester.tap(_byId('onboarding-taste-$id'));
        await tester.pump();
      }
      expect(find.text('3 elegidos'), findsOneWidget);
      expect(find.text('Continuar'), findsOneWidget);
      await tester.tap(_byId('onboarding-continue'));
      expect(out, {'1', '2', '9'});
    });

    testWidgets('error: «Saltar este paso» continúa sin gustos',
        (tester) async {
      Set<String>? out;
      await _pump(
        tester,
        OnboardingTastesStep(
          selected: const {},
          loadCategories: () async => throw Exception('offline'),
          onBack: () {},
          onContinue: (s) => out = s,
        ),
      );
      await tester.pump();
      expect(_byId('onboarding-tastes-error'), findsOneWidget);
      expect(find.text('Saltar este paso'), findsOneWidget);
      await tester.tap(_byId('onboarding-continue'));
      expect(out, isEmpty);
    });
  });

  group('paso 3 · ubicación', () {
    testWidgets('denegado → «Sin ubicación, de momento» + «Continuar»',
        (tester) async {
      final onb = _FakeOnboardingCubit();
      var continued = 0;
      await _pump(
        tester,
        OnboardingLocationStep(
          islandName: 'Tenerife',
          onBack: () {},
          onContinue: () => continued++,
        ),
        providers: [
          BlocProvider<LocationCubit>(
              create: (_) => _FakeLocationCubit(LocationPermanentlyDenied())),
          BlocProvider<OnboardingCubit>.value(value: onb),
        ],
      );
      expect(find.text('Lo bueno, cerca de ti'), findsOneWidget);
      expect(find.text('Solo mientras usas la app.'), findsOneWidget);
      expect(find.text('Ahora no'), findsOneWidget);

      await tester.tap(_byId('onboarding-continue'));
      await tester.pump();
      await tester.pump();
      expect(onb.asked, isTrue);
      expect(continued, 0);
      expect(find.text('Sin ubicación, de momento'), findsOneWidget);
      expect(find.textContaining('lo mejor de Tenerife'), findsOneWidget);
      expect(find.text('Ahora no'), findsNothing);
      await tester.tap(_byId('onboarding-continue'));
      expect(continued, 1);
    });

    testWidgets('concedido → sigue al paso siguiente', (tester) async {
      var continued = 0;
      await _pump(
        tester,
        OnboardingLocationStep(
          islandName: null,
          onBack: () {},
          onContinue: () => continued++,
        ),
        providers: [
          BlocProvider<LocationCubit>(
              create: (_) => _FakeLocationCubit(LocationLoading())),
          BlocProvider<OnboardingCubit>(create: (_) => _FakeOnboardingCubit()),
        ],
      );
      await tester.tap(_byId('onboarding-continue'));
      await tester.pump();
      await tester.pump();
      expect(continued, 1);
    });

    testWidgets('las chinchetas caen una vez y se paran (sin bucles)',
        (tester) async {
      await _pump(
        tester,
        OnboardingLocationStep(
            islandName: null, onBack: () {}, onContinue: () {}),
        providers: [
          BlocProvider<LocationCubit>(
              create: (_) => _FakeLocationCubit(LocationLoading())),
          BlocProvider<OnboardingCubit>(create: (_) => _FakeOnboardingCubit()),
        ],
        reduceMotion: false,
      );
      await tester.pump(const Duration(seconds: 3));
      // Si quedara una animación perpetua, pumpAndSettle no terminaría.
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}
