import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/core/analytics/analytics.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/data/cubit/location/location_cubit.dart';
import 'package:guachinches/data/cubit/location/location_state.dart';
import 'package:guachinches/data/cubit/new_home/visits_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_state.dart';
import 'package:guachinches/data/cubit/search/dish_search_cubit.dart';
import 'package:guachinches/data/model/Category.dart';
import 'package:guachinches/data/model/Municipality.dart';
import 'package:guachinches/data/model/Types.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/services/app_storage.dart';
import 'package:guachinches/ui/pages/advance_search/list_logic.dart';
import 'package:guachinches/ui/pages/advance_search/list_theme.dart';
import 'package:guachinches/ui/pages/advance_search/widgets/list_cards.dart';
import 'package:guachinches/ui/pages/advance_search/widgets/list_glyph.dart';
import 'package:guachinches/ui/pages/advance_search/widgets/list_map_view.dart';
import 'package:guachinches/ui/pages/advance_search/widgets/mesa_brindis_scene.dart';
import 'package:guachinches/ui/pages/advance_search/widgets/search_filter_sheet.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_home_extras.dart'
    show GmCloudEdge;
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart'
    show gmDistanceLabel, gmDistanceMeters;
import 'package:guachinches/ui/pages/restaurant_detail/ficha_logic.dart'
    show fichaCategoryFeature;
import 'package:guachinches/ui/pages/restaurant_detail/restaurant_detail_screen.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/gm_ficha_header.dart'
    show FichaFeatureChips;
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';
import 'package:guachinches/utils/contextual_pool.dart';
import 'package:guachinches/utils/debouncer.dart';
import 'package:guachinches/utils/dish_search_index.dart';
import 'package:guachinches/utils/open_state.dart';
import 'package:guachinches/utils/restaurant_type_label.dart';

/// Lista de resultados temática (rediseño iOS 27 · tableros ListaDesayuno,
/// ListaTradicional, ListaPescado, ListaBuscar, ListaFiltros y ListaMapa ·
/// Sistema §08). Es el home con otro acento: banda con ilustración (la mesa
/// con brindis animada en «Guachinches tradicionales»), hoja con el borde
/// «mar de nubes», buscador, chips de filtro quitables, orden, tarjetas
/// «Hoy» con el estado de apertura preciso y los estados de carga, vacío y
/// error.
class AdvancedSearch extends StatefulWidget {
  final List<ModelCategory> categories;
  final List<Municipality> municipalities;
  final List<Types> types;
  final String islandId;
  final List<ModelCategory> preSelectedCategories;
  final List<Types> preSelectedTypes;
  final bool preSelectedOpenOnly;

  /// Abierta desde «Hoy» de la home: manda la franja horaria (desayuno,
  /// almuerzo, golden hour, cena o madrugada).
  final bool fromToday;

  /// «Tenerife» (para «22 en Tenerife»).
  final String? islandLabel;

  /// Todos los sitios de la isla que ya tiene la home (con su tipo): da los
  /// recuentos de «Explorar por tipo», el «Para ahora» y el tipo de cada
  /// fila en resultados mezclados (findByFilter no trae el tipo).
  final List<Restaurant> pool;

  const AdvancedSearch({
    super.key,
    required this.categories,
    required this.municipalities,
    required this.types,
    required this.islandId,
    this.preSelectedCategories = const [],
    this.preSelectedTypes = const [],
    this.preSelectedOpenOnly = false,
    this.fromToday = false,
    this.islandLabel,
    this.pool = const [],
  });

  @override
  State<AdvancedSearch> createState() => _AdvancedSearchState();
}

enum _View { list, map }

class _AdvancedSearchState extends State<AdvancedSearch> {
  static const _kRecentSearchesKey = 'search_recents';
  static const _kMaxRecents = 5;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final Debouncer _searchDebouncer = Debouncer();
  final ScrollController _scroll = ScrollController();
  late RestaurantCubit _restaurantsCubit;

  SearchFilterValues _filters = const SearchFilterValues();
  late SearchFilterValues _preset;
  ListThemeKind? _context;
  ListSort? _sort;
  _View _view = _View.list;
  List<String> _recents = const [];
  bool _hasSearched = false;

  /// Arriba del todo (barra de estado sobre la banda) y la mesa a la vista.
  bool _atTop = true;
  final ValueNotifier<bool> _sceneVisible = ValueNotifier(true);

  /// Parámetros de la última petición al servidor (para saber si los
  /// recuentos del panel de filtros se pueden adelantar).
  List<String> _requestedTypes = const [];
  List<String> _requestedCategories = const [];

  // Búsqueda por plato — se calcula en _runSearch(), nunca con BlocListener.
  Set<String> _dishMatchIds = const {};
  Map<String, String> _dishFirstMatchName = const {};
  // Foto de respaldo cuando el match viene por plato y `mainFoto` está vacío:
  // la miniatura del vídeo de la visita.
  Map<String, String> _dishFirstVisitThumbnail = const {};
  List<Visit> _allVisits = const [];

  bool get _hasQuery => _searchController.text.trim().isNotEmpty;
  bool get _isActive => _hasQuery || _filters.count > 0;

  @override
  void initState() {
    super.initState();
    _restaurantsCubit = context.read<RestaurantCubit>();
    _filters = SearchFilterValues(
      categoryIds:
          widget.preSelectedCategories.map((c) => c.id).toList(growable: false),
      typeIds: widget.preSelectedTypes.map((t) => t.id).toList(growable: false),
      municipalityIds: const [],
      openOnly: widget.preSelectedOpenOnly,
    );
    _preset = _filters;
    if (widget.fromToday) _context = contextThemeForHour(DateTime.now().hour);
    _scroll.addListener(_onScroll);
    _loadRecents();
    if (_filters.count > 0) _runSearch();
  }

  @override
  void dispose() {
    _searchDebouncer.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    _scroll.dispose();
    _sceneVisible.dispose();
    super.dispose();
  }

  void _onScroll() {
    final o = _scroll.hasClients ? _scroll.offset : 0.0;
    final top = o < 40;
    if (top != _atTop) setState(() => _atTop = top);
    // La escena se apaga en cuanto sale de la pantalla.
    final scene = MesaBrindisScene.heightFor(MediaQuery.sizeOf(context).width);
    _sceneVisible.value = o < 180 + scene;
  }

  // ── Recientes ──────────────────────────────────────────────────────────

