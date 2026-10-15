import 'package:guachinches/data/model/Review.dart';
import 'package:guachinches/ui/pages/restaurant_detail/ficha_logic.dart'
    show fichaFirstName, fichaReviewText;

/// Lógica pura de «Todas las reseñas» (tablero ResenasTodas): orden,
/// textos de relleno que no se pintan, motivos de reporte y textos de
/// moderación. Sin widgets.

// ── Textos de relleno ──────────────────────────────────────────────────────

String _norm(String s) {
  const from = 'áàäâéèëêíìïîóòöôúùüûñ';
  const to = 'aaaaeeeeiiiioooouuuun';
  final buf = StringBuffer();
  for (final rune in s.trim().toLowerCase().runes) {
    final ch = String.fromCharCode(rune);
    final i = from.indexOf(ch);
    buf.write(i >= 0 ? to[i] : ch);
  }
  return buf.toString().replaceAll(RegExp(r'[.\s]+$'), '');
}

/// Títulos que mete la app vieja o el backend cuando la persona no escribió
/// ninguno: no se pintan.
const _placeholderTitles = {'titulo', 'sin titulo', 'title', 'sin title'};

/// Título tal cual, o vacío si es un relleno («Título», «Sin título»).
String reviewDisplayTitle(String raw) {
  final t = raw.trim();
  if (t.isEmpty || _placeholderTitles.contains(_norm(t))) return '';
  return t;
}

/// Texto tal cual, o vacío si es un relleno («Sin descripción»).
String reviewDisplayText(String raw) {
  final t = fichaReviewText(raw);
  return _placeholderTexts.contains(_norm(t)) ? '' : t;
}

const _placeholderTexts = {'sin descripcion', 'descripcion', 'sin comentario'};

/// ¿La reseña trae algo escrito (título o texto) aparte de las estrellas?
bool reviewHasComment(Review r) =>
    reviewDisplayTitle(r.title).isNotEmpty ||
    reviewDisplayText(r.review).isNotEmpty;

/// Nota de la reseña (0 si no se entiende).
int reviewStars(Review r) =>
    (double.tryParse(r.rating)?.round() ?? 0).clamp(0, 5);

/// Nombre de pila del autor («Anónimo» sin dato).
String reviewAuthorName(Review r) => fichaFirstName(r.usuario?.nombre);

/// Id del autor (el del usuario anidado o el de la clave foránea).
String reviewAuthorId(Review r) {
  final u = r.usuario?.id ?? '';
  return u.isNotEmpty ? u : r.valoracionesUsuarioId;
}

/// Las reseñas largas se recortan a 4 líneas con «Leer más».
bool reviewIsLong(String text) => text.length > 170;

// ── Orden ──────────────────────────────────────────────────────────────────

enum ReviewSort { relevant, best, worst }

extension ReviewSortMeta on ReviewSort {
  String get label {
    switch (this) {
      case ReviewSort.relevant:
        return 'Relevantes';
      case ReviewSort.best:
        return 'Mejor puntuadas';
      case ReviewSort.worst:
        return 'Peor puntuadas';
    }
  }

  /// Subtítulo en el menú y texto a la izquierda del botón de orden.
  String get caption {
    switch (this) {
      case ReviewSort.relevant:
        return 'Con comentario primero';
      case ReviewSort.best:
        return 'De 5 a 1 estrellas';
      case ReviewSort.worst:
        return 'De 1 a 5 estrellas';
    }
  }

  String get identifier => 'restaurant-reviews-sort-$name';
}

/// Copia ordenada. «Relevantes»: primero las que tienen comentario, sin
/// tocar el orden del servidor dentro de cada grupo. Las otras dos, por
/// estrellas (estable: a igualdad, las que tienen comentario primero).
List<Review> reviewsSorted(List<Review> reviews, ReviewSort sort) {
  final indexed = [for (var i = 0; i < reviews.length; i++) (i, reviews[i])];
  int byComment((int, Review) a, (int, Review) b) {
    final ca = reviewHasComment(a.$2) ? 0 : 1;
    final cb = reviewHasComment(b.$2) ? 0 : 1;
    return ca.compareTo(cb);
  }

  indexed.sort((a, b) {
    int c = 0;
    switch (sort) {
      case ReviewSort.relevant:
        c = byComment(a, b);
      case ReviewSort.best:
        c = reviewStars(b.$2).compareTo(reviewStars(a.$2));
        if (c == 0) c = byComment(a, b);
      case ReviewSort.worst:
        c = reviewStars(a.$2).compareTo(reviewStars(b.$2));
        if (c == 0) c = byComment(a, b);
    }
    return c != 0 ? c : a.$1.compareTo(b.$1);
  });
  return [for (final e in indexed) e.$2];
}

/// Reseñas que se ven: fuera las de personas bloqueadas.
List<Review> reviewsWithoutBlocked(
        List<Review> reviews, Set<String> blockedUserIds) =>
    [
      for (final r in reviews)
        if (!blockedUserIds.contains(reviewAuthorId(r))) r
    ];

// ── Reporte ────────────────────────────────────────────────────────────────

/// Motivos del reporte. El backend (`POST report-review`) no guarda el
/// motivo: se queda en el cliente (analítica/log) hasta que exista el campo.
enum ReviewReportReason { spam, offensive, personalData, offTopic, other }

extension ReviewReportReasonMeta on ReviewReportReason {
  String get label {
    switch (this) {
      case ReviewReportReason.spam:
        return 'Spam o repetida';
      case ReviewReportReason.offensive:
        return 'Insultos u ofensiva';
      case ReviewReportReason.personalData:
        return 'Datos personales de alguien';
      case ReviewReportReason.offTopic:
        return 'No habla de este sitio';
      case ReviewReportReason.other:
        return 'Otro motivo';
    }
  }

  /// Valor estable para analítica (y para el backend cuando acepte motivo).
  String get code {
    switch (this) {
      case ReviewReportReason.spam:
        return 'spam';
      case ReviewReportReason.offensive:
        return 'offensive';
      case ReviewReportReason.personalData:
        return 'personal_data';
      case ReviewReportReason.offTopic:
        return 'off_topic';
      case ReviewReportReason.other:
        return 'other';
    }
  }
}

// ── Textos ─────────────────────────────────────────────────────────────────

/// «1 reseña» / «36 reseñas».
String reviewsCountLabel(int n) => n == 1 ? '1 reseña' : '$n reseñas';

/// Antetítulo de la pantalla: «Guachinche El Fogón · La Laguna».
String reviewsEyebrow(String name, String municipio) {
  final n = name.trim();
  final m = municipio.trim();
  if (n.isEmpty) return m;
  if (m.isEmpty) return n;
  return '$n · $m';
}

String reviewBlockTitle(String name) => '¿Bloquear a $name?';

/// Dirección de soporte para «Escribir a soporte» (la misma que da Ayuda y
/// soporte en el Perfil).
const String kReviewSupportEmail = 'hola@dondecocomercanarias.es';

/// Asunto y cuerpo del correo a soporte para reportar sin cuenta.
Uri reviewSupportMailUri({
  required String restaurantName,
  required String authorName,
  required String reviewId,
}) =>
    Uri(
      scheme: 'mailto',
      path: kReviewSupportEmail,
      query: _encodeQuery({
        'subject': 'Reportar una reseña de $restaurantName',
        'body': 'Quiero reportar la reseña de $authorName en $restaurantName '
            '(ref. $reviewId).\n\nMotivo: ',
      }),
    );

String _encodeQuery(Map<String, String> params) => params.entries
    .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
    .join('&');
