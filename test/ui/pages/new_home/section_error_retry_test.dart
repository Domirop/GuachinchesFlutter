import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/ui/pages/new_home/widgets/section_error_retry.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData.dark().copyWith(extensions: const [BrandColors.dark]),
      home: Scaffold(body: child),
    );

Finder _bySemanticsId(String id) => find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.identifier == id,
    );

void main() {
  testWidgets(
    'SectionErrorRetry renders message, exposes anchor, and invokes onRetry on tap',
    (tester) async {
      int callCount = 0;
      const anchor = 'home-curated-retry';
      const message = 'No pudimos cargar esta sección';

      await tester.pumpWidget(
        _wrap(SectionErrorRetry(
          message: message,
          retryAnchor: anchor,
          onRetry: () => callCount++,
        )),
      );

      expect(find.text(message), findsOneWidget);

      final anchorFinder = _bySemanticsId(anchor);
      expect(anchorFinder, findsOneWidget);

      await tester.tap(anchorFinder);
      await tester.pump();
      expect(callCount, 1);
    },
  );
}
