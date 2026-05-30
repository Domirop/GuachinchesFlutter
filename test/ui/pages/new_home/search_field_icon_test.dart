import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/ui/pages/new_home/widgets/search_field_dynamic.dart';

void main() {
  group('SearchFieldDynamic icon color', () {
    testWidgets('search icon color is not atlanticoClaro (light theme)',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: appLightTheme,
        darkTheme: appDarkTheme,
        home: Scaffold(
          body: SearchFieldDynamic(onTap: () {}),
        ),
      ));
      await tester.pump();

      final iconFinder = find.byWidgetPredicate(
        (w) => w is Icon && w.icon == Icons.search_rounded,
      );
      expect(iconFinder, findsOneWidget);

      final icon = tester.widget<Icon>(iconFinder);
      expect(icon.color, isNot(equals(AppColors.atlanticoClaro)));
    });

    testWidgets('search icon color is not atlanticoClaro (dark theme)',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: appDarkTheme,
        home: Scaffold(
          body: SearchFieldDynamic(onTap: () {}),
        ),
      ));
      await tester.pump();

      final iconFinder = find.byWidgetPredicate(
        (w) => w is Icon && w.icon == Icons.search_rounded,
      );
      expect(iconFinder, findsOneWidget);

      final icon = tester.widget<Icon>(iconFinder);
      expect(icon.color, isNot(equals(AppColors.atlanticoClaro)));
    });
  });
}
