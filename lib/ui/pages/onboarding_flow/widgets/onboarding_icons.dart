import 'package:flutter/widgets.dart';
import 'package:guachinches/ui/pages/onboarding_flow/onboarding_logic.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';

/// Iconos de trazo del tablero `Onboarding` / `UbicacionDenegada`
/// (`tools/gen_arranque.py`, rejilla 24, trazo 2, `currentColor`).
///
/// Candidatos a subir a `lib/ui/theme/gm_icons.dart` (`GmIcons`): viven aquí
/// porque la capa de tema es compartida.
class OnbIcons {
  OnbIcons._();

  static String _stroke(String inner, {double width = 2}) =>
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
      'stroke="currentColor" stroke-width="$width" stroke-linecap="round" '
      'stroke-linejoin="round">$inner</svg>';

  // ── Gustos ──────────────────────────────────────────────────────────────
  static final papas = _stroke(
      '<ellipse cx="8.5" cy="14" rx="5" ry="4"/><ellipse cx="16" cy="11" rx="4.5" ry="3.6"/>'
      '<path d="M7 13.2h.01M10 15h.01M15 10.4h.01M17.4 12h.01"/>');
  static final puchero = _stroke(
      '<path d="M4.5 10.5h15v4.5a5 5 0 01-5 5h-5a5 5 0 01-5-5z"/>'
      '<path d="M2.5 10.5h19M9.5 7c0-1.2 1.2-1.6 1.2-3M13.8 7c0-1.2 1.2-1.6 1.2-3"/>');
  static final sinGluten = _stroke('<path d="M12 21V8.5"/>'
      '<path d="M12 8.5c-1.9-.9-2.8-2.6-2.8-4.6 1.9.8 2.8 2.6 2.8 4.6zM12 8.5c1.9-.9 2.8-2.6 2.8-4.6-1.9.8-2.8 2.6-2.8 4.6zM12 13.5c-2-.8-3.3-2.4-3.3-4.3 2 .4 3.3 2.2 3.3 4.3zM12 13.5c2-.8 3.3-2.4 3.3-4.3-2 .4-3.3 2.2-3.3 4.3z"/>'
      '<path d="M4 4l16 16"/>');
  static final conV = _stroke(
      '<circle cx="12" cy="12" r="8.5"/><path d="M8.6 8.4L12 16l3.4-7.6"/>');
  static final terraza = _stroke(
      '<path d="M3.5 11a8.5 8.5 0 0117 0z"/><path d="M12 11v9.5M8 20.5h8"/>');
  static final vistas = _stroke(
      '<path d="M2.5 19.5l6-9 4 5.5 2.5-3 6.5 6.5z"/><circle cx="17" cy="6" r="2.4"/>');
  static final cesta = _stroke('<path d="M3.5 10h17l-2 10h-13z"/>'
      '<path d="M8 10l3-6M16 10l-3-6M9.5 13.5v3.5M14.5 13.5v3.5"/>');
  static final datafono = _stroke(
      '<rect x="6" y="2.5" width="12" height="19" rx="2.5"/><rect x="8.5" y="5" width="7" height="4.5" rx="1"/>'
      '<path d="M9 13h.01M12 13h.01M15 13h.01M9 16.5h.01M12 16.5h.01M15 16.5h.01"/>');
  static final accesible = _stroke(
      '<circle cx="11" cy="4.5" r="1.8"/><path d="M11 7.5v6h5l2.5 5"/><path d="M8 10.6a5.5 5.5 0 107.6 7.2"/>');
  static final pata = _stroke(
      '<circle cx="6.6" cy="10" r="1.7"/><circle cx="10" cy="6" r="1.7"/><circle cx="14.4" cy="6" r="1.7"/><circle cx="17.8" cy="10" r="1.7"/>'
      '<path d="M12.2 11.2c-3 0-5.4 3.6-5.4 6 0 2 1.9 2.4 3 1.9.9-.4 1.4-.7 2.4-.7s1.5.3 2.4.7c1.1.5 3 .1 3-1.9 0-2.4-2.4-6-5.4-6z"/>');
  static final gallina = _stroke(
      '<path d="M5.5 12.5c0 4.4 3 7.5 7 7.5s6.5-3 6.5-6.5l2.5-3.5-3.2-.5c-.8-3-2.8-4.5-5.3-4.5-2.6 0-4 1.8-4 4 0 1 .3 1.8.8 2.4z"/>'
      '<path d="M10.5 5.2c-.4-1.5.6-2.7 2-2.7"/><path d="M9 20l-.5 2M14 20l.5 2"/>');
  static final globo = _stroke(
      '<path d="M12 3a5.5 5.5 0 015.5 5.5c0 3.4-2.8 6.5-5.5 6.5S6.5 11.9 6.5 8.5A5.5 5.5 0 0112 3z"/>'
      '<path d="M12 15l-1 1.6h2zM12 16.6c0 1.6-1.6 1.8-1.6 3.4 0 .9.6 1.5 1.4 1.5"/>');
  static final plato = _stroke(
      '<circle cx="12" cy="12" r="8.5"/><circle cx="12" cy="12" r="4.5"/>');

