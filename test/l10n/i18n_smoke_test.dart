import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/l10n/app_localizations.dart';

Widget _app(Locale locale, Widget child) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppL10n.localizationsDelegates,
    supportedLocales: AppL10n.supportedLocales,
    home: Scaffold(body: child),
  );
}

AppL10n _l10n(WidgetTester tester) =>
    AppL10n.of(tester.element(find.byType(Scaffold)));

void main() {
  group('i18n smoke tests', () {
    testWidgets('(a) homeGreetingMorning es → Buenos días', (tester) async {
      await tester.pumpWidget(_app(const Locale('es'), const SizedBox()));
      await tester.pumpAndSettle();
      expect(_l10n(tester).homeGreetingMorning, 'Buenos días');
    });

    testWidgets('(b) homeGreetingMorning en → Good morning', (tester) async {
      await tester.pumpWidget(_app(const Locale('en'), const SizedBox()));
      await tester.pumpAndSettle();
      expect(_l10n(tester).homeGreetingMorning, 'Good morning');
    });

    testWidgets('(c) profileVisitsCount(0) es → Sin visitas / en → No visits',
        (tester) async {
      await tester.pumpWidget(_app(const Locale('es'), const SizedBox()));
      await tester.pumpAndSettle();
      expect(_l10n(tester).profileVisitsCount(0), 'Sin visitas');

      await tester.pumpWidget(_app(const Locale('en'), const SizedBox()));
      await tester.pumpAndSettle();
      expect(_l10n(tester).profileVisitsCount(0), 'No visits');
    });

    testWidgets('(d) profileVisitsCount(5) es → 5 visitas / en → 5 visits',
        (tester) async {
      await tester.pumpWidget(_app(const Locale('es'), const SizedBox()));
      await tester.pumpAndSettle();
      expect(_l10n(tester).profileVisitsCount(5), '5 visitas');

      await tester.pumpWidget(_app(const Locale('en'), const SizedBox()));
      await tester.pumpAndSettle();
      expect(_l10n(tester).profileVisitsCount(5), '5 visits');
    });
  });
}
