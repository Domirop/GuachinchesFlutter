import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';
import 'package:guachinches/utils/distance_utils.dart';

/// Nombres que llegan TODO EN MAYÚSCULAS desde el backend («BAR RESTAURANTE
/// TERRAZA RAUL») se pintan en tipo título («Bar Restaurante Terraza Raul»):
/// la rampa SF del rediseño no grita. El resto se respeta tal cual.
String gmDisplayName(String raw) {
  final s = raw.trim();
  final letters = s.replaceAll(RegExp(r'[^A-Za-zÁÉÍÓÚÜÑáéíóúüñ]'), '');
  if (letters.length < 3 || s != s.toUpperCase()) return s;
  const small = {'de', 'del', 'la', 'las', 'el', 'los', 'y', 'en', 'a', 'al'};
  var first = true;
  return s.split(' ').map((w) {
    if (w.isEmpty) return w;
    final lower = w.toLowerCase();
    final out = (!first && small.contains(lower))
        ? lower
        : lower[0].toUpperCase() + lower.substring(1);
    first = false;
    return out;
  }).join(' ');
}

/// Topónimos en tipo título («La orotava» → «La Orotava», «LA MATANZA DE
/// ACENTEJO» → «La Matanza de Acentejo»). Si el dato ya viene bien escrito
/// («San Cristóbal de La Laguna») se respeta tal cual.
String gmPlaceName(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return s;
  const small = {'de', 'del', 'y', 'la', 'las', 'los', 'el'};
  final words = s.split(RegExp(r'\s+'));
  bool startsLower(String w) =>
      w.isNotEmpty && w[0] != w[0].toUpperCase();
  final needsFix = s == s.toUpperCase() ||
      s == s.toLowerCase() ||
      words.skip(1).any((w) => startsLower(w) && !small.contains(w)) ||
      startsLower(words.first);
  if (!needsFix) return s;
  var first = true;
  return words.map((w) {
    final lower = w.toLowerCase();
    final keep = !first && small.contains(lower);
    first = false;
    if (keep || lower.isEmpty) return lower;
    return lower[0].toUpperCase() + lower.substring(1);
  }).join(' ');
}

/// Distancia máxima que tiene sentido pintar. Más allá (usuario fuera de
/// la isla, coordenadas rotas…) se oculta: «1.834 km» no ayuda a nadie.
const double kGmMaxDistanceMeters = 200000;

/// Etiqueta de distancia o `null` si no hay ubicación, faltan coordenadas o
/// la distancia es absurda (> 200 km).
String? gmDistanceLabel(Restaurant r, double? userLat, double? userLon) {
  final m = gmDistanceMeters(r, userLat, userLon);
  return m == null ? null : formatDistance(m);
}

double? gmDistanceMeters(Restaurant r, double? userLat, double? userLon) {
  if (userLat == null || userLon == null) return null;
  if (r.lat == 0.0 && r.lon == 0.0) return null;
  final m = haversineDistanceMeters(userLat, userLon, r.lat, r.lon);
  return m > kGmMaxDistanceMeters ? null : m;
}

/// Chip de foto: con ubicación → flecha + distancia; sin ella → chincheta +
/// municipio. Devuelve `null` si no hay nada que decir.
Widget? gmLocationChip(BuildContext context, Restaurant r,
    {String? distanceLabel}) {
  if (distanceLabel != null) {
    return GmPhotoChip(
      leading: GmIcon(GmIcons.navArrow, size: 10, color: GmColors.atlantico),
      label: distanceLabel,
    );
  }
  final muni = r.municipio.trim();
  if (muni.isEmpty) return null;
  return GmPhotoChip(
    leading: GmIcon(GmIcons.pin, size: 10, color: GmColors.atlantico),
    label: gmPlaceName(muni),
  );
}

/// Foto de restaurante (red) con relleno mientras carga.
class GmPhoto extends StatelessWidget {
  final String? url;
  final int decodeWidth;
  final Alignment alignment;

  const GmPhoto(this.url,
      {super.key, this.decodeWidth = 480, this.alignment = Alignment.center});