  // ── Interfaz ────────────────────────────────────────────────────────────
  static final lock = _stroke(
      '<rect x="5" y="10.5" width="14" height="10" rx="2.5"/><path d="M8 10.5V8a4 4 0 018 0v2.5"/>',
      width: 2.2);
  static final pinOutline = _stroke(
      '<path d="M12 21.5s-7-6.6-7-12a7 7 0 0114 0c0 5.4-7 12-7 12z"/><circle cx="12" cy="9.5" r="2.6"/>',
      width: 2.2);
  static final locate =
      _stroke('<path d="M20.5 3.5L3.5 10.6l7 2.4 2.4 7z"/>', width: 2.2);
  static final locateOff = _stroke(
      '<path d="M20.5 3.5L3.5 10.6l7 2.4 2.4 7z"/><path d="M2.5 2.5l19 19"/>',
      width: 2.2);
  static final gear = _stroke(
      '<circle cx="12" cy="12" r="3"/><path d="M12 2.8v3M12 18.2v3M2.8 12h3M18.2 12h3M5.5 5.5l2.1 2.1M16.4 16.4l2.1 2.1M5.5 18.5l2.1-2.1M16.4 7.6l2.1-2.1"/>',
      width: 2.2);
  static final mano = _stroke(
      '<path d="M8 12.5V5.6a1.5 1.5 0 013 0V11M11 10.5V4.2a1.5 1.5 0 013 0v6.3M14 10.5V5.8a1.5 1.5 0 013 0V14c0 4-2.5 7-6.5 7-2.9 0-4.5-1.4-6-4l-1.8-3.2a1.5 1.5 0 012.5-1.6L8 14.2"/>',
      width: 2.2);
  static final diana = _stroke(
      '<circle cx="12" cy="12" r="7"/><circle cx="12" cy="12" r="2.4"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3"/>',
      width: 2.2);
  static final check = _stroke('<path d="M5 12.5l4.2 4.2L19 7"/>', width: 2.6);
  static final alert = _stroke(
      '<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5v5.5"/><circle cx="12" cy="16.4" r=".6" fill="currentColor"/>');

  /// Logotipo de Apple (relleno `currentColor`).
  static const apple =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path fill="currentColor" '
      'd="M16.37 12.6c-.02-2.3 1.88-3.4 1.96-3.46-1.07-1.56-2.73-1.78-3.32-1.8-1.41-.14-2.76.83-3.48.83-.72 0-1.82-.81-3-.79-1.54.02-2.96.9-3.76 2.27-1.6 2.78-.41 6.9 1.15 9.16.76 1.1 1.67 2.34 2.86 2.3 1.15-.05 1.58-.74 2.97-.74 1.38 0 1.77.74 2.98.72 1.23-.02 2.01-1.12 2.76-2.23.87-1.28 1.23-2.52 1.25-2.58-.03-.01-2.4-.92-2.42-3.66zM14.1 5.86c.63-.77 1.06-1.83.94-2.89-.91.04-2.01.61-2.66 1.37-.58.67-1.09 1.75-.96 2.79 1.02.08 2.05-.52 2.68-1.27z"/></svg>';

