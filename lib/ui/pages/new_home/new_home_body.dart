import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/data/cubit/new_home/curated_lists_cubit.dart';
import 'package:guachinches/data/cubit/new_home/new_home_filters_state.dart';
import 'package:guachinches/data/cubit/new_home/visits_cubit.dart';
import 'package:guachinches/data/model/Category.dart';
import 'package:guachinches/data/model/SimpleMunicipality.dart';
import 'package:guachinches/data/model/Types.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/data/model/weather_data.dart';
import 'package:guachinches/data/model/zone.dart';
import 'package:guachinches/ui/pages/new_home/new_home_presenter.dart';
import 'package:guachinches/data/model/Island.dart';
import 'package:guachinches/ui/pages/new_home/sheets/island_picker_sheet.dart';
import 'package:guachinches/ui/pages/new_home/sheets/zone_picker_sheet.dart';
import 'package:guachinches/ui/pages/new_home/widgets/canarian_specialties_section.dart';
import 'package:guachinches/ui/pages/curated_list_detail/curated_list_detail_screen.dart';
import 'package:guachinches/ui/pages/discover/discover_screen.dart';
import 'package:guachinches/ui/pages/new_home/widgets/card_curated_list.dart';
import 'package:guachinches/ui/pages/new_home/widgets/card_horizontal.dart';
import 'package:guachinches/ui/pages/new_home/widgets/card_nearby_minimap.dart';
import 'package:guachinches/ui/pages/new_home/widgets/card_visit.dart';
import 'package:guachinches/ui/pages/new_home/widgets/hour_aware_banner.dart';
import 'package:guachinches/ui/pages/new_home/widgets/parallax_hero.dart';
import 'package:guachinches/ui/pages/new_home/widgets/search_field_dynamic.dart';
import 'package:guachinches/ui/pages/new_home/widgets/section_header.dart';
import 'package:guachinches/ui/pages/new_home/widgets/skeletons.dart';
import 'package:guachinches/ui/pages/new_home/widgets/top_filter_bar.dart';
import 'package:guachinches/ui/pages/listas/listas_screen.dart';
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
  final List<Types> types;
  final List<SimpleMunicipality> municipalities;
  final List<NearbyRestaurant> nearbyList;
  final List<Zone> zones;
  final NewHomePresenter presenter;
  final ValueChanged<Zone?> onZoneSelected;
  final ValueChanged<Island> onIslandSelected;
  final ValueChanged<SimpleMunicipality?> onMunicipalitySelected;
  final ValueChanged<String> onRestaurantTap;
  final VoidCallback onSearchTap;
  final void Function({
    List<ModelCategory>? categories,
    List<Types>? types,
  }) onSearchPreSelected;

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
    required this.types,
    required this.municipalities,
    required this.nearbyList,
    required this.zones,
    required this.presenter,
    required this.onZoneSelected,
    required this.onIslandSelected,
    required this.onMunicipalitySelected,
    required this.onRestaurantTap,
    required this.onSearchTap,
    required this.onSearchPreSelected,
  });

  @override
  State<NewHomeBody> createState() => _NewHomeBodyState();
}

class _NewHomeBodyState extends State<NewHomeBody> {
  @override
  Widget build(BuildContext context) {
    final filters = widget.filters;
    final zoneLabel = filters.zoneLabel ?? filters.islandLabel;

    // Restaurantes para la sección "HOY EN..." — abiertos ahora y filtrados
    // por type/categoría según la hora (Bar/Cafetería para desayunos,
    // Terraza/Con vistas para atardecer, Restaurantes/Tascas para cenas...).
    // Ver lib/utils/contextual_pool.dart para el mapeo. Si la intersección
    // queda escasa cae al pool abierto sin filtrar.
    final openNow = widget.presenter.filterOpenNow(widget.pool);
    final contextual =
        widget.presenter.filterContextual(widget.pool, widget.hour);
    final todayPool = contextual.take(5).toList();
    final showTodaySection = todayPool.isNotEmpty;

    // Cantidad de overscroll (positivo cuando el usuario tira hacia abajo)
    final overscroll = math.max(-widget.scrollOffset, 0).toDouble();
    // Cantidad de scroll normal (positivo al subir el contenido)
    final scrollUp = math.max(widget.scrollOffset, 0).toDouble();

    return Stack(
      children: [
        // ── Scroll principal ──────────────────────────
        // Va PRIMERO en el Stack para que el hero (ver más abajo) quede
        // por encima en hit-testing y sus chips reciban taps. Las zonas
        // decorativas del hero usan IgnorePointer internamente para
        // dejar pasar drags al scroll.
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
            // Sólo mostramos esta sección si hay restaurantes con horario
            // confirmado abiertos ahora; si no, ocultamos banner + row para
            // no anunciar "abiertos ahora" sobre listas dudosas.
            if (widget.bootstrapLoading) ...[
              SliverToBoxAdapter(
                child: HourAwareBanner(
                  hour: widget.hour,
                  zoneLabel: zoneLabel,
                  actionLabel: 'VER TODO',
                  onAction: () {},
                ),
              ),
              const SliverToBoxAdapter(child: CardRowSkeleton()),
            ] else if (showTodaySection) ...[
              SliverToBoxAdapter(
                child: HourAwareBanner(
                  hour: widget.hour,
                  zoneLabel: zoneLabel,
                  actionLabel: 'VER TODO',
                  onAction: () {},
                ),
              ),
              SliverToBoxAdapter(child: _buildHorizontalRow(todayPool)),
            ],

            // ── ESPECIALIDADES CANARIAS ──────────────
            SliverToBoxAdapter(
              child: CanarianSpecialtiesSection(
                categories: widget.categories,
                types: widget.types,
                onSearchPreSelected: widget.onSearchPreSelected,
              ),
            ),

            // ── GUÍAS DE JONAY Y JOANA ──────────────
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'GUÍAS DE JONAY Y JOANA',
                actionLabel: 'VER TODAS',
                onAction: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ListasScreen()),
                ),
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
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CuratedListDetailScreen(
                                list: state.lists[i],
                              ),
                            ),
                          ),
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
                onAction: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DiscoverScreen()),
                ),
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

            // Padding inferior pequeño para respirar al final del scroll.
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),

        // ── Hero foto: por encima del scroll para que sus chips reciban
        //    taps. Las capas decorativas internas usan IgnorePointer y
        //    dejan pasar drags al scroll de fondo.
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
            zoneIsSet: filters.zoneLabel != null,
            openCount: openNow.length,
            onZoneChipTap: () => _showZoneSheet(context),
            onIslandChipTap: () => _showIslandSheet(context),
          ),
        ),

        // ── TopFilterBar fija (flotante sobre el scroll) ──
        Positioned(
          top: 0, left: 0, right: 0,
          child: TopFilterBar(
            islandLabel: filters.islandLabel,
            zoneLabel: filters.zoneLabel,
            weather: widget.weather,
            onIslandTap: () => _showIslandSheet(context),
            onZoneTap: () => _showZoneSheet(context),
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
          // Solo mostramos ABIERTO si el horario estructurado lo confirma.
          final open =
              r.horariosJson != null && isOpenNow(r.horariosJson, now);
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

  void _showIslandSheet(BuildContext context) {
    IslandPickerSheet.show(
      context: context,
      selectedIslandId: widget.filters.islandId,
      onSelect: widget.onIslandSelected,
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
