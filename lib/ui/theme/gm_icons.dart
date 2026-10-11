import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Iconos de interfaz del rediseño iOS 27, copiados de los tableros
/// (`design/rediseno-ios27/boards`). Se pintan con `currentColor` → el color
/// lo decide [GmIcon.color]. Los glifos de marca multicolor (cabra, cochino,
/// vieja, volcán…) viven como assets en `assets/images/new-home/glyph_*.svg`
/// (ver [GmGlyph]).
class GmIcons {
  GmIcons._();

  static String _wrap(String inner, {String attrs = ''}) =>
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" $attrs>$inner</svg>';

  static final chevronRight = _wrap('<path d="M9 6l6 6-6 6"/>',
      attrs:
          'fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"');
  static final chevronDown = _wrap('<path d="M6 9l6 6 6-6"/>',
      attrs:
          'fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"');
  static final chevronLeft = _wrap('<path d="M15 5l-7 7 7 7"/>',
      attrs:
          'fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"');
  static final search = _wrap(
      '<circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/>',
      attrs:
          'fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"');
  static final mic = _wrap(
      '<rect x="8.5" y="2.5" width="7" height="12" rx="3.5"/>'
      '<path d="M5.5 11a6.5 6.5 0 0013 0" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>'
      '<path d="M11 17.5h2V21h-2z"/>',
      attrs: 'fill="currentColor"');
  static final heart = _wrap(
      '<path d="M12 20s-7.5-4.6-7.5-10A4.3 4.3 0 0112 7.3 4.3 4.3 0 0119.5 10c0 5.4-7.5 10-7.5 10z"/>',
      attrs:
          'fill="none" stroke="currentColor" stroke-width="2.2" stroke-linejoin="round"');
  static final heartFilled = _wrap(
      '<path d="M12 20s-7.5-4.6-7.5-10A4.3 4.3 0 0112 7.3 4.3 4.3 0 0119.5 10c0 5.4-7.5 10-7.5 10z"/>',
      attrs:
          'fill="currentColor" stroke="currentColor" stroke-width="2.2" stroke-linejoin="round"');
  static final star = _wrap(
      '<path d="M12 2.8l2.8 5.8 6.3.9-4.6 4.4 1.1 6.3L12 17.2l-5.6 3 1.1-6.3-4.6-4.4 6.3-.9z"/>',
      attrs: 'fill="currentColor"');

  /// Chincheta de marca (relleno Atlántico + punto blanco).
  static final pin = _wrap(
      '<path d="M12 21.5s-7-6.6-7-12a7 7 0 0114 0c0 5.4-7 12-7 12z" fill="currentColor"/>'
      '<circle cx="12" cy="9.5" r="2.6" fill="#FFFFFF"/>');

  /// Flecha de navegación (distancia con ubicación).
  static final navArrow =
      _wrap('<path d="M20.5 3.5L3.5 10.6l7 2.4 2.4 7z"/>', attrs: 'fill="currentColor"');
  static final play =
      _wrap('<path d="M7 4.5v15l12.5-7.5z"/>', attrs: 'fill="currentColor"');
  static final share = _wrap(
      '<path d="M12 15V4M7.5 8.5L12 4l4.5 4.5"/><path d="M5 13v5.5A1.5 1.5 0 006.5 20h11a1.5 1.5 0 001.5-1.5V13"/>',
      attrs:
          'fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"');
  static final close = _wrap('<path d="M6 6l12 12M18 6L6 18"/>',
      attrs:
          'fill="none" stroke="currentColor" stroke-width="2.8" stroke-linecap="round"');
  static final arrowRight = _wrap('<path d="M5 12h14M13 6l6 6-6 6"/>',
      attrs:
          'fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"');

  /// Pulgar «Les encantó».
  static final thumb = _wrap(
      '<path d="M7 10.5v10H3.8v-10z"/><path d="M7 10.5l4.2-7c1.4 0 2.4 1.2 2.1 2.6l-.8 3.4h5.6a2 2 0 012 2.3l-1.2 7a2 2 0 01-2 1.7H7"/>',
      attrs:
          'fill="none" stroke="currentColor" stroke-width="2.2" stroke-linejoin="round" stroke-linecap="round"');

