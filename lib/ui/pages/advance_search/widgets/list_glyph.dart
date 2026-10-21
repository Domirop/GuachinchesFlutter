import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:guachinches/ui/pages/advance_search/list_theme.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart' show GmGinghamPainter;

/// Glifo de cada tipo/franja de las listas temáticas (copiados del tablero
/// ListaBuscar · «Explorar por tipo»). Los trazos usan [color] (la tinta del
/// tema); los rellenos de color son los del tablero.
class ListThemeGlyph extends StatelessWidget {
  final ListGlyph glyph;
  final double size;
  final Color color;

  const ListThemeGlyph(this.glyph,
      {super.key, this.size = 30, required this.color});

  /// SVG del glifo con la tinta dada («#RRGGBB»). Vacío para el mantel.
  static String svgFor(ListGlyph g, Color ink) {
    final argb = ink.toARGB32();
    return _svg(g, '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}');
  }

  static String _svg(ListGlyph g, String ink) {
    String wrap(String inner, {String attrs = ''}) =>
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" $attrs>$inner</svg>';
    switch (g) {
      case ListGlyph.restaurante:
        return wrap(
            '<path d="M7 3v7a2 2 0 002 2h0a2 2 0 002-2V3M9 12v9M9 3v5"/><path d="M17 3c-2 1.5-3 4-3 7h3v11M17 3v18"/>',
            attrs:
                'fill="none" stroke="$ink" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"');
      case ListGlyph.bar:
        return wrap(
            '<path d="M7.6 15.6h8.8l-.3 3.3a1.2 1.2 0 01-1.2 1.1H9.1a1.2 1.2 0 01-1.2-1.1z" fill="#F2E3C2"/><path d="M7.3 12.4h9.4l-.3 3.2H7.6z" fill="#B87A3A"/><path d="M7 9.4h10l-.3 3H7.3z" fill="#5A2E16"/><path d="M6.9 7.2h10.2l-.2 2.2H7.1z" fill="#FFF6E6"/><circle cx="10" cy="8.2" r=".5" fill="#B87A3A"/><circle cx="13.4" cy="8" r=".5" fill="#B87A3A"/><path d="M6.4 5h11.2l-1.4 15.2a2 2 0 01-2 1.8H9.8a2 2 0 01-2-1.8z" fill="none" stroke="#2A0E14" stroke-width="1.6" stroke-linejoin="round"/>');
      case ListGlyph.tradicional:
        return wrap(
            '<path d="M7.3 7.5h9.4l-.1.8a4.6 4.6 0 01-9.2 0z" fill="#8C1F2E" stroke="none"/><path d="M7 3h10l-.4 5.2a4.6 4.6 0 01-9.2 0z"/><path d="M12 13v7M8.5 21h7"/>',
            attrs:
                'fill="none" stroke="$ink" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"');
      case ListGlyph.tasca:
        return wrap(
            '<path d="M3 16h18l-2 3H5z" fill="#F2E3C2"/><path d="M12 3v13"/><circle cx="12" cy="7" r="2.4" fill="#B8322A" stroke="none"/><rect x="9" y="10" width="6" height="4" rx="1.5" fill="#E9B98A" stroke="none"/>',
            attrs:
                'fill="none" stroke="$ink" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"');
      case ListGlyph.bodegon:
        return wrap(
            '<path d="M6 4h12c1.5 2.5 1.5 13.5 0 16H6C4.5 17.5 4.5 6.5 6 4z" fill="#C9A06A"/><path d="M5 9h14M5 15h14"/>',
            attrs:
                'fill="none" stroke="$ink" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"');
      case ListGlyph.cofradia:
        return wrap(
            '<path d="M2.5 12c2-3.7 5.5-5.5 9-5.5 3 0 5.3 1.6 6.6 3.7L21.5 7v10l-3.4-3.2c-1.3 2.1-3.6 3.7-6.6 3.7-3.5 0-7-1.8-9-5.5z" fill="#C8463A"/><path d="M9.2 8.6c1 2.1 1 4.7 0 6.8" fill="none" stroke="#F2E8D5" stroke-width="1.3" stroke-linecap="round"/><circle cx="6" cy="11" r="1.2" fill="#F2E8D5"/><circle cx="6.1" cy="11" r=".55" fill="#241A16"/><path d="M12.6 10.2l2 1.8-2 1.8" fill="none" stroke="#F2E8D5" stroke-width="1.1" stroke-linecap="round" stroke-linejoin="round" opacity=".75"/>');
      case ListGlyph.mercado:
        return wrap(
            '<path d="M3.5 10h17l-2 10h-13z" fill="#E1E8D2"/><path d="M8 10l3-6M16 10l-3-6"/><circle cx="9" cy="14.5" r="1.2" fill="#B8322A" stroke="none"/><circle cx="13.5" cy="15.5" r="1.2" fill="#5E7D2E" stroke="none"/>',
            attrs:
                'fill="none" stroke="$ink" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"');
      case ListGlyph.lounge:
        return wrap(
            '<path d="M4 4h16l-8 9z" fill="#E7A5C0"/><path d="M12 13v7M8 20h8M16 7l3-4"/>',
            attrs:
                'fill="none" stroke="$ink" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"');
      case ListGlyph.experiencia:
        return wrap(
            '<path d="M12 3l2.6 5.6 6.1.7-4.5 4.2 1.2 6L12 16.6 6.6 19.5l1.2-6L3.3 9.3l6.1-.7z" fill="#F2C46A"/>',
            attrs:
                'fill="none" stroke="$ink" stroke-width="1.8" stroke-linejoin="round"');
      case ListGlyph.sol:
        return wrap(
            '<circle cx="12" cy="12" r="4.2" fill="#FFC53D" stroke="#E39B17"/><path d="M12 2.5v2.2M12 19.3v2.2M2.5 12h2.2M19.3 12h2.2M5.3 5.3l1.6 1.6M17.1 17.1l1.6 1.6M5.3 18.7l1.6-1.6M17.1 6.9l1.6-1.6" stroke="#E39B17"/>',
            attrs:
                'fill="none" stroke="$ink" stroke-width="2.2" stroke-linecap="round"');
      case ListGlyph.luna:
        return wrap(
            '<path d="M19 14.5A7.5 7.5 0 019.5 5a7.5 7.5 0 109.5 9.5z" fill="#F2E3C2"/>',
            attrs:
                'fill="none" stroke="$ink" stroke-width="2" stroke-linejoin="round"');
      case ListGlyph.buscar:
        return wrap(
            '<circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/>',
            attrs:
                'fill="none" stroke="$ink" stroke-width="2.4" stroke-linecap="round"');
      case ListGlyph.moderno:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (glyph == ListGlyph.moderno) {
      // Mantel de cuadros (tablero: losa de gingham).
      final s = size * 0.72;
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(s * 0.22),
            child: SizedBox(
              width: s,
              height: s,
              child: CustomPaint(painter: GmGinghamPainter(cell: s / 6)),
            ),
          ),
        ),
      );
    }
    return SvgPicture.string(
      svgFor(glyph, color),
      width: size,
      height: size,
      excludeFromSemantics: true,
    );
  }
}
