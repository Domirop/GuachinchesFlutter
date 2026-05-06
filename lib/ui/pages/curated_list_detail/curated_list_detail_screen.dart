import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/cubit/curated_list_detail/curated_list_detail_cubit.dart';
import 'package:guachinches/data/model/curated_list.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/pages/curated_list_detail/widgets/curated_list_item_card.dart';
import 'package:guachinches/ui/pages/restaurant_detail/restaurant_detail_screen.dart';
import 'package:http/http.dart' as http;

enum _SortMode { byPosition, alphabetical }

class CuratedListDetailScreen extends StatelessWidget {
  final CuratedList list;

  const CuratedListDetailScreen({super.key, required this.list});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CuratedListDetailCubit(
        HttpRemoteRepository(http.Client()),
      )..load(list.id),
      child: _LightTheme(child: _CuratedListDetailView(list: list)),
    );
  }
}

/// Forces light tokens for this screen regardless of global theme.
class _LightTheme extends StatelessWidget {
  final Widget child;
  const _LightTheme({required this.child});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(
        extensions: <ThemeExtension<dynamic>>[BrandColors.light],
      ),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: AppColors.crema,
        ),
        child: Builder(builder: (context) {
          // Re-sync default text color so AppTextStyles use ink, not crema.
          AppTextStyles.defaultTextColor = AppColors.ink;
          return child;
        }),
      ),
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
  String _query = '';
  String? _municipio; // null = todos
  _SortMode _sort = _SortMode.byPosition;

  @override
  Widget build(BuildContext context) {
    final list = widget.list;
    return Scaffold(
      backgroundColor: AppColors.crema,
      body: BlocBuilder<CuratedListDetailCubit, CuratedListDetailState>(
        builder: (context, state) {
          if (state is CuratedListDetailLoaded) {
            return _buildLoaded(context, state.detail);
          }
          if (state is CuratedListDetailFailure) {
            return _ErrorView(
              message: state.message,
              onRetry: () =>
                  context.read<CuratedListDetailCubit>().load(list.id),
            );
          }
          return _LoadingView(list: list);
        },
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, CuratedListDetail detail) {
    final municipalities = _municipalitiesFrom(detail);
    final filtered = _applyFilters(detail);

    return CustomScrollView(
      slivers: [
        _Hero(detail: detail),
        SliverToBoxAdapter(
          child: _ToolBar(
            query: _query,
            onQuery: (v) => setState(() => _query = v),
            municipalities: municipalities,
            municipio: _municipio,
            onMunicipio: (v) => setState(() => _municipio = v),
            sort: _sort,
            onSort: (v) => setState(() => _sort = v),
            visible: filtered.length,
            total: detail.items.length,
            accent: detail.accent,
          ),
        ),
        if (filtered.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyView(),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 32),
            sliver: SliverList.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (_, i) {
                final item = filtered[i];
                return CuratedListItemCard(
                  item: item,
                  accent: detail.accent,
                  fallbackEyebrow: detail.eyebrow,
                  onTap: () => _openRestaurant(item.restaurantId),
                );
              },
            ),
          ),
      ],
    );
  }

  void _openRestaurant(String id) {
    GlobalMethods().pushPage(context, RestaurantDetailScreen(id: id));
  }

  List<String> _municipalitiesFrom(CuratedListDetail detail) {
    final set = <String>{};
    for (final it in detail.items) {
      final m = it.restaurant?.municipio;
      if (m != null && m.trim().isNotEmpty) set.add(m.trim());
    }
    final list = set.toList()..sort();
    return list;
  }

  List<CuratedListItem> _applyFilters(CuratedListDetail detail) {
    final q = _query.trim().toLowerCase();
    Iterable<CuratedListItem> it = detail.items;

    if (q.isNotEmpty) {
      it = it.where((e) {
        final r = e.restaurant;
        final name = (r?.nombre ?? '').toLowerCase();
        final municipio = (r?.municipio ?? '').toLowerCase();
        final note = (e.note ?? '').toLowerCase();
        return name.contains(q) ||
            municipio.contains(q) ||
            note.contains(q);
      });
    }
    if (_municipio != null) {
      it = it.where((e) =>
          (e.restaurant?.municipio ?? '').trim() == _municipio);
    }

    final result = it.toList();
    switch (_sort) {
      case _SortMode.byPosition:
        result.sort((a, b) => a.position.compareTo(b.position));
        break;
      case _SortMode.alphabetical:
        result.sort((a, b) => (a.restaurant?.nombre ?? '')
            .toLowerCase()
            .compareTo((b.restaurant?.nombre ?? '').toLowerCase()));
        break;
    }
    return result;
  }
}

// ─── Hero (Sliver) ─────────────────────────────────────────────