  /// Logo de vídeo (antetítulo «Jonay y Joana»).
  static final youtube = _wrap(
      '<rect x="2" y="5" width="20" height="14" rx="4.5" fill="#FF3B30"/><path d="M10 9v6l5-3z" fill="#FFFFFF"/>');

  /// Medalla (antetítulo «Valoración media»).
  static final medal = _wrap(
      '<path d="M8 2.5l2.6 6.2M16 2.5l-2.6 6.2" stroke="#0085C4" stroke-width="2.4"/>'
      '<circle cx="12" cy="15" r="6.2" fill="#C9A96B" stroke="#8A6A2E" stroke-width="1.6"/>'
      '<path d="M12 12.2l.9 1.8 2 .3-1.5 1.4.4 2-1.8-1-1.8 1 .4-2-1.5-1.4 2-.3z" fill="#FFF6E6"/>',
      attrs: 'fill="none" stroke-linecap="round" stroke-linejoin="round"');

  /// Copa (antetítulo «Sabores de aquí»; trazo = currentColor).
  static final wineGlass = _wrap(
      '<path d="M7.3 7.5h9.4l-.1.8a4.6 4.6 0 01-9.2 0z" fill="#8C1F2E" stroke="none"/>'
      '<path d="M7 3h10l-.4 5.2a4.6 4.6 0 01-9.2 0z"/><path d="M12 13v7M8.5 21h7"/>',
      attrs:
          'fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"');

  // ── Pestañas ─────────────────────────────────────────────────────────────
  static final tabExploraOn = _wrap(
      '<path d="M12 2.5a9.5 9.5 0 110 19 9.5 9.5 0 010-19zm4.2 5.3l-6 2.4-2.4 6 6-2.4z"/>',
      attrs: 'fill="currentColor" fill-rule="evenodd"');
  static final tabExplora = _wrap(
      '<circle cx="12" cy="12" r="9" fill="none" stroke="currentColor" stroke-width="1.8"/>'
      '<path d="M16.2 7.8l-6 2.4-2.4 6 6-2.4z" fill="currentColor"/>');
  static final tabListas = _wrap(
      '<path d="M9 6h11M9 12h11M9 18h11"/>'
      '<circle cx="4.5" cy="6" r="1.2" fill="currentColor" stroke="none"/>'
      '<circle cx="4.5" cy="12" r="1.2" fill="currentColor" stroke="none"/>'
      '<circle cx="4.5" cy="18" r="1.2" fill="currentColor" stroke="none"/>',
      attrs:
          'fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"');
  static final tabMapa = _wrap(
      '<path d="M9 4L3 6.5v13L9 17l6 2.5 6-2.5v-13L15 6.5z"/><path d="M9 4v13M15 6.5v13"/>',
      attrs:
          'fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"');
  static final tabVisitas = _wrap(
      '<rect x="3.5" y="5" width="17" height="14" rx="3.5"/><path d="M10.3 9.3v5.4l4.5-2.7z" fill="currentColor"/>',
      attrs:
          'fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"');
  static final tabPerfil = _wrap(
      '<circle cx="12" cy="8.5" r="3.8"/><path d="M4.5 20c1.3-3.6 4.1-5.5 7.5-5.5s6.2 1.9 7.5 5.5"/>',
      attrs:
          'fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"');

