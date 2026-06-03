import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/cubit/location/location_cubit.dart';
import 'package:guachinches/data/cubit/location/location_state.dart';
import 'package:guachinches/data/cubit/new_home/new_home_filters_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_state.dart';
import 'package:guachinches/data/local/http_cache_store.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/components/shimmer_box.dart';
import 'package:guachinches/ui/pages/advance_search/widgets/search_result_card.dart';
import 'package:guachinches/ui/pages/restaurant_detail/restaurant_detail_screen.dart';
import 'package:guachinches/utils/location_prompt_action.dart';

class CercaAhoraScreen extends StatefulWidget {
  final int initialLimit;
  final double maxRadiusKm;

  const CercaAhoraScreen({
    super.key,
    this.initialLimit = 30,
    this.maxRadiusKm = 5,
  });

  @override
  State<CercaAhoraScreen> createState() => _CercaAhoraScreenState();
}

class _CercaAhoraScreenState extends State<CercaAhoraScreen> {
  bool _initialized = false;
  bool _isLoading = false;
  bool _resultCountLogged = false;
  late double _maxRadiusKm;

  @override
  void initState() {
    super.initState();
    _maxRadiusKm = widget.maxRadiusKm;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<LocationCubit>();
      final locState = cubit.state;
      _logEvent('cerca_ahora_opened', {
        'has_location': locState is LocationLoaded ? 1 : 0,
      });
      if (locState is LocationLoaded && !_initialized) {
        _initialized = true;
        _fetchRestaurants(locState);
      } else if (locState is LocationInitial) {
        // Si el cubit aún no ha arrancado (caso típico al entrar desde el
        // callout antes de que termine el bootstrap del home), pedimos la
        // ubicación aquí. Si el user tiene permisos esto resuelve a
        // LocationLoaded sin mostrar el empty state.
        unawaited(cubit.requestLocation());
      }
    });
  }

  Future<void> _fetchRestaurants(LocationLoaded loc) async {
    if (!mounted) return;
    final islandId = context.read<NewHomeFiltersCubit>().state.islandId;
    setState(() {
      _isLoading = true;
      _resultCountLogged = false;
    });
    await context.read<RestaurantCubit>().getFilterRestaurants(
      categories: [],
      municipalities: [],
      types: [],
      text: '',
      islandId: islandId,
      isOpen: true,
    );
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _onRefresh() async {
    await HttpCacheStore.instance.invalidate('restaurants:');
    final locState = context.read<LocationCubit>().state;
    if (locState is LocationLoaded) {
      await _fetchRestaurants(locState);
    }
  }

  void _logEvent(String name, Map<String, Object> params) {
    if (Firebase.apps.isEmpty) return;
    unawaited(
      FirebaseAnalytics.instance.logEvent(name: name, parameters: params),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<LocationCubit, LocationState>(
          listener: (context, state) {
            if (state is LocationLoaded && !_initialized) {
              _initialized = true;
              _fetchRestaurants(state);
            }
          },
        ),
        BlocListener<RestaurantCubit, RestaurantState>(
          listener: (context, state) {
            if (state is RestaurantFilter && _initialized) {
              if (!_resultCountLogged) {
                _resultCountLogged = true;
                final locState = context.read<LocationCubit>().state;
                if (locState is LocationLoaded) {
                  final count = state.filtersRestaurants
                      .where(
                        (r) =>
                            Geolocator.distanceBetween(
                              locState.latitude,
                              locState.longitude,
                              r.lat,
                              r.lon,
                            ) <=
                            _maxRadiusKm * 1000,
                      )
                      .length;
                  _logEvent('cerca_ahora_result_count', {'count': count});
                }
              }
              if (mounted) setState(() => _isLoading = false);
            }
          },
        ),
      ],
      child: Semantics(
        identifier: 'cerca-ahora-screen-root',
        child: Scaffold(
          backgroundColor: context.brand.base,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CercaHeader(onBack: () => Navigator.of(context).pop()),
                Expanded(
                  child: BlocBuilder<LocationCubit, LocationState>(
                    builder: (context, locationState) {
                      // Loading / Initial: spinner mientras el cubit resuelve.
                      // Evita mostrar "Necesitamos ubicación" prematuramente
                      // cuando el usuario SÍ tiene permisos pero el cubit aún
                      // no terminó.
                      if (locationState is LocationInitial ||
                          locationState is LocationLoading) {
                        return const _CercaListSkeleton();
                      }
                      if (locationState is LocationLoaded) {
                        return _buildContent(context, locationState);
                      }
                      // LocationDenied (y sub-tipos) + LocationUnavailable.
                      return _buildLocationRequired(context, locationState);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationRequired(BuildContext context, LocationState state) {
    return Semantics(
      identifier: 'cerca-ahora-location-required',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off_rounded,
                size: 52,
                color: context.brand.textMuted,
              ),
              const SizedBox(height: 20),
              Text(
                'Necesitamos tu ubicación',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.brand.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SF Pro Display',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Para mostrarte locales abiertos cerca de ti',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.brand.textSecondary,
                  fontFamily: 'SF Pro Display',
                ),
              ),
              const SizedBox(height: 28),
              Semantics(
                identifier: 'cerca-ahora-activate-location-button',
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.atlantico,
                    foregroundColor: context.brand.textPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => handleLocationPromptTap(context),
                  child: const Text(
                    'Activar ubicación',
                    style: TextStyle(fontFamily: 'SF Pro Display'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, LocationLoaded loc) {
    return BlocBuilder<RestaurantCubit, RestaurantState>(
      builder: (context, state) {
        if (_isLoading) {
          return const _CercaListSkeleton();
        }
        if (state is RestaurantFilter) {
          return _buildListOrEmpty(context, loc, state.filtersRestaurants);
        }
        if (_initialized) {
          return const _CercaListSkeleton();
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildListOrEmpty(
    BuildContext context,
    LocationLoaded loc,
    List<Restaurant> all,
  ) {
    final filtered = _computeFiltered(all, loc);

    if (all.isEmpty) {
      return Semantics(
        identifier: 'cerca-ahora-empty',
        child: Center(
          child: Text(
            'Nada abierto cerca ahora',
            style: TextStyle(
              color: context.brand.textPrimary,
              fontFamily: 'SF Pro Display',
            ),
          ),
        ),
      );
    }

    if (filtered.isEmpty) {
      return Semantics(
        identifier: 'cerca-ahora-empty',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 52,
                  color: context.brand.textMuted,
                ),
                const SizedBox(height: 20),
                Text(
                  'Nada abierto a menos de ${_maxRadiusKm.toStringAsFixed(0)} km.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.brand.textPrimary,
                    fontFamily: 'SF Pro Display',
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.atlantico,
                    foregroundColor: context.brand.textPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => setState(() => _maxRadiusKm *= 2),
                  child: const Text(
                    'Aumentar radio',
                    style: TextStyle(fontFamily: 'SF Pro Display'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            '${filtered.length} restaurantes abiertos a menos de '
            '${_maxRadiusKm.toStringAsFixed(0)} km',
            style: TextStyle(
              color: context.brand.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              fontFamily: 'SF Pro Display',
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            color: AppColors.atlantico,
            child: Semantics(
              identifier: 'cerca-ahora-list',
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 4, bottom: 24),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  thickness: 1,
                  color: context.brand.border,
                ),
                itemBuilder: (_, i) {
                  final entry = filtered[i];
                  final distM = entry.distanceMeters;
                  final distStr = distM < 1000
                      ? '${distM.toStringAsFixed(0)} m'
                      : '${(distM / 1000).toStringAsFixed(1)} km';
                  final r = entry.restaurant;
                  return SearchResultCard(
                    restaurant: r,
                    distance: distStr,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RestaurantDetailScreen(id: r.id),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<_RestaurantWithDistance> _computeFiltered(
    List<Restaurant> all,
    LocationLoaded loc,
  ) {
    final radiusM = _maxRadiusKm * 1000;
    final result = all
        .map(
          (r) => _RestaurantWithDistance(
            restaurant: r,
            distanceMeters: Geolocator.distanceBetween(
              loc.latitude,
              loc.longitude,
              r.lat,
              r.lon,
            ),
          ),
        )
        .where((e) => e.distanceMeters <= radiusM)
        .toList()
      ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return result;
  }
}

class _RestaurantWithDistance {
  final Restaurant restaurant;
  final double distanceMeters;

  const _RestaurantWithDistance({
    required this.restaurant,
    required this.distanceMeters,
  });
}

/// Cabecera estilo "BUSCAR": chevron de vuelta + título grande alineado a la
/// izquierda (mismo patrón que `advanced_search.dart`), en vez del AppBar
/// genérico de Material que no encaja con el resto de la app.
class _CercaHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _CercaHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          Semantics(
            identifier: 'cerca-ahora-back',
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: context.brand.textPrimary,
              ),
              onPressed: onBack,
            ),
          ),
          Expanded(
            child: Text(
              'Abiertos cerca de ti',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.displayHero(size: 26),
            ),
          ),
        ],
      ),
    );
  }
}

class _CercaListSkeleton extends StatelessWidget {
  const _CercaListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'cerca-ahora-skeleton',
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 4, bottom: 24),
        itemCount: 6,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          thickness: 1,
          color: context.brand.border,
        ),
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ShimmerBox(width: 64, height: 64, radius: 14),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: double.infinity, height: 15, radius: 4),
                    const SizedBox(height: 8),
                    ShimmerBox(width: 140, height: 12, radius: 4),
                    const SizedBox(height: 6),
                    ShimmerBox(width: 90, height: 12, radius: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