class _Hero extends StatelessWidget {
  final CuratedListDetail detail;
  const _Hero({required this.detail});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              detail.accent.withOpacity(0.32),
              detail.accent.withOpacity(0.10),
              AppColors.crema,
            ],
            stops: const [0, 0.55, 1],
          ),
        ),
        padding: EdgeInsets.fromLTRB(20, topInset + 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _IconChip(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const Spacer(),
                _IconChip(
                  icon: Icons.ios_share_rounded,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Eyebrow + count pills
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (detail.eyebrow.isNotEmpty)
                  _Pill(
                    label: detail.eyebrow.toUpperCase(),
                    bg: AppColors.ink.withOpacity(0.85),
                    fg: AppColors.crema,
                  ),
                _Pill(
                  label: '${detail.count} sitios',
                  bg: AppColors.cremaSoft,
                  fg: AppColors.ink,
                  border: AppColors.borderCreamMd,
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Title
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    detail.title.toUpperCase(),
                    style: AppTextStyles.displayHero(
                      size: 32,
                      color: AppColors.ink,
                    ).copyWith(height: 1.0),
                  ),
                ),
                if (detail.heroEmoji != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text(
                      detail.heroEmoji!,
                      style: const TextStyle(fontSize: 56),
                    ),
                  ),
              ],
            ),
            if (detail.subtitle.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                detail.subtitle,
                style: AppTextStyles.editorial(
                  size: 14,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 14, color: AppColors.inkMuted),
                const SizedBox(width: 4),
                Text(
                  detail.location,
                  style: AppTextStyles.ui(
                    size: 12,
                    weight: FontWeight.w500,
                    color: AppColors.inkMuted,
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

class _IconChip extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconChip({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.cremaSoft.withOpacity(0.85),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderCreamMd),
        ),
        child: Icon(icon, size: 18, color: AppColors.ink),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final Color? border;

  const _Pill({
    required this.label,
    required this.bg,
    required this.fg,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: border != null ? Border.all(color: border!) : null,
      ),
      child: Text(
        label,
        style: AppTextStyles.eyebrow(size: 10, color: fg),
      ),
    );
  }
}

// ─── ToolBar (search + filters + sort + count) ─────────────────

class _ToolBar extends StatelessWidget {
  final String query;
  final ValueChanged<String> onQuery;
  final List<String> municipalities;
  final String? municipio;
  final ValueChanged<String?> onMunicipio;
  final _SortMode sort;
  final ValueChanged<_SortMode> onSort;
  final int visible;
  final int total;
  final Color accent;

  const _ToolBar({
    required this.query,
    required this.onQuery,
    required this.municipalities,
    required this.municipio,
    required this.onMunicipio,
    required this.sort,
    required this.onSort,
    required this.visible,
    required this.total,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final hasFilter = query.isNotEmpty || municipio != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SearchField(value: query, onChanged: onQuery),
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: 'Todos',
                  active: municipio == null,
                  onTap: () => onMunicipio(null),
                  accent: accent,
                ),
                const SizedBox(width: 8),
                ...municipalities.map((m) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChip(
                        label: m,
                        active: municipio == m,
                        onTap: () => onMunicipio(m),
                        accent: accent,
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                hasFilter
                    ? '$visible de $total resultados'
                    : '$total sitios',
                style: AppTextStyles.ui(
                  size: 12,
                  weight: FontWeight.w600,
                  color: AppColors.inkSoft,
                ),
              ),
              const Spacer(),
              _SortToggle(value: sort, onChanged: onSort, accent: accent),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.value, required this.onChanged});

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(covariant _SearchField old) {
    super.didUpdateWidget(old);
    if (widget.value != _ctrl.text) {
      _ctrl.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.cremaSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderCream),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 18, color: AppColors.inkMuted),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _ctrl,
              onChanged: widget.onChanged,
              cursorColor: AppColors.atlantico,
              style: AppTextStyles.ui(size: 14, color: AppColors.ink),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Busca por nombre, zona o nota…',
                hintStyle: AppTextStyles.ui(
                  size: 14,
                  color: AppColors.inkMuted,
                ),
              ),
            ),
          ),
          if (widget.value.isNotEmpty)
            GestureDetector(
              onTap: () => widget.onChanged(''),
              child: Icon(Icons.close_rounded,
                  size: 18, color: AppColors.inkMuted),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color accent;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.ink : AppColors.cremaSoft,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? AppColors.ink : AppColors.borderCreamMd,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.ui(
            size: 12,
            weight: FontWeight.w600,
            color: active ? AppColors.crema : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }
}

class _SortToggle extends StatelessWidget {
  final _SortMode value;
  final ValueChanged<_SortMode> onChanged;
  final Color accent;

  const _SortToggle({
    required this.value,
    required this.onChanged,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(
        value == _SortMode.byPosition
            ? _SortMode.alphabetical
            : _SortMode.byPosition,
      ),
      child: Row(
        children: [
          Icon(
            value == _SortMode.byPosition
                ? Icons.format_list_numbered_rounded
                : Icons.sort_by_alpha_rounded,
            size: 16,
            color: AppColors.atlantico,
          ),
          const SizedBox(width: 6),
          Text(
            value == _SortMode.byPosition ? 'Por puesto' : 'Alfabético',
            style: AppTextStyles.ui(
              size: 12,
              weight: FontWeight.w600,
              color: AppColors.atlantico,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── States: loading / empty / error ───────────────────────────

class _LoadingView extends StatelessWidget {
  final CuratedList list;
  const _LoadingView({required this.list});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _Hero(
          detail: CuratedListDetail(
            id: list.id,
            eyebrow: list.eyebrow,
            title: list.title,
            subtitle: list.subtitle,
            heroAsset: list.heroAsset,
            heroEmoji: list.heroEmoji,
            count: list.count,
            location: list.location,
            accent: list.accent,
            islandId: list.islandId,
            position: list.position,
            enabled: list.enabled,
            items: const [],
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: list.accent,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 48, color: AppColors.inkMuted),
          const SizedBox(height: 12),
          Text(
            'Sin resultados',
            style: AppTextStyles.displayHero(
              size: 22,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Prueba a quitar algún filtro o cambiar la búsqueda.',
            textAlign: TextAlign.center,
            style: AppTextStyles.editorial(
              size: 13,
              color: AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: _IconChip(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ),
            const Spacer(),
            Icon(Icons.cloud_off_rounded,
                size: 48, color: AppColors.inkMuted),
            const SizedBox(height: 12),
            Text(
              'No pudimos cargar la lista',
              style: AppTextStyles.displayHero(
                size: 22,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.editorial(
                size: 12,
                color: AppColors.inkMuted,
              ),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.atlantico,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Reintentar',
                  style: AppTextStyles.ui(
                    size: 13,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
