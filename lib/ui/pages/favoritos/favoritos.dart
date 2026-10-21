import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/local/local_repository.dart';
import 'package:guachinches/data/local/sql_lite_local_repository.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/advance_search/list_logic.dart'
    show listDisplayRating, listReviewCount;
import 'package:guachinches/ui/pages/advance_search/widgets/list_cards.dart'
    show ListRating;
import 'package:guachinches/ui/pages/favoritos/favoritos_logic.dart';
import 'package:guachinches/ui/pages/favoritos/widgets/favoritos_map_view.dart';
import 'package:guachinches/ui/pages/favoritos/widgets/favoritos_widgets.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart'
    show GmPhoto, gmDisplayName;
import 'package:guachinches/ui/pages/restaurant_detail/restaurant_detail_screen.dart';
import 'package:guachinches/ui/pages/settings/settings_screen.dart'
    show perfilGoToExplore;
import 'package:guachinches/ui/pages/settings/widgets/perfil_widgets.dart';
import 'package:guachinches/ui/theme/gm_favorites.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';
import 'package:guachinches/utils/open_state.dart';
import 'package:http/http.dart' as http;

/// Guardados (tablero Guardados): los sitios con corazón de ESTE móvil
/// (tabla local `fav`, sin cuenta), el último guardado primero. Quitar con
/// el corazón o deslizando, con «Deshacer» que lo devuelve a su sitio.
/// Lista o mapa.
class FavoritosPage extends StatefulWidget {
  /// Inyectables para tests; por defecto, los de producción.
  final LocalRepository? localRepository;
  final GmFavorites? favorites;
  final RemoteRepository? repository;

  const FavoritosPage({
    super.key,
    this.localRepository,
    this.favorites,
    this.repository,
  });

  @override
  State<FavoritosPage> createState() => _FavoritosPageState();
}

enum _Status { loading, ready, error }

enum _View { list, map }

class _FavoritosPageState extends State<FavoritosPage> {
  late final LocalRepository _local =
      widget.localRepository ?? SqlLiteLocalRepository();
  late final GmFavorites _favs = widget.favorites ?? GmFavorites.instance;
  late final RemoteRepository _repo =
      widget.repository ?? HttpRemoteRepository(http.Client());

  _Status _status = _Status.loading;
  _View _view = _View.list;
  List<String> _ordered = const [];
  final Map<String, Restaurant> _byId = {};
  bool _scrolled = false;
  bool _loadingNow = false;

  /// Quitado con «Deshacer» disponible: aún está en la BD; se borra de
  /// verdad al caducar el aviso, al quitar otro o al salir. Así «Deshacer»
  /// lo devuelve a su posición también en la próxima visita.
  String? _pending;
  Timer? _pendingTimer;

  @override
  void initState() {
    super.initState();
    _favs.addListener(_onFavoritesChanged);
    _load();
  }

  @override
  void dispose() {
    _favs.removeListener(_onFavoritesChanged);
    _commitPending(notify: false);
    super.dispose();
  }

  Future<void> _load({bool quiet = false}) async {
    if (_loadingNow) return;
    _loadingNow = true;
    if (!quiet && mounted) setState(() => _status = _Status.loading);
    try {
      await _favs.ensureLoaded(force: true);
      final ordered = favoritosOrderedIds(await _local.getRestaurants());
      final missing = [
        for (final id in ordered)
          if (!_byId.containsKey(id)) id
      ];
      final fetched = await Future.wait(missing.map(_fetch));
      for (final r in fetched) {
        if (r != null) _byId[r.id] = r;
      }
      if (!mounted) return;
      final anyLoaded = ordered.any(_byId.containsKey);
      setState(() {
        _ordered = ordered;
        _status =
            ordered.isNotEmpty && !anyLoaded ? _Status.error : _Status.ready;
      });
    } catch (e) {
      AppLogger.warn('favoritos', 'no se pudieron cargar los guardados: $e');
      if (mounted) setState(() => _status = _Status.error);
    } finally {
      _loadingNow = false;
    }
  }

  Future<Restaurant?> _fetch(String id) async {
    try {
      final r = await _repo.getRestaurantById(id);
      r.id = id;
      return r;
    } catch (e) {
      AppLogger.warn('favoritos', 'no se pudo cargar $id: $e');
      return null;
    }
  }

  /// Corazones tocados en otra pantalla (ficha, listas) mientras esto vive.
  void _onFavoritesChanged() {
    if (!mounted) return;
    final unknown = _favs.value.any((id) => !_ordered.contains(id));
    if (unknown && _status == _Status.ready) {
      _load(quiet: true);
    } else {
      setState(() {});
    }
  }

  List<Restaurant> get _visible => [
        for (final id in favoritosVisible(
          ordered: _ordered,
          saved: _favs.value,
          loaded: _byId.keys.toSet(),
          pendingRemoval: _pending,
        ))
          _byId[id]!
      ];

