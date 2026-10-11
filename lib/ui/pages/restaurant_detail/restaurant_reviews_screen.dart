import 'package:flutter/material.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/model/Review.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/rating_summary.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/review_card.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

enum _SortOrder { original, bestFirst, worstFirst }

class RestaurantReviewsScreen extends StatefulWidget {
  final Restaurant restaurant;

  const RestaurantReviewsScreen({super.key, required this.restaurant});

  @override
  State<RestaurantReviewsScreen> createState() =>
      _RestaurantReviewsScreenState();
}

class _RestaurantReviewsScreenState extends State<RestaurantReviewsScreen> {
  int? _activeFilter;
  _SortOrder _sortOrder = _SortOrder.original;

  List<Review> get _filtered {
    final all = widget.restaurant.valoraciones;
    var list = _activeFilter == null
        ? List<Review>.of(all)
        : all
            .where((r) =>
                (double.tryParse(r.rating)?.round() ?? 0) == _activeFilter)
            .toList();

    switch (_sortOrder) {
      case _SortOrder.bestFirst:
        list.sort((a, b) {
          final ra = double.tryParse(a.rating) ?? 0;
          final rb = double.tryParse(b.rating) ?? 0;
          return rb.compareTo(ra);
        });
      case _SortOrder.worstFirst:
        list.sort((a, b) {
          final ra = double.tryParse(a.rating) ?? 0;
          final rb = double.tryParse(b.rating) ?? 0;
          return ra.compareTo(rb);
        });
      case _SortOrder.original:
        break;
    }

    return list;
  }

  int _countForStar(int star) => widget.restaurant.valoraciones
      .where((r) => (double.tryParse(r.rating)?.round() ?? 0) == star)
      .length;

  @override
  Widget build(BuildContext context) {
    final total = widget.restaurant.valoraciones.length;
    final filtered = _filtered;
    final brand = context.brand;
    final gm = GmColors.of(context);

    return Semantics(
      identifier: 'restaurant-reviews-screen',
      child: Scaffold(
        backgroundColor: gm.canvas,
        appBar: AppBar(
          backgroundColor: gm.canvas,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leadingWidth: 64,
          leading: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Center(
              child: GmToolbarButton(
                icon: GmIcons.chevronLeft,
                iconSize: 20,
                light: true,
                semanticLabel: 'Volver',
                identifier: 'restaurant-reviews-back-button',
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          centerTitle: true,
          title: Text('Reseñas ($total)',
              style: GmText.body17(color: gm.label, w: FontWeight.w700)),
        ),
        body: Column(
          children: [
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _buildChip(
                    identifier: 'restaurant-reviews-filter-chip-all',
                    label: 'Todas ($total)',
                    isActive: _activeFilter == null,
                    onTap: () => setState(() => _activeFilter = null),
                  ),
                  for (int star = 5; star >= 1; star--)
                    _buildChip(
                      identifier: 'restaurant-reviews-filter-chip-$star',
                      label: '$star★ (${_countForStar(star)})',
                      isActive: _activeFilter == star,
                      onTap: () => setState(() => _activeFilter = star),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Semantics(
                    identifier: 'restaurant-reviews-sort-button',
                    child: PopupMenuButton<_SortOrder>(
                      initialValue: _sortOrder,
                      onSelected: (v) => setState(() => _sortOrder = v),
                      color: brand.elevated,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _sortLabel(_sortOrder),
                            style: GmText.sub(color: gm.label2),
                          ),
                          Icon(
                            Icons.unfold_more_rounded,
                            size: 16,
                            color: brand.textMuted,
                          ),
                        ],
                      ),
                      itemBuilder: (ctx) => [
                        _menuItem(
                            'Orden original', _SortOrder.original, brand),
                        _menuItem(
                            'Mejor puntuadas', _SortOrder.bestFirst, brand),
                        _menuItem(
                            'Peor puntuadas', _SortOrder.worstFirst, brand),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: RatingSummary(restaurant: widget.restaurant),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Semantics(
                      identifier: 'restaurant-reviews-empty-state',
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 48,
                                color: brand.textMuted,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No hay reseñas que coincidan con este filtro',
                                textAlign: TextAlign.center,
                                style: GmText.body(color: gm.label2),
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () =>
                                    setState(() => _activeFilter = null),
                                child: Text(
                                  'Quitar filtros',
                                  style: GmText.body(
                                      color: gm.accent, w: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : Semantics(
                      identifier: 'restaurant-reviews-list',
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (ctx, i) =>
                            ReviewCard(review: filtered[i], index: i),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required String identifier,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final gm = GmColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
        identifier: identifier,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isActive ? gm.accentSoft : gm.card,
              borderRadius: BorderRadius.circular(GmRadius.pill),
              boxShadow: isActive ? null : gm.shadow1,
            ),
            child: Text(
              label,
              style: GmText.sub(
                color: isActive ? gm.accent : gm.label,
                w: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<_SortOrder> _menuItem(
      String label, _SortOrder value, BrandColors brand) {
    return PopupMenuItem<_SortOrder>(
      value: value,
      child: Text(
        label,
        style: AppTextStyles.ui(size: 13, color: brand.textPrimary),
      ),
    );
  }

  String _sortLabel(_SortOrder order) {
    switch (order) {
      case _SortOrder.original:
        return 'Orden original';
      case _SortOrder.bestFirst:
        return 'Mejor puntuadas';
      case _SortOrder.worstFirst:
        return 'Peor puntuadas';
    }
  }
}