  // ── Ficha ────────────────────────────────────────────────────────────────
  static final car = _wrap(
      '<path d="M5 11l1.6-4.4A2 2 0 018.5 5.3h7a2 2 0 011.9 1.3L19 11a2 2 0 011 1.7V17a1 1 0 01-1 1h-1a1 1 0 01-1-1v-1H7v1a1 1 0 01-1 1H5a1 1 0 01-1-1v-4.3A2 2 0 015 11zm2.2-.5h9.6l-1.1-3.2H8.3zM7.5 14.3a1.2 1.2 0 100-2.4 1.2 1.2 0 000 2.4zm9 0a1.2 1.2 0 100-2.4 1.2 1.2 0 000 2.4z"/>',
      attrs: 'fill="currentColor" fill-rule="evenodd"');
  static final phone = _wrap(
      '<path d="M6.6 3.5h2.6l1.6 4.4-2 1.4a11 11 0 005.9 5.9l1.4-2 4.4 1.6v2.6a2 2 0 01-2.1 2A15.7 15.7 0 014.6 5.6a2 2 0 012-2.1z"/>',
      attrs: 'fill="currentColor"');
  static final bookmark = _wrap('<path d="M6.5 4h11v16l-5.5-4-5.5 4z"/>',
      attrs:
          'fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"');
  static final bookmarkFilled = _wrap('<path d="M6.5 4h11v16l-5.5-4-5.5 4z"/>',
      attrs:
          'fill="currentColor" stroke="currentColor" stroke-width="2" stroke-linejoin="round"');
  static final video = _wrap(
      '<rect x="3.5" y="5" width="17" height="14" rx="3.5"/><path d="M10.3 9.3v5.4l4.5-2.7z" fill="currentColor"/>',
      attrs:
          'fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"');
  static final clock = _wrap(
      '<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/>',
      attrs:
          'fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"');
  static final placeFilled = _wrap(
      '<path d="M12 2.5a7 7 0 017 7c0 5.2-7 12-7 12s-7-6.8-7-12a7 7 0 017-7zm0 4.5a2.5 2.5 0 100 5 2.5 2.5 0 000-5z"/>',
      attrs: 'fill="currentColor" fill-rule="evenodd"');
  static final globe = _wrap(
      '<circle cx="12" cy="12" r="8.5"/><path d="M3.5 12h17M12 3.5c2.4 2.4 3.5 5.2 3.5 8.5s-1.1 6.1-3.5 8.5c-2.4-2.4-3.5-5.2-3.5-8.5s1.1-6.1 3.5-8.5z"/>',
      attrs:
          'fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"');
  static final sun = _wrap(
      '<circle cx="12" cy="12" r="4.2" fill="#FFC53D" stroke="#E39B17"/>'
      '<path d="M12 2.5v2.2M12 19.3v2.2M2.5 12h2.2M19.3 12h2.2M5.3 5.3l1.6 1.6M17.1 17.1l1.6 1.6M5.3 18.7l1.6-1.6M17.1 6.9l1.6-1.6" stroke="#E39B17"/>',
      attrs: 'fill="none" stroke-width="2.2" stroke-linecap="round"');
  static final muted = _wrap(
      '<path d="M4 9.5h3.5L12 5.5v13l-4.5-4H4z" fill="currentColor" stroke="none"/><path d="M16 9.5l5 5M21 9.5l-5 5"/>',
      attrs:
          'fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"');
  static final volume = _wrap(
      '<path d="M4 9.5h3.5L12 5.5v13l-4.5-4H4z" fill="currentColor" stroke="none"/><path d="M15.5 9a4 4 0 010 6M18 6.5a7.5 7.5 0 010 11"/>',
      attrs:
          'fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"');
  static final chevronDouble = _wrap('<path d="M5 6l6 6-6 6M12 6l6 6-6 6"/>',
      attrs:
          'fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"');
}

/// Icono SVG de [GmIcons] con `currentColor` = [color].
class GmIcon extends StatelessWidget {
  final String svg;
  final double size;
  final Color color;
  final String? semanticLabel;

  const GmIcon(this.svg,
      {super.key, this.size = 18, required this.color, this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      svg,
      width: size,
      height: size,
      theme: SvgTheme(currentColor: color),
      semanticsLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
  }
}

/// Glifos de marca (multicolor, assets). Ver `assets/images/new-home/glyph_*`.
enum GmGlyphKind {
  volcan('glyph_volcan'),
  cabra('glyph_cabra'),
  cochino('glyph_cochino'),
  vieja('glyph_vieja'),
  copa('glyph_copa'),
  medalla('glyph_medalla'),
  pin('glyph_pin'),
  pulgar('glyph_pulgar'),
  barraquito('glyph_barraquito');

  final String file;
  const GmGlyphKind(this.file);

  String get asset => 'assets/images/new-home/$file.svg';
}

class GmGlyph extends StatelessWidget {
  final GmGlyphKind kind;
  final double size;
  const GmGlyph(this.kind, {super.key, this.size = 24});

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
        kind.asset,
        width: size,
        height: size,
        excludeFromSemantics: true,
      );
}
