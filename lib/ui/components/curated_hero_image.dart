import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Portada de una lista curada.
///
/// El backend puede entregar `heroAsset` como **URL remota** (S3) o como ruta
/// de **asset local** empaquetado. `Image.asset` solo lee del bundle, así que
/// una URL remota lanzaba "Unable to load asset: Asset not found" y mostraba
/// la X de error. Este widget decide el cargador correcto:
/// - `http(s)://…`  → [CachedNetworkImage] (cachea + placeholder).
/// - cualquier otra  → [Image.asset].
///
/// En cualquier fallo (red caída, asset inexistente) cae a [SizedBox.shrink]
/// para que el degradado/emoji que va DETRÁS en el `Stack` quede visible, en
/// vez de un cuadro roto.
class CuratedHeroImage extends StatelessWidget {
  /// URL remota o ruta de asset local.
  final String source;
  final BoxFit fit;

  const CuratedHeroImage({
    super.key,
    required this.source,
    this.fit = BoxFit.cover,
  });

  bool get _isRemote =>
      source.startsWith('http://') || source.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    if (_isRemote) {
      return CachedNetworkImage(
        imageUrl: source,
        fit: fit,
        // Mientras carga / si falla: nada, así se ve el degradado de fondo.
        placeholder: (_, __) => const SizedBox.shrink(),
        errorWidget: (_, __, ___) => const SizedBox.shrink(),
      );
    }
    return Image.asset(
      source,
      fit: fit,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }
}
