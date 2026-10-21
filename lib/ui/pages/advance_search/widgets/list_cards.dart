import 'package:flutter/material.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/advance_search/list_logic.dart';
import 'package:guachinches/ui/pages/advance_search/list_theme.dart';
import 'package:guachinches/ui/pages/advance_search/widgets/list_glyph.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart'
    show GmPhoto, gmDisplayName, gmPlaceName;
import 'package:guachinches/ui/pages/restaurant_detail/ficha_logic.dart'
    show FichaFeature, fichaCategoryFeature;
import 'package:guachinches/ui/pages/restaurant_detail/widgets/gm_ficha_header.dart'
    show FichaFeatureChips;
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';
import 'package:guachinches/utils/open_state.dart';

/// Tarjetas de la lista de resultados (Sistema §08 · «Anatomía de la
/// tarjeta de lista»): foto 4:3 r18 en tarjeta r24, como mucho un chip de
/// texto arriba a la izquierda, corazón de 44, distancia en cristal (solo
/// con ubicación), nombre en tipo título (2 líneas), estado preciso y
/// «municipio · ★ 4,8 (9)» solo si hay reseñas.

/// Datos ya resueltos de una tarjeta (los calcula la pantalla una vez).
class ListCardData {
  final Restaurant restaurant;
  final OpenState open;
  final String? distance;
  final String? photo;

  /// Plato que coincide con la búsqueda (resultados por plato).
  final String? dishMatch;

  /// «Guachinche tradicional» (resultados mezclados).
  final String? typeLabel;

  const ListCardData({
    required this.restaurant,
    required this.open,
    this.distance,
    this.photo,
    this.dishMatch,
    this.typeLabel,
  });
}

