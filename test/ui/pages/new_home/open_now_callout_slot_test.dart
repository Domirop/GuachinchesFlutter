import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/data/cubit/location/location_cubit.dart';
import 'package:guachinches/data/cubit/location/location_state.dart';
import 'package:guachinches/ui/pages/new_home/widgets/open_now_callout_slot.dart';

Finder _bySemId(String id) => find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.identifier == id,
    );

class _FakeLocationCubit extends Cubit<LocationState> implements LocationCubit {
  _FakeLocationCubit(LocationState initial) : super(initial);

  @override
  Future<void> requestLocation() async {}

  @override
  Future<void> checkLocationSilently() async {}
}

Widget _wrap(Widget child, _FakeLocationCubit cubit) {
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
  group('OpenNowCalloutSlot', () {
    testWidgets(
        '(a) bootstrapLoading=true → skeleton presente, cta ausente',
        (tester) async {
      final cubit = _FakeLocationCubit(LocationInitial());
      await tester.pumpWidget(_wrap(
        const OpenNowCalloutSlot(
          bootstrapLoading: true,
          count: 5,
          contextLabel: 'Tenerife',
        ),
        cubit,
      ));
      await tester.pump();
      expect(_bySemId('home-cerca-ahora-skeleton'), findsOneWidget);
      expect(_bySemId('home-cerca-ahora-cta'), findsNothing);
    });

    testWidgets(
        '(b) bootstrapLoading=false + LocationDenied → ambos anchors ausentes',
        (tester) async {
      final cubit = _FakeLocationCubit(LocationDenied());
      await tester.pumpWidget(_wrap(
        const OpenNowCalloutSlot(
          bootstrapLoading: false,
          count: 5,
          contextLabel: 'Tenerife',
        ),
        cubit,
      ));
      await tester.pump();
      expect(_bySemId('home-cerca-ahora-skeleton'), findsNothing);
      expect(_bySemId('home-cerca-ahora-cta'), findsNothing);
    });

    testWidgets(
        '(c) bootstrapLoading=false + LocationPermanentlyDenied → ambos anchors ausentes',
        (tester) async {
      final cubit = _FakeLocationCubit(LocationPermanentlyDenied());
      await tester.pumpWidget(_wrap(
        const OpenNowCalloutSlot(
          bootstrapLoading: false,
          count: 5,
          contextLabel: 'Tenerife',
        ),
        cubit,
      ));
      await tester.pump();
      expect(_bySemId('home-cerca-ahora-skeleton'), findsNothing);
      expect(_bySemId('home-cerca-ahora-cta'), findsNothing);
    });

    testWidgets(
        '(d) bootstrapLoading=false + LocationLoaded + count=5 → cta presente con texto correcto',
        (tester) async {
      final cubit = _FakeLocationCubit(
        LocationLoaded(latitude: 28, longitude: -16),
      );
      await tester.pumpWidget(_wrap(
        const OpenNowCalloutSlot(
          bootstrapLoading: false,
          count: 5,
          contextLabel: 'Tenerife',
        ),
        cubit,
      ));
      await tester.pump();
      expect(_bySemId('home-cerca-ahora-cta'), findsOneWidget);
      expect(find.text('5 sitios abiertos cerca'), findsOneWidget);
    });

    testWidgets(
        '(e) bootstrapLoading=false + LocationUnavailable + count=3 → cta presente',
        (tester) async {
      final cubit = _FakeLocationCubit(LocationUnavailable());
      await tester.pumpWidget(_wrap(
        const OpenNowCalloutSlot(
          bootstrapLoading: false,
          count: 3,
          contextLabel: 'La Palma',
        ),
        cubit,
      ));
      await tester.pump();
      expect(_bySemId('home-cerca-ahora-cta'), findsOneWidget);
    });
  });
}
