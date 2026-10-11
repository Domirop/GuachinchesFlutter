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
// "Descubre planes" desactivado de momento — ver el bloque comentado en
// _NewHomeBodyState. El motor y el widget siguen en el repo con sus tests.
// import 'package:guachinches/domain/occasions/occasion.dart';
// import 'package:guachinches/domain/occasions/occasion_catalog.dart';
// import 'package:guachinches/domain/occasions/occasion_context.dart';
// import 'package:guachinches/domain/occasions/occasion_engine.dart';
// import 'package:guachinches/ui/pages/new_home/widgets/occasion_planner_card.dart';
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
import 'package:guachinches/ui/pages/new_home/widgets/card_visit.dart';
import 'package:guachinches/ui/pages/new_home/widgets/parallax_hero.dart';
import 'package:guachinches/ui/pages/new_home/widgets/quiz_banner.dart';
import 'package:guachinches/ui/pages/new_home/widgets/parallax_hero_slot.dart';
import 'package:guachinches/ui/components/canarismo_card.dart';
import 'package:guachinches/ui/components/location_prompt_banner.dart';
import 'package:guachinches/utils/contextual_pool.dart';
import 'package:guachinches/ui/pages/new_home/widgets/search_field_dynamic.dart';
import 'package:guachinches/ui/pages/new_home/widgets/section_error_retry.dart';
import 'package:guachinches/ui/pages/new_home/widgets/skeletons.dart';
import 'package:guachinches/core/remote_config/dcc_remote_config.dart';
import 'package:guachinches/ui/pages/new_home/widgets/top_filter_bar.dart';
import 'package:guachinches/ui/pages/listas/listas_screen.dart';
import 'package:guachinches/ui/pages/visit/visit_screen.dart';
import 'package:guachinches/utils/distance_utils.dart';
import 'package:guachinches/data/cubit/location/location_cubit.dart';
import 'package:guachinches/data/cubit/location/location_state.dart';
import 'package:guachinches/utils/time_of_day_engine.dart';
import 'package:guachinches/utils/restaurant_type_label.dart';
import 'package:guachinches/data/model/TopRestaurants.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_home_extras.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_tab_accessory.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

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

  // ── "Descubre planes" — DESACTIVADO de momento ───────────────────────────
  // El banner del planificador por ocasión queda comentado, no borrado: el
  // motor (domain/occasions/), su widget y sus tests siguen en el repo y
  // verdes. Para reactivarlo: descomentar este bloque, el sliver de más abajo
  // y los imports de occasions al principio del fichero.
  //
  // Pendiente antes de reactivarlo: la búsqueda a la que lleva se titula
  // "5 TIPOS" en vez del nombre del plan.
  //
  // OccasionContext? _memoOccasionCtx;
  // Occasion? _occasion;
  // // Banner cerrado por el usuario en esta sesión (por id de ocasión: si
  // // cambia el plan —p. ej. llega un festivo— vuelve a mostrarse).
  // String? _dismissedOccasionId;
  //
  // void _refreshOccasionIfNeeded() {
  //   final ctx = OccasionContext.resolve(now: DateTime.now());
  //   if (_memoOccasionCtx != ctx) {
  //     _memoOccasionCtx = ctx;
  //     _occasion = activeOccasion(kOccasionCatalog, ctx);
  //   }
  // }
  //
  // /// Abre la búsqueda con el filtro de la ocasión (mismo patrón que
  // /// [_openContextualSearch]): resuelve los IDs contra los tipos/categorías
  // /// cargados y aplica `openOnly`.
  // void _openOccasionSearch(Occasion o) {
  //   final types = widget.types
  //       .where((t) => o.typeIds.contains(t.id))
  //       .toList(growable: false);
  //   final categories = widget.categories
  //       .where((cat) => o.categoryIds.contains(cat.id))
  //       .toList(growable: false);
  //   widget.onSearchPreSelected(
  //     types: types.isEmpty ? null : types,
  //     categories: categories.isEmpty ? null : categories,
  //     openOnly: o.openOnly,
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    _refreshMemoIfNeeded();

    final filters = widget.filters;

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

    final gm = GmColors.of(context);
    final locDenied = locState is LocationDenied;

    // Accesorio de la barra minimizada (InicioScroll): lo más útil ahora.
    _publishAccessory(showTodaySection && !widget.bootstrapLoading
        ? GmTabAccessoryData(
            eyebrow: TodayGridSection.copyForHour(widget.hour, widget.minute)
                .eyebrow,
            title: contextualCount == 1
                ? '1 sitio abierto ahora'
                : '$contextualCount sitios abiertos ahora',
            photoUrl: todayPool.first.mainFoto,
            onTap: _openContextualSearch,
          )
        : null);

    // Etiqueta por tipo de local para el subtítulo del top (p. ej.
    // «Tasca · La Laguna»). Solo presentación: id → Type vía el helper común.
    String? typeLabelFor(String id) {
      for (final r in widget.pool) {
        if (r.id == id) return restaurantTypeLabel(r.type);
      }
      return null;
    }

    // Espaciado entre secciones del sistema (40).
    Widget section(Widget child, {double top = GmSpace.section}) =>
        SliverToBoxAdapter(
          child: Padding(padding: EdgeInsets.only(top: top), child: child),
        );

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
            color: gm.accent,
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

                // ── Buscar + aviso de ubicación (una línea) ─────────────────
                // Aviso adaptativo: si LocationDenied → tap dispara modal nativo;
                // si LocationPermanentlyDenied/ServiceDisabled → guía a Ajustes.
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GmRise(
                          trigger: GmTrigger.mount,
                          child: SearchFieldDynamic(
                            zone: filters.zoneLabel,
                            onTap: widget.onSearchTap,
                          ),
                        ),
                        if (locDenied) ...[
                          const SizedBox(height: 12),
                          const GmRise(
                            trigger: GmTrigger.mount,
                            index: 1,
                            child: LocationPromptBanner(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // ── DESCUBRE PLANES — DESACTIVADO ────────────────────────────
                // Banner de plan anticipado según día/franja/festivo (motor en
                // domain/occasions/). Tap → búsqueda filtrada al plan.
                // Para reactivarlo, descomentar también el bloque de estado en
                // _NewHomeBodyState y los imports de occasions.
                //
                // if (!widget.bootstrapLoading &&
                //     _occasion != null &&
                //     _occasion!.id != _dismissedOccasionId) ...[
                //   SliverToBoxAdapter(
                //     child: OccasionPlannerCard(
                //       occasion: _occasion!,
                //       onTap: () => _openOccasionSearch(_occasion!),
                //       onDismiss: () =>
                //           setState(() => _dismissedOccasionId = _occasion!.id),
                //     ),
                //   ),
                // ],

                // ── ABIERTOS CERCA AHORA ─────────────────────────────────────
                // Callout "N sitios abiertos cerca" retirado de momento (decisión
                // de producto): el conteo de abiertos se comunica ya en el hero y
                // duplicaba intención con la sección "HOY EN…". Para reactivarlo,
                // reinsertar aquí un OpenNowCalloutSlot con `openNow.length`.

                // ── HOY (rejilla de sitios según la hora) ───────────────────
                // Sólo mostramos esta sección si hay restaurantes con horario
                // confirmado abiertos ahora; si no, el fallback "abren pronto"
                // (mismo bloque, otra copy) o nada.
                if (widget.bootstrapLoading)
                  section(Semantics(
                    identifier: 'home-section-today',
                    child: TodayGridSection(
                      hour: widget.hour,
                      minute: widget.minute,
                      restaurants: const [],
                      onRestaurantTap: widget.onRestaurantTap,
                    ),
                  ))
                else if (showTodaySection)
                  section(Semantics(
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
                  ))
                else if (showOpeningSoonSection)
                  section(Semantics(
                    identifier: 'home-section-today',
                    child: TodayGridSection(
                      hour: widget.hour,
                      minute: widget.minute,
                      count: openingLater.length,
                      restaurants: openingSoonPool,
                      userLat: userLat,
                      userLon: userLon,
                      openingSoon: true,
                      zoneLabel: filters.zoneLabel,
                      onRestaurantTap: widget.onRestaurantTap,
                    ),
                  )),

                // ── JUEGO: ¿CUÁNTO SABES DE CANARIAS? ───────────────
                section(Semantics(
                  identifier: 'home-section-quiz-banner',
                  child: const GmRise(index: 2, child: QuizBanner()),
                )),

                // ── CERCA DE TI ────────────────────────
                // Con ubicación: carrusel. Sin permiso: tarjeta bloqueada del
                // mismo alto que lleva al flujo de permiso.
                if (widget.nearbyList.isNotEmpty)
                  section(_buildNearbySection(context))
                else if (locDenied)
                  section(_buildNearbyLocked(context)),

                // ── ÚLTIMAS VISITAS ──
                section(_buildVisitsSection(context)),

                // ── CANARISMO DEL DÍA ──────────────
                section(const GmRise(index: 1, child: CanarismoCard())),

                // ── MEJOR VALORADOS · {ISLA} ─────────────
                if (TopRatedSection.shouldRender(widget.topRated))
                  section(TopRatedSection(
                    restaurants: widget.topRated,
                    islandLabel: filters.islandLabel,
                    onRestaurantTap: widget.onRestaurantTap,
                    onSeeRanking: widget.onShowRanking,
                    typeLabelFor: typeLabelFor,
                  )),

                // ── ESPECIALIDADES CANARIAS (banda crema) ──────────────
                section(Semantics(
                  identifier: 'home-section-specialties',
                  child: CanarianSpecialtiesSection(
                    categories: widget.categories,
                    types: widget.types,
                    pool: widget.pool,
                    onSearchPreSelected: widget.onSearchPreSelected,
                  ),
                )),

                // ── GUÍAS (lazy, on-demand via SliverChildBuilderDelegate) ─
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (c, i) {
                      if (i == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 30),
                          child: _buildCuratedListsSection(c),
                        );
                      }
                      return null;
                    },
                    childCount: 1,
                  ),
                ),

                // ── Pie: volcán mascota ─────────────
                section(const GmHomeFooter()),

                // Clearance inferior: la barra flotante (cápsula 64 + márgenes)
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

        // ── Borde «mar de nubes» de la hoja: sigue al scroll justo en el
        //    canto inferior del hero (encima de él, debajo de la barra fija).
        ValueListenableBuilder<double>(
          valueListenable: widget.scrollListenable,
          child: const GmCloudEdge(),
          builder: (_, offset, edge) => Positioned(
            left: 0,
            right: 0,
            top: kHeroHeight - offset - GmCloudEdge.height + 4,
            // Fuera de pantalla las nubes no tienen por qué seguir derivando.
            child: TickerMode(
              enabled: offset < kHeroHeight + 40,
              child: edge!,
            ),
          ),
        ),

        // ── Fundido superior (edgeTop): cuando la hoja pasa bajo la barra
        //    de estado, un velo del lienzo mantiene legible el reloj. Va por
        //    debajo de la TopFilterBar (que no se toca).
        ValueListenableBuilder<double>(
          valueListenable: widget.scrollListenable,
          builder: (context, offset, _) {
            final top = MediaQuery.paddingOf(context).top;
            final t =
                ((offset - (kHeroHeight - top - 64)) / 48).clamp(0.0, 1.0);
            if (t <= 0) return const SizedBox.shrink();
            return Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: top + 64,
              child: IgnorePointer(
                child: Opacity(
                  opacity: t,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [gm.edgeTop0, gm.edgeTop1, gm.edgeFade0],
                        stops: const [0, 0.7, 1],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // ── TopFilterBar fija (flotante sobre el scroll) ──
        Positioned(
          top: 0,
          left: 0,
          right: 0,
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

  void _publishAccessory(GmTabAccessoryData? data) {
    if (gmTabAccessory.value == data) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) gmTabAccessory.value = data;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      gmTabAccessory.value = null;
    });
    super.dispose();
  }

  /// Antetítulo honesto de «Cerca de ti»: el radio real de lo que se ve.
  String _nearbyEyebrow(List<NearbyRestaurant> shown) {
    double? maxM;
    for (final n in shown) {
      final l = n.distanceLabel.trim();
      double? m;
      if (l.endsWith(' km')) {
        m = double.tryParse(
            l.replaceAll(' km', '').replaceAll('.', '').replaceAll(',', '.'));
        if (m != null) m *= 1000;
      } else if (l.endsWith(' m')) {
        m = double.tryParse(l.replaceAll(' m', ''));
      }
      if (m == null) continue;
      if (maxM == null || m > maxM) maxM = m;
    }
    if (maxM == null || maxM > kGmMaxDistanceMeters)
      return 'Lo más cerca de ti';
    if (maxM <= 2000) return 'A menos de 2 km';
    return 'A menos de ${(maxM / 1000).ceil()} km';
  }

  Widget _buildNearbySection(BuildContext context) {
    final gm = GmColors.of(context);
    final shown = widget.nearbyList.take(8).toList();
    return Semantics(
      identifier: 'home-section-nearby',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GmRise(
            index: 1,
            child: GmSectionHeader(
              eyebrow: GmEyebrow(
                leading: GmIcon(GmIcons.pin, size: 11, color: gm.accent),
                text: _nearbyEyebrow(shown),
              ),
              title: AppL10n.of(context).homeNearbySectionTitle,
              onTap: widget.onShowAllNearby,
              identifier: 'home-nearby-see-all',
            ),
          ),
          const SizedBox(height: 6),
          // Tarjetas de alto fijo en carrusel: el texto escala hasta 1,3×.
          MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: Builder(
                builder: (context) => SizedBox(
                      height: CardNearbyMinimap.heightFor(context),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        padding: const EdgeInsets.symmetric(
                            horizontal: GmSpace.gutter),
                        itemCount: shown.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: GmSpace.cardGap),
                        itemBuilder: (_, i) {
                          final nearby = shown[i];
                          return RepaintBoundary(
                            child: GmRise(
                              index: 2 + i.clamp(0, 2),
                              child: CardNearbyMinimap(
                                nearby: nearby,
                                onTap: () => widget
                                    .onRestaurantTap(nearby.restaurant.id),
                              ),
                            ),
                          );
                        },
                      ),
                    )),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyLocked(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: 'home-section-nearby',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GmRise(
            index: 1,
            child: GmSectionHeader(
              eyebrow: GmEyebrow(
                leading: GmIcon(GmIcons.pin, size: 11, color: gm.accent),
                text: 'A menos de 2 km',
              ),
              title: AppL10n.of(context).homeNearbySectionTitle,
              onTap: widget.onShowAllNearby,
              identifier: 'home-nearby-see-all',
            ),
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: GmSpace.gutter),
            child: GmRise(index: 2, child: LocationLockedCard()),
          ),
        ],
      ),
    );
  }

  Widget _buildCuratedListsSection(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: 'home-section-curated-lists',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GmRise(
            child: GmSectionHeader(
              eyebrow: GmEyebrow(
                leading: GmIcon(GmIcons.pin, size: 12, color: gm.accent),
                text: 'Rutas elegidas a mano',
              ),
              title: 'Guías de Jonay y Joana',
              identifier: 'home-curated-see-all',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ListasScreen()),
              ),
            ),
          ),
          const SizedBox(height: 6),
          BlocBuilder<CuratedListsCubit, CuratedListsState>(
            builder: (_, state) {
              if (state is CuratedListsLoaded) {
                if (state.lists.isEmpty) return const SizedBox.shrink();
                return MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.3,
                  child: Builder(
                      builder: (context) => SizedBox(
                            height: CardCuratedList.heightFor(context),
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              // Sin recorte vertical: deja respirar la sombra de las cards.
                              clipBehavior: Clip.none,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: GmSpace.gutter),
                              itemCount: state.lists.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: GmSpace.cardGap),
                              itemBuilder: (_, i) => RepaintBoundary(
                                child: GmRise(
                                  index: 1 + i.clamp(0, 2),
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
                              ),
                            ),
                          )),
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
              return CardRowSkeleton(
                itemWidth: CardCuratedList.width,
                itemHeight: CardCuratedList.heightFor(context),
                radius: GmRadius.guide,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVisitsSection(BuildContext context) {
    return Semantics(
      identifier: 'home-section-visits',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GmRise(
            index: 1,
            child: GmSectionHeader(
              eyebrow: GmEyebrow(
                leading: GmIcon(GmIcons.youtube,
                    size: 13, color: GmColors.of(context).label2),
                text: 'Jonay y Joana',
              ),
              title: 'Últimas visitas',
              identifier: 'home-visits-see-all',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DiscoverScreen()),
              ),
            ),
          ),
          const SizedBox(height: 6),
          BlocBuilder<VisitsCubit, VisitsState>(
            builder: (_, state) {
              if (state is VisitsLoaded) {
                if (state.visits.isEmpty) return const SizedBox.shrink();
                return SizedBox(
                  height: CardVisit.cardHeight,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    // Sin recorte vertical: el carrusel mide exactamente la
                    // card y sin esto la sombra inferior se corta en seco.
                    clipBehavior: Clip.none,
                    padding:
                        const EdgeInsets.symmetric(horizontal: GmSpace.gutter),
                    itemCount: state.visits.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: GmSpace.cardGap),
                    itemBuilder: (_, i) {
                      final v = state.visits[i];
                      return RepaintBoundary(
                        child: GmRise(
                          index: 2 + i.clamp(0, 2),
                          child: CardVisit(
                            visit: v,
                            pulse: i == 0,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VisitDetailPage(visitId: v.id),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }
              if (state is VisitsFailure) {
                return SectionErrorRetry(
                  message: 'No pudimos cargar esta sección',
                  retryAnchor: 'home-visits-retry',
                  onRetry: () => context.read<VisitsCubit>().loadVisits(),
                );
              }
              return const CardRowSkeleton(
                itemWidth: CardVisit.cardWidth,
                itemHeight: CardVisit.cardHeight,
                radius: GmRadius.poster,
              );
            },
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