  // ── Quitar / deshacer ──────────────────────────────────────────────────

  void _remove(Restaurant r) {
    HapticFeedback.lightImpact();
    if (_pending != null && _pending != r.id) _commitPending();
    _pendingTimer?.cancel();
    setState(() => _pending = r.id);
    _pendingTimer = Timer(const Duration(seconds: 4), _commitPending);
  }

  void _undo() {
    _pendingTimer?.cancel();
    HapticFeedback.selectionClick();
    setState(() => _pending = null);
  }

  void _commitPending({bool notify = true}) {
    _pendingTimer?.cancel();
    final id = _pending;
    if (id == null) return;
    _pending = null;
    _ordered = [
      for (final x in _ordered)
        if (x != id) x
    ];
    if (_favs.isSaved(id)) _favs.toggle(id);
    if (notify && mounted) setState(() {});
  }

  // ── Navegación ─────────────────────────────────────────────────────────

  Future<void> _open(Restaurant r) async {
    _commitPending();
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => RestaurantDetailScreen(id: r.id),
    ));
    if (mounted) _load(quiet: true);
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final media = MediaQuery.of(context);
    final visible = _visible;
    final ready = _status == _Status.ready;
    final empty = ready && visible.isEmpty;
    final showSegmented = _status != _Status.error && !empty;
    final map = _view == _View.map && ready && visible.isNotEmpty;
    final pendingName =
        _pending == null ? null : gmDisplayName(_byId[_pending]?.nombre ?? '');

    return Scaffold(
      backgroundColor: gm.canvas,
      body: Stack(
        children: [
          Positioned.fill(
            child: map
                ? FavoritosMapView(
                    items: visible,
                    topInset: media.padding.top + 56,
                    onOpen: _open,
                    onRemove: _remove,
                  )
                : _list(context, visible),
          ),
          if (!map) GmTopScrim(visible: _scrolled, extra: 60),
          Positioned(
            left: GmSpace.gutter,
            right: GmSpace.gutter,
            top: media.padding.top + 4,
            child: Row(
              children: [
                const PerfilBackButton(identifier: 'favoritos-back-button'),
                const Spacer(),
                if (showSegmented)
                  _ViewSegmented(
                    view: _view,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _view = v);
                    },
                  ),
              ],
            ),
          ),
          Positioned(
            left: GmSpace.gutter,
            right: GmSpace.gutter,
            bottom: media.padding.bottom + 16,
            child: PerfilToastSlot(
              toast: pendingName == null
                  ? null
                  : PerfilToast(
                      identifier: 'favoritos-undo-toast',
                      message: favoritosRemovedText(pendingName),
                      actionLabel: 'Deshacer',
                      onAction: _undo,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(BuildContext context, List<Restaurant> visible) {
    final gm = GmColors.of(context);
    final media = MediaQuery.of(context);
    final ready = _status == _Status.ready;
    final empty = ready && visible.isEmpty;
    final now = DateTime.now();

    final Widget body;
    if (_status == _Status.loading) {
      body = const _Skeleton();
    } else if (_status == _Status.error) {
      body = PerfilStateCard(
        identifier: 'favoritos-error',
        art: const GmSadVolcano(width: 96),
        title: 'No pudimos cargar tus guardados',
        text: 'Siguen guardados en este móvil. Revisa tu conexión e '
            'inténtalo de nuevo.',
        action: GmCapsuleButton(
          label: 'Reintentar',
          identifier: 'favoritos-retry-button',
          onTap: _load,
        ),
      );
    } else if (empty) {
      body = PerfilStateCard(
        identifier: 'favoritos-empty',
        art: ExcludeSemantics(
          child: Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
                color: PerfilColors.heartSoft, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: GmIcon(GmIcons.heart, size: 30, color: GmColors.heart),
          ),
        ),
        title: 'Aún no has guardado nada',
        text: 'Toca el corazón en cualquier sitio y lo tendrás aquí. '
            'No hace falta cuenta.',
        action: GmCapsuleButton(
          label: 'Explorar sitios',
          identifier: 'favoritos-explore-button',
          onTap: () => perfilGoToExplore(context),
        ),
      );
    } else {
      body = GmRise(
        index: 2,
        trigger: GmTrigger.mount,
        child: Semantics(
          identifier: 'favoritos-list',
          container: true,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: GmSpace.gutter),
            padding: const EdgeInsets.symmetric(vertical: 2),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: gm.card,
              borderRadius: BorderRadius.circular(GmRadius.card),
              boxShadow: gm.shadow1,
            ),
            child: Column(
              children: [
                for (var i = 0; i < visible.length; i++) ...[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 94),
                      child: Container(height: 1, color: gm.sep),
                    ),
                  _SavedRow(
                    key: ValueKey(visible[i].id),
                    restaurant: visible[i],
                    now: now,
                    onTap: () => _open(visible[i]),
                    onRemove: () => _remove(visible[i]),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    final count = ready ? visible.length : null;
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.depth == 0 && n.metrics.axis == Axis.vertical) {
          final s = n.metrics.pixels > 4;
          if (s != _scrolled) setState(() => _scrolled = s);
        }
        return false;
      },
      child: RefreshIndicator(
        color: gm.accent,
        backgroundColor: gm.card,
        edgeOffset: media.padding.top + 52,
        onRefresh: () => _load(quiet: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            top: media.padding.top + 58,
            bottom: media.padding.bottom + 96,
          ),
          children: [
            GmRise(
              trigger: GmTrigger.mount,
              child: PerfilLargeTitle(
                'Guardados',
                eyebrow: GmEyebrow(
                  leading: GmIcon(GmIcons.heartFilled,
                      size: 12, color: GmColors.heart),
                  text: 'En este móvil',
                ),
                subtitle: (_status == _Status.error || empty)
                    ? null
                    : favoritosSubtitle(count),
              ),
            ),
            SizedBox(height: _status == _Status.ready && !empty ? 14 : 24),
            body,
          ],
        ),
      ),
    );
  }
}

// ── Fila ────────────────────────────────────────────────────────────────────

class _SavedRow extends StatelessWidget {
  final Restaurant restaurant;
  final DateTime now;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _SavedRow({
    super.key,
    required this.restaurant,
    required this.now,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final r = restaurant;
    final name = gmDisplayName(r.nombre);
    final meta = favoritosMeta(r);
    final row = Semantics(
      identifier: 'favoritos-row-${r.id}',
      container: true,
      child: Container(
        color: gm.card,
        constraints: const BoxConstraints(minHeight: 92),
        padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
        child: Row(
          children: [
            Expanded(
              child: GmPressable(
                onTap: onTap,
                pressedScale: 0.98,
                semanticsLabel: '$name, ver ficha',
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        width: 72,
                        height: 72,
                        child: GmPhoto(r.mainFoto, decodeWidth: 216),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GmText.body17(
                                    color: gm.label, w: FontWeight.w600)
                                .copyWith(height: 22 / 17),
                          ),
                          if (meta.isNotEmpty)
                            Text(
                              meta,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GmText.meta(color: gm.label2),
                            ),
                          const SizedBox(height: 1),
                          Row(
                            children: [
                              Flexible(
                                  child:
                                      FavOpenLine(restaurantOpenState(r, now))),
                              if (listReviewCount(r) > 0) ...[
                                const SizedBox(width: 8),
                                ListRating(
                                    listDisplayRating(r), listReviewCount(r)),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            FavRemoveHeart(restaurantId: r.id, name: name, onRemove: onRemove),
          ],
        ),
      ),
    );
    return Dismissible(
      key: ValueKey('dismiss-${r.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        color: GmColors.badgeRed,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GmIcon(PerfilIcons.trash, size: 20, color: Colors.white),
            const SizedBox(height: 3),
            const Text(
              'Quitar',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
          ],
        ),
      ),
      child: row,
    );
  }
}

// ── Lista / Mapa ────────────────────────────────────────────────────────────

class _ViewSegmented extends StatelessWidget {
  final _View view;
  final ValueChanged<_View> onChanged;
  const _ViewSegmented({required this.view, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final reduced = GmMotion.reduced(context);
    Widget seg(_View v, String icon, String label) {
      final on = view == v;
      return Semantics(
        identifier: 'favoritos-view-${v.name}',
        button: true,
        selected: on,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(v),
          child: AnimatedContainer(
            duration: Duration(milliseconds: reduced ? 0 : 200),
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
                GmIcon(icon, size: 16, color: on ? gm.label : gm.label2),
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

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: GmGlass(
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
      ),
    );
  }
}

// ── Cargando ────────────────────────────────────────────────────────────────

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    Widget row() => ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 92),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
            child: Row(
              children: [
                const PerfilSkeleton(width: 72, height: 72, radius: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: LayoutBuilder(
                    builder: (_, c) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PerfilSkeleton(width: c.maxWidth * 0.62, height: 16),
                        const SizedBox(height: 8),
                        PerfilSkeleton(width: c.maxWidth * 0.48, height: 12),
                        const SizedBox(height: 8),
                        PerfilSkeleton(width: c.maxWidth * 0.56, height: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
    return Semantics(
      identifier: 'favoritos-loading',
      label: 'Cargando tus guardados',
      child: ExcludeSemantics(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: GmSpace.gutter),
          decoration: BoxDecoration(
            color: gm.card,
            borderRadius: BorderRadius.circular(GmRadius.card),
            boxShadow: gm.shadow1,
          ),
          child: Column(
            children: [
              for (var i = 0; i < 5; i++) ...[
                if (i > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 94),
                    child: Container(height: 1, color: gm.sep),
                  ),
                row(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
