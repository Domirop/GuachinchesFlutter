import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/data/cubit/user/user_state.dart';
import 'package:guachinches/data/model/Review.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/data/model/user_info.dart';
import 'package:guachinches/ui/pages/favoritos/favoritos_logic.dart'
    show favoritosMeta;
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart'
    show GmPhoto, gmDisplayName;
import 'package:guachinches/ui/pages/restaurant_detail/restaurant_detail_screen.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/write_review_screen.dart';
import 'package:guachinches/ui/pages/settings/perfil_logic.dart';
import 'package:guachinches/ui/pages/settings/settings_screen.dart'
    show perfilGoToExplore;
import 'package:guachinches/ui/pages/settings/widgets/perfil_widgets.dart';
import 'package:guachinches/ui/pages/valoraciones/valoraciones_logic.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';
import 'package:http/http.dart' as http;

/// Mis reseñas (tablero PerfilMisResenas): las reseñas del usuario con su
/// nota, resumen arriba y, en cada tarjeta, ir a la ficha o editarla con el
/// editor de la ficha (precargado). Estados: listo, cargando, vacío, error.
class ValoracionesPage extends StatefulWidget {
  /// Inyectable para tests; por defecto, el de producción.
  final RemoteRepository? repository;

  const ValoracionesPage({super.key, this.repository});

  @override
  State<ValoracionesPage> createState() => _ValoracionesPageState();
}

enum _Status { loading, ready, error }

class _ValoracionesPageState extends State<ValoracionesPage> {
  late final RemoteRepository _repo =
      widget.repository ?? HttpRemoteRepository(http.Client());
  final _storage = const FlutterSecureStorage();

