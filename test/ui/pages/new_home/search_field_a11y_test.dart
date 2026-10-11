import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/pages/new_home/widgets/search_field_dynamic.dart';

Finder _bySemId(String id) => find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.identifier == id,
    );

Widget _wrap(Widget child) => MaterialApp(
      theme: appLightTheme,
      darkTheme: appDarkTheme,
      themeMode: ThemeMode.light,
      home: Scaffold(body: child),
    );

void main() {
  group('SearchFieldDynamic a11y', () {
    testWidgets('(a) placeholder usa el secundario del rediseño (light theme)',
        (tester) async {
      await tester.pumpWidget(_wrap(SearchFieldDynamic(onTap: () {})));
      await tester.pump();

      final textFinder = find.text('Buscar restaurante');
      expect(textFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(textFinder);
      expect(
        textWidget.style?.color,
        equals(GmColors.day.label2),
        reason: 'Placeholder usa el secundario del rediseño (#6E6253, 5,9:1)',
      );
    });

    testWidgets('(b) existe exactamente un Semantics con identifier home-search-field',
        (tester) async {
      await tester.pumpWidget(_wrap(SearchFieldDynamic(onTap: () {})));
      await tester.pump();

      expect(
        _bySemId('home-search-field'),
        findsOneWidget,
        reason: 'Anchor home-search-field debe existir exactamente una vez',
      );
    });

    testWidgets('(a+b) dark theme — placeholder secundario, anchor presente',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: appDarkTheme,
        themeMode: ThemeMode.dark,
        home: Scaffold(body: SearchFieldDynamic(onTap: () {})),
      ));
      await tester.pump();

      final textFinder = find.text('Buscar restaurante');
      expect(textFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(textFinder);
      expect(
        textWidget.style?.color,
        equals(GmColors.night.label2),
        reason: 'Dark: placeholder usa el secundario de noche',
      );

      expect(_bySemId('home-search-field'), findsOneWidget);
    });
  });
}
