import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/data/cubit/onboarding/onboarding_cubit.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/theme/theme_cubit.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/data/cubit/user/user_state.dart';
import 'package:guachinches/data/local/sql_lite_local_repository.dart';
import 'package:guachinches/data/model/Cupones.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/data/model/user_info.dart';
import 'package:guachinches/ui/pages/favoritos/favoritos.dart';
import 'package:guachinches/ui/pages/profile/about_page.dart';
import 'package:guachinches/ui/pages/profile/edit_profile_page.dart';
import 'package:guachinches/ui/pages/profile/help_page.dart';
import 'package:guachinches/ui/pages/profile/notifications_page.dart';
import 'package:guachinches/ui/pages/profile/profile_presenter.dart';
import 'package:guachinches/ui/pages/splash_screen/splash_screen.dart';
import 'package:guachinches/ui/pages/valoraciones/valoraciones.dart';
import 'package:http/http.dart';

class Profilev2 extends StatefulWidget {
  const Profilev2({super.key});

  @override
  State<Profilev2> createState() => _Profilev2State();
}

class _Profilev2State extends State<Profilev2> implements ProfileView {
  late RemoteRepository remoteRepository;
  late ProfilePresenter _presenter;
  final _localRepo = SqlLiteLocalRepository();
  final _storage = const FlutterSecureStorage();
  int _favCount = 0;

  @override
  void initState() {
    super.initState();
    final userCubit = context.read<UserCubit>();
    remoteRepository = HttpRemoteRepository(Client());
    _presenter = ProfilePresenter(this, userCubit, remoteRepository);
    _loadFavCount();
    _ensureUserLoaded(userCubit);
  }

  Future<void> _ensureUserLoaded(UserCubit userCubit) async {
    if (userCubit.state is UserLoaded) return;
    final userId = await _storage.read(key: 'userId');
    if (userId == null || userId.isEmpty) return;
    await userCubit.getUserInfo(userId);
  }

  Future<void> _loadFavCount() async {
    final list = await _localRepo.getRestaurants();
    if (!mounted) return;
    setState(() => _favCount = list.length);
  }

  Future<void> _confirmLogout() async {
    final ok = await _showConfirm(
      title: 'Cerrar sesión',
      message: '¿Seguro que quieres cerrar sesión?',
      confirmLabel: 'Cerrar sesión',
      destructive: false,
    );
    if (ok == true) _presenter.logOut();
  }

  Future<void> _confirmDelete() async {
    final ok = await _showConfirm(
      title: 'Eliminar cuenta',
      message:
          'Esta acción es permanente. Se borrarán todas tus valoraciones y datos.',
      confirmLabel: 'Eliminar',
      destructive: true,
    );
    if (ok == true) _presenter.deleteAccount();
  }

