/// Custom Google Maps JSON style aligned with the app's cream/atlántico
/// palette (see `AppColors`). Land uses cream tones, water a muted atlántico,
/// POIs/transit are hidden so our restaurant markers stand out.
const String kMapStyleLight = '''
[
  {"elementType":"geometry","stylers":[{"color":"#F8F1E2"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#4A3A2A"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#F8F1E2"}]},
  {"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#D4A96A"},{"weight":0.6}]},
  {"featureType":"administrative.land_parcel","stylers":[{"visibility":"off"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#1A0D00"}]},
  {"featureType":"administrative.neighborhood","elementType":"labels.text.fill","stylers":[{"color":"#4A3A2A"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#E8DBC0"}]},
  {"featureType":"poi.park","elementType":"labels","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#FFFFFF"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#7A6A58"}]},
  {"featureType":"road","elementType":"labels.text.stroke","stylers":[{"color":"#FFFFFF"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#F2D8A6"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#D4A96A"}]},
  {"featureType":"road.highway.controlled_access","elementType":"geometry","stylers":[{"color":"#E8C58A"}]},
  {"featureType":"road.local","elementType":"geometry","stylers":[{"color":"#FCF7EC"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#A6CDDB"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#3E7A93"}]},
  {"featureType":"water","elementType":"labels.text.stroke","stylers":[{"color":"#A6CDDB"}]}
]
''';