  Future<void> _loadRecents() async {
    try {
      final raw = await AppStorage.instance.read(key: _kRecentSearchesKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = json.decode(raw);
      if (decoded is List && mounted) {
        setState(() => _recents = decoded.whereType<String>().toList());
      }
    } catch (e) {
      AppLogger.warn('advanced-search', 'no se pudieron leer recientes: $e');
    }
  }

  Future<void> _saveRecents() async {
    try {
      await AppStorage.instance
          .write(key: _kRecentSearchesKey, value: json.encode(_recents));
    } catch (e) {
      AppLogger.warn('advanced-search', 'no se pudieron guardar recientes: $e');
    }
  }

  void _addRecent(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    final next = [
      q,
      ..._recents.where((r) => r.toLowerCase() != q.toLowerCase())
    ];
    setState(() => _recents = next.take(_kMaxRecents).toList());
    _saveRecents();
  }

  Future<void> _clearRecents() async {
    setState(() => _recents = const []);
    try {
      await AppStorage.instance.delete(key: _kRecentSearchesKey);
    } catch (e) {
      AppLogger.warn('advanced-search', 'no se pudieron borrar recientes: $e');
    }
  }

  // ── Búsqueda ───────────────────────────────────────────────────────────

  /// Categorías que se mandan al servidor: con una sola, Y = O; con varias
  /// el servidor haría Y y la lista quiere O, así que se filtran aquí.
  static List<String> _serverCategories(SearchFilterValues f) =>
      f.categoryIds.length == 1 ? f.categoryIds : const [];

  void _runSearch() {
    final query = _searchController.text;

    final dishState = context.read<DishSearchCubit>().state;
    final visitsState = context.read<VisitsCubit>().state;
    Set<String> newDishMatchIds = const {};
    Map<String, String> newDishFirstMatchName = const {};
    Map<String, String> newDishFirstVisitThumbnail = const {};
    List<Visit> newAllVisits = const [];

    final indexSize = dishState is DishSearchReady ? dishState.index.length : 0;
    AppLogger.info(
      'advanced-search',
      'query="$query" len=${query.length} '
          'dish_state=${dishState.runtimeType} index_tokens=$indexSize '
          'visits_state=${visitsState.runtimeType}',
    );

    // Queries de plato: el texto escrito (si ≥3) + el NOMBRE de cada categoría
    // seleccionada. Así, entrar en "Carne de cabra" desde el home también trae
    // negocios cuyas visitas tienen ese plato, igual que en Buscar.
    final dishQueries = <String>[
      if (query.trim().length >= 3) query,
      ..._selectedCategoryNames(),
    ];

    if (dishState is DishSearchReady && dishQueries.isNotEmpty) {
      final matched = <String>{};
      for (final q in dishQueries) {
        matched.addAll(matchRestaurantIds(dishState.index, q));
      }
      newDishMatchIds = matched;
      if (newDishMatchIds.isNotEmpty) {
        newAllVisits =
            visitsState is VisitsLoaded ? visitsState.visits : const [];
        final names = <String, String>{};
        for (final q in dishQueries) {
          final partial =
              buildDishFirstMatchNames(newAllVisits, newDishMatchIds, q);
          for (final e in partial.entries) {
            names.putIfAbsent(e.key, () => e.value);
          }
        }
        newDishFirstMatchName = names;
        newDishFirstVisitThumbnail =
            buildDishFirstVisitThumbnails(newAllVisits, newDishMatchIds);
      }
    }

    setState(() {
      _hasSearched = true;
      _dishMatchIds = newDishMatchIds;
      _dishFirstMatchName = newDishFirstMatchName;
      _dishFirstVisitThumbnail = newDishFirstVisitThumbnail;
      _allVisits = newAllVisits;
    });

    if (_usePresetPool) {
      // Desde «Hoy» con el preset intacto: los mismos sitios que la home
      // (el número de abiertos coincide). Cualquier cambio de tipos pide
      // al servidor.
      _requestedTypes = const ['__home-pool__'];
      _requestedCategories = const [];
      return;
    }
    _requestedTypes = List.of(_filters.typeIds);
    _requestedCategories = _serverCategories(_filters);
    // Municipios, «Abierto ahora» y las categorías múltiples se filtran en
    // el dispositivo (recuentos inmediatos y una sola regla de apertura).
    _restaurantsCubit.getFilterRestaurantsAdvance(
      categories: _requestedCategories,
      municipalities: const [],
      text: query,
      types: _filters.typeIds,
      islandId: widget.islandId,
      isOpen: false,
    );

    if (query.length >= 3) {
      final prev = _restaurantsCubit.state;
      final prevIds = prev is RestaurantFilterAdvanced
          ? prev.restaurantFilterAdvanced.map((r) => r.id).toSet()
          : const <String>{};
      Analytics.I.logEvent('search_dish_match', {
        'query_len': query.length,
        'server_count': prevIds.length,
        'dish_count': newDishMatchIds.length,
        'dish_only_count': newDishMatchIds.difference(prevIds).length,
      });
    }
  }

  List<String> _selectedCategoryNames() {
    if (_filters.categoryIds.isEmpty) return const [];
    final byId = {for (final c in widget.categories) c.id: c.nombre};
    return _filters.categoryIds
        .map((id) => byId[id])
        .whereType<String>()
        .toList(growable: false);
  }

  void _onQueryChanged(String _) {
    setState(() {});
    _searchDebouncer(() {
      if (_backToBrowse()) return;
      _runSearch();
    });
  }

  /// Sin texto ni filtros se vuelve a «Explorar» (no se pide la isla
  /// entera).
  bool _backToBrowse() {
    if (_hasQuery || _filters.count > 0) return false;
    setState(() => _hasSearched = false);
    return true;
  }

  void _onSubmitted(String value) {
    _searchDebouncer.cancel();
    _addRecent(value);
    _runSearch();
  }

  /// Cambia los filtros: si solo tocan lo local no hace falta el servidor.
  void _applyFilters(SearchFilterValues next) {
    final needsServer =
        !SearchFilterValues.sameIds(next.typeIds, _requestedTypes) ||
            !SearchFilterValues.sameIds(
                _serverCategories(next), _requestedCategories) ||
            !_hasSearched;
    final catsChanged =
        !SearchFilterValues.sameIds(next.categoryIds, _filters.categoryIds);
    setState(() => _filters = next);
    if (needsServer || catsChanged) {
      _runSearch();
    }
  }

  Future<void> _openFilterSheet() async {
    final state = _restaurantsCubit.state;
    final base = _usePresetPool
        ? _presetPool
        : state is RestaurantFilterAdvanced
            ? state.restaurantFilterAdvanced
            : const <Restaurant>[];
    final result = await SearchFilterSheet.show(
      context: context,
      initial: _filters,
      categories: widget.categories,
      types: widget.types,
      municipalities: widget.municipalities,
      base: base,
      baseTypeIds: _usePresetPool ? _preset.typeIds : _requestedTypes,
      municipalityNames: _municipalityNames,
      badgeFor: (v) => listPresetSummary(
        hasContext: _context != null,
        presetTypes: _preset.typeIds,
        presetCategories: _preset.categoryIds,
        presetOpenOnly: _preset.openOnly,
        types: v.typeIds,
        categories: v.categoryIds,
        municipalities: v.municipalityIds,
        openOnly: v.openOnly,
      ).badge,
      // Con la base pedida sin categorías, cualquier combinación se cuenta
      // aquí; con una categoría en el servidor, solo si sigue siendo esa.
      countFor: (v) => _requestedCategories.isEmpty
          ? _results(base, v, DateTime.now(), allCategories: true).length
          : SearchFilterValues.sameIds(
                  _serverCategories(v), _requestedCategories)
              ? _results(base, v, DateTime.now()).length
              : -1,
    );
    if (result != null) _applyFilters(result);
  }

  void _pickType(Types type) {
    _searchController.clear();
    setState(() {
      _context = null;
      _filters = SearchFilterValues(typeIds: [type.id]);
      _preset = _filters;
    });
    _runSearch();
  }

  void _openContext(ListThemeKind k) {
    final cfg = contextualFilterFor(DateTime.now().hour);
    _searchController.clear();
    setState(() {
      _context = k;
      _filters = SearchFilterValues(
        typeIds: [
          for (final t in widget.types)
            if (cfg.typeIds.contains(t.id)) t.id
        ],
        categoryIds: [
          for (final c in widget.categories)
            if (cfg.categoryIds.contains(c.id)) c.id
        ],
        openOnly: true,
      );
      _preset = _filters;
    });
    _runSearch();
  }

  void _useRecent(String query) {
    _searchController.text = query;
    _searchController.selection =
        TextSelection.fromPosition(TextPosition(offset: query.length));
    _addRecent(query);
    _runSearch();
  }

  void _openRestaurant(Restaurant r) {
    _addRecent(_searchController.text);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RestaurantDetailScreen(id: r.id)),
    );
  }

  // ── Datos derivados ────────────────────────────────────────────────────

  /// Nombres de los municipios vistos en los resultados, por clave (id del
  /// municipio del sitio). Se van acumulando para que los chips de los
  /// elegidos sigan teniendo nombre aunque cambien los resultados.
  final Map<String, String> _muniNames = {};

  Map<String, String> get _municipalityNames => _muniNames;

  void _rememberMunicipalities(List<Restaurant> list) {
    for (final r in list) {
      final k = listMunicipalityKey(r);
      if (k.isNotEmpty) {
        _muniNames.putIfAbsent(k, () => listMunicipalityName(r.municipio));
      }
    }
  }

  LocalFilters _local(SearchFilterValues f,
      {bool openOnly = true, bool allCategories = false}) {
    return LocalFilters(
      categoryIds: (allCategories || f.categoryIds.length > 1)
          ? f.categoryIds.toSet()
          : const {},
      municipalityKeys: f.municipalityIds.toSet(),
      openOnly: openOnly && f.openOnly,
    );
  }

  /// Lista abierta desde «Hoy» con el preset sin tocar y con los sitios de
  /// la home a mano: se usan esos mismos sitios.
  bool get _usePresetPool =>
      widget.pool.isNotEmpty &&
      _context != null &&
      _filters.sameAs(_preset) &&
      !_hasQuery;

  /// Base del preset desde el pool de la home (misma función que «Hoy»).
  List<Restaurant> get _presetPool => contextualMatches(
        widget.pool,
        ContextualFilter(
          typeIds: _preset.typeIds.toSet(),
          categoryIds: _preset.categoryIds.toSet(),
        ),
      );

  /// Resultados del servidor (o del pool) que pasan los filtros locales.
  /// Los que solo coinciden por plato van aparte ([_dishResults]).
  List<Restaurant> _mainResults(
      List<Restaurant> server, SearchFilterValues f, DateTime now,
      {bool openOnly = true, bool allCategories = false}) {
    final local = _local(f, openOnly: openOnly, allCategories: allCategories);
    return [
      for (final r in server)
        if (listMatches(r, local, now)) r
    ];
  }

  /// Sitios que solo coinciden por plato (de las visitas), sin los que ya
  /// están en [server].
  List<Restaurant> _dishResults(
      List<Restaurant> server, SearchFilterValues f, DateTime now,
      {bool openOnly = true}) {
    final local = _local(f, openOnly: openOnly);
    final ids = server.map((r) => r.id).toSet();
    final dishLocal = LocalFilters(
        municipalityKeys: local.municipalityKeys, openOnly: local.openOnly);
    final types = f.typeIds.toSet();
    final seen = <String>{};
    final out = <Restaurant>[];
    for (final v in _allVisits) {
      final r = v.restaurant;
      if (r == null || !_dishMatchIds.contains(v.restaurantId)) continue;
      if (ids.contains(v.restaurantId) || !seen.add(v.restaurantId)) continue;
      // Con tipo elegido, los que llegan por plato también han de serlo.
      if (types.isNotEmpty && !types.contains(_typeIdOf(r))) continue;
      if (listMatches(r, dishLocal, now)) out.add(r);
    }
    return out;
  }

  /// Todos (principal + por plato), para los recuentos del panel.
  List<Restaurant> _results(
          List<Restaurant> server, SearchFilterValues f, DateTime now,
          {bool openOnly = true, bool allCategories = false}) =>
      [
        ..._mainResults(server, f, now,
            openOnly: openOnly, allCategories: allCategories),
        ..._dishResults(server, f, now, openOnly: openOnly),
      ];

  /// Tipo del sitio: el de la fila o, si no lo trae, el de la home.
  String? _typeIdOf(Restaurant r) {
    if (r.type.isNotEmpty && r.type != 'vacio') return r.type;
    for (final p in widget.pool) {
      if (p.id == r.id) return p.type;
    }
    return null;
  }

  String? _typeLabelFor(Restaurant r) {
    if (_filters.typeIds.length == 1) {
      final l = restaurantTypeLabel(_filters.typeIds.first);
      if (l.isNotEmpty) return l;
    }
    final fromRow = restaurantTypeLabel(r.type);
    if (fromRow.isNotEmpty) return fromRow;
    for (final p in widget.pool) {
      if (p.id == r.id) {
        final l = restaurantTypeLabel(p.type);
        return l.isEmpty ? null : l;
      }
    }
    return null;
  }

  ListCardData _card(Restaurant r, OpenState s, double? lat, double? lon,
          {bool mixed = false}) =>
      ListCardData(
        restaurant: r,
        open: s,
        distance: gmDistanceLabel(r, lat, lon),
        photo:
            r.mainFoto.isNotEmpty ? r.mainFoto : _dishFirstVisitThumbnail[r.id],
        dishMatch: _dishFirstMatchName[r.id],
        typeLabel: mixed ? _typeLabelFor(r) : null,
      );

  ListHeader _header(int? resultCount, int? typeTotal) {
    final typesById = {for (final t in widget.types) t.id: t.nombre};
    final catsById = {for (final c in widget.categories) c.id: c.nombre};
    return resolveListHeader(
      context: _context,
      filtersArePreset: _filters.sameAs(_preset),
      types: [
        for (final id in _filters.typeIds) (id, typesById[id] ?? ''),
      ],
      categoryLabels: [
        for (final id in _filters.categoryIds)
          if (catsById[id] != null) listCategoryLabel(catsById[id]!)
      ],
      query: _searchController.text,
      resultCount: resultCount,
      typeTotal: typeTotal,
      islandLabel: widget.islandLabel,
      now: DateTime.now(),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return BlocBuilder<RestaurantCubit, RestaurantState>(
      builder: (context, state) {
        final loc = _locationState(context);
        final lat = loc is LocationLoaded ? loc.latitude : null;
        final lon = loc is LocationLoaded ? loc.longitude : null;
        final now = DateTime.now();
        final showResults = _isActive || _hasSearched;

        final pooled = _usePresetPool;
        final server = pooled
            ? _presetPool
            : state is RestaurantFilterAdvanced
                ? state.restaurantFilterAdvanced
                : null;
        final loading = showResults &&
            !pooled &&
            state is! RestaurantFilterAdvanced &&
            state is! RestaurantFilterAdvancedError;
        final error =
            showResults && !pooled && state is RestaurantFilterAdvancedError;

        if (server != null) _rememberMunicipalities(server);
        // Principal (cuenta en el antetítulo) y «También por plato» aparte.
        final results =
            server == null ? null : _mainResults(server, _filters, now);
        final dishOnly = server == null
            ? const <Restaurant>[]
            : _dishResults(server, _filters, now);
        final typeTotal = server != null &&
                _filters.typeIds.length == 1 &&
                _requestedCategories.isEmpty &&
                !_hasQuery
            ? server.length
            : null;
        final header = showResults
            ? _header(results?.length, typeTotal)
            : resolveListHeader(
                filtersArePreset: true,
                types: const [],
                categoryLabels: const [],
                query: '',
                resultCount: null,
                now: now);
        final theme = header.theme;
        final themed = showResults && theme.kind != ListThemeKind.buscar;
        final dark = gm.isDark;

        final sort = _sort ??
            listDefaultSort(
                fromContext: _context != null && _filters.sameAs(_preset),
                hasLocation: lat != null);
        final sorted = results == null
            ? null
            : listSorted(results, sort, now,
                distance: (r) => gmDistanceMeters(r, lat, lon));
        final mixed = _filters.typeIds.length != 1;
        final cards = sorted == null
            ? const <ListCardData>[]
            : [
                for (final r in sorted)
                  _card(r, restaurantOpenState(r, now), lat, lon, mixed: mixed)
              ];
        final dishCards = [
          for (final r in listSorted(dishOnly, sort, now,
              distance: (r) => gmDistanceMeters(r, lat, lon)))
            _card(r, restaurantOpenState(r, now), lat, lon, mixed: true)
        ];
        final openCount = cards.where((c) => c.open.isOpen).length;

        final overBand = themed && _atTop && _view == _View.list;
        final statusStyle =
            dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;

        final sectionEyebrow = listSectionEyebrow(
          context: _filters.sameAs(_preset) ? _context : null,
          openCount: openCount,
          total: cards.length,
          openOnly: _filters.openOnly,
          query: _searchController.text,
        );

        Widget body;
        if (_view == _View.map && showResults) {
          body = ListMapView(
            items: [...cards, ...dishCards],
            theme: theme,
            eyebrow: sectionEyebrow,
            live: openCount > 0 && !_hasQuery,
            onOpen: (d) => _openRestaurant(d.restaurant),
            topInset: MediaQuery.paddingOf(context).top + 60,
          );
        } else {
          body = CustomScrollView(
            controller: _scroll,
            slivers: [
              SliverToBoxAdapter(
                child: _ListHeaderBand(
                  header: header,
                  themed: themed,
                  sceneVisible: _sceneVisible,
                  animatedScene:
                      themed && theme.kind == ListThemeKind.tradicional,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: themed ? 4 : 0),
                  child: _SearchRow(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    filterCount: _presetSummary.badge,
                    onChanged: _onQueryChanged,
                    onSubmitted: _onSubmitted,
                    onClear: () {
                      setState(() => _searchController.clear());
                      if (!_backToBrowse()) _runSearch();
                    },
                    onFilter: _openFilterSheet,
                  ),
                ),
              ),
              if (showResults && _filters.count + _suggestions().length > 0)
                SliverToBoxAdapter(
                  child: _FilterChipsRow(
                    chips: _activeChips(),
                    suggestions: _suggestions(),
                  ),
                ),
              if (!showResults)
                SliverToBoxAdapter(
                  child: _BrowseView(
                    recents: _recents,
                    types: widget.types,
                    pool: widget.pool,
                    onUseRecent: _useRecent,
                    onClearRecents: _clearRecents,
                    onPickType: _pickType,
                    onOpenContext: _openContext,
                  ),
                )
              else if (error)
                SliverToBoxAdapter(
                  child: _ErrorState(
                    onRetry: _runSearch,
                    types: widget.types,
                    pool: widget.pool,
                    onPickType: _pickType,
                  ),
                )
              else ...[
                if (loc is! LocationLoaded && !_hasQuery)
                  SliverToBoxAdapter(
                    child: _LocationBanner(
                      onEnable: () => _requestLocation(context),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: _SectionHead(
                    eyebrow:
                        loading ? 'Buscando ${theme.noun}…' : sectionEyebrow,
                    live: !loading && openCount > 0 && !_hasQuery,
                    title: _sectionTitle(theme),
                    sort: sort,
                    showSort:
                        loading || cards.isNotEmpty || dishCards.isNotEmpty,
                    options: listSortOptions(hasLocation: lat != null),
                    onSort: (s) => setState(() => _sort = s),
                  ),
                ),
                if (loading)
                  const SliverToBoxAdapter(child: _SkeletonGrid())
                else if (cards.isEmpty && dishCards.isEmpty)
                  SliverToBoxAdapter(
                    child:
                        _emptyState(theme, server ?? const [], now, lat, lon),
                  )
                else ...[
                  if (cards.isNotEmpty)
                    ..._resultSlivers(
                        cards, theme, sort, server ?? const [], now),
                  if (dishCards.isNotEmpty)
                    ..._dishSlivers(dishCards, theme, alone: cards.isEmpty),
                ],
              ],
              SliverToBoxAdapter(
                child:
                    SizedBox(height: MediaQuery.paddingOf(context).bottom + 96),
              ),
            ],
          );
        }

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: statusStyle,
          child: Scaffold(
            backgroundColor: overBand ? theme.band(dark) : gm.canvas,
            resizeToAvoidBottomInset: false,
            body: Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(color: gm.canvas, child: body),
                ),
                if (_view == _View.list)
                  GmTopScrim(visible: !_atTop, extra: 64),
                _TopBar(
                  showViews: showResults,
                  view: _view,
                  title: _view == _View.map ? header.title : null,
                  onBack: () => Navigator.maybePop(context),
                  onView: (v) {
                    HapticFeedback.selectionClick();
                    setState(() => _view = v);
                    _sceneVisible.value = v == _View.list && _atTop;
                  },
                ),
                if (_view == _View.list) const _MiniTabBar(),
              ],
            ),
          ),
        );
      },
    );
  }

  LocationState? _locationState(BuildContext context) {
    try {
      return context.watch<LocationCubit>().state;
    } on ProviderNotFoundException {
      // Pantalla montada sin LocationCubit (tests aislados): sin distancias.
      return null;
    }
  }

  void _requestLocation(BuildContext context) {
    try {
      context.read<LocationCubit>().requestLocation();
    } on ProviderNotFoundException {
      AppLogger.warn(
          'advanced-search', 'sin LocationCubit para pedir ubicación');
    }
  }

  String _sectionTitle(ListTheme theme) {
    if (_hasQuery) return 'Resultados';
    if (theme.isContext && _filters.sameAs(_preset)) return theme.sectionTitle;
    if (_filters.openOnly) return 'Abiertos ahora';
    if (theme.kind == ListThemeKind.categoria) return 'Dónde comerlo';
    if (theme.kind == ListThemeKind.buscar) return 'Resultados';
    return theme.sectionTitle;
  }

  /// Rejilla (listas temáticas) o filas (búsqueda por texto), destacado y
  /// «N más».
  List<Widget> _resultSlivers(List<ListCardData> cards, ListTheme theme,
      ListSort sort, List<Restaurant> server, DateTime now) {
    final rows = _hasQuery;
    final featured = !rows &&
        sort == ListSort.topRated &&
        listReviewCount(cards.first.restaurant) > 0 &&
        theme.isType;
    final rest = featured ? cards.skip(1).toList() : cards;

    Widget card(ListCardData d, int i) => listRise(
          i,
          ListGridCard(
            data: d,
            theme: theme,
            identifier: 'advanced-search-result-$i',
            onTap: () => _openRestaurant(d.restaurant),
          ),
        );

    final later = _filters.openOnly && !rows
        ? listLaterBreakdown(
            [
              for (final r
                  in _mainResults(server, _filters, now, openOnly: false))
                if (!restaurantOpenState(r, now).isOpen) r
            ],
            now,
          )
        : null;
    final laterText =
        later == null ? null : listLaterText(later, noun: theme.noun);

    return [
      if (featured)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: listRise(
              1,
              ListFeaturedCard(
                data: cards.first,
                theme: theme,
                onTap: () => _openRestaurant(cards.first.restaurant),
              ),
            ),
          ),
        ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverSemantics(
          identifier: 'advanced-search-results-list',
          container: true,
          sliver: SliverList.builder(
            itemCount: rows ? rest.length : (rest.length + 1) ~/ 2,
            itemBuilder: (_, i) {
              if (rows) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: listRise(
                    i + 2,
                    ListRowCard(
                      data: rest[i],
                      theme: theme,
                      onTap: () => _openRestaurant(rest[i].restaurant),
                    ),
                  ),
                );
              }
              final a = i * 2;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ListCardRow(
                  left: card(rest[a], a + 2),
                  right: a + 1 < rest.length ? card(rest[a + 1], a + 3) : null,
                ),
              );
            },
          ),
        ),
      ),
      if (laterText != null)
        SliverToBoxAdapter(
          child: _LaterCard(
            lead: laterText.$1,
            text: laterText.$2,
            onSeeAll: () => _applyFilters(_filters.copyWith(openOnly: false)),
          ),
        ),
    ];
  }

  /// «También por plato»: sitios que no son del filtro pero tienen el
  /// plato en una visita. Van aparte para que el recuento de arriba sea el
  /// del filtro (el mismo que en la home).
  List<Widget> _dishSlivers(List<ListCardData> cards, ListTheme theme,
      {required bool alone}) {
    final gm = GmColors.of(context);
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, alone ? 0 : 14, 20, 10),
          child: Semantics(
            identifier: 'advanced-search-dish-group',
            header: true,
            child: GmEyebrow(
              leading: GmIcon(GmIcons.video, size: 13, color: gm.label2),
              text: alone
                  ? 'Por plato · ${cards.length == 1 ? '1 sitio' : '${cards.length} sitios'}'
                  : 'También por plato · ${cards.length == 1 ? '1 sitio' : '${cards.length} sitios'}',
            ),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList.builder(
          itemCount: cards.length,
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ListRowCard(
              data: cards[i],
              theme: theme,
              onTap: () => _openRestaurant(cards[i].restaurant),
            ),
          ),
        ),
      ),
    ];
  }

  // ── Chips ──────────────────────────────────────────────────────────────

  /// El preset de la franja sigue entero en los filtros.
  PresetSummary get _presetSummary => listPresetSummary(
        hasContext: _context != null,
        presetTypes: _preset.typeIds,
        presetCategories: _preset.categoryIds,
        presetOpenOnly: _preset.openOnly,
        types: _filters.typeIds,
        categories: _filters.categoryIds,
        municipalities: _filters.municipalityIds,
        openOnly: _filters.openOnly,
      );

  /// Quita el preset de la franja (tipos, sus categorías y «Abierto
  /// ahora») y deja lo que el usuario añadió encima.
  void _clearPreset() {
    final extras = _presetSummary.extraCategoryIds;
    final next = SearchFilterValues(
      categoryIds: extras,
      municipalityIds: _filters.municipalityIds,
    );
    setState(() => _context = null);
    if (next.count == 0 && !_hasQuery) {
      setState(() {
        _filters = next;
        _hasSearched = false;
      });
      return;
    }
    _applyFilters(next);
  }

  List<_ChipData> _activeChips() {
    final gm = GmColors.of(context);
    final typesById = {for (final t in widget.types) t.id: t};
    final catsById = {for (final c in widget.categories) c.id: c};
    final names = _municipalityNames;
    final out = <_ChipData>[];
    final preset = _presetSummary;
    if (preset.active) {
      // Un solo chip para el preset («Para almorzar ×»); dentro del panel
      // de filtros se ve desplegado en sus tipos.
      final th = kListThemes[_context]!;
      out.add(_ChipData(
        label: th.title,
        leading: ListThemeGlyph(th.glyph, size: 16, color: gm.accent),
        onTap: _clearPreset,
      ));
      for (final id in preset.extraCategoryIds) {
        final c = catsById[id];
        if (c == null) continue;
        out.add(_ChipData(
          label: listCategoryLabel(c.nombre),
          leading:
              FichaFeatureChips.glyph(fichaCategoryFeature(c.nombre).glyph, gm),
          onTap: () => _applyFilters(_filters.copyWith(
              categoryIds: [..._filters.categoryIds]..remove(id))),
        ));
      }
      for (final id in _filters.municipalityIds) {
        out.add(_ChipData(
          label: names[id] ?? 'Municipio',
          leading: GmIcon(GmIcons.pin, size: 13, color: gm.accent),
          onTap: () => _applyFilters(_filters.copyWith(
              municipalityIds: [..._filters.municipalityIds]..remove(id))),
        ));
      }
      return out;
    }
    for (final id in _filters.typeIds) {
      final t = typesById[id];
      if (t == null) continue;
      final k = listThemeForType(t.id, t.nombre);
      out.add(_ChipData(
        label: k == null ? t.nombre : kListThemes[k]!.title,
        leading: k == null
            ? null
            : ListThemeGlyph(kListThemes[k]!.glyph, size: 16, color: gm.accent),
        onTap: () => _applyFilters(
            _filters.copyWith(typeIds: [..._filters.typeIds]..remove(id))),
      ));
    }
    if (_filters.openOnly) {
      out.add(_ChipData(
        label: 'Abierto ahora',
        leading: const GmLiveDot(),
        onTap: () => _applyFilters(_filters.copyWith(openOnly: false)),
      ));
    }
    for (final id in _filters.categoryIds) {
      final c = catsById[id];
      if (c == null) continue;
      out.add(_ChipData(
        label: listCategoryLabel(c.nombre),
        leading:
            FichaFeatureChips.glyph(fichaCategoryFeature(c.nombre).glyph, gm),
        onTap: () => _applyFilters(_filters.copyWith(
            categoryIds: [..._filters.categoryIds]..remove(id))),
      ));
    }
    for (final id in _filters.municipalityIds) {
      out.add(_ChipData(
        label: names[id] ?? 'Municipio',
        leading: GmIcon(GmIcons.pin, size: 13, color: gm.accent),
        onTap: () => _applyFilters(_filters.copyWith(
            municipalityIds: [..._filters.municipalityIds]..remove(id))),
      ));
    }
    return out;
  }

  /// Sugerencias (borde discontinuo): «Abierto ahora» y dos o tres de «Qué
  /// buscas» que aún no están puestas.
  List<_ChipData> _suggestions() {
    final gm = GmColors.of(context);
    final out = <_ChipData>[];
    if (!_filters.openOnly) {
      out.add(_ChipData(
        label: 'Abierto ahora',
        leading: GmLiveDot(color: gm.green),
        onTap: () => _applyFilters(_filters.copyWith(openOnly: true)),
      ));
    }
    const wanted = [
      CategoryIds.terraza,
      CategoryIds.carneCabra,
      CategoryIds.conVistas,
      CategoryIds.pescadoMarisco,
    ];
    final catsById = {for (final c in widget.categories) c.id: c};
    for (final id in wanted) {
      if (out.length >= 4) break;
      final c = catsById[id];
      if (c == null || _filters.categoryIds.contains(id)) continue;
      out.add(_ChipData(
        label: listCategoryLabel(c.nombre),
        leading:
            FichaFeatureChips.glyph(fichaCategoryFeature(c.nombre).glyph, gm),
        onTap: () => _applyFilters(
            _filters.copyWith(categoryIds: [..._filters.categoryIds, id])),
      ));
    }
    return out;
  }

  // ── Vacío ──────────────────────────────────────────────────────────────

  Widget _emptyState(ListTheme theme, List<Restaurant> server, DateTime now,
      double? lat, double? lon) {
    final catsById = {for (final c in widget.categories) c.id: c};
    final names = _municipalityNames;
    // El filtro que más estorba: el último local que se pueda quitar.
    String? label;
    SearchFilterValues? without;
    if (_filters.municipalityIds.isNotEmpty) {
      final id = _filters.municipalityIds.last;
      label = names[id];
      without = _filters.copyWith(
          municipalityIds: [..._filters.municipalityIds]..remove(id));
    } else if (_filters.categoryIds.isNotEmpty) {
      final id = _filters.categoryIds.last;
      final c = catsById[id];
      label = c == null ? null : listCategoryLabel(c.nombre);
      without =
          _filters.copyWith(categoryIds: [..._filters.categoryIds]..remove(id));
    } else if (_filters.openOnly) {
      label = 'Abierto ahora';
      without = _filters.copyWith(openOnly: false);
    }
    // Solo se adelanta la lista sin ese filtro si no hace falta el servidor.
    final local = without != null &&
        SearchFilterValues.sameIds(
            _serverCategories(without), _requestedCategories);
    final alt = local
        ? listSorted(_results(server, without, now), ListSort.openFirst, now,
            distance: (r) => gmDistanceMeters(r, lat, lon)).take(4).toList()
        : const <Restaurant>[];
    final q = _searchController.text.trim();
    final open = theme.feminine ? 'abierta' : 'abierto';
    final title = q.isNotEmpty
        ? 'Sin resultados para «$q»'
        : label == null
            ? '${theme.none} con esos filtros'
            : '${theme.none}${_filters.openOnly && label != 'Abierto ahora' ? ' $open' : ''} con «$label»';
    final line = q.isNotEmpty
        ? 'Prueba con otra búsqueda o quita filtros.'
        : theme.emptyLine;

    final altOpen = alt.where((r) => restaurantOpenState(r, now).isOpen).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: _StateCard(
            identifier: 'advanced-search-empty',
            art: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                  color: theme.tint(GmColors.of(context).isDark),
                  shape: BoxShape.circle),
              alignment: Alignment.center,
              child: ListThemeGlyph(theme.glyph,
                  size: 42, color: theme.ink(GmColors.of(context).isDark)),
            ),
            title: title,
            text: line,
            action: without == null ? null : 'Quitar «$label»',
            onAction: without == null ? null : () => _applyFilters(without!),
          ),
        ),
        if (alt.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
            child: GmEyebrow(
              leading: const GmLiveDot(),
              text: 'Sin ese filtro · '
                  '${altOpen == 1 ? '1 abierto ahora' : '$altOpen abiertos ahora'}',
              color: GmColors.of(context).greenText,
            ),
          ),
          for (var i = 0; i < alt.length; i += 2)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: ListCardRow(
                left: ListGridCard(
                  data:
                      _card(alt[i], restaurantOpenState(alt[i], now), lat, lon),
                  theme: theme,
                  onTap: () => _openRestaurant(alt[i]),
                ),
                right: i + 1 < alt.length
                    ? ListGridCard(
                        data: _card(alt[i + 1],
                            restaurantOpenState(alt[i + 1], now), lat, lon),
                        theme: theme,
                        onTap: () => _openRestaurant(alt[i + 1]),
                      )
                    : null,
              ),
            ),
        ],
      ],
    );
  }
}

