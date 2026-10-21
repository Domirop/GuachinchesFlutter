import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/cubit/curated_list_detail/curated_list_detail_cubit.dart';
import 'package:guachinches/data/cubit/new_home/islands_cubit.dart';
import 'package:guachinches/data/cubit/new_home/visits_cubit.dart';
import 'package:guachinches/data/http_client.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/data/model/curated_list.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/components/vignettes/list_vignette.dart';
import 'package:guachinches/ui/pages/advance_search/list_theme.dart';
import 'package:guachinches/ui/pages/curated_list_detail/curated_list_logic.dart';
import 'package:guachinches/ui/pages/curated_list_detail/widgets/curated_list_header.dart';
import 'package:guachinches/ui/pages/curated_list_detail/widgets/curated_place_card.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart'
    show gmDisplayName;
import 'package:guachinches/ui/pages/restaurant_detail/restaurant_detail_screen.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams;

/// Lista curada de Jonay y Joana (tableros «Lista curada, bocadillos de
/// cochino», «japoneses» y «ocasiones especiales»): cabecera con la banda
/// del tema y su viñeta animada, hoja con buscador, zonas y orden, y rejilla
/// de 2 columnas con la portada del vídeo de cada sitio.
class CuratedListDetailScreen extends StatelessWidget {
  final CuratedList list;

  const CuratedListDetailScreen({super.key, required this.list});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CuratedListDetailCubit(
        HttpRemoteRepository(sharedHttpClient),
      )..load(list.id),
      child: _CuratedListDetailView(list: list),
    );
  }
}

class _CuratedListDetailView extends StatefulWidget {
  final CuratedList list;
  const _CuratedListDetailView({required this.list});

  @override
  State<_CuratedListDetailView> createState() => _CuratedListDetailViewState();
}

class _CuratedListDetailViewState extends State<_CuratedListDetailView> {
  final _search = TextEditingController();
  String _query = '';
  String? _zone;
  CuratedSort _sort = CuratedSort.byRank;

  /// La viñeta de la cabecera solo corre mientras se ve.
  final ValueNotifier<bool> _sceneVisible = ValueNotifier(true);

  @override
  void dispose() {
    _search.dispose();
    _sceneVisible.dispose();
    super.dispose();
  }

  String? _islandName(String? islandId) {
    if (islandId == null) return null;
    final s = context.watch<IslandsCubit>().state;
    if (s is! IslandsLoaded) return null;
    for (final i in s.islands) {
      if (i.id == islandId) return i.name;
    }
    return null;
  }

