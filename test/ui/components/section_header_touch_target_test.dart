import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/ui/components/section_header.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData.dark().copyWith(extensions: const [BrandColors.dark]),
      home: Scaffold(body: child),
    );

Finder _bySemanticsId(String id) => find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.identifier == id,
    );

void main() {
  testWidgets(
    'SectionHeader CTA meets 44pt minimum touch target and invokes callback on tap',
    (tester) async {
      int callCount = 0;
      await tester.pumpWidget(
        _wrap(SectionHeader(
          title: 'X',
          actionLabel: 'VER',
          onAction: () => callCount++,
        )),
      );

      final ctaFinder = _bySemanticsId('section-header-cta');
      expect(ctaFinder, findsOneWidget);

      final size = tester.getSize(ctaFinder);
      expect(size.height, greaterThanOrEqualTo(44.0));
      expect(size.width, greaterThanOrEqualTo(44.0));

      await tester.tap(ctaFinder);
      await tester.pump();
      expect(callCount, 1);
    },
  );
}
