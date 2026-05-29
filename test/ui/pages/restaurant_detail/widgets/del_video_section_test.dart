import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/data/model/short_quote.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/del_video_section.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: appDarkTheme,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  group('DelVideoSection — debug cleanup regression', () {
    const quotes = [
      ShortQuote(
        text: 'Increíble guiso de cabra, uno de los mejores',
        timestamp: '0:45',
        isWarning: false,
      ),
    ];

    testWidgets('(a) no [DBG] suffix in rendered text', (tester) async {
      await tester.pumpWidget(
        _wrap(const DelVideoSection(quotes: quotes, videoId: 'dQw4w9WgXcW')),
      );
      await tester.pump();

      expect(find.textContaining('[DBG]'), findsNothing);
    });

    testWidgets('(b) no Container with color yellow in the tree', (tester) async {
      await tester.pumpWidget(
        _wrap(const DelVideoSection(quotes: quotes, videoId: 'dQw4w9WgXcW')),
      );
      await tester.pump();

      final yellowContainers = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) => c.color == Colors.yellow)
          .toList();

      expect(yellowContainers, isEmpty);
    });

    testWidgets('(c) quote text renders with italic fontStyle', (tester) async {
      await tester.pumpWidget(
        _wrap(const DelVideoSection(quotes: quotes, videoId: 'dQw4w9WgXcW')),
      );
      await tester.pump();

      final texts = tester.widgetList<Text>(find.byType(Text)).toList();
      final quoteText = texts.firstWhere(
        (t) => t.data?.contains('Increíble guiso de cabra') == true,
        orElse: () => const Text('NOT_FOUND'),
      );

      expect(quoteText.data, isNot('NOT_FOUND'));
      expect(quoteText.style?.fontStyle, FontStyle.italic);
    });
  });
}
