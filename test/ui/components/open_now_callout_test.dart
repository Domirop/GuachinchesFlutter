import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/ui/components/open_now_callout.dart';

Finder _bySemId(String id) => find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.identifier == id,
    );

Widget _wrap(Widget child) => MaterialApp(
      theme: appLightTheme,
      darkTheme: appDarkTheme,
      home: Scaffold(body: SizedBox(width: 400, child: child)),
    );

void main() {
  group('OpenNowCallout', () {
    testWidgets('(a) count=23 muestra plural "23 sitios abiertos cerca"',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const OpenNowCallout(count: 23, contextLabel: 'Tenerife')),
      );
      await tester.pump();

      expect(_bySemId('home-cerca-ahora-cta'), findsOneWidget);
      expect(find.text('23 sitios abiertos cerca'), findsOneWidget);
      expect(find.text('ABIERTOS AHORA · TENERIFE'), findsOneWidget);
      // No debe aparecer copy del estado vacío
      expect(find.text('Sin abiertos cerca'), findsNothing);
    });

    testWidgets('(b) count=1 muestra singular "1 sitio abierto cerca"',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const OpenNowCallout(count: 1, contextLabel: 'La Gomera')),
      );
      await tester.pump();
      expect(find.text('1 sitio abierto cerca'), findsOneWidget);
      expect(find.text('ABIERTOS AHORA · LA GOMERA'), findsOneWidget);
    });

    testWidgets('(c) count=0 muestra estado vacío con tono "abre pronto"',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const OpenNowCallout(count: 0, contextLabel: 'El Hierro')),
      );
      await tester.pump();
      expect(find.text('Sin abiertos cerca'), findsOneWidget);
      expect(find.text('ABRE PRONTO · EL HIERRO'), findsOneWidget);
      // Cuando count=0 no hay LIVE dot (eyebrow sin punto verde)
      expect(find.text('ABIERTOS AHORA · EL HIERRO'), findsNothing);
    });

    testWidgets('(d) count>99 colapsa a copy "Muchos abiertos cerca"',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const OpenNowCallout(count: 124, contextLabel: 'Tenerife')),
      );
      await tester.pump();
      expect(find.text('Muchos abiertos cerca'), findsOneWidget);
      expect(find.text('124 sitios abiertos cerca'), findsNothing);
    });

    testWidgets('(e) tap invoca onTap', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        _wrap(OpenNowCallout(
          count: 5,
          contextLabel: 'Tenerife',
          onTap: () => tapped++,
        )),
      );
      await tester.pump();
      await tester.tap(_bySemId('home-cerca-ahora-cta'));
      expect(tapped, 1);
    });

    testWidgets('(f) sin onTap el callout no tiene chevron de acción',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const OpenNowCallout(count: 5, contextLabel: 'Tenerife')),
      );
      await tester.pump();
      expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
    });
  });
}
