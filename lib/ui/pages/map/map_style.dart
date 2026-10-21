import 'dart:ui' show Color;

import 'package:guachinches/ui/theme/gm_tokens.dart';

/// Estilo de Google Maps de la pestaña Mapa con los tokens del mapa claro
/// (DISENO-FINAL §2.6: `mapLand`, `mapRoad`, `mapCasing`, `mapMajor`,
/// `mapSea`, `mapPark`, `mapLabel`), día y noche. Sin puntos de interés ni
/// transporte: los sitios de la app son las únicas chinchetas. Se dejan los
/// nombres de los pueblos (como en el tablero) y se apagan barrios, parcelas
/// y nombres de calles.
String mapStyleFor(GmColors gm) {
  final land = mapHex(gm.mapLand);
  final road = mapHex(gm.mapRoad);
  // Google solo acepta colores opacos: el filo translúcido se mezcla con
  // la tierra.
  final casing = mapHex(_over(gm.mapCasing, gm.mapLand));
  final major = mapHex(gm.mapMajor);
  final majorCasing = mapHex(_over(gm.mapCasing, gm.mapMajor));
  final sea = mapHex(gm.mapSea);
  final park = mapHex(gm.mapPark);
  final label = mapHex(_over(gm.mapLabel, gm.mapLand));
  return '''
[
  {"elementType":"geometry","stylers":[{"color":"$land"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"$label"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"$land"},{"weight":3}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"visibility":"off"}]},
  {"featureType":"administrative.land_parcel","stylers":[{"visibility":"off"}]},
  {"featureType":"administrative.neighborhood","stylers":[{"visibility":"off"}]},
  {"featureType":"administrative.province","stylers":[{"visibility":"off"}]},
  {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"$land"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"visibility":"on"},{"color":"$park"}]},
  {"featureType":"poi.park","elementType":"labels","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"$road"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"$casing"}]},
  {"featureType":"road","elementType":"labels","stylers":[{"visibility":"off"}]},
  {"featureType":"road.highway","elementType":"geometry.fill","stylers":[{"color":"$major"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"$majorCasing"}]},
  {"featureType":"road.highway","elementType":"labels.text","stylers":[{"visibility":"on"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"$sea"}]},
  {"featureType":"water","elementType":"labels","stylers":[{"visibility":"off"}]}
]''';
}

/// «#RRGGBB» (sin alfa).
String mapHex(Color c) {
  final v = c.toARGB32() & 0xFFFFFF;
  return '#${v.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

/// [top] (translúcido) sobre [base] (opaco).
Color _over(Color top, Color base) => Color.alphaBlend(top, base);
