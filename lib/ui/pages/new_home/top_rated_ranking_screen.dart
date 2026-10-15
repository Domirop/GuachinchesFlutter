import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/new_home/islands_cubit.dart';
import 'package:guachinches/data/cubit/new_home/new_home_filters_cubit.dart';
import 'package:guachinches/data/model/Island.dart';
import 'package:guachinches/data/model/TopRestaurants.dart';
import 'package:guachinches/ui/pages/advance_search/list_theme.dart'
    show ListGlyph;
import 'package:guachinches/ui/pages/advance_search/widgets/list_glyph.dart';
import 'package:guachinches/ui/pages/listas/listas_logic.dart'
    show listasNormalize, listasTopReviewCount;
import 'package:guachinches/ui/pages/new_home/sheets/island_picker_sheet.dart';
import 'package:guachinches/ui/pages/new_home/top_rated_logic.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_state_card.dart';
import 'package:guachinches/ui/pages/restaurant_detail/restaurant_detail_screen.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';
import 'package:guachinches/utils/island_key_utils.dart';
import 'package:http/http.dart' as http;

/// Carga el ranking de una isla: `/restaurant/top/all` (global) ∩ isla por
/// municipio (lista oficial + barrios de `/areas/islands/:id`).
class TopRatedRankingLoader {
  final RemoteRepository repository;
  const TopRatedRankingLoader(this.repository);

  Future<List<TopRestaurants>> load({
    String? islandId,
    required String islandKey,
  }) async {
    final top = await repository.getTopRestaurants();
    // El repositorio devuelve [] cuando la petición falla: un ranking global
    // vacío es un fallo, no «nadie llega a 10 reseñas».
    if (top.isEmpty) {
      throw StateError('ranking global vacío (/restaurant/top/all)');
    }
    var areas = const <String>[];
    if (islandId != null && islandId.isNotEmpty) {
      try {
        final ms = await repository.getAllMunicipalitiesFiltered(islandId);
        areas = [
          for (final a in ms)
            for (final m in a.municipalities) m.nombre
        ];
      } catch (e, st) {
        // Sin barrios seguimos con la lista oficial de municipios.
        AppLogger.error('top-rated', e, st);
      }
    }
    return topRatedForIsland(top, islandKey, areaNames: areas);
  }
}

class _IslandRef {
  final String? id;
  final String key;
  final String label;
  const _IslandRef({this.id, required this.key, required this.label});
}

enum _Status { loading, ready, error }

/// «Mejor valorados» (tablero MejorValorados): ranking ponderado de la isla
/// (solo sitios con 10 reseñas o más), «Aún con pocas reseñas» aparte y
/// píldora para mirar otra isla.
///
/// [restaurants] son los sitios del ranking de la isla [islandLabel] (sin
/// filtrar o ya filtrados a ≥ 10). Vacío → la pantalla los carga.
class TopRatedRankingScreen extends StatefulWidget {
  final List<TopRestaurants> restaurants;
  final String islandLabel;

  /// Para cargar otra isla o cuando [restaurants] llega vacío. Por defecto
  /// `HttpRemoteRepository`.
  final RemoteRepository? repository;

  /// Isla de [islandLabel]. Si no llegan, se toman del filtro global
  /// (`NewHomeFiltersCubit`) cuando es la misma isla, o del nombre.
  final String? islandId;
  final String? islandKey;

  const TopRatedRankingScreen({
    super.key,
    required this.restaurants,
    required this.islandLabel,
    this.repository,
    this.islandId,
    this.islandKey,
  });

  @override
  State<TopRatedRankingScreen> createState() => _TopRatedRankingScreenState();
}

class _TopRatedRankingScreenState extends State<TopRatedRankingScreen> {
  late _IslandRef _island;
  _IslandRef? _previous;
  final Map<String, TopRatedSplit> _cache = {};
  TopRatedSplit _split = TopRatedSplit.empty;
  _Status _status = _Status.loading;
  bool _fewExpanded = false;
  bool _scrolled = false;
  int _seq = 0;
  TopRatedRankingLoader? _loader;

  TopRatedRankingLoader get _rankingLoader => _loader ??= TopRatedRankingLoader(
      widget.repository ?? HttpRemoteRepository(http.Client()));