  _Status _status = _Status.loading;
  String? _userId;
  final Map<String, Restaurant> _restaurants = {};
  final Set<String> _requested = {};
  bool _scrolled = false;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<UserCubit>();
    if (cubit.state is UserLoaded) {
      _status = _Status.ready;
      _fetchRestaurants((cubit.state as UserLoaded).user.valoraciones);
    }
    _load();
  }

  void _retry() {
    setState(() => _status = _Status.loading);
    _load();
  }

  Future<void> _load() async {
    final cubit = context.read<UserCubit>();
    final hadData = cubit.state is UserLoaded;
    String? id;
    try {
      id = await _storage.read(key: 'userId');
    } catch (e) {
      AppLogger.warn('mis-resenas', 'no se pudo leer la sesión: $e');
    }
    if (!mounted) return;
    if (id == null || id.isEmpty) {
      setState(() => _status = hadData ? _Status.ready : _Status.error);
      return;
    }
    _userId = id;
    final ok = await cubit.getUserInfo(id);
    if (!mounted) return;
    final state = cubit.state;
    if (state is UserLoaded) {
      setState(() => _status = _Status.ready);
      _fetchRestaurants(state.user.valoraciones);
    } else if (!ok) {
      setState(() => _status = _Status.error);
    }
  }

  /// Fotos, tipo y municipio de cada sitio (el perfil solo trae el nombre).
  /// Si falla, la tarjeta se pinta igual sin foto.
  Future<void> _fetchRestaurants(List<Valoraciones> reviews) async {
    final ids = {
      for (final v in reviews)
        if (resenaRestaurantId(v).isNotEmpty) resenaRestaurantId(v)
    }.where((id) => _requested.add(id)).toList();
    if (ids.isEmpty) return;
    await Future.wait(ids.map((id) async {
      try {
        final r = await _repo.getRestaurantById(id);
        r.id = id;
        if (mounted) setState(() => _restaurants[id] = r);
      } catch (e) {
        _requested.remove(id);
        AppLogger.warn('mis-resenas', 'no se pudo cargar el sitio $id: $e');
      }
    }));
  }

  void _openFicha(String restaurantId) {
    if (restaurantId.isEmpty) return;
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => RestaurantDetailScreen(id: restaurantId),
    ));
  }

  Future<void> _edit(Valoraciones v) async {
    final id = resenaRestaurantId(v);
    final restaurant = _restaurants[id] ??
        Restaurant(id: id, nombre: v.restaurantes?.nombre ?? '');
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => WriteReviewScreen(
        restaurant: restaurant,
        initialRating: perfilStars(v.rating) ?? 0,
        existingReview: Review(
          id: v.id,
          title: v.title,
          review: v.review,
          rating: v.rating,
          valoracionesNegocioId: id,
          valoracionesUsuarioId: v.valoracionesUsuarioId,
        ),
      ),
    ));
    if (saved == true && mounted) {
      final userId = _userId;
      if (userId != null) await context.read<UserCubit>().getUserInfo(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final media = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: gm.canvas,
      body: Stack(
        children: [
          Positioned.fill(
            child: BlocBuilder<UserCubit, UserState>(
              builder: (context, state) {
                final reviews = state is UserLoaded
                    ? state.user.valoraciones
                    : const <Valoraciones>[];
                return _scroll(context, reviews);
              },
            ),
          ),
          GmTopScrim(visible: _scrolled, extra: 60),
          Positioned(
            left: GmSpace.gutter,
            top: media.padding.top + 4,
            child:
                const PerfilBackButton(identifier: 'mis-resenas-back-button'),
          ),
        ],
      ),
    );
  }

  Widget _scroll(BuildContext context, List<Valoraciones> reviews) {
    final gm = GmColors.of(context);
    final media = MediaQuery.of(context);
    final children = <Widget>[
      const GmRise(
        trigger: GmTrigger.mount,
        child: PerfilLargeTitle('Mis reseñas',
            subtitle: 'Las que has escrito con tu cuenta.'),
      ),
    ];
    switch (_status) {
      case _Status.loading:
        children.add(const _Skeleton());
      case _Status.error:
        children.addAll([
          const SizedBox(height: 24),
          PerfilStateCard(
            identifier: 'mis-resenas-error',
            art: const GmSadVolcano(width: 96),
            title: 'No pudimos cargar tus reseñas',
            text: 'Revisa tu conexión e inténtalo de nuevo.',
            action: GmCapsuleButton(
              label: 'Reintentar',
              identifier: 'mis-resenas-retry-button',
              onTap: _retry,
            ),
          ),
        ]);
      case _Status.ready:
        if (reviews.isEmpty) {
          children.addAll([
            const SizedBox(height: 24),
            PerfilStateCard(
              identifier: 'mis-resenas-empty',
              art: const PerfilHappyVolcano(),
              title: 'Aún no has escrito ninguna reseña',
              text: 'Cuando reseñes un sitio desde su ficha, la verás aquí y '
                  'podrás editarla.',
              action: GmCapsuleButton(
                label: 'Explorar sitios',
                identifier: 'mis-resenas-explore-button',
                onTap: () => perfilGoToExplore(context),
              ),
            ),
          ]);
        } else {
          children.addAll([
            const SizedBox(height: 16),
            GmRise(
              index: 1,
              trigger: GmTrigger.mount,
              child: _StatsCard(reviews: reviews),
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < reviews.length; i++)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    GmSpace.gutter, 0, GmSpace.gutter, GmSpace.cardGap),
                child: GmRise(
                  index: 2 + i.clamp(0, 4),
                  trigger: GmTrigger.mount,
                  child: _ReviewCard(
                    review: reviews[i],
                    restaurant: _restaurants[resenaRestaurantId(reviews[i])],
                    onOpen: () => _openFicha(resenaRestaurantId(reviews[i])),
                    onEdit: () => _edit(reviews[i]),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 0),
              child: Text(
                'Tu nombre de pila se muestra junto a cada reseña en la ficha '
                'del sitio.',
                style: GmText.meta(color: gm.label2),
              ),
            ),
          ]);
        }
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.depth == 0 && n.metrics.axis == Axis.vertical) {
          final s = n.metrics.pixels > 4;
          if (s != _scrolled) setState(() => _scrolled = s);
        }
        return false;
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          top: media.padding.top + 58,
          bottom: media.padding.bottom + 40,
        ),
        children: children,
      ),
    );
  }
}

