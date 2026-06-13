import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/model/Visit.dart';

void main() {
  test('parsea videoPublishedAt desde youtubeVideo.publishedAt', () {
    final v = Visit.fromJson({
      'id': '1',
      'restaurantId': 'r1',
      'publishedAt': '2026-06-09T11:00:00.000Z', // fecha de publicación en app
      'youtubeVideo': {
        'videoId': 'abc',
        'publishedAt': '2025-05-06T13:27:54.000Z', // fecha real del vídeo
      },
    });
    expect(v.videoPublishedAt, '2025-05-06T13:27:54.000Z');
    // sortDate prioriza la fecha del vídeo sobre la de la app.
    expect(v.sortDate, '2025-05-06T13:27:54.000Z');
  });

  test('sortDate cae a publishedAt y luego createdAt', () {
    final soloApp = Visit.fromJson({
      'id': '2',
      'restaurantId': 'r2',
      'publishedAt': '2026-06-09T11:00:00.000Z',
    });
    expect(soloApp.sortDate, '2026-06-09T11:00:00.000Z');

    final soloCreated = Visit.fromJson({
      'id': '3',
      'restaurantId': 'r3',
      'createdAt': '2026-04-26T10:20:00.000Z',
    });
    expect(soloCreated.sortDate, '2026-04-26T10:20:00.000Z');
  });

  test('ordena visitas por fecha de vídeo desc (más nuevo primero)', () {
    Visit make(String id, String videoDate, String appDate) =>
        Visit.fromJson({
          'id': id,
          'restaurantId': 'r$id',
          'publishedAt': appDate, // todas el mismo día (job de publicación)
          'youtubeVideo': {'videoId': 'v$id', 'publishedAt': videoDate},
        });

    // Mismas fechas de app, distintas fechas de vídeo.
    final visits = [
      make('a', '2025-05-06T00:00:00.000Z', '2026-06-09T11:00:00.000Z'),
      make('c', '2026-06-01T00:00:00.000Z', '2026-06-09T11:00:00.000Z'),
      make('b', '2025-12-15T00:00:00.000Z', '2026-06-09T11:00:00.000Z'),
    ];

    visits.sort((x, y) {
      final dx = DateTime.parse(x.sortDate!);
      final dy = DateTime.parse(y.sortDate!);
      return dy.compareTo(dx);
    });

    expect(visits.map((v) => v.id).toList(), ['c', 'b', 'a']);
  });
}
