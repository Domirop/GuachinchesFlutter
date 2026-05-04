import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/data/cubit/new_home/curated_lists_cubit.dart';
import 'package:guachinches/data/cubit/new_home/new_home_filters_state.dart';
import 'package:guachinches/data/cubit/new_home/visits_cubit.dart';
import 'package:guachinches/data/model/Category.dart';
import 'package:guachinches/data/model/SimpleMunicipality.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/data/model/weather_data.dart';
import 'package:guachinches/data/model/zone.dart';
import 'package:guachinches/ui/pages/new_home/new_home_presenter.dart';
import 'package:guachinches/ui/pages/new_home/sheets/zone_picker_sheet.dart';
import 'package:guachinches/ui/pages/new_home/widgets/card_curated_list.dart';
import 'package:guachinches/ui/pages/new_home/widgets/card_horizontal.dart';
import 'package:guachinches/ui/pages/new_home/widgets/card_nearby_minimap.dart';
import 'package:guachinches/ui/pages/new_home/widgets/card_visit.dart';
import 'package:guachinches/ui/pages/new_home/widgets/glass_tab_bar.dart';
import 'package:guachinches/ui/pages/new_home/widgets/hour_aware_banner.dart';
import 'package:guachinches/ui/pages/new_home/widgets/parallax_hero.dart';
import 'package:guachinches/ui/pages/new_home/widgets/search_field_dynamic.dart';
import 'package:guachinches/ui/pages/new_home/widgets/section_header.dart';
import 'package:guachinches/ui/pages/new_home/widgets/skeletons.dart';
import 'package:guachinches/ui/pages/new_home/widgets/top_filter_bar.dart';
import 'package:guachinches/ui/pages/visit/visit_screen.dart';
import 'package:guachinches/utils/distance_utils.dart';
import 'package:guachinches/utils/open_now_utils.dart';
import 'package:guachinches/utils/time_of_day_engine.dart';

class NewHomeBody extends StatefulWidget {
  final ScrollController scrollCtrl;
  final double scrollOffset;
  final bool bootstrapLoading;
  final int hour;
  final TimeOfDayWindow window;
  final NewHomeFiltersState filters;
  final WeatherData weather;
  final List<Restaurant> pool;
  final List<ModelCategory> categories;
  final List<SimpleMunicipality> municipalities;
  final List<NearbyRestaurant> nearbyList;
  final List<Zone> zones;
  final NewHomePresenter presenter;
  final ValueChanged<Zone?> onZoneSelected;
  final ValueChanged<SimpleMunicipality?> onMunicipalitySelected;
  final ValueChanged<String> onRestaurantTap;
  final VoidCallback onSearchTap;

  const NewHomeBody({
    super.key,
    required this.scrollCtrl,
    required this.scrollOffset,
    required this.bootstrapLoading,
    required this.hour,
    required this.window,
    required this.filters,
    required this.weather,
    required this.pool,
    required this.categories,
    required this.municipalities,
    required this.nearbyList,
    required this.zones,
    required this.presenter,
    required this.onZoneSelected,
    required this.onMunicipalitySelected,
    required this.onRestaurantTap,
    required this.onSearchTap,
  });

  @override
  State<NewHomeBody> createState() => _NewHomeBodyState();
}

