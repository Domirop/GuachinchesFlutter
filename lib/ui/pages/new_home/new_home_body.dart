import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/config/app_spacing.dart';
import 'package:guachinches/l10n/app_localizations.dart';
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
import 'package:guachinches/ui/pages/new_home/widgets/card_nearby_minimap.dart';
import 'package:guachinches/ui/pages/new_home/widgets/top_rated_section.dart';
import 'package:guachinches/ui/pages/new_home/widgets/today_grid_section.dart';
import 'package:guachinches/data/model/TopRestaurants.dart';
import 'package:guachinches/ui/pages/new_home/widgets/card_visit.dart';
import 'package:guachinches/ui/pages/new_home/widgets/hour_aware_banner.dart';
import 'package:guachinches/ui/pages/new_home/widgets/parallax_hero.dart';
import 'package:guachinches/ui/pages/new_home/widgets/quiz_banner.dart';
import 'package:guachinches/ui/pages/new_home/widgets/parallax_hero_slot.dart';
import 'package:guachinches/ui/components/canarismo_card.dart';
import 'package:guachinches/ui/components/location_prompt_banner.dart';
import 'package:guachinches/ui/pages/new_home/widgets/card_horizontal.dart';
import 'package:guachinches/ui/pages/new_home/widgets/contextual_section_card.dart';
import 'package:guachinches/utils/contextual_pool.dart';
import 'package:guachinches/ui/pages/new_home/widgets/search_field_dynamic.dart';
import 'package:guachinches/ui/components/section_header.dart';
import 'package:guachinches/ui/pages/new_home/widgets/section_error_retry.dart';
import 'package:guachinches/ui/pages/new_home/widgets/skeletons.dart';
import 'package:guachinches/core/remote_config/dcc_remote_config.dart';
import 'package:guachinches/ui/pages/new_home/widgets/top_filter_bar.dart';
import 'package:guachinches/ui/pages/listas/listas_screen.dart';
import 'package:guachinches/ui/pages/visit/visit_screen.dart';
import 'package:guachinches/utils/distance_utils.dart';
import 'package:guachinches/data/cubit/location/location_cubit.dart';
import 'package:guachinches/data/cubit/location/location_state.dart';
import 'package:guachinches/utils/opening_later_utils.dart';
import 'package:guachinches/utils/time_of_day_engine.dart';

class NewHomeBody extends StatefulWidget {
  final ScrollController scrollCtrl;
  final ValueListenable<double> scrollListenable;
  final bool bootstrapLoading;
  final int hour;
  final int minute;
  final TimeOfDayWindow window;
  final NewHomeFiltersState filters;
  final WeatherData weather;
  final List<Restaurant> pool;
  final List<ModelCategory> categories;
  final List<Types> types;
  final List<SimpleMunicipality> municipalities;
  final List<NearbyRestaurant> nearbyList;
  final List<Zone> zones;
  /// Top valorados de la isla (ya filtrados aguas arriba). Vacío → sin sección.
  final List<TopRestaurants> topRated;
  final NewHomePresenter presenter;
  final ValueChanged<Zone?> onZoneSelected;
  final ValueChanged<Island> onIslandSelected;
  final ValueChanged<SimpleMunicipality?> onMunicipalitySelected;
  final ValueChanged<String> onRestaurantTap;
  final VoidCallback onSearchTap;
  final void Function({
    List<ModelCategory>? categories,
    List<Types>? types,
    bool openOnly,
  }) onSearchPreSelected;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onShowAllNearby;
  /// Abre el ranking completo "Mejor valorados".
  final VoidCallback onShowRanking;

  const NewHomeBody({
    super.key,
    required this.scrollCtrl,
    required this.scrollListenable,
    required this.bootstrapLoading,
    required this.hour,
    this.minute = 0,
    required this.window,
    required this.filters,
    required this.weather,
    required this.pool,
    required this.categories,
    required this.types,
    required this.municipalities,
    required this.nearbyList,
    required this.zones,
    required this.topRated,
    required this.presenter,
    required this.onZoneSelected,
    required this.onIslandSelected,
    required this.onMunicipalitySelected,
    required this.onRestaurantTap,
    required this.onSearchTap,
    required this.onSearchPreSelected,
    this.onRefresh,
    this.onShowAllNearby,
    required this.onShowRanking,
  });

  @override
  State<NewHomeBody> createState() => _NewHomeBodyState();
}