  Future<void> _resetOnboarding() async {
    final confirmed = await _showResetOnboardingDialog();
    if (confirmed != true) return;
    await context.read<OnboardingCubit>().reset();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => SplashScreen()),
      (_) => false,
    );
  }

  Future<bool?> _showResetOnboardingDialog() {
    final brand = context.brand;
    return showDialog<bool>(
      context: context,
      builder: (dialogCtx) => Semantics(
        identifier: 'reset-onboarding-confirm-dialog',
        child: AlertDialog(
          backgroundColor: brand.elevated,
          title: const Text('¿Resetear onboarding?'),
          content: const Text(
            'Se borrarán tus preferencias y volverás a la pantalla de bienvenida al reiniciar.',
          ),
          actions: [
            Semantics(
              identifier: 'reset-onboarding-cancel-cta',
              child: TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(false),
                child: const Text('Cancelar'),
              ),
            ),
            Semantics(
              identifier: 'reset-onboarding-confirm-cta',
              child: TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(true),
                child: const Text('Resetear'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showConfirm({
    required String title,
    required String message,
    required String confirmLabel,
    required bool destructive,
  }) {
    final brand = context.brand;
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: brand.elevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        final bottom = MediaQuery.of(sheetCtx).padding.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: brand.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.displayHero(size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.ui(
                  size: 13,
                  color: brand.textSecondary,
                ),
              ),
              const SizedBox(height: 22),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      destructive ? AppColors.mojo : AppColors.atlantico,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(sheetCtx, true),
                child: Text(
                  confirmLabel.toUpperCase(),
                  style: AppTextStyles.displaySection(size: 12)
                      .copyWith(color: Colors.white, letterSpacing: 1.0),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(sheetCtx, false),
                child: Text(
                  'Cancelar',
                  style: AppTextStyles.ui(
                    size: 13,
                    weight: FontWeight.w600,
                    color: brand.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Scaffold(
      backgroundColor: brand.base,
      body: SafeArea(
        child: BlocBuilder<UserCubit, UserState>(
          builder: (context, state) {
            UserInfo user = UserInfo();
            if (state is UserLoaded) user = state.user;
            final reviewCount = user.valoraciones.length;
            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                _Header(),
                const SizedBox(height: 8),
                _ProfileCard(user: user),
                const SizedBox(height: 20),
                _StatsRow(
                  reviewCount: reviewCount,
                  favCount: _favCount,
                  onTapReviews: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ValoracionesPage(),
                    ),
                  ),
                  onTapFavs: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FavoritosPage(),
                      ),
                    );
                    _loadFavCount();
                  },
                ),
                const SizedBox(height: 24),
                _SectionLabel('CUENTA'),
                _MenuTile(
                  icon: Icons.rate_review_outlined,
                  iconColor: AppColors.atlanticoClaro,
                  title: 'Mis valoraciones',
                  subtitle: reviewCount == 0
                      ? 'Aún no has valorado'
                      : '$reviewCount ${reviewCount == 1 ? "reseña" : "reseñas"}',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ValoracionesPage(),
                    ),
                  ),
                ),
                _MenuTile(
                  icon: Icons.bookmark_border_rounded,
                  iconColor: AppColors.atlanticoClaro,
                  title: 'Favoritos',
                  subtitle: _favCount == 0
                      ? 'Sin restaurantes guardados'
                      : '$_favCount ${_favCount == 1 ? "guardado" : "guardados"}',
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FavoritosPage(),
                      ),
                    );
                    _loadFavCount();
                  },
                ),
                const SizedBox(height: 24),
                _SectionLabel('AJUSTES'),
                const _ThemeTile(),
                const SizedBox(height: 24),
                _SectionLabel('PREFERENCIAS'),
                Semantics(
                  identifier: 'profile-menu-editar-perfil',
                  child: _MenuTile(
                    icon: Icons.person_outline_rounded,
                    iconColor: AppColors.atlanticoClaro,
                    title: 'Editar perfil',
                    subtitle: 'Nombre, email e isla',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditarPerfilPage()),
                    ),
                  ),
                ),
                Semantics(
                  identifier: 'profile-menu-notificaciones',
                  child: _MenuTile(
                    icon: Icons.notifications_outlined,
                    iconColor: AppColors.sol,
                    title: 'Notificaciones',
                    subtitle: 'Gestiona tus alertas',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificacionesPage()),
                    ),
                  ),
                ),
                Semantics(
                  identifier: 'profile-menu-ayuda',
                  child: _MenuTile(
                    icon: Icons.help_outline_rounded,
                    iconColor: AppColors.laurisilva,
                    title: 'Ayuda y soporte',
                    subtitle: 'Preguntas frecuentes y contacto',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AyudaPage()),
                    ),
                  ),
                ),
                Semantics(
                  identifier: 'profile-menu-acerca-de',
                  child: _MenuTile(
                    icon: Icons.info_outline_rounded,
                    iconColor: AppColors.atlantico,
                    title: 'Acerca de',
                    subtitle: 'Versión, términos y privacidad',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AcercaDePage()),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                _DangerZone(
                  onLogout: _confirmLogout,
                  onDelete: _confirmDelete,
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 28),
                  _SectionLabel('DEV'),
                  Semantics(
                    identifier: 'profile-reset-onboarding-button',
                    child: _MenuTile(
                      icon: Icons.refresh_rounded,
                      iconColor: AppColors.mojo,
                      title: 'Reiniciar onboarding',
                      subtitle:
                          'Borra preferencias y vuelve a la pantalla de bienvenida',
                      onTap: _resetOnboarding,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    '¿Dónde Comer Canarias?',
                    style: AppTextStyles.eyebrow(
                      size: 10,
                      color: brand.textMuted,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ProfileView impls (legacy — usados por otros presenters)
  @override
  goSplashScreen() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => SplashScreen()),
      (_) => false,
    );
  }

  @override
  updateCupones(List<Cupones> cupones) {}

  @override
  updateListSql(List<Restaurant> restaurants) {}
}

