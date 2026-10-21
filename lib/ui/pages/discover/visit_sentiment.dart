/// Lo que les pareció el sitio a Jonay y Joana según el tono del vídeo
/// (`Visit.overallSentiment`, ya normalizado por `Visit.fromJson` a
/// `muy_positivo` | `positivo` | `neutro` | `negativo`).
enum VisitMood { loved, liked, regular }

extension VisitMoodMeta on VisitMood {
  /// Etiqueta del filtro («Les encantó», «Les gustó», «Regular»).
  String get label {
    switch (this) {
      case VisitMood.loved:
        return 'Les encantó';
      case VisitMood.liked:
        return 'Les gustó';
      case VisitMood.regular:
        return 'Regular';
    }
  }

  /// Valor de `overallSentiment`.
  String get sentiment {
    switch (this) {
      case VisitMood.loved:
        return 'muy_positivo';
      case VisitMood.liked:
        return 'positivo';
      case VisitMood.regular:
        return 'neutro';
    }
  }
}

/// Ánimo de una visita; `null` si no hay dato o es negativo (no se ofrece
/// como filtro).
VisitMood? visitMoodOf(String? overallSentiment) {
  switch ((overallSentiment ?? '').toLowerCase()) {
    case 'muy_positivo':
    case 'very_positive':
      return VisitMood.loved;
    case 'positivo':
    case 'positive':
      return VisitMood.liked;
    case 'neutro':
    case 'neutral':
      return VisitMood.regular;
  }
  return null;
}