class _NewHomeBodyState extends State<NewHomeBody> {
  // Memoized filter results: only recomputed when (pool, hour) changes.
  List<Restaurant>? _memoPool;
  int? _memoHour;
  List<Restaurant> _openNowCache = const [];
  List<Restaurant> _contextualCache = const [];

  void _refreshMemoIfNeeded() {
    if (!identical(_memoPool, widget.pool) || _memoHour != widget.hour) {
      _memoPool = widget.pool;
      _memoHour = widget.hour;
      _openNowCache = widget.presenter.filterOpenNow(widget.pool);
      _contextualCache =
          widget.presenter.filterContextual(widget.pool, widget.hour);
    }
  }

  @override
  Widget build(BuildContext context) {
    _refreshMemoIfNeeded();

    final filters = widget.filters;
    final zoneLabel = filters.zoneLabel ?? filters.islandLabel;

    // Restaurantes para la sección "HOY EN..." — abiertos ahora y filtrados
    // por type/categoría según la hora (Bar/Cafetería para desayunos,
    // Terraza/Con vistas para atardecer, Restaurantes/Tascas para cenas...).
    // Ver lib/utils/contextual_pool.dart para el mapeo. Si la intersección
    // queda escasa cae al pool abierto sin filtrar.
    final openNow = _openNowCache;
    final contextual = _contextualCache;
    final contextualCount = contextual.length;

    // Ubicación del usuario (si hay permiso) para ordenar "HOY EN..." por
    // cercanía y pintar la distancia en cada card.
    final locState = context.watch<LocationCubit>().state;
    final double? userLat =
        locState is LocationLoaded ? locState.latitude : null;
    final double? userLon =
        locState is LocationLoaded ? locState.longitude : null;

    final todayPool =
        _sortByProximity(contextual, userLat, userLon).take(5).toList();
    final showTodaySection = todayPool.isNotEmpty;

    // Fallback "abren pronto": cuando no hay nada abierto ahora pero sí
    // restaurantes que abren más tarde HOY. Pensado para islas donde la
    // cocina arranca a las 13:00-13:30 (El Hierro, La Gomera, La Palma).
    // El threshold de 2 es deliberado: con 1 sólo restaurante la sección
    // se ve triste; mejor ocultar y dejar que aparezcan otras secciones.
    final now = DateTime.now();
    final openingLater = showTodaySection
        ? const <Restaurant>[]
        : widget.presenter.filterOpeningLaterToday(widget.pool, now);
    final showOpeningSoonSection = openingLater.length >= 2;
    final openingSoonPool = openingLater.take(5).toList();

    return Stack(
      children: [
        // ── Scroll principal ──────────────────────────
        // Va PRIMERO en el Stack para que el hero (ver más abajo) quede
        // por encima en hit-testing y sus chips reciban taps. Las zonas
        // decorativas del hero usan IgnorePointer internamente para
        // dejar pasar drags al scroll.
        Semantics(
          identifier: 'home-refresh-indicator',
          child: RefreshIndicator(
            onRefresh: widget.onRefresh ?? () async {},
            color: Theme.of(context).colorScheme.primary,
            child: CustomScrollView(
          controller: widget.scrollCtrl,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
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

            // ── LOCATION PROMPT (si no hay permiso) ──────────────────────
            // Banner adaptativo: si LocationDenied → tap dispara modal nativo;
            // si LocationPermanentlyDenied/ServiceDisabled → push guía a
            // Ajustes. Auto-oculto cuando hay permiso (LocationLoaded).
            const SliverToBoxAdapter(child: LocationPromptBanner()),

            // ── ABIERTOS CERCA AHORA ─────────────────────────────────────
            // Callout "N sitios abiertos cerca" retirado de momento (decisión
            // de producto): el conteo de abiertos se comunica ya en el hero y
            // duplicaba intención con la sección "HOY EN…". Para reactivarlo,
            // reinsertar aquí un OpenNowCalloutSlot con `openNow.length`.

            // ── HOY EN ··· (banner contextual + cards integrados) ───────
            // Sólo mostramos esta sección si hay restaurantes con horario
            // confirmado abiertos ahora; si no, ocultamos banner + row para
            // no anunciar "abiertos ahora" sobre listas dudosas.
            //
            // Banner + carrusel van envueltos en [ContextualSectionCard]
            // (fondo crema + banda lateral) para que se lean como una unidad
            // visual, en lugar de dos elementos sueltos. El scroll interno
            // sigue siendo el `CardHorizontal` clásico (no se toca).
            if (widget.bootstrapLoading) ...[
              SliverToBoxAdapter(
                child: Semantics(
                  identifier: 'home-section-today',
                  child: TodayGridSection(
                    hour: widget.hour,
                    minute: widget.minute,
                    restaurants: const [],
                    onRestaurantTap: widget.onRestaurantTap,
                  ),
                ),
              ),
            ] else if (showTodaySection) ...[
              SliverToBoxAdapter(
                child: Semantics(
                  identifier: 'home-section-today',
                  child: TodayGridSection(
                    hour: widget.hour,
                    minute: widget.minute,
                    count: contextualCount,
                    restaurants: todayPool,
                    userLat: userLat,
                    userLon: userLon,
                    onRestaurantTap: widget.onRestaurantTap,
                    onSeeAll: _openContextualSearch,
                  ),
                ),
              ),
            ] else if (showOpeningSoonSection) ...[
              SliverToBoxAdapter(
                child: Semantics(
                  identifier: 'home-section-today',
                  child: ContextualSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HourAwareBanner(
                          hour: widget.hour,
                          zoneLabel: zoneLabel,
                          // Sin "VER TODO" en este modo: la lista ya es
                          // pequeña y todo el contenido relevante está en
                          // el carrusel.
                          count: openingLater.length,
                          mode: HourBannerMode.openingSoon,
                        ),
                        _buildHorizontalRowOpeningSoon(
                            openingSoonPool, now, userLat, userLon),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            // ── JUEGO: ¿CUÁNTO SABES DE CANARIAS? ───────────────
            SliverToBoxAdapter(
              child: Semantics(
                identifier: 'home-section-quiz-banner',
                child: const QuizBanner(),
              ),
            ),

            // ── CERCA DE TI ────────────────────────
            if (widget.nearbyList.isNotEmpty)
              SliverToBoxAdapter(
                child: Semantics(
                  identifier: 'home-section-nearby',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: AppL10n.of(context).homeNearbySectionTitle.toUpperCase(),
                        actionLabel: widget.onShowAllNearby != null
                            ? AppL10n.of(context).homeSeeAll.toUpperCase()
                            : null,
                        onAction: widget.onShowAllNearby,
                      ),
                      SizedBox(
                        // Altura = card estándar (200) + aire para su sombra.
                        height: 210,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                          itemCount: widget.nearbyList.take(8).length,
                          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.cardGap),
                          itemBuilder: (_, i) {
                            final nearby = widget.nearbyList[i];
                            return RepaintBoundary(
                              child: CardNearbyMinimap(
                                nearby: nearby,
                                onTap: () =>
                                    widget.onRestaurantTap(nearby.restaurant.id),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── ÚLTIMAS VISITAS (encima de Mejor Valorados) ──
            SliverToBoxAdapter(child: _buildVisitsSection(context)),

            // ── CANARISMO DEL DÍA (teaser colapsable) ──────────────
            const SliverToBoxAdapter(child: CanarismoCard()),

            // ── MEJOR VALORADOS · {ISLA} ─────────────
            if (TopRatedSection.shouldRender(widget.topRated))
              SliverToBoxAdapter(
                child: TopRatedSection(
                  restaurants: widget.topRated,
                  islandLabel: filters.islandLabel,
                  onRestaurantTap: widget.onRestaurantTap,
                  onSeeRanking: widget.onShowRanking,
                ),
              ),

            // ── ESPECIALIDADES CANARIAS ──────────────
            SliverToBoxAdapter(
              child: Semantics(
                identifier: 'home-section-specialties',
                child: CanarianSpecialtiesSection(
                  categories: widget.categories,
                  types: widget.types,
                  onSearchPreSelected: widget.onSearchPreSelected,
                ),
              ),
            ),

            // ── GUÍAS (lazy, on-demand via SliverChildBuilderDelegate) ─
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (c, i) {
                  if (i == 0) return _buildCuratedListsSection(c);
                  return null;
                },
                childCount: 1,
              ),
            ),

            // Clearance inferior: la navbar flotante (cápsula 64 + márgenes)
            // va sobre el scroll (`extendBody`), así que el final debe
            // despejarla + el safe area para que la última sección respire.
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).padding.bottom +
                    64 +
                    AppSpacing.scrollBottom,
              ),
            ),
          ],
        ),
          ),
        ),

        // ── Hero foto: posicionado por ParallaxHeroSlot sin reconstruirse
        //    en cada tick de scroll. Las capas decorativas internas usan
        //    IgnorePointer y dejan pasar drags al scroll de fondo.
        ParallaxHeroSlot(
          offset: widget.scrollListenable,
          child: Semantics(
            identifier: 'home-hero',
            child: ParallaxHero(
              scrollOffset: 0, // posicionamiento manejado por el outer Stack
              hour: widget.hour,
              assetImage: _assetForIsland(filters.islandKey),
              islandPhrase: _phraseForIsland(filters.islandKey),
              zona: filters.zoneLabel ?? filters.islandLabel,
              islandLabel: filters.islandLabel,
              zoneIsSet: filters.zoneLabel != null,
              openCount: openNow.length,
              onZoneChipTap: () => _showZoneSheet(context),
              onIslandChipTap: () => _showIslandSheet(context),
            ),
          ),
        ),

        // ── TopFilterBar fija (flotante sobre el scroll) ──
        Positioned(
          top: 0, left: 0, right: 0,
          child: TopFilterBar(
            islandLabel: filters.islandLabel,
            zoneLabel: filters.zoneLabel,
            weather: DccRemoteConfig.instance.showWeatherChip
                ? widget.weather
                : const WeatherData.unknown(),
            onIslandTap: () => _showIslandSheet(context),
            onZoneTap: () => _showZoneSheet(context),
          ),
        ),

      ],
    );
  }

  Widget _buildCuratedListsSection(BuildContext context) {
    return Semantics(
      identifier: 'home-section-curated-lists',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'GUÍAS DE JONAY Y JOANA',
            actionLabel: AppL10n.of(context).homeSeeAll.toUpperCase(),
            onAction: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ListasScreen()),
            ),
          ),
          SizedBox(
            height: 320,
            child: BlocBuilder<CuratedListsCubit, CuratedListsState>(
              builder: (_, state) {
                if (state is CuratedListsLoaded) {
                  if (state.lists.isEmpty) return const SizedBox.shrink();
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    // Sin recorte vertical: deja respirar la sombra de las cards.
                    clipBehavior: Clip.none,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                    itemCount: state.lists.length,
                    separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.cardGap),
                    itemBuilder: (_, i) => RepaintBoundary(
                      child: CardCuratedList(
                        list: state.lists[i],
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CuratedListDetailScreen(
                              list: state.lists[i],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }
                if (state is CuratedListsFailure) {
                  return SectionErrorRetry(
                    message: 'No pudimos cargar esta sección',
                    retryAnchor: 'home-curated-retry',
                    onRetry: () => context
                        .read<CuratedListsCubit>()
                        .loadForIsland(widget.filters.islandId),
                  );
                }
                return const CardRowSkeleton();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitsSection(BuildContext context) {
    return Semantics(
      identifier: 'home-section-visits',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            // Corto para que quepa a 18pt sin ellipsis; la autoría ya la
            // acredita la sección GUÍAS DE JONAY Y JOANA de arriba.
            title: 'ÚLTIMAS VISITAS',
            actionLabel: AppL10n.of(context).homeSeeAll.toUpperCase(),
            onAction: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DiscoverScreen()),
            ),
          ),
          SizedBox(
            height: CardVisit.cardHeight,
            child: BlocBuilder<VisitsCubit, VisitsState>(
              builder: (_, state) {
                if (state is VisitsLoaded) {
                  if (state.visits.isEmpty) return const SizedBox.shrink();
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    // Sin recorte vertical: el carrusel mide exactamente la
                    // card y sin esto la sombra inferior se corta en seco.
                    clipBehavior: Clip.none,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                    itemCount: state.visits.length,
                    separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.cardGap),
                    itemBuilder: (_, i) {
                      final v = state.visits[i];
                      return RepaintBoundary(
                        child: CardVisit(
                          visit: v,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VisitDetailPage(visitId: v.id),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
                if (state is VisitsFailure) {
                  return SectionErrorRetry(
                    message: 'No pudimos cargar esta sección',
                    retryAnchor: 'home-visits-retry',
                    onRetry: () => context.read<VisitsCubit>().loadVisits(),
                  );
                }
                return const CardRowSkeleton();
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Abre `AdvancedSearch` con los filtros contextuales correspondientes al
  /// slot horario actual (ej. desayuno → type Bar/Cafetería) y
  /// `openOnly: true`. Usado por el "VER TODO" del banner.
  void _openContextualSearch() {
    final cfg = contextualFilterFor(widget.hour);
    final types = widget.types
        .where((t) => cfg.typeIds.contains(t.id))
        .toList(growable: false);
    final categories = widget.categories
        .where((c) => cfg.categoryIds.contains(c.id))
        .toList(growable: false);
    widget.onSearchPreSelected(
      types: types.isEmpty ? null : types,
      categories: categories.isEmpty ? null : categories,
      openOnly: true,
    );
  }

  /// Orden "proximidad-primero": agrupa por bandas de 500 m (los más cercanos
  /// delante) y, dentro de cada banda, gana la mejor nota. Así un sitio lejano
  /// no se cuela por delante de uno cercano, pero a igualdad de cercanía manda
  /// la valoración. Sin ubicación o sin coordenadas → orden original.
  List<Restaurant> _sortByProximity(
      List<Restaurant> items, double? userLat, double? userLon) {
    if (userLat == null || userLon == null) return items;
    double? distOf(Restaurant r) {
      if (r.lat == 0.0 && r.lon == 0.0) return null;
      return haversineDistanceMeters(userLat, userLon, r.lat, r.lon);
    }

    final sorted = [...items];
    sorted.sort((a, b) {
      final da = distOf(a);
      final db = distOf(b);
      if (da == null && db == null) return b.avgRating.compareTo(a.avgRating);
      if (da == null) return 1;
      if (db == null) return -1;
      final bandA = (da / 500).floor();
      final bandB = (db / 500).floor();
      if (bandA != bandB) return bandA.compareTo(bandB);
      final byRating = b.avgRating.compareTo(a.avgRating);
      if (byRating != 0) return byRating;
      return da.compareTo(db);
    });
    return sorted;
  }

  String? _distanceLabel(Restaurant r, double? userLat, double? userLon) {
    if (userLat == null || userLon == null) return null;
    if (r.lat == 0.0 && r.lon == 0.0) return null;
    return formatDistance(
        haversineDistanceMeters(userLat, userLon, r.lat, r.lon));
  }

  /// Carrusel para el fallback "abren pronto". Mismo widget que el normal
  /// pero el badge cambia a `ABRE HH:MM` (color sol) — pista visual clara
  /// de que no están abiertos *ahora* pero sí hoy.
  Widget _buildHorizontalRowOpeningSoon(
      List<Restaurant> items, DateTime now, double? userLat, double? userLon) {
    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final r = items[i];
          final label = nextOpenLabel(r.horariosJson, now);
          return CardHorizontal(
            restaurant: r,
            openingLabel: label,
            distanceLabel: _distanceLabel(r, userLat, userLon),
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

  /// Devuelve el background del hero según la isla seleccionada.
  /// Mapeado por `islandKey` (más estable que el UUID y cubre las 7 islas).
  /// Si una isla no tiene asset propio aún, devuelve `null` y el hero cae
  /// al color de marca (`context.brand.surface`).
  String? _assetForIsland(String islandKey) {
    const base = 'assets/images/backgrounds/ddc_island_bg';
    switch (islandKey) {
      case 'TF':
        // Tenerife: foto de día (playa de La Tejita) hasta las 19:00; a partir
        // de esa hora, la nocturna original. Mismo tamaño/decode que el resto
        // de heroes (1920×1080 jpg) para no penalizar rendimiento.
        return widget.hour < 19
            ? '$base/tenerife_dcc_day.jpg'
            : '$base/tenerife_dcc.jpg';
      case 'GC':
        return '$base/las_palmas_dcc.jpg';
      case 'LZ':
        return '$base/lanzarote_dcc.jpg';
      case 'FV':
        return '$base/fuerteventura_dcc.jpg';
      case 'GO':
        return '$base/la_gomera_dcc.jpg';
      case 'EH':
        return '$base/el_hierro_dcc.jpg';
      case 'LP':
        // TODO: añadir la_palma_dcc.jpg cuando esté disponible.
        return null;
      default:
        return null;
    }
  }

  /// Frase editorial fija por isla (tagline del hero). Mapeado por `islandKey`.
  /// Si una isla no tiene frase, devuelve `null` y el hero cae a la copy por
  /// hora del día.
  String? _phraseForIsland(String islandKey) {
    switch (islandKey) {
      case 'TF':
        return 'Todos somos hijos del volcán';
      case 'GC':
        return 'Todos somos Costeros';
      case 'LP':
        return 'No hay nada como la isla bonita';
      case 'LZ':
        return 'Somos volcán y salitre';
      case 'FV':
        return 'Soñando en las mejores playas';
      case 'GO':
        return 'La isla del ritmo desde el mar hasta la cumbre';
      case 'EH':
        return 'Una isla para soñar';
      default:
        return null;
    }
  }
}
