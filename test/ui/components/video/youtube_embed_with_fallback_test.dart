import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/ui/components/video/youtube_embed_with_fallback.dart';

Finder _bySemId(String id) => find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.identifier == id,
    );

/// El componente está diseñado para vivir dentro de un sheet con altura
/// limitada (ver `youtube_embed_sheet.dart` → `ConstrainedBox(maxHeight)`).
/// El AspectRatio 9/16 sin altura constrained hace overflow vertical, así
/// que los tests envuelven en un SizedBox que simula ese constraint.
Widget _wrap(Widget child) => MaterialApp(
      theme: appDarkTheme,
      home: Scaffold(
        body: SizedBox(
          height: 500,
          width: 300,
          child: child,
        ),
      ),
    );

void main() {
  group('YoutubeEmbedWithFallback — invalid videoId early return', () {
    testWidgets('(a) empty videoId renders fallback anchor, no player anchor',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const YoutubeEmbedWithFallback(videoId: '')),
      );
      await tester.pump();

      expect(_bySemId('youtube-embed-fallback'), findsOneWidget);
      expect(_bySemId('youtube-embed-player'), findsNothing);
    });

    testWidgets(
        '(b) videoId with length != 11 renders fallback anchor, no player anchor',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const YoutubeEmbedWithFallback(videoId: 'abc')),
      );
      await tester.pump();

      expect(_bySemId('youtube-embed-fallback'), findsOneWidget);
      expect(_bySemId('youtube-embed-player'), findsNothing);
    });

    testWidgets('(c) container anchor always present', (tester) async {
      await tester.pumpWidget(
        _wrap(const YoutubeEmbedWithFallback(videoId: '')),
      );
      await tester.pump();

      expect(_bySemId('youtube-embed-container'), findsOneWidget);
    });
  });
}