  @override
  Widget build(BuildContext context) {
    final u = url;
    if (u == null || u.isEmpty) return const GmFill();
    return CachedNetworkImage(
      imageUrl: u,
      fit: BoxFit.cover,
      alignment: alignment,
      memCacheWidth: decodeWidth,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (_, __) => const GmFill(),
      errorWidget: (_, __, ___) => const GmFill(),
    );
  }
}

/// Tarjeta de sitio del rediseño: tarjeta blanca r24 con la foto r18 a 6 px
/// (radios concéntricos), chip de distancia sobre la foto, corazón de
/// cristal y debajo nombre 16/21 + fila meta.
class GmPlaceCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;

  /// Proporción de la foto (rejilla 4:3). Si [photoHeight] != null manda él.
  final double photoAspect;
  final double? photoHeight;

  /// Chip sobre la foto (abajo-izquierda).
  final Widget? chip;

  /// Fila meta bajo el nombre.
  final Widget meta;

  /// Reserva dos líneas de título (rejilla) o una (carrusel).
  final bool twoLineTitle;
  final EdgeInsets textPadding;
  final double metaGap;
  final String? identifier;

  const GmPlaceCard({
    super.key,
    required this.restaurant,
    required this.onTap,
    required this.meta,
    this.chip,
    this.photoAspect = 4 / 3,
    this.photoHeight,
    this.twoLineTitle = true,
    this.textPadding = const EdgeInsets.fromLTRB(6, 9, 6, 5),
    this.metaGap = 4,
    this.identifier,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final r = restaurant;
    Widget photo = Stack(
      fit: StackFit.expand,
      children: [
        GmPhoto(r.mainFoto),
        if (chip != null)
          Positioned(
            left: 8,
            bottom: 8,
            right: 8,
            child: Align(alignment: Alignment.bottomLeft, child: chip!),
          ),
      ],
    );
    photo = ClipRRect(
      borderRadius: BorderRadius.circular(GmRadius.photo),
      child: photoHeight != null
          ? SizedBox(height: photoHeight, width: double.infinity, child: photo)
          : AspectRatio(aspectRatio: photoAspect, child: photo),
    );

    final title = Text(
      gmDisplayName(r.nombre),
      maxLines: twoLineTitle ? 2 : 1,
      overflow: TextOverflow.ellipsis,
      style: GmText.cardTitle(color: gm.label),
    );

    return Stack(
      children: [
        GmPressable(
          onTap: onTap,
          semanticsIdentifier: identifier,
          semanticsLabel: r.nombre,
          child: GmCard(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  photo,
                  Padding(
                    padding: textPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (twoLineTitle)
                          // Reserva dos líneas (escaladas con el tamaño de
                          // texto del sistema) para alinear la fila meta.
                          ConstrainedBox(
                            constraints: BoxConstraints(
                                minHeight: MediaQuery.textScalerOf(context)
                                        .scale(21) *
                                    2),
                            child: Align(
                                alignment: Alignment.topLeft, child: title),
                          )
                        else
                          title,
                        SizedBox(height: metaGap),
                        meta,
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: 4,
          top: 4,
          child: GmFavButton(
            restaurantId: r.id,
            restaurantName: r.nombre,
          ),
        ),
      ],
    );
  }
}

/// Fila meta estándar: «● Abierto …… ★ 4,7» en una línea.
class GmMetaRow extends StatelessWidget {
  final Widget leading;
  final double rating;
  final double fontSize;

  const GmMetaRow({
    super.key,
    required this.leading,
    required this.rating,
    this.fontSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
          minHeight: MediaQuery.textScalerOf(context)
              .scale(fontSize == 13 ? 18 : 19)),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              // Un texto suelto se recorta con «…»; las piezas compuestas
              // («● Abierto») se encogen antes que desbordar.
              child: leading is Text
                  ? leading
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: leading,
                    ),
            ),
          ),
          if (rating > 0) ...[
            const SizedBox(width: 8),
            GmRating(rating, fontSize: fontSize),
          ],
        ],
      ),
    );
  }
}
