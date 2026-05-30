import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/ui/pages/new_home/widgets/skeletons.dart';

Finder _bySemId(String id) => find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.identifier == id,
    );

Widget _wrap(Widget child) => MaterialApp(
      theme: appLightTheme,
      darkTheme: appDarkTheme,
      home: Scaffold(body: SizedBox(width: 400, child: child)),
    );

void main() {
  group('OpenNowCalloutSkeleton', () {
    testWidgets('tiene anchor home-cerca-ahora-skeleton', (tester) async {
      await tester.pumpWidget(_wrap(const OpenNowCalloutSkeleton()));
      await tester.pump();
      expect(_bySemId('home-cerca-ahora-skeleton'), findsOneWidget);
    });

    testWidgets('no muestra copy "Sin abiertos cerca"', (tester) async {
      await tester.pumpWidget(_wrap(const OpenNowCalloutSkeleton()));
      await tester.pump();
      expect(find.text('Sin abiertos cerca'), findsNothing);
    });

    testWidgets('no contiene texto con "abiertos"', (tester) async {
      await tester.pumpWidget(_wrap(const OpenNowCalloutSkeleton()));
      await tester.pump();
      expect(find.textContaining('abiertos'), findsNothing);
    });

    testWidgets('no tiene ícono de acción', (tester) async {
      await tester.pumpWidget(_wrap(const OpenNowCalloutSkeleton()));
      await tester.pump();
      expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
    });
  });
}
