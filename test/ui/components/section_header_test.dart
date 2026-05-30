import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/ui/components/section_header.dart';

Widget _wrap(Widget child, {bool lightTheme = false}) {
  final theme = lightTheme
      ? ThemeData.light().copyWith(extensions: const [BrandColors.light])
      : ThemeData.dark().copyWith(extensions: const [BrandColors.dark]);
  return MaterialApp(
    theme: theme,
    home: Scaffold(body: child),
  );
}

Finder _bySemanticsId(String id) => find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.identifier == id,
    );

void main() {
  group('SectionHeader', () {
    testWidgets('(a) renders title text', (tester) async {
      await tester.pumpWidget(
        _wrap(const SectionHeader(title: 'CERCA DE TI')),
      );
      expect(find.text('CERCA DE TI'), findsOneWidget);
    });

    testWidgets(
      '(b) with actionLabel and onAction: renders section-header-cta, tap invokes callback',
      (tester) async {
        int calls = 0;
        await tester.pumpWidget(
          _wrap(SectionHeader(
            title: 'GUÍAS',
            actionLabel: 'VER TODAS',
            onAction: () => calls++,
          )),
        );

        final cta = _bySemanticsId('section-header-cta');
        expect(cta, findsOneWidget);

        await tester.tap(cta);
        await tester.pump();

        expect(calls, 1);
      },
    );

    testWidgets(
      '(c) without onAction, section-header-cta not found',
      (tester) async {
        await tester.pumpWidget(
          _wrap(const SectionHeader(
            title: 'GUÍAS',
            actionLabel: 'VER TODAS',
          )),
        );
        expect(_bySemanticsId('section-header-cta'), findsNothing);
      },
    );

    testWidgets(
      '(d) without actionLabel but with onAction, section-header-cta not found',
      (tester) async {
        await tester.pumpWidget(
          _wrap(SectionHeader(
            title: 'GUÍAS',
            onAction: () {},
          )),
        );
        expect(_bySemanticsId('section-header-cta'), findsNothing);
      },
    );

    testWidgets(
      '(e) under light theme the title text color is not white',
      (tester) async {
        const testTitle = 'SECCION PRUEBA';
        await tester.pumpWidget(
          _wrap(
            const SectionHeader(title: testTitle),
            lightTheme: true,
          ),
        );

        final titleWidget = tester.widget<Text>(find.text(testTitle));
        expect(
          titleWidget.style?.color,
          isNot(equals(const Color(0xFFFFFFFF))),
        );
      },
    );
  });
}