  void _clearFilters() {
    _search.clear();
    setState(() {
      _query = '';
      _zone = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final state = context.watch<CuratedListDetailCubit>().state;
    final visitsState = context.watch<VisitsCubit>().state;
    final visits =
        visitsState is VisitsLoaded ? visitsState.visits : const <Visit>[];

    final CuratedList info =
        state is CuratedListDetailLoaded ? state.detail : widget.list;
    final vignette = listVignetteFor('${info.id} ${info.title}');
    final theme = kListThemes[curatedThemeKind(vignette)]!;
    final count = state is CuratedListDetailLoaded
        ? state.detail.items.length
        : info.count;

    final slivers = <Widget>[
      SliverToBoxAdapter(
        child: CuratedListHeader(
          theme: theme,
          vignette: vignette,
          eyebrow: curatedHeaderEyebrow(
              info.eyebrow, count, _islandName(info.islandId)),
          title: gmDisplayName(info.title),
          subtitle: info.subtitle.trim(),
          sceneVisible: _sceneVisible,
          onBack: () => Navigator.of(context).maybePop(),
          onShare: () => SharePlus.instance.share(
            ShareParams(text: '${info.title} en ¿Dónde Comer Canarias?'),
          ),
        ),
      ),
      ..._body(context, state, visits),
      SliverToBoxAdapter(
        child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 32),
      ),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: gm.isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark
              .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: gm.canvas,
        body: Semantics(
          identifier: 'curated-list-content',
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.depth == 0) _sceneVisible.value = n.metrics.pixels < 260;
              return false;
            },
            child: CustomScrollView(slivers: slivers),
          ),
        ),
      ),
    );
  }

  List<Widget> _body(
      BuildContext context, CuratedListDetailState state, List<Visit> visits) {
    if (state is CuratedListDetailFailure) {
      return [
        SliverToBoxAdapter(
          child: _StateCard(
            identifier: 'curated-list-error',
            title: 'No pudimos cargar la lista',
            text: 'Revisa tu conexión e inténtalo de nuevo.',
            action: 'Reintentar',
            onAction: () =>
                context.read<CuratedListDetailCubit>().load(widget.list.id),
          ),
        ),
      ];
    }
    if (state is! CuratedListDetailLoaded) {
      return [
        const SliverToBoxAdapter(child: SizedBox(height: 74)),
        const SliverToBoxAdapter(child: _SectionSkeleton()),
        _grid(List.generate(4, (_) => const CuratedPlaceSkeleton())),
      ];
    }

    final places = curatedPlaces(state.detail.items, visits);
    final zones = curatedZones(places);
    final shown =
        filterCuratedPlaces(places, query: _query, zone: _zone, sort: _sort);
    final filtering = _query.trim().isNotEmpty || _zone != null;

    return [
      SliverToBoxAdapter(
        child: GmRise(
          index: 1,
          child: _SearchField(
            controller: _search,
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
      ),
      if (zones.isNotEmpty)
        SliverToBoxAdapter(
          child: GmRise(
            index: 1,
            child: _ZoneChips(
              zones: zones,
              selected: _zone,
              onSelected: (z) => setState(() => _zone = z),
            ),
          ),
        ),
      SliverToBoxAdapter(
        child: GmRise(
          index: 2,
          child: _SectionHead(
            eyebrow: filtering
                ? '${shown.length} de ${places.length}'
                : '${places.length} en total',
            sort: _sort,
            onSort: () => setState(() => _sort = _sort == CuratedSort.byRank
                ? CuratedSort.alphabetical
                : CuratedSort.byRank),
          ),
        ),
      ),
      if (shown.isEmpty)
        SliverToBoxAdapter(
          child: _StateCard(
            identifier: 'curated-list-empty',
            title: _query.trim().isNotEmpty
                ? 'Ningún sitio con «${_query.trim()}»'
                : 'Ningún sitio en esa zona',
            text: 'Quita el filtro y vuelven todos.',
            action: 'Ver todos',
            onAction: _clearFilters,
          ),
        )
      else
        _grid([
          for (final (i, p) in shown.indexed)
            GmRise(
              index: 2 + (i ~/ 2).clamp(0, 4),
              child: CuratedPlaceCard(
                place: p,
                onTap: () => GlobalMethods().pushPage(
                    context, RestaurantDetailScreen(id: p.restaurantId)),
              ),
            ),
        ]),
    ];
  }

  /// Rejilla de 2 columnas (filas con alto natural: el texto puede crecer).
  Widget _grid(List<Widget> cards) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      sliver: SliverList.separated(
        itemCount: (cards.length + 1) ~/ 2,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, row) {
          final a = cards[row * 2];
          final b = row * 2 + 1 < cards.length ? cards[row * 2 + 1] : null;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: a),
              const SizedBox(width: 12),
              Expanded(child: b ?? const SizedBox.shrink()),
            ],
          );
        },
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        height: 48,
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
                identifier: 'curated-list-search-field',
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  textInputAction: TextInputAction.search,
                  style: GmText.body17(color: gm.label),
                  cursorColor: gm.accent,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'Nombre, zona, plato…',
                    hintStyle: GmText.body17(color: gm.label2),
                  ),
                ),
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (_, v, __) => v.text.isEmpty
                  ? const SizedBox(width: 16)
                  : GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        controller.clear();
                        onChanged('');
                      },
                      child: Semantics(
                        button: true,
                        label: 'Borrar búsqueda',
                        child: SizedBox(
                          width: 44,
                          height: 48,
                          child: Center(
                            child: GmIcon(GmIcons.xSmall,
                                size: 16, color: gm.label2),
                          ),
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

class _ZoneChips extends StatelessWidget {
  final List<String> zones;
  final String? selected;
  final ValueChanged<String?> onSelected;
  const _ZoneChips(
      {required this.zones, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    Widget chip(String label, String? value) {
      final on = selected == value;
      return Semantics(
        button: true,
        selected: on,
        identifier: 'curated-list-zone-${value ?? 'todas'}',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onSelected(on && value != null ? null : value),
          child: Padding(
            // 34 visibles, 44 de toque.
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? gm.accentSoft : gm.fill,
                borderRadius: BorderRadius.circular(GmRadius.pill),
              ),
              child: Text(label,
                  style: GmText.sub(
                      color: on ? gm.accent : gm.label, w: FontWeight.w600)),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 54,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        itemCount: zones.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => i == 0
            ? chip('Todas las zonas', null)
            : chip(zones[i - 1], zones[i - 1]),
      ),
    );
  }
}

class _SectionHead extends StatelessWidget {
  final String eyebrow;
  final CuratedSort sort;
  final VoidCallback onSort;
  const _SectionHead(
      {required this.eyebrow, required this.sort, required this.onSort});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final label =
        sort == CuratedSort.byRank ? 'Orden de la guía' : 'De la A a la Z';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GmEyebrow(text: eyebrow),
                const SizedBox(height: 2),
                Text('Los sitios', style: GmText.title2(color: gm.label)),
              ],
            ),
          ),
          GmPressable(
            semanticsIdentifier: 'curated-list-sort',
            semanticsLabel: 'Ordenar: $label',
            onTap: onSort,
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
                    Text(label,
                        style: GmText.sub(color: gm.label, w: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionSkeleton extends StatelessWidget {
  const _SectionSkeleton();

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: gm.fill,
            borderRadius: BorderRadius.circular(6),
          ),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Semantics(
        identifier: 'curated-list-loading',
        label: 'Cargando la lista',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [bar(90, 12), const SizedBox(height: 10), bar(140, 22)],
        ),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  final String identifier;
  final String title;
  final String text;
  final String action;
  final VoidCallback onAction;
  const _StateCard({
    required this.identifier,
    required this.title,
    required this.text,
    required this.action,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Semantics(
        identifier: identifier,
        child: GmCard(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          child: Column(
            children: [
              Text(title,
                  textAlign: TextAlign.center,
                  style: GmText.title2(color: gm.label)
                      .copyWith(fontSize: 20, height: 25 / 20)),
              const SizedBox(height: 6),
              Text(text,
                  textAlign: TextAlign.center,
                  style: GmText.body(color: gm.label2)),
              const SizedBox(height: 14),
              GmCapsuleButton(label: action, onTap: onAction),
            ],
          ),
        ),
      ),
    );
  }
}
