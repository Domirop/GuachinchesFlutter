import 'package:guachinches/data/model/user_info.dart';

/// Lógica pura de Mis reseñas (tablero PerfilMisResenas).

/// Palabras de la nota (las mismas del editor de reseñas).
const kResenaWords = ['Mala', 'Regular', 'Aceptable', 'Muy buena', 'Excelente'];

/// «4» → «Muy buena». Vacío si la nota no es válida.
String resenaWord(int? stars) =>
    (stars == null || stars < 1 || stars > 5) ? '' : kResenaWords[stars - 1];

/// Botón de la tarjeta: sin texto, «Añadir texto»; con texto, «Editar».
String resenaActionLabel(Valoraciones v) =>
    v.review.trim().isEmpty ? 'Añadir texto' : 'Editar';

/// Solo puso estrellas (ni título ni texto).
bool resenaOnlyStars(Valoraciones v) =>
    v.title.trim().isEmpty && v.review.trim().isEmpty;

/// Id del sitio reseñado (el del payload o el del restaurante incluido).
String resenaRestaurantId(Valoraciones v) {
  final a = v.valoracionesNegocioId.trim();
  if (a.isNotEmpty) return a;
  return v.restaurantes?.id.trim() ?? '';
}

/// «4 reseñas escritas» → la etiqueta bajo el número.
String resenasCountCaption(int n) =>
    n == 1 ? 'reseña escrita' : 'reseñas escritas';