// ── Cabecera ──────────────────────────────────────────────────────────────

class _ListHeaderBand extends StatelessWidget {
  final ListHeader header;
  final bool themed;
  final bool animatedScene;
  final ValueNotifier<bool> sceneVisible;

  const _ListHeaderBand({
    required this.header,
    required this.themed,
    required this.animatedScene,
    required this.sceneVisible,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final dark = gm.isDark;
    final t = header.theme;
    final top = MediaQuery.paddingOf(context).top;
    final width = MediaQuery.sizeOf(context).width;

    // Lista de categoría: el glifo de la característica (cabra, cochino…).
    final catGlyph = t.kind == ListThemeKind.categoria
        ? FichaFeatureChips.glyph(fichaCategoryFeature(header.title).glyph, gm)
        : null;
    Widget glyph(double size) => catGlyph != null
        ? SizedBox(width: size, height: size, child: FittedBox(child: catGlyph))
        : ListThemeGlyph(t.glyph, size: size, color: t.ink(dark));

    final text = MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.25,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (header.eyebrow.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: GmEyebrow(
                leading: themed ? glyph(14) : null,
                text: header.eyebrow,
                color: themed ? t.ink(dark) : gm.label2,
              ),
            ),
          Semantics(
            header: true,
            identifier: 'advanced-search-title',
            child: Text(
              header.title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GmText.largeTitle(color: gm.label)
                  .copyWith(height: 39 / 34, letterSpacing: -0.8),
            ),
          ),
          if (header.subtitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                header.subtitle,
                style: GmText.body(color: gm.label2),
              ),
            ),
        ],
      ),
    );

    if (!themed) {
      return Padding(
        padding: EdgeInsets.fromLTRB(20, top + 66, 20, 16),
        child: text,
      );
    }

    final scene = animatedScene;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: ColoredBox(color: t.band(dark))),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                  20, top + 58, scene ? 20 : 120, scene ? 18 : 40),
              child: text,
            ),
            if (scene)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ValueListenableBuilder<bool>(
                  valueListenable: sceneVisible,
                  builder: (_, visible, __) =>
                      MesaBrindisScene(active: visible),
                ),
              ),
          ],
        ),
        if (!scene)
          Positioned(
            right: 22,
            top: top + 62,
            child: ExcludeSemantics(
              child:
                  _BandArt(theme: t, dark: dark, width: width, glyph: catGlyph),
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

/// Ilustración quieta de la banda: el glifo del tema a 84 con un halo.
class _BandArt extends StatelessWidget {
  final ListTheme theme;
  final bool dark;
  final double width;

  /// Glifo propio (listas de categoría); si no, el del tema.
  final Widget? glyph;
  const _BandArt(
      {required this.theme,
      required this.dark,
      required this.width,
      this.glyph});

  @override
  Widget build(BuildContext context) {
    final size = width < 360 ? 64.0 : 84.0;
    return Container(
      width: size + 20,
      height: size + 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [
          Colors.white.withValues(alpha: dark ? 0.06 : 0.55),
          Colors.white.withValues(alpha: 0),
        ]),
      ),
      alignment: Alignment.center,
      child: glyph != null
          ? SizedBox(
              width: size * 0.8,
              height: size * 0.8,
              child: FittedBox(child: glyph))
          : ListThemeGlyph(theme.glyph, size: size, color: theme.ink(dark)),
    );
  }
}

