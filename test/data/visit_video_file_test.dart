import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/model/Visit.dart';

/// Contrato de lectura del mp4 self-host (migration-mobile/008): el app lee
/// `youtubeVideo.videoFile.s3Url` solo cuando `status == stored`, con fallbacks
/// tolerantes. Ausente / null / no-stored → null → fallback a YouTube.
void main() {
  Visit parse(Map<String, dynamic> yt, {Map<String, dynamic>? extra}) =>
      Visit.fromJson({
        'id': '1',
        'restaurantId': 'r',
        'youtubeVideo': yt,
        ...?extra,
      });

  test('lee s3Url cuando status == stored', () {
    final v = parse({
      'videoId': 'abc',
      'videoFile': {'s3Url': 'https://s3/v.mp4', 'status': 'stored'},
    });
    expect(v.videoFileUrl, 'https://s3/v.mp4');
  });

  test('null cuando no hay videoFile', () {
    final v = parse({'videoId': 'abc'});
    expect(v.videoFileUrl, isNull);
  });

  test('null cuando status != stored (p.ej. pending)', () {
    final v = parse({
      'videoId': 'abc',
      'videoFile': {'s3Url': 'https://s3/v.mp4', 'status': 'pending'},
    });
    expect(v.videoFileUrl, isNull);
  });

  test('tolera snake_case (video_file / s3_url) y status ausente', () {
    final v = parse({
      'videoId': 'abc',
      'video_file': {'s3_url': 'https://s3/snake.mp4'},
    });
    expect(v.videoFileUrl, 'https://s3/snake.mp4');
  });

  test('atajo top-level videoFileUrl', () {
    final v = parse({'videoId': 'abc'},
        extra: {'videoFileUrl': 'https://s3/flat.mp4'});
    expect(v.videoFileUrl, 'https://s3/flat.mp4');
  });

  // ── Gate de reproducción in-app (migration-backend/035) ──────────────────
  // iOS no decodifica AV1/VP9 → frame negro. Solo reproducimos self-host si el
  // backend confirma un códec compatible; en otro caso caemos a YouTube.
  group('selfHostVideoPlayable (gate de códec)', () {
    test('true con h264', () {
      final v = parse({
        'videoId': 'abc',
        'videoFile': {
          's3Url': 'https://s3/v.mp4',
          'status': 'stored',
          'videoCodec': 'h264',
        },
      });
      expect(v.videoCodec, 'h264');
      expect(v.selfHostVideoPlayable, isTrue);
    });

    test('true con hevc (case-insensitive)', () {
      final v = parse({
        'videoId': 'abc',
        'videoFile': {
          's3Url': 'https://s3/v.mp4',
          'status': 'stored',
          'videoCodec': 'HEVC',
        },
      });
      expect(v.selfHostVideoPlayable, isTrue);
    });

    test('false con av1 (iOS pintaría negro)', () {
      final v = parse({
        'videoId': 'abc',
        'videoFile': {
          's3Url': 'https://s3/v.mp4',
          'status': 'stored',
          'videoCodec': 'av1',
        },
      });
      expect(v.videoFileUrl, 'https://s3/v.mp4'); // la URL sí se parsea
      expect(v.selfHostVideoPlayable, isFalse); // pero NO se reproduce in-app
    });

    test('false cuando el códec es desconocido (conservador)', () {
      final v = parse({
        'videoId': 'abc',
        'videoFile': {'s3Url': 'https://s3/v.mp4', 'status': 'stored'},
      });
      expect(v.videoFileUrl, isNotNull);
      expect(v.videoCodec, isNull);
      expect(v.selfHostVideoPlayable, isFalse);
    });

    test('false cuando no hay mp4 self-host', () {
      final v = parse({'videoId': 'abc'});
      expect(v.selfHostVideoPlayable, isFalse);
    });
  });
}
