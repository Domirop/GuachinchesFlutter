import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/l10n/app_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/cubit/menu/menu_cubit.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/data/cubit/user/user_state.dart';
import 'package:guachinches/data/cubit/visits/user_visits_cubit.dart';
import 'package:guachinches/data/cubit/visits/user_visits_state.dart';
import 'package:guachinches/data/model/user_visit.dart';
import 'package:guachinches/ui/components/cards/visit_card.dart';
import 'package:guachinches/ui/pages/restaurant_detail/restaurant_detail_screen.dart';

class VisitasScreen extends StatefulWidget {
  const VisitasScreen({super.key});

  @override
  State<VisitasScreen> createState() => _VisitasScreenState();
}

class _VisitasScreenState extends State<VisitasScreen> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    _resolveUserIdAndLoad();
  }

  Future<void> _resolveUserIdAndLoad() async {
    final userState = context.read<UserCubit>().state;
    if (userState is UserLoaded) {
      _userId = userState.user.id;
    }
    if (_userId == null || _userId!.isEmpty) {
      _userId = await const FlutterSecureStorage().read(key: 'userId');
    }
    if (_userId != null && _userId!.isNotEmpty && mounted) {
      context.read<UserVisitsCubit>().load(_userId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;

    return Scaffold(
      backgroundColor: brand.base,
      appBar: AppBar(
        title: Text(AppL10n.of(context).visitsScreenTitle),
        backgroundColor: brand.surface,
        foregroundColor: brand.textPrimary,
        elevation: 0,
      ),
      body: Semantics(
        identifier: 'visitas-screen-root',
        child: BlocBuilder<UserVisitsCubit, UserVisitsState>(
          builder: (context, state) {
            if (state is UserVisitsLoading || state is UserVisitsInitial) {
              return _SkeletonList(brand: brand);
            }
            if (state is UserVisitsLoaded) {
              return _LoadedBody(
                visits: state.visits,
                onRefresh: () async {
                  if (_userId != null && _userId!.isNotEmpty) {
                    await context.read<UserVisitsCubit>().refresh(_userId!);
                  }
                },
              );
            }
            if (state is UserVisitsEmpty) {
              return _EmptyBody(brand: brand);
            }
            if (state is UserVisitsError) {
              return _ErrorBody(
                message: state.message,
                brand: brand,
                onRetry: () {
                  if (_userId != null && _userId!.isNotEmpty) {
                    context.read<UserVisitsCubit>().load(_userId!);
                  }
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _LoadedBody extends StatelessWidget {
  final List<UserVisit> visits;
  final Future<void> Function() onRefresh;

  const _LoadedBody({required this.visits, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'visitas-refresh-indicator',
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: Semantics(
          identifier: 'visitas-list',
          child: ListView.builder(
            itemCount: visits.length,
            itemBuilder: (context, index) {
              final visit = visits[index];
              return Semantics(
                identifier: 'visitas-card-${visit.id}',
                child: VisitCard(
                  visit: visit,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          RestaurantDetailScreen(id: visit.restaurantId),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EmptyBody extends StatelessWidget {
  final BrandColors brand;

  const _EmptyBody({required this.brand});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_menu_outlined, size: 72, color: brand.textMuted),
            const SizedBox(height: 16),
            Text(
              AppL10n.of(context).visitsEmpty,
              style: TextStyle(
                color: brand.textSecondary,
                fontSize: 16,
                fontFamily: 'SF Pro Display',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Semantics(
              identifier: 'visitas-empty-cta',
              child: ElevatedButton(
                onPressed: () =>
                    context.read<MenuCubit>().updateSelectedIndex(0),
                child: const Text('Explorar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  final BrandColors brand;
  final VoidCallback onRetry;

  const _ErrorBody({
    required this.message,
    required this.brand,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: brand.textMuted),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(color: brand.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Semantics(
              identifier: 'visitas-retry-button',
              child: ElevatedButton(
                onPressed: onRetry,
                child: const Text('Reintentar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonList extends StatefulWidget {
  final BrandColors brand;

  const _SkeletonList({required this.brand});

  @override
  State<_SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<_SkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.3, end: 0.7).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, _) {
        return Opacity(
          opacity: _opacity.value,
          child: ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            itemBuilder: (_, __) => _SkeletonCard(brand: widget.brand),
          ),
        );
      },
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final BrandColors brand;

  const _SkeletonCard({required this.brand});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      height: 88,
      decoration: BoxDecoration(
        color: brand.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: brand.elevated,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: brand.elevated,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 80,
                    decoration: BoxDecoration(
                      color: brand.elevated,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