/// Atrás de cristal + segmento Lista/Mapa (fijos arriba).
class _TopBar extends StatelessWidget {
  final bool showViews;
  final _View view;
  final String? title;
  final VoidCallback onBack;
  final ValueChanged<_View> onView;

  const _TopBar({
    required this.showViews,
    required this.view,
    required this.onBack,
    required this.onView,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final top = MediaQuery.paddingOf(context).top;
    return Positioned(
      left: 16,
      right: 16,
      top: top + 2,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.2,
        child: Row(
          children: [
            GmToolbarButton(
              icon: GmIcons.chevronLeft,
              iconSize: 20,
              light: true,
              semanticLabel: 'Volver',
              identifier: 'advanced-search-back',
              onTap: onBack,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: title == null
                  ? const SizedBox.shrink()
                  : Align(
                      alignment: Alignment.centerLeft,
                      child: GmGlass(
                        borderRadius: BorderRadius.circular(GmRadius.pill),
                        tint: gm.glass,
                        edge: gm.glassEdge,
                        shadow: gm.shadow1,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child: Text(title!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GmText.body(
                                  color: gm.label, w: FontWeight.w600)),
                        ),
                      ),
                    ),
            ),
            if (showViews) ...[
              const SizedBox(width: 8),
              _Segmented(view: view, onChanged: onView),
            ],
          ],
        ),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  final _View view;
  final ValueChanged<_View> onChanged;
  const _Segmented({required this.view, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    Widget seg(_View v, String icon, String label) {
      final on = view == v;
      return Semantics(
        identifier: 'advanced-search-view-${v.name}',
        button: true,
        selected: on,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(v),
          child: AnimatedContainer(
            duration:
                Duration(milliseconds: GmMotion.reduced(context) ? 0 : 200),
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: on ? gm.card : Colors.transparent,
              borderRadius: BorderRadius.circular(GmRadius.pill),
              boxShadow: on
                  ? const [
                      BoxShadow(
                          color: Color(0x1F000000),
                          blurRadius: 4,
                          offset: Offset(0, 1))
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GmIcon(icon, size: 17, color: on ? gm.label : gm.label2),
                const SizedBox(width: 5),
                Text(label,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: on ? gm.label : gm.label2)),
              ],
            ),
          ),
        ),
      );
    }

    return GmGlass(
      borderRadius: BorderRadius.circular(GmRadius.pill),
      tint: gm.glass,
      edge: gm.glassEdge,
      shadow: gm.shadow1,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            seg(_View.list, GmIcons.list, 'Lista'),
            const SizedBox(width: 2),
            seg(_View.map, GmIcons.map, 'Mapa'),
          ],
        ),
      ),
    );
  }
}

