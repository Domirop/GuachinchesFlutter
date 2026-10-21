import 'package:flutter/foundation.dart';

/// Contenido del «accesorio» de la barra de pestañas minimizada (tablero
/// InicioScroll): al bajar por la home la barra se encoge a un círculo y a su
/// lado aparece una cápsula con lo más útil del momento («Golden hour · 41
/// abiertos ahora»). La home lo publica aquí; la barra lo escucha.
@immutable
class GmTabAccessoryData {
  final String eyebrow;
  final String title;
  final String? photoUrl;
  final VoidCallback onTap;

  const GmTabAccessoryData({
    required this.eyebrow,
    required this.title,
    required this.onTap,
    this.photoUrl,
  });

  @override
  bool operator ==(Object other) =>
      other is GmTabAccessoryData &&
      other.eyebrow == eyebrow &&
      other.title == title &&
      other.photoUrl == photoUrl;

  @override
  int get hashCode => Object.hash(eyebrow, title, photoUrl);
}

/// `null` → sin accesorio (la barra no se minimiza).
final ValueNotifier<GmTabAccessoryData?> gmTabAccessory =
    ValueNotifier<GmTabAccessoryData?>(null);
