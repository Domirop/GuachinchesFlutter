import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/data/cubit/user/user_state.dart';
import 'package:guachinches/data/model/user_info.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/pages/login/login.dart';
import 'package:guachinches/ui/pages/valoraciones/valoracion_detail_screen.dart';
import 'package:guachinches/ui/pages/valoraciones/valoraciones_presenter.dart';
import 'package:http/http.dart';

class ValoracionesPage extends StatefulWidget {
  const ValoracionesPage({super.key});

  @override
  State<ValoracionesPage> createState() => _ValoracionesPageState();
}

class _ValoracionesPageState extends State<ValoracionesPage>
    implements ValoracionesView {
  late RemoteRepository _remoteRepository;
  late ValoracionesPresenter _presenter;

  @override
  void initState() {
    super.initState();
    _remoteRepository = HttpRemoteRepository(Client());
    final userCubit = context.read<UserCubit>();
    _presenter = ValoracionesPresenter(this, _remoteRepository, userCubit);
    _presenter.isUserLogged();
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
          'Mis valoraciones',
          style: AppTextStyles.displaySection(size: 13),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<UserCubit, UserState>(
        builder: (context, state) {
          if (state is! UserLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final reviews = state.user.valoraciones;
          if (reviews.isEmpty) {
            return _EmptyState();
          }
          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _StatsHeader(user: state.user),
              const SizedBox(height: 14),
              ...reviews.map(
                (v) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ValoracionCard(valoracion: v),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  goToLogin() {
    GlobalMethods()
        .pushPage(context, Login('Inicia sesión para ver tus valoraciones'));
  }
}

// ─────────────────────────────────────────────────────────────────────

class _StatsHeader extends StatelessWidget {
  final UserInfo user;

  const _StatsHeader({required this.user});

  double get _avgGiven {
    final list = user.valoraciones;
    if (list.isEmpty) return 0;
    double sum = 0;
    int n = 0;
    for (final v in list) {
      final r = double.tryParse(v.rating);
      if (r != null) {
        sum += r;
        n++;
      }
    }
    return n == 0 ? 0 : sum / n;
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final total = user.valoraciones.length;
    final avg = _avgGiven;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: brand.surface,
        border: Border.all(color: brand.borderStrong),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Stat(
              value: '$total',
              label: total == 1 ? 'reseña' : 'reseñas',
              icon: Icons.rate_review_rounded,
              accent: AppColors.atlanticoClaro,
            ),
          ),
          Container(width: 1, height: 36, color: brand.borderStrong),
          Expanded(
            child: _Stat(
              value: avg > 0 ? avg.toStringAsFixed(1) : '—',
              label: 'media dada',
              icon: Icons.star_rounded,
              accent: AppColors.sol,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color accent;

  const _Stat({
    required this.value,
    required this.label,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: accent),
            const SizedBox(width: 4),
            Text(
              value,
              style: AppTextStyles.displayHero(size: 22),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.ui(
            size: 11,
            color: brand.textMuted,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────

class _ValoracionCard extends StatelessWidget {
  final Valoraciones valoracion;

  const _ValoracionCard({required this.valoracion});

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final ratingNum = double.tryParse(valoracion.rating)?.round() ?? 0;
    final restaurantName = valoracion.restaurantes?.nombre ?? 'Restaurante';
    final hasReview = valoracion.review.trim().isNotEmpty;
    final hasTitle = valoracion.title.trim().isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ValoracionDetailScreen(valoracion: valoracion),
              ),
            ),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          decoration: BoxDecoration(
            color: brand.surface,
            border: Border.all(color: brand.borderStrong),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.atlantico.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.restaurant_rounded,
                      size: 18,
                      color: AppColors.atlanticoClaro,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          restaurantName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.displayHero(size: 16),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            ...List.generate(5, (i) {
                              return Icon(
                                i < ratingNum
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 13,
                                color: AppColors.sol,
                              );
                            }),
                            const SizedBox(width: 6),
                            Text(
                              valoracion.rating,
                              style: AppTextStyles.ui(
                                size: 11,
                                weight: FontWeight.w700,
                                color: brand.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: brand.textMuted,
                    size: 22,
                  ),
                ],
              ),
              if (hasTitle || hasReview) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  decoration: BoxDecoration(
                    color: brand.elevated,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasTitle)
                        Text(
                          valoracion.title,
                          style: AppTextStyles.ui(
                            size: 13,
                            weight: FontWeight.w700,
                            color: brand.textPrimary,
                          ),
                        ),
                      if (hasTitle && hasReview) const SizedBox(height: 4),
                      if (hasReview)
                        Text(
                          valoracion.review,
                          style: AppTextStyles.editorial(
                            size: 13,
                            color: brand.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.sol.withOpacity(0.15),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.star_outline_rounded,
                size: 38,
                color: AppColors.sol,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Aún no has valorado ningún sitio',
              textAlign: TextAlign.center,
              style: AppTextStyles.displayHero(size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              'Cuando dejes una reseña en un restaurante, aparecerá aquí.',
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