// ── Resumen ─────────────────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  final List<Valoraciones> reviews;
  const _StatsCard({required this.reviews});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final n = reviews.length;
    final avg = perfilAverage(reviews.map((v) => v.rating));
    const big = TextStyle(
        fontSize: 22,
        height: 28 / 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4);
    return Semantics(
      identifier: 'mis-resenas-stats',
      container: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: GmSpace.gutter),
        child: GmCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$n', style: big.copyWith(color: gm.label)),
                      Text(resenasCountCaption(n),
                          style: GmText.meta(color: gm.label2)),
                    ],
                  ),
                ),
                if (avg != null) ...[
                  Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: gm.sep,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GmIcon(GmIcons.star,
                                size: 20, color: GmColors.star),
                            const SizedBox(width: 5),
                            Text(perfilFormatAvg(avg),
                                style: big.copyWith(color: gm.label)),
                          ],
                        ),
                        Text('nota media que das',
                            style: GmText.meta(color: gm.label2)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Tarjeta de reseña ───────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final Valoraciones review;
  final Restaurant? restaurant;
  final VoidCallback onOpen;
  final VoidCallback onEdit;

  const _ReviewCard({
    required this.review,
    required this.restaurant,
    required this.onOpen,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final v = review;
    final r = restaurant;
    final name = gmDisplayName((r?.nombre.isNotEmpty ?? false)
        ? r!.nombre
        : v.restaurantes?.nombre ?? '');
    final meta = r == null ? '' : favoritosMeta(r);
    final stars = perfilStars(v.rating);
    final word = resenaWord(stars);

    return Semantics(
      identifier: 'mis-resenas-card-${v.id}',
      container: true,
      child: GmCard(
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GmPressable(
              onTap: onOpen,
              pressedScale: 0.98,
              semanticsIdentifier: 'mis-resenas-open-${v.id}',
              semanticsLabel: '$name, ver ficha',
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 64),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          width: 52,
                          height: 52,
                          child: GmPhoto(r?.mainFoto, decodeWidth: 156),
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
                              Text(meta,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GmText.meta(color: gm.label2)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GmIcon(GmIcons.chevronRight, size: 14, color: gm.label2),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (stars != null)
                    Semantics(
                      label: '$stars de 5 estrellas',
                      excludeSemantics: true,
                      child: Row(
                        children: [
                          for (var i = 0; i < 5; i++)
                            Padding(
                              padding: const EdgeInsets.only(right: 2),
                              child: GmIcon(
                                i < stars ? GmIcons.star : GmIcons.starOutline,
                                size: 16,
                                color: i < stars ? GmColors.star : gm.label2,
                              ),
                            ),
                          const SizedBox(width: 4),
                          Text(word, style: GmText.eyebrow(color: gm.label2)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 6),
                  if (v.title.trim().isNotEmpty)
                    Text(
                      v.title.trim(),
                      style: GmText.body17(color: gm.label, w: FontWeight.w600)
                          .copyWith(height: 22 / 17),
                    ),
                  if (v.review.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        v.review.trim(),
                        style: GmText.body(color: gm.label)
                            .copyWith(height: 21 / 15),
                      ),
                    ),
                  if (resenaOnlyStars(v))
                    Text(
                      'Solo pusiste estrellas. Puedes añadir unas líneas '
                      'cuando quieras.',
                      style: GmText.body(color: gm.label2)
                          .copyWith(height: 21 / 15),
                    ),
                  const SizedBox(height: 12),
                  PerfilSoftButton(
                    label: resenaActionLabel(v),
                    identifier: 'mis-resenas-edit-${v.id}',
                    height: 36,
                    fontSize: 14,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    leading:
                        GmIcon(PerfilIcons.pencil, size: 15, color: gm.accent),
                    onTap: onEdit,
                  ),
                ],
              ),
            ),
          ],
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
    Widget card() => Padding(
          padding: const EdgeInsets.fromLTRB(
              GmSpace.gutter, 0, GmSpace.gutter, GmSpace.cardGap),
          child: GmCard(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
            child: LayoutBuilder(
              builder: (_, c) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const PerfilSkeleton(width: 52, height: 52, radius: 16),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PerfilSkeleton(width: c.maxWidth * 0.45, height: 16),
                          const SizedBox(height: 8),
                          PerfilSkeleton(width: c.maxWidth * 0.55, height: 12),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PerfilSkeleton(width: c.maxWidth * 0.36, height: 14),
                        const SizedBox(height: 9),
                        PerfilSkeleton(width: c.maxWidth * 0.6, height: 16),
                        const SizedBox(height: 9),
                        PerfilSkeleton(width: c.maxWidth * 0.88, height: 13),
                        const SizedBox(height: 9),
                        PerfilSkeleton(width: c.maxWidth * 0.74, height: 13),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
    return Semantics(
      identifier: 'mis-resenas-loading',
      label: 'Cargando tus reseñas',
      child: ExcludeSemantics(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  GmSpace.gutter, 0, GmSpace.gutter, 14),
              child: GmCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (_, c) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PerfilSkeleton(width: c.maxWidth * 0.3, height: 22),
                            const SizedBox(height: 8),
                            PerfilSkeleton(width: c.maxWidth * 0.7, height: 12),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (_, c) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PerfilSkeleton(width: c.maxWidth * 0.4, height: 22),
                            const SizedBox(height: 8),
                            PerfilSkeleton(width: c.maxWidth * 0.8, height: 12),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            card(),
            card(),
            card(),
          ],
        ),
      ),
    );
  }
}
