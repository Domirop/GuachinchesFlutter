import 'package:flutter/material.dart';
import 'package:guachinches/data/model/Review.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/discover/widgets/gm_pull_down_menu.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart'
    show gmDisplayName, gmPlaceName;
import 'package:guachinches/ui/pages/restaurant_detail/review_moderation.dart';
import 'package:guachinches/ui/pages/restaurant_detail/reviews_logic.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/rating_summary.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/review_card.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

/// «Todas las reseñas» (tablero ResenasTodas): pantalla empujada con Volver
/// de cristal, «<Sitio> · <Municipio>» + «Reseñas», resumen con la nota y la
/// distribución, orden en menú de cristal (Relevantes / Mejor puntuadas /
/// Peor puntuadas) y las reseñas literales con «⋯» (Reportar / Bloquear).
class RestaurantReviewsScreen extends StatefulWidget {
  final Restaurant restaurant;
  final ReviewModeration? moderation;

  const RestaurantReviewsScreen({
    super.key,
    required this.restaurant,
    this.moderation,
  });

  @override
  State<RestaurantReviewsScreen> createState() =>
      _RestaurantReviewsScreenState();
}

class _RestaurantReviewsScreenState extends State<RestaurantReviewsScreen> {
  final ScrollController _scroll = ScrollController();
  ReviewSort _sort = ReviewSort.relevant;
  bool _scrolled = false;

  ReviewModeration get _mod => widget.moderation ?? ReviewModeration.instance;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    // Para no ofrecer «⋯» en la reseña propia.
    _mod.currentUserId();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    final s = _scroll.hasClients && _scroll.offset > 4;
    if (s != _scrolled) setState(() => _scrolled = s);
  }

  Future<void> _openSort(BuildContext anchorContext) async {
    final picked = await showGmPullDownMenu<ReviewSort>(
      context,
      anchor: gmAnchorRect(anchorContext),
      title: 'Ordenar reseñas',
      width: 260,
      selected: _sort,
      identifier: 'restaurant-reviews-sort-menu',
      items: [
        for (final s in ReviewSort.values)
          GmMenuItem(
            value: s,
            label: s.label,
            subtitle: s == ReviewSort.relevant ? s.caption : null,
            identifier: s.identifier,
          ),
      ],
    );
    if (picked != null && picked != _sort && mounted) {
      setState(() => _sort = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final media = MediaQuery.of(context);
    final r = widget.restaurant;
    final name = gmDisplayName(r.nombre);

    return Semantics(
      identifier: 'restaurant-reviews-screen',
      child: Scaffold(
        backgroundColor: gm.canvas,
        body: Stack(
          children: [
            ListenableBuilder(
              listenable: _mod,
              builder: (context, _) {
                final visible = reviewsSorted(
                  reviewsWithoutBlocked(r.valoraciones, _mod.blockedUserIds),
                  _sort,
                );
                return CustomScrollView(
                  controller: _scroll,
                  slivers: [
                    SliverToBoxAdapter(
                      child: SizedBox(height: media.padding.top + 60),
                    ),
                    SliverToBoxAdapter(
                      child: GmRise(
                        trigger: GmTrigger.mount,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: GmSpace.titleInset),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reviewsEyebrow(name, gmPlaceName(r.municipio)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GmText.eyebrow(color: gm.label2),
                              ),
                              Semantics(
                                header: true,
                                child: Text('Reseñas',
                                    style: GmText.largeTitle(color: gm.label)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (visible.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                          child: _EmptyCard(
                            blockedAll: r.valoraciones.isNotEmpty,
                          ),
                        ),
                      )
                    else ...[
                      SliverToBoxAdapter(
                        child: GmRise(
                          index: 1,
                          trigger: GmTrigger.mount,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                            child: RatingSummary(
                              restaurant: Restaurant(
                                id: r.id,
                                nombre: r.nombre,
                                valoraciones: visible,
                                avgRating: r.avgRating,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: GmRise(
                          index: 2,
                          trigger: GmTrigger.mount,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 6, 16, 0),
                            child: _SortBar(
                              sort: _sort,
                              onTap: _openSort,
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                            16, 4, 16, 120 + media.padding.bottom),
                        sliver: SliverList.separated(
                          itemCount: visible.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) => GmRise(
                            index: 3 + i.clamp(0, 4),
                            trigger: GmTrigger.mount,
                            child: ReviewCard(
                              key: ValueKey('review-${visible[i].id}-$i'),
                              review: visible[i],
                              index: _avatarIndex(visible[i]),
                              restaurantName: name,
                              moderation: widget.moderation,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            GmTopScrim(visible: _scrolled, extra: 60),
            Positioned(
              left: 16,
              top: media.padding.top + 8,
              child: GmToolbarButton(
                icon: GmIcons.chevronLeft,
                iconSize: 20,
                light: true,
                semanticLabel: 'Volver',
                identifier: 'restaurant-reviews-back-button',
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tinte estable por reseña (no cambia al reordenar).
  int _avatarIndex(Review review) {
    final i = widget.restaurant.valoraciones.indexOf(review);
    return i < 0 ? 0 : i;
  }
}

/// «Con comentario primero» + botón «Relevantes ⌄» que abre el menú.
class _SortBar extends StatelessWidget {
  final ReviewSort sort;
  final ValueChanged<BuildContext> onTap;

  const _SortBar({required this.sort, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(sort.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GmText.body(color: gm.label2)),
        ),
        Builder(
          builder: (anchorCtx) => Semantics(
            identifier: 'restaurant-reviews-sort-button',
            button: true,
            label: 'Ordenar reseñas: ${sort.label}',
            excludeSemantics: true,
            child: GmPressable(
              onTap: () => onTap(anchorCtx),
              child: SizedBox(
                height: 44,
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: gm.card,
                      borderRadius: BorderRadius.circular(GmRadius.pill),
                      boxShadow: gm.shadow1,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GmIcon(GmIcons.sort, size: 14, color: gm.label),
                        const SizedBox(width: 6),
                        Text(sort.label,
                            style: GmText.sub(
                                color: gm.label, w: FontWeight.w600)),
                        const SizedBox(width: 6),
                        GmIcon(GmIcons.chevronDown, size: 14, color: gm.label),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  /// Hay reseñas, pero todas son de personas que has bloqueado.
  final bool blockedAll;
  const _EmptyCard({required this.blockedAll});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: 'restaurant-reviews-empty-state',
      container: true,
      child: GmCard(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              GmIcon(GmIcons.starOutline, size: 34, color: gm.label2),
              const SizedBox(height: 10),
              Text(
                blockedAll
                    ? 'No quedan reseñas que mostrar'
                    : 'Todavía no hay reseñas',
                textAlign: TextAlign.center,
                style: GmText.poster(color: gm.label),
              ),
              const SizedBox(height: 6),
              Text(
                blockedAll
                    ? 'Las que había son de personas que has bloqueado.'
                    : 'Sé el primero en contar tu experiencia desde la ficha.',
                textAlign: TextAlign.center,
                style: GmText.body(color: gm.label2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