  static T? _maybeRead<T>(BuildContext context) {
    try {
      return context.read<T>();
    } on ProviderNotFoundException {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _island = _initialIsland();
    if (widget.restaurants.isNotEmpty) {
      _split = topRatedSplit(widget.restaurants);
      _cache[_island.key] = _split;
      _status = _Status.ready;
    } else {
      _fetch();
    }
  }

  _IslandRef _initialIsland() {
    final label = widget.islandLabel.trim();
    final f = _maybeRead<NewHomeFiltersCubit>(context)?.state;
    final same = f != null &&
        listasNormalize(f.islandLabel.trim()) == listasNormalize(label);
    return _IslandRef(
      id: widget.islandId ?? (same ? f.islandId : null),
      key: widget.islandKey ?? (same ? f.islandKey : islandKeyFromName(label)),
      label: label,
    );
  }

  Future<void> _fetch() async {
    final island = _island;
    final seq = ++_seq;
    if (_status != _Status.loading) {
      setState(() => _status = _Status.loading);
    }
    try {
      final list =
          await _rankingLoader.load(islandId: island.id, islandKey: island.key);
      if (!mounted || seq != _seq) return;
      final split = topRatedSplit(list);
      setState(() {
        _cache[island.key] = split;
        _split = split;
        _status = _Status.ready;
      });
    } catch (e, st) {
      AppLogger.error('top-rated', e, st);
      if (!mounted || seq != _seq) return;
      setState(() => _status = _Status.error);
    }
  }

  void _show(_IslandRef island, {_IslandRef? previous}) {
    final cached = _cache[island.key];
    setState(() {
      _previous = previous;
      _island = island;
      _fewExpanded = false;
      if (cached != null) {
        _seq++;
        _split = cached;
        _status = _Status.ready;
      }
    });
    if (cached == null) _fetch();
  }

  void _pickIsland() {
    if (_maybeRead<IslandsCubit>(context) == null) {
      AppLogger.warn(
          'top-rated', 'sin IslandsCubit: no se puede cambiar de isla');
      return;
    }
    IslandPickerSheet.show(
      context: context,
      selectedIslandId: _island.id ?? '',
      onSelect: (Island island) {
        final key = (island.key != null && island.key!.isNotEmpty)
            ? island.key!.toUpperCase()
            : islandKeyFromName(island.name);
        if (key == _island.key) return;
        _show(
          _IslandRef(id: island.id, key: key, label: island.name),
          previous: _island,
        );
      },
    );
  }

  void _backToPrevious() {
    final p = _previous;
    if (p != null) _show(p);
  }

  void _seeIsland() {
    final filters = _maybeRead<NewHomeFiltersCubit>(context);
    final id = _island.id;
    if (filters != null && id != null && id.isNotEmpty) {
      filters.selectIsland(id: id, key: _island.key, label: _island.label);
    }
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  void _open(TopRestaurants t) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RestaurantDetailScreen(id: t.id),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final top = MediaQuery.paddingOf(context).top;
    final bottom = 120 + MediaQuery.paddingOf(context).bottom;

    final List<Widget> content;
    switch (_status) {
      case _Status.loading:
        content = const [_RankingSkeleton()];
      case _Status.error:
        content = [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: GmRise(
              trigger: GmTrigger.mount,
              child: GmStateCard(
                identifier: 'top-rated-error',
                liveRegion: true,
                art: const GmSadVolcano(),
                title: kTopRatedErrorTitle,
                text: kTopRatedErrorText,
                action: GmCapsuleButton(
                  label: 'Reintentar',
                  identifier: 'top-rated-retry',
                  onTap: _fetch,
                ),
              ),
            ),
          ),
        ];
      case _Status.ready:
        content = _split.isEmpty ? _empty() : _list();
    }

    return Scaffold(
      backgroundColor: gm.canvas,
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.depth == 0) {
                final s = n.metrics.pixels > 4;
                if (s != _scrolled) setState(() => _scrolled = s);
              }
              return false;
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: top + 58),
                    child: GmRise(
                      trigger: GmTrigger.mount,
                      child: _Header(
                        islandLabel: _island.label,
                        onPickIsland: _pickIsland,
                      ),
                    ),
                  ),
                ),
                SliverList(delegate: SliverChildListDelegate(content)),
                SliverToBoxAdapter(child: SizedBox(height: bottom)),
              ],
            ),
          ),
          GmTopScrim(visible: _scrolled, extra: 58),
          Positioned(
            top: top + 6,
            left: 16,
            child: GmToolbarButton(
              icon: GmIcons.chevronLeft,
              light: true,
              semanticLabel: 'Volver',
              identifier: 'top-rated-back-button',
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _list() {
    final gm = GmColors.of(context);
    final ranked = _split.ranked;
    final few = _split.few;
    final fewShown = _fewExpanded || few.length <= kTopRatedFewPreview
        ? few
        : few.take(kTopRatedFewPreview).toList();
    return [
      GmRise(
        index: 1,
        trigger: GmTrigger.mount,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          child: Text(kTopRatedSubtitle, style: GmText.body(color: gm.label2)),
        ),
      ),
      GmRise(
        index: 2,
        trigger: GmTrigger.mount,
        child: Semantics(
          identifier: 'top-rated-list',
          container: true,
          child: _RowsCard(
            separatorInset: 124,
            children: [
              for (var i = 0; i < ranked.length; i++)
                _RankRow(
                  restaurant: ranked[i],
                  rank: i + 1,
                  onTap: () => _open(ranked[i]),
                ),
            ],
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        child: Text(kTopRatedCaption, style: GmText.meta(color: gm.label2)),
      ),
      if (few.isNotEmpty) ...[
        const SizedBox(height: 36),
        GmRise(
          child: GmSectionHeader(
            eyebrow: const GmEyebrow(text: kTopRatedFewEyebrow),
            title: kTopRatedFewTitle,
          ),
        ),
        const SizedBox(height: 8),
        GmRise(
          index: 1,
          child: Semantics(
            identifier: 'top-rated-few-list',
            container: true,
            child: _RowsCard(
              separatorInset: 82,
              children: [
                for (final t in fewShown)
                  _RankRow(restaurant: t, onTap: () => _open(t)),
              ],
            ),
          ),
        ),
        if (fewShown.length < few.length) ...[
          const SizedBox(height: GmSpace.cardGap),
          _MoreRow(
            label: topRatedFewMoreLabel(few.length),
            onTap: () => setState(() => _fewExpanded = true),
          ),
        ],
      ],
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 36, 20, 0),
        child: Column(
          children: [
            const GmHappyVolcano(width: 84),
            const SizedBox(height: 10),
            Text(
              kTopRatedFooter,
              textAlign: TextAlign.center,
              style: GmText.body(color: gm.label2),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _empty() {
    final label = _island.label;
    final previous = _previous;
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: GmRise(
          trigger: GmTrigger.mount,
          child: GmStateCard(
            identifier: 'top-rated-empty',
            art: const GmHappyVolcano(),
            title: topRatedEmptyTitle(label),
            text: topRatedEmptyText(label),
            action: GmCapsuleButton(
              label: topRatedSeeIslandCta(label),
              identifier: 'top-rated-empty-see-island',
              onTap: _seeIsland,
            ),
          ),
        ),
      ),
      if (previous != null) ...[
        const SizedBox(height: 12),
        Center(
          child: GmSoftCapsuleButton(
            label: topRatedBackToRankingCta(previous.label),
            fontSize: 15,
            identifier: 'top-rated-empty-back',
            onTap: _backToPrevious,
          ),
        ),
      ],
    ];
  }
}

// ─────────────────────────────────────────────────────────────────────
// Cabecera
// ─────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String islandLabel;
  final VoidCallback onPickIsland;
  const _Header({required this.islandLabel, required this.onPickIsland});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: GmSpace.titleInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GmEyebrow(
            leading: GmGlyph(GmGlyphKind.medalla, size: 14),
            text: kTopRatedEyebrow,
          ),
          const SizedBox(height: 4),
          Semantics(
            header: true,
            child:
                Text(kTopRatedTitle, style: GmText.largeTitle(color: gm.label)),
          ),
          const SizedBox(height: 4),
          Semantics(
            identifier: 'top-rated-island-pill',
            button: true,
            label: 'Cambiar de isla, $islandLabel',
            excludeSemantics: true,
            child: GmPressable(
              onTap: onPickIsland,
              pressedScale: 0.95,
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                alignment: Alignment.centerLeft,
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
                      GmIcon(GmIcons.pin, size: 15, color: gm.accent),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          islandLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              GmText.sub(color: gm.label, w: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GmIcon(GmIcons.chevronDown, size: 12, color: gm.label2),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Filas
// ─────────────────────────────────────────────────────────────────────

class _RowsCard extends StatelessWidget {
  final double separatorInset;
  final List<Widget> children;
  const _RowsCard({required this.separatorInset, required this.children});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: GmSpace.gutter),
      child: GmCard(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0)
                Container(
                  height: 1,
                  margin: EdgeInsets.only(left: separatorInset),
                  color: gm.sep,
                ),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final TopRestaurants restaurant;

  /// Puesto (1…); `null` en «Aún con pocas reseñas» (sin número).
  final int? rank;
  final VoidCallback onTap;

  const _RankRow({required this.restaurant, this.rank, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final t = restaurant;
    final name = topRatedDisplayName(gmDisplayName(t.nombre));
    final place = gmPlaceName(t.municipio);
    final n = listasTopReviewCount(t);
    final r = rank;
    return Semantics(
      identifier: 'top-rated-row-${t.id}',
      button: true,
      label: topRatedRowSemantics(
        rank: r,
        name: name,
        place: place,
        avg: t.avg,
        reviews: n,
      ),
      excludeSemantics: true,
      child: GmPressable(
        onTap: onTap,
        pressedScale: 0.98,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 76),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 16, 10),
            child: Row(
              children: [
                if (r != null) ...[
                  r <= 3 ? _Medal(rank: r) : _RankNumber(rank: r),
                  const SizedBox(width: 12),
                ],
                _RowPhoto(url: t.imagen),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GmText.cardTitle(color: gm.label),
                      ),
                      if (place.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(
                            place,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GmText.sub(color: gm.label2),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GmRating(t.avg, fontSize: 15, starSize: 12),
                    const SizedBox(height: 1),
                    Text(
                      topRatedReviewsLabel(n),
                      style: GmText.chip(color: gm.label2, w: FontWeight.w400),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Medalla de 30 px (oro, plata, bronce; Sistema §5) con el puesto.
class _Medal extends StatelessWidget {
  final int rank;
  const _Medal({required this.rank});

  static const _fills = [
    [Color(0xFFF3DFA8), Color(0xFFD6B675), Color(0xFFB08A48)],
    [Color(0xFFF4F4F6), Color(0xFFC9CCD3), Color(0xFF9EA2AB)],
    [Color(0xFFF2C9A2), Color(0xFFCD8F5C), Color(0xFF9C6236)],
  ];
  static const _inks = [
    Color(0xFF3A2410),
    Color(0xFF2A2D33),
    Color(0xFF3A1C08)
  ];

  @override
  Widget build(BuildContext context) {
    final i = (rank - 1).clamp(0, 2);
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: const Alignment(-0.77, -0.64),
          end: const Alignment(0.77, 0.64),
          colors: _fills[i],
          stops: i == 0 ? const [0, 0.45, 1] : const [0, 0.5, 1],
        ),
        boxShadow: const [
          BoxShadow(
              color: Color(0x2E503714), offset: Offset(0, 2), blurRadius: 6),
        ],
      ),
      foregroundDecoration: const BoxDecoration(
        shape: BoxShape.circle,
        border: Border(top: BorderSide(color: Color(0x99FFFFFF), width: 1)),
      ),
      child: MediaQuery.withNoTextScaling(
        child: Text(
          '$rank',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: _inks[i],
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

/// «Nº» pequeño sobre el puesto (del 4 en adelante).
class _RankNumber extends StatelessWidget {
  final int rank;
  const _RankNumber({required this.rank});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return SizedBox(
      width: 30,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Nº', style: GmText.tab(color: gm.label2)),
          Text(
            '$rank',
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible,
            style: TextStyle(
              fontSize: 17,
              height: 22 / 17,
              fontWeight: FontWeight.w700,
              color: gm.label2,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Foto 56 · r14; sin foto, banda con el glifo de restaurante.
class _RowPhoto extends StatelessWidget {
  final String url;
  const _RowPhoto({required this.url});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(GmRadius.listIcon),
      child: SizedBox(
        width: 56,
        height: 56,
        child: url.trim().isEmpty
            ? ColoredBox(
                color: gm.band,
                child: Center(
                  child: ListThemeGlyph(ListGlyph.restaurante,
                      size: 28, color: gm.bandInk),
                ),
              )
            : GmPhoto(url, decodeWidth: 168),
      ),
    );
  }
}

class _MoreRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _MoreRow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: GmSpace.gutter),
      child: Semantics(
        identifier: 'top-rated-few-more',
        button: true,
        label: label,
        excludeSemantics: true,
        child: GmPressable(
          onTap: onTap,
          child: GmCard(
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child:
                        Text(label, style: GmText.cardTitle(color: gm.label)),
                  ),
                  GmIcon(GmIcons.chevronDown, size: 14, color: gm.label2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RankingSkeleton extends StatelessWidget {
  const _RankingSkeleton();

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    Widget block(double? w, double h, double r) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: gm.fill,
            borderRadius: BorderRadius.circular(r),
          ),
        );
    return Semantics(
      identifier: 'top-rated-loading',
      label: 'Cargando ranking',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  block(double.infinity, 15, 7),
                  const SizedBox(height: 6),
                  FractionallySizedBox(
                      widthFactor: 0.7, child: block(null, 15, 7)),
                ],
              ),
            ),
            _RowsCard(
              separatorInset: 0,
              children: [
                for (var i = 0; i < 8; i++)
                  SizedBox(
                    height: 76,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 16, 0),
                      child: Row(
                        children: [
                          block(30, 30, GmRadius.pill),
                          const SizedBox(width: 12),
                          block(56, 56, GmRadius.listIcon),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                block(110.0 + (i * 37) % 70, 14, 7),
                                const SizedBox(height: 7),
                                block(80.0 + (i * 23) % 60, 11, 6),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          block(40, 14, 7),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
