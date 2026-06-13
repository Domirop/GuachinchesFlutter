/// Custom Google Maps JSON style alineado con la paleta crema/atlántico de la
/// app (ver `AppColors`).
///
/// Decisiones (v2):
/// - Agua más limpia y luminosa (#A3CFE3): la anterior (#A6CDDB) quedaba
///   grisácea, no leía "Atlántico".
/// - Autopistas en arena suave (#F4E3BC): el ámbar anterior dominaba la vista
///   de isla y competía con los markers (que son el contenido del mapa).
/// - Parques/naturaleza en verde laurisilva suave (#DCE7CB) en vez de beige.
/// - Bordes administrativos casi imperceptibles (#E2D4B8 @ 0.5): los límites
///   municipales dorados metían ruido por toda la isla.
/// - Topónimos: localidades en tinta (jerarquía clara), barrios en marrón
///   apagado — las ZONAS se leen, pero no gritan.
/// - POIs/transit/iconos ocultos: nuestros restaurantes son los protagonistas.
const String kMapStyleLight = '''
[
  {"elementType":"geometry","stylers":[{"color":"#F7F2E7"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#4A3A2A"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#F7F2E7"}]},
  {"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#E2D4B8"},{"weight":0.5}]},
  {"featureType":"administrative.land_parcel","stylers":[{"visibility":"off"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#241A10"}]},
  {"featureType":"administrative.neighborhood","elementType":"labels.text.fill","stylers":[{"color":"#6E5F4D"}]},
  {"featureType":"landscape.natural","elementType":"geometry","stylers":[{"color":"#F2EDDD"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#DCE7CB"}]},
  {"featureType":"poi.park","elementType":"labels","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#FFFFFF"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#8A7A66"}]},
  {"featureType":"road","elementType":"labels.text.stroke","stylers":[{"color":"#FFFFFF"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#F4E3BC"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#E3CE9E"}]},
  {"featureType":"road.highway.controlled_access","elementType":"geometry","stylers":[{"color":"#F0DCAE"}]},
  {"featureType":"road.local","elementType":"geometry","stylers":[{"color":"#FBF7EE"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#A3CFE3"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#2E6E8C"}]},
  {"featureType":"water","elementType":"labels.text.stroke","stylers":[{"color":"#A3CFE3"}]}
]
''';
