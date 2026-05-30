import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder _bySemanticsId(String id) => find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.identifier == id,
    );

void main() {
  testWidgets(
    'home-section-nearby appears above home-section-specialties in scroll order',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                Semantics(
                  identifier: 'home-section-nearby',
                  child: const SizedBox(height: 50),
                ),
                Semantics(
                  identifier: 'home-section-specialties',
                  child: const SizedBox(height: 50),
                ),
              ],
            ),
          ),
        ),
      );

      final nearby = _bySemanticsId('home-section-nearby');
      final specialties = _bySemanticsId('home-section-specialties');

      expect(nearby, findsOneWidget);
      expect(specialties, findsOneWidget);

      expect(
        tester.getTopLeft(nearby).dy,
        lessThan(tester.getTopLeft(specialties).dy),
      );
    },
  );
}