class _NewHomeBodyState extends State<NewHomeBody> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final filters = widget.filters;
    final zoneLabel = filters.zoneLabel ?? filters.islandLabel;

    // Restaurantes para la sección "HOY EN..."
    final openNow = widget.presenter.filterOpenNow(widget.pool);
    final todayPool = openNow.isNotEmpty
        ? openNow.take(5).toList()
        : widget.pool.take(5).toList();

    // Cantidad de overscroll (positivo cuando el usuario tira hacia abajo)
    final overscroll = math.max(-widget.scrollOffset, 0).toDouble();
    // Cantidad de scroll normal (positivo al subir el contenido)
    final scrollUp = math.max(widget.scrollOffset, 0).toDouble();

    return Stack(
      children: [
        // ── Hero foto: anclado arriba, scroll-away en scroll normal,
        //    se estira al hacer pull-down (sin que aparezca cream por arriba) ──
        Positioned(
          top: -scrollUp,
          left: 0,
          right: 0,
          height: kHeroHeight + overscroll,
          child: ParallaxHero(
            scrollOffset: 0, // posicionamiento manejado por el outer Stack
            hour: widget.hour,
            assetImage: _assetForIsland(filters.islandId),
            zona: filters.zoneLabel ?? filters.islandLabel,
            islandLabel: filters.islandLabel,
            openCount: openNow.length,
            onZoneChipTap: () => _showZoneSheet(context),
          ),
        ),

        // ── Scroll principal ──────────────────────────
        CustomScrollView(
          controller: widget.scrollCtrl,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Espacio reservado para el hero (que se posiciona en el outer Stack)
            const SliverToBoxAdapter(
              child: SizedBox(height: kHeroHeight),
            ),

            // Barra de búsqueda (lure → navega a AdvancedSearch)
            SliverToBoxAdapter(
              child: SearchFieldDynamic(
                zone: filters.zoneLabel,
                onTap: widget.onSearchTap,
              ),
            ),

            // ── HOY EN ··· (banner contextual + cards integrados) ───────
            SliverToBoxAdapter(
              child: HourAwareBanner(
                hour: widget.hour,
                zoneLabel: zoneLabel,
                actionLabel: 'VER TODO',
                onAction: () {},
              ),
            ),
            SliverToBoxAdapter(
              child: widget.bootstrapLoading
                  ? const CardRowSkeleton()
                  : todayPool.isEmpty
                      ? const SizedBox.shrink()
                      : _buildHorizontalRow(todayPool),
            ),

            // ── GUÍAS DE JONAY Y JOANA ──────────────
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'GUÍAS DE JONAY Y JOANA',
                actionLabel: 'VER TODAS',
                onAction: () {},
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 320,
                child: BlocBuilder<CuratedListsCubit, CuratedListsState>(
                  builder: (_, state) {
                    if (state is CuratedListsLoaded) {
                      if (state.lists.isEmpty) return const SizedBox.shrink();
                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        itemCount: state.lists.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (_, i) => CardCuratedList(
                          list: state.lists[i],
                          onTap: () {},
                        ),
                      );
                    }
                    if (state is CuratedListsFailure) return const SizedBox.shrink();
                    return const CardRowSkeleton();
                  },
                ),
              ),
            ),

            // ── ÚLTIMAS VISITAS DE JONAY Y JOANA ───
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'ÚLTIMAS VISITAS DE JONAY Y JOANA',
                actionLabel: 'VER TODAS',
                onAction: () {},
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 300,
                child: BlocBuilder<VisitsCubit, VisitsState>(
                  builder: (_, state) {
                    if (state is VisitsLoaded) {
                      if (state.visits.isEmpty) return const SizedBox.shrink();
                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        itemCount: state.visits.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (_, i) {
                          final v = state.visits[i];
                          return CardVisit(
                            visit: v,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VisitDetailPage(visitId: v.id),
                              ),
                            ),
                          );
                        },
                      );
                    }
                    if (state is VisitsFailure) return const SizedBox.shrink();
                    return const CardRowSkeleton();
                  },
                ),
              ),
            ),

            // ── CERCA DE TI ────────────────────────
            if (widget.nearbyList.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'CERCA DE TI',
                  actionLabel: 'VER MAPA',
                  onAction: () {},
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 172,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    itemCount: widget.nearbyList.take(8).length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final nearby = widget.nearbyList[i];
                      return CardNearbyMinimap(
                        nearby: nearby,
                        onTap: () =>
                            widget.onRestaurantTap(nearby.restaurant.id),
                      );
                    },
                  ),
                ),
              ),
            ],

            // Padding inferior para la tab bar
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),

        // ── TopFilterBar fija (flotante sobre el scroll) ──
        Positioned(
          top: 0, left: 0, right: 0,
          child: TopFilterBar(
            islandLabel: filters.islandLabel,
            zoneLabel: filters.zoneLabel,
            weather: widget.weather,
            onZoneTap: () => _showZoneSheet(context),
          ),
        ),

        // ── Glass Tab Bar flotante ────────────────────
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: GlassTabBar(
            currentIndex: _tabIndex,
            onTap: (i) => setState(() => _tabIndex = i),
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalRow(List<Restaurant> items) {
    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final r = items[i];
          final now = DateTime.now();
          final open = r.horariosJson != null
              ? isOpenNow(r.horariosJson, now)
              : r.open;
          return CardHorizontal(
            restaurant: r,
            showOpenBadge: open,
            onTap: () => widget.onRestaurantTap(r.id),
          );
        },
      ),
    );
  }

  // ── Sheet helpers ─────────────────────────────────

  void _showZoneSheet(BuildContext context) {
    ZonePickerSheet.show(
      context: context,
      islandLabel: widget.filters.islandLabel,
      zones: widget.zones,
      selectedZoneKey: widget.filters.zoneKey,
      weather: widget.weather,
      onSelect: widget.onZoneSelected,
    );
  }

  String? _assetForIsland(String islandId) {
    if (islandId == '76ac0bec-4bc1-41a5-bc60-e528e0c12f4d') {
      return 'assets/images/new-home/tenerife-norte.png';
    }
    if (islandId == '6f91d60f-0996-4dde-9088-167aab83a21a') {
      return 'assets/images/new-home/Lanzarote.png';
    }
    return null;
  }
}
