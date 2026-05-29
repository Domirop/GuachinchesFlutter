import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/ui/components/video/youtube_embed_sheet.dart';

Finder _bySemId(String id) => find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.identifier == id,
    );

void main() {
  group('YoutubeEmbedSheet', () {
    testWidgets(
        '(a) show() renders sheet-root and open-external-button with valid videoId',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: appDarkTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => YoutubeEmbedSheet.show(
                  ctx,
                  videoId: 'dQw4w9WgXcW',
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(_bySemId('youtube-embed-sheet-root'), findsOneWidget);
      expect(_bySemId('youtube-embed-open-external-button'), findsWidgets);
    });

    testWidgets('(b) close button dismisses the sheet', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: appDarkTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => YoutubeEmbedSheet.show(
                  ctx,
                  videoId: 'dQw4w9WgXcW',
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(_bySemId('youtube-embed-sheet-root'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(_bySemId('youtube-embed-sheet-root'), findsNothing);
    });
  });
}