/// Barra de pestañas minimizada (abajo a la izquierda): vuelve a Explora.
class _MiniTabBar extends StatelessWidget {
  const _MiniTabBar();

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Positioned(
      left: 16,
      bottom: MediaQuery.paddingOf(context).bottom + 6,
      child: Semantics(
        identifier: 'advanced-search-tab-explora',
        button: true,
        label: 'Explora',
        excludeSemantics: true,
        child: GmPressable(
          onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
          pressedScale: 0.9,
          child: SizedBox(
            width: 54,
            height: 54,
            child: GmGlass(
              borderRadius: BorderRadius.circular(27),
              tint: gm.glass,
              edge: gm.glassEdge,
              shadow: gm.shadow2,
              child: Center(
                child: GmIcon(GmIcons.tabExploraOn,
                    size: 24, color: GmColors.atlantico),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Buscador y chips ──────────────────────────────────────────────────────

class _SearchRow extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final int filterCount;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final VoidCallback onFilter;

  const _SearchRow({
    required this.controller,
    required this.focusNode,
    required this.filterCount,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Row(
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                decoration: BoxDecoration(
                  color: gm.card,
                  borderRadius: BorderRadius.circular(GmRadius.pill),
                  boxShadow: gm.shadow1,
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 15),
                    GmIcon(GmIcons.search, size: 18, color: gm.label2),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Semantics(
                        identifier: 'advanced-search-input',
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          onChanged: onChanged,
                          onSubmitted: onSubmitted,
                          textInputAction: TextInputAction.search,
                          cursorColor: gm.accent,
                          style: GmText.body17(color: gm.label),
                          decoration: InputDecoration(
                            hintText: 'Nombre, zona, plato…',
                            hintStyle: GmText.body17(color: gm.label2),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ),
                    if (controller.text.isNotEmpty)
                      Semantics(
                        identifier: 'advanced-search-clear',
                        button: true,
                        label: 'Borrar búsqueda',
                        excludeSemantics: true,
                        child: GestureDetector(
                          onTap: onClear,
                          behavior: HitTestBehavior.opaque,
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Center(
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                    color: gm.fill, shape: BoxShape.circle),
                                alignment: Alignment.center,
                                child: GmIcon(GmIcons.xSmall,
                                    size: 10, color: gm.label2),
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              identifier: 'advanced-search-filter-button',
              button: true,
              label: filterCount == 0
                  ? 'Filtros'
                  : 'Filtros, $filterCount activos',
              excludeSemantics: true,
              child: GmPressable(
                onTap: onFilter,
                pressedScale: 0.95,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: gm.card,
                    borderRadius: BorderRadius.circular(GmRadius.pill),
                    boxShadow: gm.shadow1,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GmIcon(GmIcons.filters, size: 16, color: gm.label),
                      const SizedBox(width: 6),
                      Text('Filtros',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: gm.label)),
                      if (filterCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          constraints: const BoxConstraints(minWidth: 20),
                          height: 20,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            gradient: GmColors.accentFill,
                            borderRadius: BorderRadius.circular(GmRadius.pill),
                          ),
                          alignment: Alignment.center,
                          child: Text('$filterCount',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipData {
  final String label;
  final Widget? leading;
  final VoidCallback onTap;
  const _ChipData({required this.label, required this.onTap, this.leading});
}

/// Chips activos (azul suave con aspa) y sugerencias (borde fino). Alto
/// visual 34, toque de 44.
class _FilterChipsRow extends StatelessWidget {
  final List<_ChipData> chips;
  final List<_ChipData> suggestions;
  const _FilterChipsRow({required this.chips, required this.suggestions});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    Widget chip(_ChipData c, bool active) => Semantics(
          button: true,
          label:
              active ? 'Quitar filtro ${c.label}' : 'Añadir filtro ${c.label}',
          excludeSemantics: true,
          child: GmPressable(
            onTap: () {
              HapticFeedback.selectionClick();
              c.onTap();
            },
            pressedScale: 0.95,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Container(
                height: 34,
                padding: EdgeInsets.fromLTRB(12, 0, active ? 8 : 12, 0),
                decoration: BoxDecoration(
                  color: active ? gm.accentSoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(GmRadius.pill),
                  border: active ? null : Border.all(color: gm.sep, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (c.leading != null) ...[
                      SizedBox(
                          width: 16,
                          height: 16,
                          child: Center(child: c.leading)),
                      const SizedBox(width: 6),
                    ],
                    Text(c.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              active ? FontWeight.w600 : FontWeight.w500,
                          color: active ? gm.accent : gm.label,
                        )),
                    if (active) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                            color: Color(0x24006FA3), shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child:
                            GmIcon(GmIcons.xSmall, size: 9, color: gm.accent),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: SizedBox(
        height: 56,
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) => LinearGradient(
            colors: const [Colors.black, Colors.black, Colors.transparent],
            stops: [0, (rect.width - 24) / rect.width, 1],
          ).createShader(rect),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            children: [
              for (final c in chips) ...[
                chip(c, true),
                const SizedBox(width: 8)
              ],
              for (final c in suggestions) ...[
                chip(c, false),
                const SizedBox(width: 8)
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sección de resultados ─────────────────────────────────────────────────

class _SectionHead extends StatelessWidget {
  final String eyebrow;
  final bool live;
  final String title;
  final ListSort sort;
  final bool showSort;
  final List<ListSort> options;
  final ValueChanged<ListSort> onSort;

  const _SectionHead({
    this.showSort = true,
    required this.eyebrow,
    required this.live,
    required this.title,
    required this.sort,
    required this.options,
    required this.onSort,
  });

  Future<void> _pick(BuildContext context) async {
    final gm = GmColors.of(context);
    final picked = await showModalBottomSheet<ListSort>(
      context: context,
      backgroundColor: gm.canvas,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                child: Text('Ordenar', style: GmText.title2(color: gm.label)),
              ),
              GmCard(
                child: Column(
                  children: [
                    for (var i = 0; i < options.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: gm.sep, indent: 16),
                      Semantics(
                        button: true,
                        selected: options[i] == sort,
                        child: InkWell(
                          onTap: () => Navigator.pop(ctx, options[i]),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 52),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(listSortLabel(options[i]),
                                      style: GmText.body17(color: gm.label)),
                                ),
                                if (options[i] == sort)
                                  GmIcon(GmIcons.check,
                                      size: 14, color: gm.accent),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) onSort(picked);
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final caption = showSort ? listSortCaption(sort) : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            identifier: 'advanced-search-result-count',
            child: GmEyebrow(
              leading: live ? const GmLiveDot(live: true) : null,
              text: eyebrow,
              color: live ? gm.greenText : gm.label2,
            ),
          ),
          // Título y orden en una fila (el título se recorta antes); solo
          // con texto grande el orden baja a la línea siguiente.
          Builder(builder: (context) {
            final large = MediaQuery.textScalerOf(context).scale(10) > 11.5;
            final title2 = Text(title,
                maxLines: large ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: GmText.title2(color: gm.label));
            final sortPill = !showSort
                ? null
                : Semantics(
                    identifier: 'advanced-search-sort',
                    button: true,
                    label: 'Ordenar: ${listSortLabel(sort)}',
                    excludeSemantics: true,
                    child: GmPressable(
                      onTap: () => _pick(context),
                      pressedScale: 0.95,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Container(
                          height: 36,
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
                              Text(listSortShortLabel(sort),
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: gm.label)),
                              const SizedBox(width: 4),
                              GmIcon(GmIcons.chevronDown,
                                  size: 12, color: gm.label),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
            if (large || sortPill == null) {
              return Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 6,
                children: [title2, if (sortPill != null) sortPill],
              );
            }
            return Row(
              children: [
                Expanded(child: title2),
                const SizedBox(width: 10),
                sortPill,
              ],
            );
          }),
          if (caption != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(caption, style: GmText.meta(color: gm.label2)),
            ),
        ],
      ),
    );
  }
}

class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'advanced-search-loading',
      label: 'Cargando resultados',
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            ListCardRow(left: ListSkeletonCard(), right: ListSkeletonCard()),
            SizedBox(height: 12),
            ListCardRow(left: ListSkeletonCard(), right: ListSkeletonCard()),
          ],
        ),
      ),
    );
  }
}

class _LaterCard extends StatelessWidget {
  final String lead;
  final String text;
  final VoidCallback onSeeAll;
  const _LaterCard(
      {required this.lead, required this.text, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Semantics(
        identifier: 'advanced-search-more',
        container: true,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
          decoration: BoxDecoration(
            color: gm.band,
            borderRadius: BorderRadius.circular(GmRadius.card),
          ),
          child: Row(
            children: [
              GmIcon(GmIcons.clock, size: 18, color: gm.bandInk),
              const SizedBox(width: 12),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                          text: '$lead ',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      TextSpan(text: text),
                    ],
                  ),
                  style: GmText.sub(color: gm.label),
                ),
              ),
              const SizedBox(width: 8),
              GmPressable(
                onTap: onSeeAll,
                semanticsIdentifier: 'advanced-search-see-all',
                semanticsLabel: 'Ver todas',
                child: Container(
                  constraints: const BoxConstraints(minHeight: 40),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: gm.card,
                    borderRadius: BorderRadius.circular(GmRadius.pill),
                    boxShadow: gm.shadow1,
                  ),
                  alignment: Alignment.center,
                  child: Text('Ver todas',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: gm.label)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationBanner extends StatelessWidget {
  final VoidCallback onEnable;
  const _LocationBanner({required this.onEnable});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: GmCard(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: [
              GmIcon(GmIcons.placeFilled, size: 16, color: GmColors.atlantico),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Activa la ubicación para ver distancias',
                    style: GmText.sub(color: gm.label, w: FontWeight.w500)),
              ),
              Semantics(
                identifier: 'advanced-search-location-enable',
                button: true,
                child: GmPressable(
                  onTap: onEnable,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: gm.accentSoft,
                      borderRadius: BorderRadius.circular(GmRadius.pill),
                    ),
                    alignment: Alignment.center,
                    child: Text('Activar',
                        style:
                            GmText.body(color: gm.accent, w: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de estado (vacío o error) con ilustración, texto y acción.
class _StateCard extends StatelessWidget {
  final String identifier;
  final Widget art;
  final String title;
  final String text;
  final String? action;
  final VoidCallback? onAction;

  const _StateCard({
    required this.identifier,
    required this.art,
    required this.title,
    required this.text,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: identifier,
      container: true,
      child: GmCard(
        radius: 28,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
          child: Column(
            children: [
              art,
              const SizedBox(height: 14),
              Text(title,
                  textAlign: TextAlign.center,
                  style: GmText.guideTitle(color: gm.label).copyWith(
                      fontSize: 19,
                      height: 24 / 19,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(text,
                  textAlign: TextAlign.center,
                  style: GmText.body(color: gm.label2)),
              if (action != null) ...[
                const SizedBox(height: 16),
                GmCapsuleButton(
                  label: action!,
                  identifier: '$identifier-action',
                  onTap: onAction,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  final List<Types> types;
  final List<Restaurant> pool;
  final ValueChanged<Types> onPickType;

  const _ErrorState({
    required this.onRetry,
    required this.types,
    required this.pool,
    required this.onPickType,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: _StateCard(
            identifier: 'advanced-search-error',
            art: const GmGlyph(GmGlyphKind.volcan, size: 72),
            title: 'No pudimos cargar los resultados',
            text: 'Revisa tu conexión e inténtalo de nuevo. Tus filtros se '
                'quedan como están.',
            action: 'Reintentar',
            onAction: onRetry,
          ),
        ),
        if (types.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
            child: Text('Mientras tanto, explora por tipo',
                style: GmText.eyebrow(color: gm.label2)),
          ),
          _TypeGrid(types: types, pool: pool, onPick: onPickType),
        ],
      ],
    );
  }
}

// ── Explorar (sin búsqueda) ───────────────────────────────────────────────

class _BrowseView extends StatelessWidget {
  final List<String> recents;
  final List<Types> types;
  final List<Restaurant> pool;
  final ValueChanged<String> onUseRecent;
  final VoidCallback onClearRecents;
  final ValueChanged<Types> onPickType;
  final ValueChanged<ListThemeKind> onOpenContext;

  const _BrowseView({
    required this.recents,
    required this.types,
    required this.pool,
    required this.onUseRecent,
    required this.onClearRecents,
    required this.onPickType,
    required this.onOpenContext,
  });

  static const _days = [
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo'
  ];

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final dark = gm.isDark;
    final now = DateTime.now();
    final k = contextThemeForHour(now.hour);
    final t = kListThemes[k]!;
    final cfg = contextualFilterFor(now.hour);
    // Mismo recuento que «Hoy» en la home.
    final openForContext = contextualOpenNow(pool, cfg, now).length;
    final time = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            identifier: 'advanced-search-for-now',
            button: true,
            child: GmPressable(
              onTap: () => onOpenContext(k),
              pressedScale: 0.98,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: t.band(dark),
                  borderRadius: BorderRadius.circular(GmRadius.card),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: gm.card,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child:
                          ListThemeGlyph(t.glyph, size: 40, color: t.ink(dark)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Para ahora · ${_days[now.weekday - 1]}, $time',
                              style: GmText.chip(color: t.ink(dark))),
                          Text(t.title,
                              style: GmText.guideTitle(color: gm.label)
                                  .copyWith(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w700)),
                          if (pool.isNotEmpty)
                            Row(
                              children: [
                                GmLiveDot(live: openForContext > 0),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    openForContext == 1
                                        ? '1 abierto ahora'
                                        : '$openForContext abiertos ahora',
                                    style: GmText.sub(
                                        color: gm.greenText,
                                        w: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    GmIcon(GmIcons.chevronRight, size: 13, color: gm.label2),
                    const SizedBox(width: 6),
                  ],
                ),
              ),
            ),
          ),
          if (recents.isNotEmpty) ...[
            const SizedBox(height: 26),
            Row(
              children: [
                Expanded(
                  child: Text('Búsquedas recientes',
                      style: GmText.eyebrow(color: gm.label2)),
                ),
                Semantics(
                  identifier: 'advanced-search-clear-recents',
                  button: true,
                  child: GestureDetector(
                    onTap: onClearRecents,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text('Borrar',
                          style: GmText.eyebrow(color: gm.label2)),
                    ),
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in recents)
                  GmPressable(
                    onTap: () => onUseRecent(r),
                    semanticsLabel: 'Buscar $r',
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 36),
                      padding: const EdgeInsets.fromLTRB(10, 7, 14, 7),
                      decoration: BoxDecoration(
                        color: gm.card,
                        borderRadius: BorderRadius.circular(GmRadius.pill),
                        boxShadow: gm.shadow1,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GmIcon(GmIcons.clock, size: 13, color: gm.label),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(r,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: gm.label)),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (types.isNotEmpty) ...[
            const SizedBox(height: 26),
            Text('Explorar por tipo', style: GmText.eyebrow(color: gm.label2)),
            const SizedBox(height: 10),
            _TypeGrid(types: types, pool: pool, onPick: onPickType, inset: 0),
          ],
        ],
      ),
    );
  }
}

/// «Explorar por tipo»: loseta con el tinte y el glifo de cada tipo y su
/// recuento real (si la home ya trajo los sitios).
class _TypeGrid extends StatelessWidget {
  final List<Types> types;
  final List<Restaurant> pool;
  final ValueChanged<Types> onPick;
  final double inset;

  const _TypeGrid({
    required this.types,
    required this.pool,
    required this.onPick,
    this.inset = 16,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final dark = gm.isDark;
    final counts = <String, int>{};
    for (final r in pool) {
      counts[r.type] = (counts[r.type] ?? 0) + 1;
    }
    // Más sitios primero; los que no tienen ninguno, fuera.
    final list = [...types];
    if (pool.isNotEmpty) {
      list.removeWhere((t) => (counts[t.id] ?? 0) == 0);
      list.sort((a, b) => (counts[b.id] ?? 0).compareTo(counts[a.id] ?? 0));
    }

    Widget tile(Types t) {
      final k = listThemeForType(t.id, t.nombre) ?? ListThemeKind.restaurante;
      final th = kListThemes[k]!;
      final n = counts[t.id];
      return Semantics(
        identifier: 'advanced-search-type-${k.name}',
        button: true,
        label: n == null ? th.title : '${th.title}, $n sitios',
        excludeSemantics: true,
        child: GmPressable(
          onTap: () => onPick(t),
          child: GmCard(
            radius: 22,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: th.tint(dark),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child:
                        ListThemeGlyph(th.glyph, size: 30, color: th.ink(dark)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(th.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GmText.cardTitle(color: gm.label)
                                .copyWith(fontSize: 15, height: 19 / 15)),
                        if (n != null)
                          Text(n == 1 ? '1 sitio' : '$n sitios',
                              style: GmText.meta(color: gm.label2)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: inset),
      child: Column(
        children: [
          for (var i = 0; i < list.length; i += 2) ...[
            if (i > 0) const SizedBox(height: 10),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: tile(list[i])),
                  const SizedBox(width: 10),
                  Expanded(
                    child: i + 1 < list.length
                        ? tile(list[i + 1])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
