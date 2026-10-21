import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/ui/components/vignettes/list_vignette.dart';
import 'package:guachinches/ui/pages/advance_search/list_theme.dart';
import 'package:guachinches/ui/pages/advance_search/widgets/list_glyph.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_home_extras.dart'
    show GmCloudEdge;
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

/// Cabecera de la lista curada (tableros «Lista curada, …»): banda del tema,
/// viñeta con personaje a la derecha (180×180 a escala), antetítulo con el
/// glifo del tema, título grande y subtítulo, y el borde «mar de nubes».
/// Atrás y Compartir son botones de cristal fijos arriba.
class CuratedListHeader extends StatelessWidget {
  final ListTheme theme;
  final ListVignetteKind? vignette;
  final String eyebrow;
  final String title;
  final String subtitle;

  /// La viñeta solo corre mientras la cabecera se ve.
  final ValueListenable<bool> sceneVisible;
  final VoidCallback onBack;
  final VoidCallback onShare;

  const CuratedListHeader({
    super.key,
    required this.theme,
    required this.vignette,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.sceneVisible,
    required this.onBack,
    required this.onShare,
  });

  static TextStyle _titleStyle(Color color, double size) =>
      GmText.largeTitle(color: color)
          .copyWith(fontSize: size, height: 39 / 34, letterSpacing: -0.8);

  /// Tamaño del título junto a la viñeta: el mayor (34 → 28) con el que cada
  /// palabra cabe entera en [maxWidth] y el título no pasa de 3 líneas.
  /// `null` si ni a 28 cabe: entonces el título va a todo el ancho y la
  /// viñeta baja junto al subtítulo.
  @visibleForTesting
  static double? titleSizeBeside(
      String title, double maxWidth, TextScaler scaler) {
    final words = title.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    for (final size in const [34.0, 31.0, 28.0]) {
      final style = _titleStyle(const Color(0xFF000000), size);
      TextPainter paint(String t, {double? width}) => TextPainter(
            text: TextSpan(text: t, style: style),
            textDirection: TextDirection.ltr,
            textScaler: scaler,
          )..layout(maxWidth: width ?? double.infinity);
      final wordsFit = words.every((w) => paint(w).width <= maxWidth);
      if (wordsFit &&
          paint(title, width: maxWidth).computeLineMetrics().length <= 3) {
        return size;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final dark = gm.isDark;
    final top = MediaQuery.paddingOf(context).top;
    final width = MediaQuery.sizeOf(context).width;
    final s = (width / 402).clamp(0.8, 1.2);
    final ink = theme.ink(dark);
    final kind = vignette;
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);
    final bigText = scaler.scale(10) > 12;

    Widget scene(double size) => ExcludeSemantics(
          child: SizedBox(
            width: size,
            height: size,
            child: ValueListenableBuilder<bool>(
              valueListenable: sceneVisible,
              builder: (_, visible, __) =>
                  ListVignette(kind: kind!, active: visible),
            ),
          ),
        );

    final eyebrowW = GmEyebrow(
      leading: ListThemeGlyph(theme.glyph, size: 14, color: ink),
      text: eyebrow,
      color: ink,
    );
    Widget titleW(double size) => Semantics(
          header: true,
          identifier: 'curated-list-title',
          child: Text(title, style: _titleStyle(gm.label, size)),
        );
    final subtitleW = subtitle.isEmpty
        ? null
        : Text(subtitle, style: GmText.body(color: gm.label2));

    // Tablero: texto en x 20…212 y la viñeta de 180 a la derecha (asoma 12
    // por el margen). El subtítulo va a todo el ancho, debajo.
    final besideWidth = width - 40 - 168 * s;
    final besideSize = kind == null || bigText
        ? null
        : titleSizeBeside(title, besideWidth, scaler);

    final Widget content;
    if (kind == null || bigText) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          eyebrowW,
          const SizedBox(height: 4),
          titleW(34),
          if (subtitleW != null) ...[const SizedBox(height: 6), subtitleW],
          if (kind != null) ...[
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerRight, child: scene(132 * s)),
          ],
        ],
      );
    } else if (besideSize != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      eyebrowW,
                      const SizedBox(height: 4),
                      titleW(besideSize),
                    ],
                  ),
                ),
              ),
              // Reserva 168 × 150; la viñeta de 180 asoma 30 por arriba (bajo
              // la barra) y 12 por el margen derecho, como en el tablero.
              SizedBox(
                width: 168 * s,
                height: 150 * s,
                child: OverflowBox(
                  minWidth: 180 * s,
                  maxWidth: 180 * s,
                  minHeight: 180 * s,
                  maxHeight: 180 * s,
                  alignment: Alignment.bottomLeft,
                  child: scene(180 * s),
                ),
              ),
            ],
          ),
          if (subtitleW != null) ...[const SizedBox(height: 4), subtitleW],
        ],
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          eyebrowW,
          const SizedBox(height: 4),
          titleW(34),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: subtitleW ?? const SizedBox.shrink()),
              const SizedBox(width: 8),
              scene(140 * s),
            ],
          ),
        ],
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: ColoredBox(color: theme.band(dark))),
        Padding(
          padding: EdgeInsets.fromLTRB(20, top + 64, 20, 52),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: scaler),
            child: content,
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          top: top + 2,
          child: Row(
            children: [
              GmToolbarButton(
                icon: GmIcons.chevronLeft,
                iconSize: 20,
                light: true,
                semanticLabel: 'Volver',
                identifier: 'curated-list-back-button',
                onTap: onBack,
              ),
              const Spacer(),
              GmToolbarButton(
                icon: GmIcons.share,
                light: true,
                semanticLabel: 'Compartir lista',
                identifier: 'curated-list-share-button',
                onTap: onShare,
              ),
            ],
          ),
        ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: -1,
          child: GmCloudEdge(),
        ),
      ],
    );
  }
}
