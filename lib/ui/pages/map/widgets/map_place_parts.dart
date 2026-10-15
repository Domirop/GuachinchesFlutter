import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guachinches/ui/pages/advance_search/list_theme.dart';
import 'package:guachinches/ui/pages/advance_search/widgets/list_cards.dart'
    show ListOpenStatus, ListRating;
import 'package:guachinches/ui/pages/map/map_logic.dart';
import 'package:guachinches/ui/pages/map/widgets/map_chrome.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart'
    show GmPhoto, gmDisplayName, gmPlaceName;
import 'package:guachinches/ui/theme/gm_favorites.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';

/// Piezas de sitio compartidas por la hoja del sitio elegido, el carrusel y
/// la lista de «Cerca de ti».

/// Foto del sitio o, si no tiene, tinte del tipo + glifo.
class MapSitePhoto extends StatelessWidget {
  final MapSite site;
  final double size;
  final double radius;
  final double glyph;
  const MapSitePhoto(this.site,
      {super.key, required this.size, required this.radius, this.glyph = 40});

  @override
  Widget build(BuildContext context) {
    final url = site.restaurant.mainFoto;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: url.isEmpty
            ? MapTypeTile(site.kind, size: size, glyph: glyph, radius: radius)
            : GmPhoto(url, decodeWidth: (size * 3).round()),
      ),
    );
  }
}

/// «★ 5,0 (7)» / «★ 5,0 · 3 reseñas»; nada sin valoración.
Widget? mapRating(MapSite s, {bool long = false}) {
  final r = s.restaurant;
  if (r.avgRating <= 0) return null;
  final n = r.valoraciones.length;
  if (n == 0) return null;
  return ListRating(r.avgRating, n, long: long);
}

/// Meta de fila: «Tipo · Municipio · 1,4 km» (tipo en negrita).
class MapSiteMeta extends StatelessWidget {
  final MapSite site;
  final bool showType;
  final bool showRating;
  const MapSiteMeta(this.site,
      {super.key, this.showType = true, this.showRating = false});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final muni = gmPlaceName(site.restaurant.municipio);
    final type = site.typeLabel;
    final km = site.meters == null ? null : mapKm(site.meters!);
    final parts = <InlineSpan>[];
    void add(InlineSpan s) {
      if (parts.isNotEmpty) parts.add(const TextSpan(text: ' · '));
      parts.add(s);
    }

    if (showType && type.isNotEmpty) {
      add(TextSpan(
          text: type,
          style: TextStyle(fontWeight: FontWeight.w600, color: gm.label)));
    }
    if (muni.isNotEmpty) add(TextSpan(text: muni));
    if (km != null) add(TextSpan(text: km));
    final r = site.restaurant;
    if (showRating && r.avgRating > 0 && r.valoraciones.isNotEmpty) {
      add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.only(right: 3),
          child: GmIcon(GmIcons.star, size: 11, color: GmColors.star),
        ),
      ));
      parts.add(TextSpan(
          text: '${r.avgRating.toStringAsFixed(1).replaceAll('.', ',')} ',
          style: TextStyle(color: gm.label, fontWeight: FontWeight.w600)));
      parts.add(TextSpan(text: '(${r.valoraciones.length})'));
    }
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text.rich(
      TextSpan(children: parts),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GmText.meta(color: gm.label2),
    );
  }
}

/// Fila de sitio en tarjeta (carrusel de «Cerca de ti»): foto 88, nombre,
/// meta, estado y valoración; corazón a la derecha.
class MapRowCard extends StatelessWidget {
  final MapSite site;
  final VoidCallback onTap;
  final bool highlighted;
  final GmFavorites? favorites;
  const MapRowCard({
    super.key,
    required this.site,
    required this.onTap,
    this.highlighted = false,
    this.favorites,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final r = site.restaurant;
    final rating = mapRating(site, long: true);
    return Semantics(
      identifier: 'mapa-nearby-card-${r.id}',
      container: true,
      child: Stack(
        children: [
          GmPressable(
            onTap: onTap,
            semanticsLabel: gmDisplayName(r.nombre),
            child: AnimatedContainer(
              duration:
                  Duration(milliseconds: GmMotion.reduced(context) ? 0 : 220),
              padding: const EdgeInsets.fromLTRB(8, 8, 44, 8),
              decoration: BoxDecoration(
                color: gm.card,
                borderRadius: BorderRadius.circular(GmRadius.card),
                boxShadow: gm.shadow1,
                border: Border.all(
                    color: highlighted ? gm.accent : Colors.transparent,
                    width: 1.5),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MapSitePhoto(site, size: 88, radius: 16),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            gmDisplayName(r.nombre),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GmText.guideTitle(color: gm.label),
                          ),
                          const SizedBox(height: 2),
                          MapSiteMeta(site, showType: false),
                          const SizedBox(height: 2),
                          ListOpenStatus(site.open),
                          if (rating != null) ...[
                            const SizedBox(height: 2),
                            rating,
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 2,
            top: 2,
            child: MapSaveHeart(
              restaurantId: r.id,
              restaurantName: gmDisplayName(r.nombre),
              favorites: favorites,
            ),
          ),
        ],
      ),
    );
  }
}

/// Corazón sobre tarjeta (relleno `fill`, 32 visibles, 44 de toque),
/// cableado a [GmFavorites]. Variante de `GmFavButton` para tarjeta blanca.
class MapSaveHeart extends StatelessWidget {
  final String restaurantId;
  final String restaurantName;
  final GmFavorites? favorites;
  const MapSaveHeart({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
    this.favorites,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final favs = favorites ?? GmFavorites.instance;
    favs.ensureLoaded();
    return ValueListenableBuilder<Set<String>>(
      valueListenable: favs,
      builder: (_, ids, __) {
        final saved = ids.contains(restaurantId);
        return Semantics(
          button: true,
          toggled: saved,
          label: saved
              ? 'Quitar $restaurantName de guardados'
              : 'Guardar $restaurantName',
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.lightImpact();
              favs.toggle(restaurantId);
            },
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: Container(
                  width: 32,
                  height: 32,
                  decoration:
                      BoxDecoration(color: gm.fill, shape: BoxShape.circle),
                  child: Center(
                    child: GmIcon(saved ? GmIcons.heartFilled : GmIcons.heart,
                        size: 16, color: saved ? GmColors.heart : gm.label2),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Antetítulo con glifo del tipo: «Guachinche moderno · La Victoria».
class MapSiteEyebrow extends StatelessWidget {
  final MapSite site;
  const MapSiteEyebrow(this.site, {super.key});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final theme = site.kind == null ? null : kListThemes[site.kind];
    final color = theme?.ink(gm.isDark) ?? gm.label2;
    final muni = gmPlaceName(site.restaurant.municipio);
    final text = [
      if (site.typeLabel.isNotEmpty) site.typeLabel,
      if (muni.isNotEmpty) muni,
    ].join(' · ');
    if (text.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        if (theme != null) ...[
          MapTypeGlyph(site.kind, size: 14, color: color),
          const SizedBox(width: 5),
        ],
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GmText.eyebrow(color: color),
          ),
        ),
      ],
    );
  }
}
