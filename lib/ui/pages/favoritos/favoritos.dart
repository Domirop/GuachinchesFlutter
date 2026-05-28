import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/local/sql_lite_local_repository.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/components/open_status_badge.dart';
import 'package:guachinches/ui/pages/favoritos/favorito_detail_screen.dart';
import 'package:http/http.dart' as http;

class FavoritosPage extends StatefulWidget {
  const FavoritosPage({super.key});

  @override
  State<FavoritosPage> createState() => _FavoritosPageState();
}

class _FavoritosPageState extends State<FavoritosPage> {
  final _localRepo = SqlLiteLocalRepository();
  late final HttpRemoteRepository _repo =
      HttpRemoteRepository(http.Client());

  bool _loading = true;
  List<Restaurant> _restaurants = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final favs = await _localRepo.getRestaurants();
      final futures = favs.map((f) async {
        try {
          final r = await _repo.getRestaurantById(f.restaurantId);
          r.id = f.restaurantId;
          return r;
        } catch (_) {
          return null;
        }
      });
      final results = await Future.wait(futures);
      final list = results.whereType<Restaurant>().toList();
      if (!mounted) return;
      setState(() {
        _restaurants = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _remove(Restaurant r) async {
    await _localRepo.removeRestaurant(r.id);
    if (!mounted) return;
    setState(() {
      _restaurants = _restaurants.where((x) => x.id != r.id).toList();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${r.nombre}" eliminado de favoritos'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: context.brand.elevated,
        action: SnackBarAction(
          label: 'Deshacer',
          textColor: AppColors.atlanticoClaro,
          onPressed: () async {
            await _localRepo.insertRestaurant(r.id);
            if (!mounted) return;
            setState(() => _restaurants = [..._restaurants, r]);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Scaffold(
      backgroundColor: brand.base,
      appBar: AppBar(
        backgroundColor: brand.base,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: brand.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Favoritos',
          style: AppTextStyles.displaySection(size: 13),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: AppColors.atlantico,
        backgroundColor: brand.surface,
        onRefresh: _load,
        child: _buildBody(brand),
      ),
    );
  }

  Widget _buildBody(dynamic brand) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_restaurants.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          _EmptyState(),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _restaurants.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6, top: 4),
            child: Text(
              '${_restaurants.length} ${_restaurants.length == 1 ? "local guardado" : "locales guardados"}',
              style: AppTextStyles.eyebrow(
                size: 11,
                color: brand.textMuted,
              ),
            ),
          );
        }
        final r = _restaurants[i - 1];
        return _FavoriteCard(
          restaurant: r,
          onTap: () async {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => FavoritoDetailScreen(restaurant: r),
              ),
            );
            if (result == true) _load();
          },
          onRemove: () => _remove(r),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────

class _FavoriteCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FavoriteCard({
    required this.restaurant,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final r = restaurant;
    final hasImage = r.mainFoto.isNotEmpty;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: brand.surface,
            border: Border.all(color: brand.borderStrong),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child: hasImage
                      ? Image.network(
                          r.mainFoto,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _ImageFallback(brand: brand),
                        )
                      : _ImageFallback(brand: brand),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.displayHero(size: 16),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star_rounded,
                              size: 13, color: AppColors.sol),
                          const SizedBox(width: 2),
                          Text(
                            r.avgRating > 0
                                ? r.avgRating.toStringAsFixed(1)
                                : 'n/d',
                            style: AppTextStyles.ui(
                              size: 12,
                              weight: FontWeight.w700,
                              color: brand.textPrimary,
                            ),
                          ),
                          if (r.municipio.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text('·',
                                style: AppTextStyles.ui(
                                    size: 12, color: brand.textMuted)),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                r.municipio,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.ui(
                                  size: 12,
                                  color: brand.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      OpenStatusBadge(
                        horariosJson: r.horariosJson,
                        fallbackOpen: r.open,
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.bookmark_rounded,
                  color: AppColors.atlanticoClaro,
                  size: 22,
                ),
                onPressed: onRemove,
                tooltip: 'Quitar de favoritos',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                    minWidth: 36, minHeight: 36),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  final dynamic brand;
  const _ImageFallback({required this.brand});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: brand.elevated,
      alignment: Alignment.center,
      child: Icon(
        Icons.restaurant_rounded,
        color: brand.textMuted,
        size: 24,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            Container(
              width: 88,
              height: 88,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.atlantico.withOpacity(0.12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.bookmark_outline_rounded,
                size: 38,
                color: AppColors.atlanticoClaro,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Aún no tienes favoritos',
              textAlign: TextAlign.center,
              style: AppTextStyles.displayHero(size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              'Toca el icono de marcador en cualquier restaurante para guardarlo y tenerlo siempre a mano.',
              textAlign: TextAlign.center,
              style: AppTextStyles.ui(
                size: 13,
                color: brand.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
