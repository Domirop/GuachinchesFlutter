import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/ui/components/curated_hero_image.dart';

void main() {
  group('CuratedHeroImage', () {
    testWidgets('una URL remota se carga con CachedNetworkImage (no Image.asset)',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CuratedHeroImage(
              source: 'http://louvre.s3.fr-par.scw.cloud/upload/images/x.png',
            ),
          ),
        ),
      );

      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    testWidgets('una URL https también usa CachedNetworkImage', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CuratedHeroImage(source: 'https://cdn.example.com/y.jpg'),
          ),
        ),
      );

      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    testWidgets('una ruta de asset local usa Image.asset (no red)',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CuratedHeroImage(source: 'assets/images/foo.png'),
          ),
        ),
      );

      expect(find.byType(CachedNetworkImage), findsNothing);
      // Image.asset construye un Image con AssetImage como provider.
      final img = tester.widget<Image>(find.byType(Image));
      expect(img.image, isA<AssetImage>());
    });
  });
}