// ─────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TU CUENTA',
                  style: AppTextStyles.eyebrow(
                    size: 10,
                    color: context.brand.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mi perfil',
                  style: AppTextStyles.displayHero(size: 32),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final UserInfo user;

  const _ProfileCard({required this.user});

  String get _displayName {
    final n = user.nombre.trim();
    if (n.isEmpty) return 'Usuario';
    return '${n[0].toUpperCase()}${n.substring(1)}';
  }

  String get _initial {
    final n = _displayName;
    return n.isNotEmpty ? n[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.atlantico.withOpacity(0.18),
            AppColors.profundo.withOpacity(0.10),
          ],
        ),
        border: Border.all(color: brand.borderStrong),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.atlantico,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.atlantico.withOpacity(0.35),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Text(
              _initial,
              style: AppTextStyles.displayHero(
                size: 28,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.displayHero(size: 22),
                ),
                if (user.apellidos.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    user.apellidos,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.ui(
                      size: 13,
                      color: brand.textSecondary,
                    ),
                  ),
                ],
                if (user.email.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.mail_outline_rounded,
                          size: 13, color: brand.textMuted),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          user.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.ui(
                            size: 12,
                            color: brand.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int reviewCount;
  final int favCount;
  final VoidCallback onTapReviews;
  final VoidCallback onTapFavs;

  const _StatsRow({
    required this.reviewCount,
    required this.favCount,
    required this.onTapReviews,
    required this.onTapFavs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.star_rounded,
            iconColor: AppColors.sol,
            value: '$reviewCount',
            label: reviewCount == 1 ? 'valoración' : 'valoraciones',
            onTap: onTapReviews,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.bookmark_rounded,
            iconColor: AppColors.atlanticoClaro,
            value: '$favCount',
            label: favCount == 1 ? 'favorito' : 'favoritos',
            onTap: onTapFavs,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final VoidCallback onTap;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: brand.surface,
            border: Border.all(color: brand.borderStrong),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(height: 8),
              Text(
                value,
                style: AppTextStyles.displayHero(size: 26),
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
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 10),
      child: Text(
        text,
        style: AppTextStyles.eyebrow(
          size: 11,
          color: context.brand.textMuted,
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: brand.surface,
              border: Border.all(color: brand.borderStrong),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.ui(
                          size: 14,
                          weight: FontWeight.w700,
                          color: brand.textPrimary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: AppTextStyles.ui(
                            size: 11,
                            color: brand.textMuted,
                          ),
                        ),
                      ],
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
          ),
        ),
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (_, mode) {
        final isDark = mode == ThemeMode.dark;
        final brand = context.brand;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: brand.surface,
            border: Border.all(color: brand.borderStrong),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.sol.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isDark
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  size: 20,
                  color: AppColors.sol,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Modo oscuro',
                      style: AppTextStyles.ui(
                        size: 14,
                        weight: FontWeight.w700,
                        color: brand.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isDark ? 'Activado' : 'Desactivado',
                      style: AppTextStyles.ui(
                        size: 11,
                        color: brand.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isDark,
                activeColor: Colors.white,
                activeTrackColor: AppColors.atlantico,
                onChanged: (v) => context.read<ThemeCubit>().setMode(
                      v ? ThemeMode.dark : ThemeMode.light,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DangerZone extends StatelessWidget {
  final VoidCallback onLogout;
  final VoidCallback onDelete;

  const _DangerZone({
    required this.onLogout,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: onLogout,
          icon: Icon(Icons.logout_rounded,
              size: 18, color: brand.textPrimary),
          label: Text(
            'Cerrar sesión',
            style: AppTextStyles.ui(
              size: 14,
              weight: FontWeight.w600,
              color: brand.textPrimary,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(color: brand.borderStrong),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: onDelete,
          child: Text(
            'Eliminar cuenta',
            style: AppTextStyles.ui(
              size: 12,
              weight: FontWeight.w600,
              color: AppColors.mojo,
            ),
          ),
        ),
      ],
    );
  }
}
