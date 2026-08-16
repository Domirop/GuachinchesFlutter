import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/domain/occasions/occasion.dart';
import 'package:guachinches/ui/pages/new_home/widgets/occasion_planner_card.dart';

const _occ = Occasion(
  id: 'friday_brunch',
  priority: 80,
  character: 'jonay_joana',
  eyebrow: 'ESTA SEMANA EN CANARIAS',
  headline: 'Planes del finde',
  tagline: 'Brunch, romerías y playa',
  body: 'cuerpo largo para el push',
  ctaLabel: '',
  accentKey: 'finde',
);

Widget _host({required VoidCallback onTap, VoidCallback? onDismiss}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: OccasionPlannerCard(
          occasion: _occ,
          onTap: onTap,
          onDismiss: onDismiss,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('pinta header DESCUBRE PLANES, eyebrow, titular y subcopy',
      (t) async {
    await t.pumpWidget(_host(onTap: () {}));
    await t.pump();

    expect(find.text('DESCUBRE PLANES'), findsOneWidget); // header (uppercase)
    expect(find.text('ESTA SEMANA EN CANARIAS'), findsOneWidget); // eyebrow
    expect(find.text('PLANES DEL FINDE'), findsOneWidget); // titular (uppercase)
    expect(find.text('Brunch, romerías y playa'), findsOneWidget); // subcopy
  });

  testWidgets('tap en el banner dispara onTap', (t) async {
    var tapped = false;
    await t.pumpWidget(_host(onTap: () => tapped = true));
    await t.tap(find.text('PLANES DEL FINDE'));
    expect(tapped, isTrue);
  });

  testWidgets('el botón flecha también dispara onTap', (t) async {
    var taps = 0;
    await t.pumpWidget(_host(onTap: () => taps++));
    await t.tap(find.byIcon(Icons.arrow_forward_rounded)); // botón flecha
    expect(taps, 1);
  });

  testWidgets('la × cierra el banner (onDismiss) sin disparar onTap',
      (t) async {
    var tapped = false;
    var dismissed = false;
    await t.pumpWidget(_host(
      onTap: () => tapped = true,
      onDismiss: () => dismissed = true,
    ));
    await t.tap(find.byIcon(Icons.close_rounded));
    expect(dismissed, isTrue);
    expect(tapped, isFalse);
  });

  testWidgets('sin onDismiss no se pinta la ×', (t) async {
    await t.pumpWidget(_host(onTap: () {}));
    expect(find.byIcon(Icons.close_rounded), findsNothing);
  });
}