  /// «G» de Google a cuatro colores (marca; no se tiñe).
  static const google =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="12 12 20 20">'
      '<path d="M31.6 22.2273C31.6 21.5182 31.5364 20.8364 31.4182 20.1818H22V24.05H27.3818C27.15 25.3 26.4455 26.3591 25.3864 27.0682V29.5773H28.6182C30.5091 27.8364 31.6 25.2727 31.6 22.2273Z" fill="#4285F4"/>'
      '<path d="M22 32C24.7 32 26.9636 31.1045 28.6181 29.5773L25.3863 27.0682C24.4909 27.6682 23.3454 28.0227 22 28.0227C19.3954 28.0227 17.1909 26.2636 16.4045 23.9H13.0636V26.4909C14.7091 29.7591 18.0909 32 22 32Z" fill="#34A853"/>'
      '<path d="M16.4045 23.9C16.2045 23.3 16.0909 22.6591 16.0909 22C16.0909 21.3409 16.2045 20.7 16.4045 20.1V17.5091H13.0636C12.3864 18.8591 12 20.3864 12 22C12 23.6136 12.3864 25.1409 13.0636 26.4909L16.4045 23.9Z" fill="#FBBC04"/>'
      '<path d="M22 15.9773C23.4681 15.9773 24.7863 16.4818 25.8227 17.4727L28.6909 14.6045C26.9591 12.9909 24.6954 12 22 12C18.0909 12 14.7091 14.2409 13.0636 17.5091L16.4045 20.1C17.1909 17.7364 19.3954 15.9773 22 15.9773Z" fill="#E94235"/></svg>';
}

/// Glifo de un gusto: los de marca son assets multicolor ([GmGlyph]); el
/// resto, trazo en el color del texto del chip.
class OnbTasteIcon extends StatelessWidget {
  final OnbTasteGlyph glyph;
  final Color color;
  final double size;

  const OnbTasteIcon(this.glyph,
      {super.key, required this.color, this.size = 18});

  @override
  Widget build(BuildContext context) {
    final brand = switch (glyph) {
      OnbTasteGlyph.cabra => GmGlyphKind.cabra,
      OnbTasteGlyph.cochino => GmGlyphKind.cochino,
      OnbTasteGlyph.vieja => GmGlyphKind.vieja,
      OnbTasteGlyph.copa => GmGlyphKind.copa,
      OnbTasteGlyph.volcan => GmGlyphKind.volcan,
      _ => null,
    };
    if (brand != null) return GmGlyph(brand, size: size);
    final svg = switch (glyph) {
      OnbTasteGlyph.papas => OnbIcons.papas,
      OnbTasteGlyph.puchero => OnbIcons.puchero,
      OnbTasteGlyph.sinGluten => OnbIcons.sinGluten,
      OnbTasteGlyph.conV => OnbIcons.conV,
      OnbTasteGlyph.terraza => OnbIcons.terraza,
      OnbTasteGlyph.vistas => OnbIcons.vistas,
      OnbTasteGlyph.cesta => OnbIcons.cesta,
      OnbTasteGlyph.datafono => OnbIcons.datafono,
      OnbTasteGlyph.accesible => OnbIcons.accesible,
      OnbTasteGlyph.pata => OnbIcons.pata,
      OnbTasteGlyph.gallina => OnbIcons.gallina,
      OnbTasteGlyph.globo => OnbIcons.globo,
      _ => OnbIcons.plato,
    };
    return GmIcon(svg, size: size, color: color);
  }
}
