import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart'
    show gmDisplayName, gmPlaceName;
import 'package:guachinches/ui/pages/restaurant_detail/ficha_logic.dart'
    show fichaDateFromIso, fichaDuration;
import 'package:guachinches/utils/restaurant_type_label.dart';

/// Lógica pura de la hoja del vídeo de YouTube (tablero `VideoYouTube`).

/// IDs de YouTube: 11 caracteres. Con otro largo no se intenta incrustar.
bool youtubeIdLooksValid(String id) => id.length == 11;

/// Enlace externo al Short. Path `/shorts/<id>` para que la app de YouTube
/// lo abra en vertical (todos los vídeos del proyecto son Shorts).
Uri youtubeExternalUri(String videoId, {int? startSeconds}) =>
    startSeconds != null
        ? Uri.parse('https://youtube.com/shorts/$videoId?t=$startSeconds')
        : Uri.parse('https://youtube.com/shorts/$videoId');

/// Póster del vídeo: el fotograma propio si llega; si no, la miniatura HQ de
/// YouTube. `null` sin ninguno de los dos.
String? youtubePosterUrl(String videoId, {String? posterUrl}) {
  final p = posterUrl?.trim() ?? '';
  if (p.isNotEmpty) return p;
  if (videoId.trim().isEmpty) return null;
  return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
}

/// Lo que va tras «Jonay y Joana» en el pie: « · 8 oct 2026 · 1:35». Cadena
/// vacía si no se conoce ni la fecha ni la duración.
String youtubeCreditMeta({String? publishedAtIso, int? durationSeconds}) {
  final parts = [
    if (fichaDateFromIso(publishedAtIso) != null)
      fichaDateFromIso(publishedAtIso)!,
    if (fichaDuration(seconds: durationSeconds) != null)
      fichaDuration(seconds: durationSeconds)!,
  ];
  return parts.map((p) => ' · $p').join();
}

/// «Guachinche moderno · La Victoria de Acentejo» (tipo y municipio, lo que
/// haya). `null` sin ninguno.
String? youtubePlaceMeta({String? type, String? town}) {
  final t = restaurantTypeLabel(type).trim();
  final m = gmPlaceName(town ?? '').trim();
  final parts = [if (t.isNotEmpty) t, if (m.isNotEmpty) m];
  return parts.isEmpty ? null : parts.join(' · ');
}

/// Datos del pie de la hoja.
class YoutubeSheetInfo {
  final String? placeName;
  final String? placeMeta;
  final String? publishedAtIso;
  final int? durationSeconds;
  final String? posterUrl;

  const YoutubeSheetInfo({
    this.placeName,
    this.placeMeta,
    this.publishedAtIso,
    this.durationSeconds,
    this.posterUrl,
  });

  /// Lo explícito manda; lo que falte se saca de [visit] (si la hay).
  factory YoutubeSheetInfo.resolve({
    Visit? visit,
    String? placeName,
    String? placeMeta,
    String? publishedAtIso,
    int? durationSeconds,
    String? posterUrl,
  }) {
    String? clean(String? s) => s?.trim().isNotEmpty == true ? s!.trim() : null;
    final v = visit;
    final r = v?.restaurant;
    String? visitPlace() {
      if (v == null) return null;
      final raw = r?.nombre.trim().isNotEmpty == true ? r!.nombre : v.name;
      return clean(gmDisplayName(raw ?? ''));
    }

    String? visitMeta() {
      if (v == null) return null;
      final town =
          r?.municipio.trim().isNotEmpty == true ? r!.municipio : v.zone;
      return youtubePlaceMeta(type: r?.type, town: town);
    }

    return YoutubeSheetInfo(
      placeName: clean(placeName) ?? visitPlace(),
      placeMeta: clean(placeMeta) ?? visitMeta(),
      publishedAtIso: clean(publishedAtIso) ?? clean(v?.sortDate),
      durationSeconds: durationSeconds ?? v?.durationSeconds,
      posterUrl: clean(posterUrl) ?? clean(v?.posterUrl),
    );
  }
}
