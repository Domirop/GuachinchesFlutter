import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_spacing.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/ui/components/open_now_callout.dart';
import 'package:guachinches/ui/pages/new_home/widgets/contextual_section_card.dart';

/// Finds Container widgets whose width constraint equals [width].
Finder _bandFinder(double width) => find.byWidgetPredicate(
      (w) =>
          w is Container &&
          w.constraints != null &&
          w.constraints!.minWidth == width &&
          w.constraints!.maxWidth == width,
    );

Widget _wrap(Widget child) => MaterialApp(
      theme: appLightTheme,
      darkTheme: appDarkTheme,
      home: Scaffold(body: SizedBox(width: 400, child: child)),
    );

void main() {
  group('Accent band width', () {
    // La banda lateral de ContextualSectionCard se eliminó por decisión de
    // producto (2026-06): la card "HOY EN…" ya no lleva accent band.
    testWidgets(
        'ContextualSectionCard ya NO pinta banda lateral',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const ContextualSectionCard(child: SizedBox())),
      );
      await tester.pump();

      expect(_bandFinder(AppSpacing.accentBand), findsNothing);
    });

    testWidgets(
        'OpenNowCallout exposes band with width == AppSpacing.accentBand',
        (tester) async {
      await tester.pumpWidget(
        _wrap(OpenNowCallout(
          count: 3,
          contextLabel: 'Tenerife',
          onTap: () {},
        )),
      );
      await tester.pump();

      expect(_bandFinder(AppSpacing.accentBand), findsAtLeastNWidgets(1));
    });

    testWidgets('el token accentBand sigue siendo 4 (lo usa OpenNowCallout)', (tester) async {
      expect(AppSpacing.accentBand, 4.0);
    });
  });
}
