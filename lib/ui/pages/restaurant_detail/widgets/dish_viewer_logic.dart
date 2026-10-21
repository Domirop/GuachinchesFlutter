import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart'
    show gmDisplayName;
import 'package:guachinches/ui/pages/restaurant_detail/ficha_logic.dart'
    show fichaDateFromIso;

/// Lógica pura del visor de foto de plato (tablero `PlatoVisor`).

/// Sello que acompaña al plato bajo la foto.
enum DishStamp {
  /// «Les encantó» (sello vino + oro).
  loved,

  /// «No les convenció» (sello ámbar).
  disliked,

  /// Nada (neutro, «les gustó» o sin dato).
  none,
}

const _lovedSentiments = {
  'loved',
  'muy_positivo',
  'very_positive',
};

const _dislikedSentiments = {
  'disliked',
  'negative',
  'negativo',
  'muy_negativo',
  'very_negative',
  'bad',
};

/// Sentimiento del plato → sello. Solo se marcan los extremos: lo que les
/// encantó y lo que no les convenció. Sin sentimiento, un plato marcado como
/// top por el backend cuenta como «Les encantó».
DishStamp dishStampFor({String? sentiment, bool isTop = false}) {
  final s = sentiment?.trim().toLowerCase() ?? '';
  if (_lovedSentiments.contains(s)) return DishStamp.loved;
  if (_dislikedSentiments.contains(s)) return DishStamp.disliked;
  if (s.isEmpty && isTop) return DishStamp.loved;
  return DishStamp.none;
}

DishStamp dishStampOf(VisitDish d) =>
    dishStampFor(sentiment: d.sentiment, isTop: d.isTop);

/// «26 €» / «12,50 €». `null` sin precio (o precio no positivo).
String? dishPriceLabel(num? price) {
  if (price == null || price <= 0) return null;
  if (price % 1 == 0) return '${price.toInt()} €';
  return '${price.toStringAsFixed(2).replaceAll('.', ',')} €';
}

/// «5 / 6».
String dishViewerCounter(int index, int total) => '${index + 1} / $total';

/// Nombre del sitio de una visita («Casa Ángela»): el del restaurante y, si
/// falta, el de la visita. `null` si no hay ninguno.
String? dishViewerPlaceName(Visit v) {
  final raw = v.restaurant?.nombre.trim().isNotEmpty == true
      ? v.restaurant!.nombre
      : (v.name ?? '');
  final name = gmDisplayName(raw).trim();
  return name.isEmpty ? null : name;
}

/// Pie bajo la descripción: «Casa Ángela · Visita del 8 oct 2026». Con solo
/// uno de los dos datos, solo ese; sin ninguno, `null`.
String? dishViewerFooter({String? placeName, String? visitDateIso}) {
  final place = placeName?.trim() ?? '';
  final date = fichaDateFromIso(visitDateIso);
  final parts = [
    if (place.isNotEmpty) place,
    if (date != null) 'Visita del $date',
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

/// Texto para compartir: «Conejo en Casa Ángela» + la URL de la foto.
String dishShareText({
  required String dishName,
  String? placeName,
  String? photoUrl,
}) {
  final name = dishName.trim();
  final place = placeName?.trim() ?? '';
  final head = place.isEmpty ? name : '$name en $place';
  final url = photoUrl?.trim() ?? '';
  return url.isEmpty ? head : '$head\n$url';
}

/// Desplazamiento de la tira de miniaturas que centra la [index]-ésima en un
/// visor de ancho [viewport] (acotado a los extremos de la tira).
double dishThumbOffset({
  required int index,
  required int count,
  required double viewport,
  double size = 52,
  double gap = 10,
  double padding = 16,
}) {
  if (count <= 0) return 0;
  final content = padding * 2 + count * size + (count - 1) * gap;
  final maxOffset = content - viewport;
  if (maxOffset <= 0) return 0;
  final centre = padding + index * (size + gap) + size / 2;
  return (centre - viewport / 2).clamp(0.0, maxOffset);
}
