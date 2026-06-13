import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/ui/pages/new_home/widgets/hour_aware_banner.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    );

void main() {
  testWidgets('almuerzo: eyebrow + título grande + subtítulo + VER TODO',
      (tester) async {
    await tester.pumpWidget(_host(
      HourAwareBanner(
        hour: 13,
        zoneLabel: 'Tenerife',
        count: 34,
        actionLabel: 'VER TODO',
        onAction: () {},
      ),
    ));

    expect(find.text('AHORA · HORA DEL ALMUERZO'), findsOneWidget);
    expect(find.text('34 SITIOS PARA ALMORZAR'), findsOneWidget);
    expect(find.text('"Hora punta del almuerzo canario"'), findsOneWidget);
    expect(find.text('VER TODO ›'), findsOneWidget);
    // El icono emoji 🍽 del diseño anterior ya no existe.
    expect(find.text('🍽'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sobremesa: copy editorial propio', (tester) async {
    await tester.pumpWidget(_host(
      const HourAwareBanner(hour: 15, count: 12),
    ));

    expect(find.text('AHORA · LA SOBREMESA'), findsOneWidget);
    expect(find.text('12 SITIOS PARA LA SOBREMESA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('singular: 1 sitio (sin pluralizar)', (tester) async {
    await tester.pumpWidget(_host(
      const HourAwareBanner(hour: 21, count: 1),
    ));

    expect(find.text('1 SITIO PARA CENAR'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('count null (carga): título sin cifra', (tester) async {
    await tester.pumpWidget(_host(
      const HourAwareBanner(hour: 13),
    ));

    expect(find.text('SITIOS PARA ALMORZAR'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('openingSoon: dot ámbar y copy "abren pronto"', (tester) async {
    await tester.pumpWidget(_host(
      const HourAwareBanner(
        hour: 12,
        zoneLabel: 'El Hierro',
        count: 3,
        mode: HourBannerMode.openingSoon,
      ),
    ));

    expect(find.text('EN BREVE · EN EL HIERRO'), findsOneWidget);
    expect(find.text('3 SITIOS ABREN PRONTO'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
