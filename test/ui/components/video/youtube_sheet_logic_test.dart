import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/components/video/youtube_sheet_logic.dart';
import 'package:guachinches/utils/contextual_pool.dart';

void main() {
  group('youtubeExternalUri', () {
    test('Short sin y con segundo de inicio', () {
      expect(youtubeExternalUri('dQw4w9WgXcW').toString(),
          'https://youtube.com/shorts/dQw4w9WgXcW');
      expect(youtubeExternalUri('dQw4w9WgXcW', startSeconds: 42).toString(),
          'https://youtube.com/shorts/dQw4w9WgXcW?t=42');
    });
  });

  test('youtubeIdLooksValid: solo 11 caracteres', () {
    expect(youtubeIdLooksValid('dQw4w9WgXcW'), isTrue);
    expect(youtubeIdLooksValid('abc'), isFalse);
    expect(youtubeIdLooksValid(''), isFalse);
  });

  test('youtubePosterUrl: el póster propio manda; si no, hqdefault', () {
    expect(youtubePosterUrl('id', posterUrl: 'https://cdn/p.jpg'),
        'https://cdn/p.jpg');
    expect(youtubePosterUrl('dQw4w9WgXcW'),
        'https://img.youtube.com/vi/dQw4w9WgXcW/hqdefault.jpg');
    expect(youtubePosterUrl('', posterUrl: ' '), isNull);
  });

  test('youtubeCreditMeta: fecha y duración solo si se conocen', () {
    expect(
        youtubeCreditMeta(
            publishedAtIso: '2026-10-08T12:00:00Z', durationSeconds: 95),
        ' · 8 oct 2026 · 1:35');
    expect(youtubeCreditMeta(durationSeconds: 95), ' · 1:35');
    expect(youtubeCreditMeta(publishedAtIso: '2026-10-08T12:00:00Z'),
        ' · 8 oct 2026');
    expect(
        youtubeCreditMeta(publishedAtIso: 'no-date', durationSeconds: 0), '');
  });

  test('youtubePlaceMeta: tipo y municipio, lo que haya', () {
    expect(
        youtubePlaceMeta(
            type: RestaurantTypeIds.guachinchesModernos,
            town: 'LA VICTORIA DE ACENTEJO'),
        'Guachinche moderno · La Victoria de Acentejo');
    expect(youtubePlaceMeta(town: 'La Laguna'), 'La Laguna');
    // Un UUID desconocido nunca se pinta.
    expect(
        youtubePlaceMeta(type: '00000000-0000-0000-0000-000000000000'), isNull);
  });

  group('YoutubeSheetInfo.resolve', () {
    final visit = Visit(
      id: 'v',
      restaurantId: 'r',
      videoPublishedAt: '2026-10-08T12:00:00Z',
      durationSeconds: 95,
      posterUrl: 'https://cdn/poster.jpg',
      restaurant: Restaurant(
        id: 'r',
        nombre: 'Casa Ángela',
        municipio: 'La Victoria de Acentejo',
        type: RestaurantTypeIds.guachinchesModernos,
      ),
    );

    test('saca todo de la visita', () {
      final i = YoutubeSheetInfo.resolve(visit: visit);
      expect(i.placeName, 'Casa Ángela');
      expect(i.placeMeta, 'Guachinche moderno · La Victoria de Acentejo');
      expect(i.publishedAtIso, '2026-10-08T12:00:00Z');
      expect(i.durationSeconds, 95);
      expect(i.posterUrl, 'https://cdn/poster.jpg');
    });

    test('lo explícito manda sobre la visita', () {
      final i = YoutubeSheetInfo.resolve(
          visit: visit, placeName: 'Otro', placeMeta: 'Bodegón · Tacoronte');
      expect(i.placeName, 'Otro');
      expect(i.placeMeta, 'Bodegón · Tacoronte');
    });

    test('sin visita ni datos: todo nulo', () {
      final i = YoutubeSheetInfo.resolve(placeName: '  ');
      expect(i.placeName, isNull);
      expect(i.placeMeta, isNull);
      expect(i.publishedAtIso, isNull);
      expect(i.durationSeconds, isNull);
      expect(i.posterUrl, isNull);
    });
  });
}
