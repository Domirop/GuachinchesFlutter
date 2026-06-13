import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/data/cubit/location/location_cubit.dart';
import 'package:guachinches/data/cubit/location/location_state.dart';
import 'package:guachinches/ui/components/location_prompt_banner.dart';

Finder _bySemId(String id) => find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.identifier == id,
    );

/// Fake cubit con un estado fijo. Evita depender de la API real de geolocator
/// en widget tests, que no responde correctamente al stub de método nativo.
class _FakeLocationCubit extends Cubit<LocationState> implements LocationCubit {
  _FakeLocationCubit(LocationState initial) : super(initial);

  int requestCalls = 0;
  int silentCalls = 0;

  @override
  Future<void> requestLocation() async {
    requestCalls++;
  }

  @override
  Future<void> requestPermissionOnly() async {
    requestCalls++;
  }

  @override
  Future<void> checkLocationSilently() async {
    silentCalls++;
  }
}

Widget _wrap(Widget child, LocationState state, _FakeLocationCubit cubit) {
  return MaterialApp(
    theme: appLightTheme,
    darkTheme: appDarkTheme,
    home: BlocProvider<LocationCubit>.value(
      value: cubit,
      child: Scaffold(body: SizedBox(width: 400, child: child)),
    ),
  );
}

void main() {
  group('LocationPromptBanner', () {
    testWidgets('(a) LocationLoaded → no renderiza nada', (tester) async {
      final cubit = _FakeLocationCubit(
        LocationLoaded(latitude: 28.0, longitude: -16.5),
      );
      await tester.pumpWidget(_wrap(
        const LocationPromptBanner(),
        cubit.state,
        cubit,
      ));
      await tester.pump();
      expect(_bySemId('home-location-prompt'), findsNothing);
    });

    testWidgets('(b) LocationInitial → no renderiza nada', (tester) async {
      final cubit = _FakeLocationCubit(LocationInitial());
      await tester.pumpWidget(_wrap(
        const LocationPromptBanner(),
        cubit.state,
        cubit,
      ));
      await tester.pump();
      expect(_bySemId('home-location-prompt'), findsNothing);
    });

    testWidgets('(c) LocationDenied base → renderiza banner "Activar"',
        (tester) async {
      final cubit = _FakeLocationCubit(LocationDenied());
      await tester.pumpWidget(_wrap(
        const LocationPromptBanner(),
        cubit.state,
        cubit,
      ));
      await tester.pump();
      expect(_bySemId('home-location-prompt'), findsOneWidget);
      expect(find.text('ACTIVAR UBICACIÓN'), findsOneWidget);
      expect(find.text('Activar'), findsOneWidget);
    });

    testWidgets(
        '(d) LocationDenied base → tap llama requestLocation (modal nativo)',
        (tester) async {
      final cubit = _FakeLocationCubit(LocationDenied());
      await tester.pumpWidget(_wrap(
        const LocationPromptBanner(),
        cubit.state,
        cubit,
      ));
      await tester.pump();
      await tester.tap(_bySemId('home-location-prompt'));
      await tester.pump();
      expect(cubit.requestCalls, 1);
    });

    testWidgets(
        '(e) LocationPermanentlyDenied → CTA dice "Ajustes" (no "Activar")',
        (tester) async {
      final cubit = _FakeLocationCubit(LocationPermanentlyDenied());
      await tester.pumpWidget(_wrap(
        const LocationPromptBanner(),
        cubit.state,
        cubit,
      ));
      await tester.pump();
      expect(find.text('Ajustes'), findsOneWidget);
      expect(find.text('Activar'), findsNothing);
      expect(find.text('PERMISO BLOQUEADO'), findsOneWidget);
    });

    testWidgets(
        '(f) LocationServiceDisabled → copy explícita "Servicios de Localización"',
        (tester) async {
      final cubit = _FakeLocationCubit(LocationServiceDisabled());
      await tester.pumpWidget(_wrap(
        const LocationPromptBanner(),
        cubit.state,
        cubit,
      ));
      await tester.pump();
      expect(find.text('UBICACIÓN APAGADA'), findsOneWidget);
      expect(find.text('Activa Servicios de Localización'), findsOneWidget);
      expect(find.text('Ajustes'), findsOneWidget);
    });

    testWidgets('(g) LocationUnavailable → no renderiza (oculto silente)',
        (tester) async {
      final cubit = _FakeLocationCubit(LocationUnavailable());
      await tester.pumpWidget(_wrap(
        const LocationPromptBanner(),
        cubit.state,
        cubit,
      ));
      await tester.pump();
      expect(_bySemId('home-location-prompt'), findsNothing);
    });
  });
}