/// «● Abierto hasta 13:00» / ámbar «Cierra en 20 min» / «Cerrado · abre…» /
/// «🕒 Horario sin confirmar».
class ListOpenStatus extends StatelessWidget {
  final OpenState state;
  final double fontSize;
  const ListOpenStatus(this.state, {super.key, this.fontSize = 13});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final l = listOpenLabel(state);
    final lh = fontSize == 13 ? 18 / 13 : 1.3;
    TextStyle st(Color c, FontWeight w) =>
        TextStyle(fontSize: fontSize, height: lh, fontWeight: w, color: c);
    Widget dot(Color c) => Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        );
    final Widget lead;
    final Color color;
    switch (l.kind) {
      case OpenKind.open:
        lead = dot(gm.green);
        color = gm.greenText;
      case OpenKind.closingSoon:
        lead = dot(gm.warnText);
        color = gm.warnText;
      case OpenKind.closed:
        lead = dot(gm.closedText);
        color = gm.closedText;
      case OpenKind.unknown:
        lead = GmIcon(GmIcons.clock, size: 12, color: gm.label2);
        color = gm.label2;
    }
    return Semantics(
      label: l.text,
      excludeSemantics: true,
      child: Row(
        children: [
          lead,
          const SizedBox(width: 5),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: l.lead,
                style: st(
                    color,
                    l.kind == OpenKind.unknown
                        ? FontWeight.w400
                        : FontWeight.w600),
                children: [
                  if (l.rest.isNotEmpty)
                    TextSpan(
                        text: l.rest, style: st(gm.label2, FontWeight.w500)),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// «★ 4,8 (9)» o «★ 4,8 · 9 reseñas».
class ListRating extends StatelessWidget {
  final double value;
  final int count;
  final bool long;
  const ListRating(this.value, this.count, {super.key, this.long = false});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    if (value <= 0 || count == 0) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GmIcon(GmIcons.star, size: 12, color: GmColors.star),
        const SizedBox(width: 3),
        Text.rich(
          TextSpan(
            text: GmRating.format(value),
            style: TextStyle(
                fontSize: 13,
                height: 18 / 13,
                fontWeight: FontWeight.w600,
                color: gm.label),
            children: [
              TextSpan(
                text: long
                    ? ' · ${count == 1 ? '1 reseña' : '$count reseñas'}'
                    : ' ($count)',
                style: TextStyle(fontWeight: FontWeight.w500, color: gm.label2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Hueco sin foto: tinte del tema + glifo del tipo.
class ListNoPhoto extends StatelessWidget {
  final ListTheme theme;
  final double glyphSize;
  const ListNoPhoto(this.theme, {super.key, this.glyphSize = 44});

  @override
  Widget build(BuildContext context) {
    final dark = GmColors.of(context).isDark;
    return ColoredBox(
      color: theme.tint(dark),
      child: Center(
        child: ListThemeGlyph(theme.glyph,
            size: glyphSize, color: theme.ink(dark)),
      ),
    );
  }
}

Widget _photo(ListCardData d, ListTheme theme, {double glyph = 44}) {
  final url = d.photo;
  if (url == null || url.isEmpty) return ListNoPhoto(theme, glyphSize: glyph);
  return GmPhoto(url, decodeWidth: 600, fallbacks: const []);
}

Widget? _textChip(Restaurant r) {
  final label = listCardChip(r);
  if (label == null) return null;
  return Builder(builder: (context) {
    final gm = GmColors.of(context);
    return GmPhotoChip(
      label: label,
      leading: label == 'Terraza'
          ? GmIcon(GmIcons.sun, size: 13, color: const Color(0xFFE39B17))
          : GmIcon(GmIcons.paw, size: 12, color: gm.photoInk),
    );
  });
}

Widget _distanceChip(String d) => GmPhotoChip(
      leading: GmIcon(GmIcons.navArrow, size: 10, color: GmColors.atlantico),
      label: d,
    );

/// Chip del plato buscado (resultados por plato).
class ListDishChip extends StatelessWidget {
  final String restaurantId;
  final String dish;
  const ListDishChip(
      {super.key, required this.restaurantId, required this.dish});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final t = dish.trim();
    final label = t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);
    final f = fichaCategoryFeature(dish);
    final glyph = FichaFeatureChips.glyph(f.glyph, gm);
    return Semantics(
      identifier: 'advanced-search-dish-chip-$restaurantId',
      label: 'Coincide con tu búsqueda: $dish',
      excludeSemantics: true,
      child: Container(
        height: 26,
        padding: const EdgeInsets.fromLTRB(7, 0, 9, 0),
        decoration: BoxDecoration(
          color: gm.accentSoft,
          borderRadius: BorderRadius.circular(GmRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (glyph != null) ...[
              IconTheme(data: IconThemeData(color: gm.accent), child: glyph),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GmText.chip(color: gm.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta de la rejilla de 2 columnas.
class ListGridCard extends StatelessWidget {
  final ListCardData data;
  final ListTheme theme;
  final VoidCallback onTap;
  final String? identifier;

  const ListGridCard({
    super.key,
    required this.data,
    required this.theme,
    required this.onTap,
    this.identifier,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final r = data.restaurant;
    final chip = _textChip(r);
    final muni = gmPlaceName(r.municipio);
    final rating = listDisplayRating(r);
    final reviews = listReviewCount(r);
    final lineH = MediaQuery.textScalerOf(context).scale(21);

    return Stack(
      children: [
        GmPressable(
          onTap: onTap,
          semanticsIdentifier: identifier,
          semanticsLabel: r.nombre,
          child: GmCard(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(GmRadius.photo),
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _photo(data, theme),
                          if (chip != null)
                            Positioned(left: 8, top: 8, child: chip),
                          if (data.distance != null)
                            Positioned(
                                left: 8,
                                bottom: 8,
                                child: _distanceChip(data.distance!)),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 9, 6, 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(minHeight: lineH * 2),
                          child: Text(
                            gmDisplayName(r.nombre),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GmText.cardTitle(color: gm.label),
                          ),
                        ),
                        const SizedBox(height: 3),
                        ListOpenStatus(data.open),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                data.typeLabel != null && muni.isNotEmpty
                                    ? '${data.typeLabel} · $muni'
                                    : (data.typeLabel ?? muni),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GmText.meta(color: gm.label2),
                              ),
                            ),
                            if (reviews > 0) ...[
                              const SizedBox(width: 6),
                              ListRating(rating, reviews),
                            ],
                          ],
                        ),
                        if (data.dishMatch != null) ...[
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: ListDishChip(
                                restaurantId: r.id, dish: data.dishMatch!),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: 4,
          top: 4,
          child: GmFavButton(restaurantId: r.id, restaurantName: r.nombre),
        ),
      ],
    );
  }
}

/// Primera tarjeta destacada (a todo el ancho): «Mejor valorado · 9
/// reseñas», título 20/25 y los chips de características.
class ListFeaturedCard extends StatelessWidget {
  final ListCardData data;
  final ListTheme theme;
  final VoidCallback onTap;

  const ListFeaturedCard({
    super.key,
    required this.data,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final r = data.restaurant;
    final reviews = listReviewCount(r);
    final features = <FichaFeature>[];
    for (final c in r.categoriaRestaurantes) {
      final f = fichaCategoryFeature(c.categorias.nombre);
      if (f.label.isEmpty || features.any((x) => x.label == f.label)) continue;
      features.add(f);
    }
    final ink = theme.ink(gm.isDark);
    final muni = gmPlaceName(r.municipio);

    return Stack(
      children: [
        GmPressable(
          onTap: onTap,
          semanticsIdentifier: 'advanced-search-featured',
          semanticsLabel: r.nombre,
          child: GmCard(
            radius: 28,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: SizedBox(
                      height: 196,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _photo(data, theme, glyph: 64),
                          if (data.distance != null)
                            Positioned(
                                left: 10,
                                bottom: 10,
                                child: _distanceChip(data.distance!)),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 11, 10, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ListThemeGlyph(theme.glyph, size: 14, color: ink),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                reviews == 1
                                    ? 'Mejor valorado · 1 reseña'
                                    : 'Mejor valorado · $reviews reseñas',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    GmText.chip(color: ink, w: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          gmDisplayName(r.nombre),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GmText.poster(color: gm.label),
                        ),
                        const SizedBox(height: 3),
                        ListOpenStatus(data.open),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (muni.isNotEmpty)
                              Flexible(
                                child: Text(muni,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GmText.meta(color: gm.label2)),
                              ),
                            const SizedBox(width: 8),
                            ListRating(listDisplayRating(r), reviews,
                                long: true),
                          ],
                        ),
                        if (data.dishMatch != null) ...[
                          const SizedBox(height: 6),
                          ListDishChip(
                              restaurantId: r.id, dish: data.dishMatch!),
                        ] else if (features.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          _FeatureRow(features: features),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: 8,
          top: 8,
          child: GmFavButton(restaurantId: r.id, restaurantName: r.nombre),
        ),
      ],
    );
  }
}

/// Chips de características (fondo de relleno, fundido a la derecha).
class _FeatureRow extends StatelessWidget {
  final List<FichaFeature> features;
  const _FeatureRow({required this.features});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) => LinearGradient(
          colors: const [Colors.black, Colors.black, Colors.transparent],
          stops: [0, (rect.width - 28) / rect.width, 1],
        ).createShader(rect),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Row(
            children: [
              for (final f in features.take(4)) ...[
                Container(
                  height: 26,
                  margin: const EdgeInsets.only(right: 5),
                  padding: const EdgeInsets.fromLTRB(7, 0, 9, 0),
                  decoration: BoxDecoration(
                    color: gm.fill,
                    borderRadius: BorderRadius.circular(GmRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (FichaFeatureChips.glyph(f.glyph, gm)
                          case final g?) ...[
                        SizedBox(
                            width: 15, height: 15, child: FittedBox(child: g)),
                        const SizedBox(width: 5)
                      ],
                      Text(f.label, style: GmText.chip(color: gm.label)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Fila de resultados de búsqueda (tablero ListaBuscar · resultados): foto
/// a la izquierda, «Tipo · municipio · km», estado, nota y chips.
class ListRowCard extends StatelessWidget {
  final ListCardData data;
  final ListTheme theme;
  final VoidCallback onTap;

  const ListRowCard({
    super.key,
    required this.data,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final r = data.restaurant;
    final muni = gmPlaceName(r.municipio);
    final reviews = listReviewCount(r);
    final meta = <InlineSpan>[
      if (data.typeLabel != null)
        TextSpan(
            text: data.typeLabel,
            style: TextStyle(fontWeight: FontWeight.w600, color: gm.label)),
      if (data.typeLabel != null && muni.isNotEmpty)
        const TextSpan(text: ' · '),
      if (muni.isNotEmpty) TextSpan(text: muni),
      if (data.distance != null) TextSpan(text: ' · ${data.distance}'),
    ];

    return Stack(
      children: [
        GmPressable(
          onTap: onTap,
          semanticsLabel: r.nombre,
          child: GmCard(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(GmRadius.photo),
                    child: SizedBox(
                        width: 92,
                        height: 92,
                        child: _photo(data, theme, glyph: 34)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 4, 36, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            gmDisplayName(r.nombre),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GmText.guideTitle(color: gm.label),
                          ),
                          if (meta.isNotEmpty)
                            Text.rich(
                              TextSpan(children: meta),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GmText.meta(color: gm.label2),
                            ),
                          const SizedBox(height: 2),
                          ListOpenStatus(data.open),
                          if (reviews > 0) ...[
                            const SizedBox(height: 2),
                            ListRating(listDisplayRating(r), reviews,
                                long: true),
                          ],
                          if (data.dishMatch != null) ...[
                            const SizedBox(height: 6),
                            ListDishChip(
                                restaurantId: r.id, dish: data.dishMatch!),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: 2,
          top: 2,
          child: GmFavButton(restaurantId: r.id, restaurantName: r.nombre),
        ),
      ],
    );
  }
}

/// Tarjeta esqueleto quieta (sin brillo): mismo hueco que la real.
class ListSkeletonCard extends StatelessWidget {
  const ListSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    // Sin LayoutBuilder: la fila usa IntrinsicHeight y LayoutBuilder no
    // admite medidas intrínsecas.
    Widget bar(double f) => FractionallySizedBox(
          widthFactor: f,
          alignment: Alignment.centerLeft,
          child: Container(
            height: 11,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
                color: gm.fill, borderRadius: BorderRadius.circular(6)),
          ),
        );
    return GmCard(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: DecoratedBox(
                decoration: BoxDecoration(
                    color: gm.fill,
                    borderRadius: BorderRadius.circular(GmRadius.photo)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [bar(0.8), bar(0.55), bar(0.7)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dos tarjetas en fila con el mismo alto (la más alta manda).
class ListCardRow extends StatelessWidget {
  final Widget left;
  final Widget? right;
  const ListCardRow({super.key, required this.left, this.right});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          const SizedBox(width: 12),
          Expanded(child: right ?? const SizedBox.shrink()),
        ],
      ),
    );
  }
}

/// Entrada suave de la tarjeta (sube 14 px una vez; quieta con movimiento
/// reducido).
Widget listRise(int index, Widget child) =>
    GmRise(trigger: GmTrigger.mount, index: index.clamp(0, 6), child: child);
