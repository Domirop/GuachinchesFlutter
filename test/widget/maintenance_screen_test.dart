import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/ui/pages/maintenance/maintenance_screen.dart';

void main() {
  testWidgets('MaintenanceScreen shows copy and Semantics identifier',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: MaintenanceScreen()),
    );

    expect(
      find.text('Estamos haciendo mejoras, volvemos pronto.'),
      findsOneWidget,
    );

    expect(
      find.byWidgetPredicate((widget) =>
          widget is Semantics &&
          widget.properties.identifier == 'maintenance-screen-root'),
      findsOneWidget,
    );
  });
}
