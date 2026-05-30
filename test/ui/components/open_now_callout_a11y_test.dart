import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/ui/components/open_now_callout.dart';

Finder _bySemId(String id) => find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.identifier == id,
    );

Widget _wrap(Widget child) => MaterialApp(
      theme: appLightTheme,
      home: Scaffold(body: SizedBox(width: 400, child: child)),
    );

void main() {
  group('OpenNowCallout a11y', () {
    testWidgets('(a) existe exactamente un anchor home-cerca-ahora-cta',
        (tester) async {
      await tester.pumpWidget(_wrap(OpenNowCallout(
        count: 5,
        contextLabel: 'Tenerife',
        onTap: () {},
      )));
      await tester.pump();

      expect(
        _bySemId('home-cerca-ahora-cta'),
        findsOneWidget,
        reason: 'Debe existir exactamente un Semantics con identifier home-cerca-ahora-cta',
      );
    });

    testWidgets('(b) _LiveDot decorativo envuelto en ExcludeSemantics cuando count > 0',
        (tester) async {
      // Sin onTap para no renderizar el chevron Icon (que también agrega
      // ExcludeSemantics internamente), permitiendo verificar exactamente 1.
      await tester.pumpWidget(_wrap(const OpenNowCallout(
        count: 5,
        contextLabel: 'Tenerife',
      )));
      await tester.pump();

      expect(
        find.descendant(
          of: _bySemId('home-cerca-ahora-cta'),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
        reason: 'El _LiveDot decorativo debe estar envuelto en ExcludeSemantics dentro del callout',
      );
    });

    testWidgets('(c) count=0: no renderiza _LiveDot ni ExcludeSemantics en el callout',
        (tester) async {
      await tester.pumpWidget(_wrap(const OpenNowCallout(
        count: 0,
        contextLabel: 'Tenerife',
      )));
      await tester.pump();

      expect(
        find.descendant(
          of: _bySemId('home-cerca-ahora-cta'),
          matching: find.byType(ExcludeSemantics),
        ),
        findsNothing,
        reason: 'Con count=0 no hay _LiveDot, por lo que no debe haber ExcludeSemantics dentro del callout',
      );
      expect(
        _bySemId('home-cerca-ahora-cta'),
        findsOneWidget,
        reason: 'El callout sigue renderizando con count=0',
      );
    });
  });
}
