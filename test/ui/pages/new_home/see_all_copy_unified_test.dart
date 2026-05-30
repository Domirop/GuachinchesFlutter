import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/l10n/app_localizations_es.dart';
import 'package:guachinches/ui/components/section_header.dart';
import 'package:guachinches/ui/pages/new_home/widgets/hour_aware_banner.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('see_all copy unified', () {
    testWidgets('HourAwareBanner shows VER TODO and not VER TODAS/VER TODOS',
        (tester) async {
      await tester.pumpWidget(_wrap(HourAwareBanner(
        hour: 12,
        actionLabel: 'VER TODO',
        onAction: () {},
      )));
      await tester.pumpAndSettle();

      expect(find.textContaining('VER TODO'), findsAtLeastNWidgets(1));
      expect(find.textContaining('VER TODAS'), findsNothing);
      expect(find.textContaining('VER TODOS'), findsNothing);
    });

    testWidgets('SectionHeader shows VER TODO and not VER TODAS/VER TODOS',
        (tester) async {
      await tester.pumpWidget(_wrap(SectionHeader(
        title: 'SECCIÓN',
        actionLabel: 'VER TODO',
        onAction: () {},
      )));
      await tester.pumpAndSettle();

      expect(find.textContaining('VER TODO'), findsAtLeastNWidgets(1));
      expect(find.textContaining('VER TODAS'), findsNothing);
      expect(find.textContaining('VER TODOS'), findsNothing);
    });

    test('AppLocalizationsEs.homeSeeAll returns Ver todo (singular)', () {
      expect(AppL10nEs().homeSeeAll, 'Ver todo');
    });
  });
}
