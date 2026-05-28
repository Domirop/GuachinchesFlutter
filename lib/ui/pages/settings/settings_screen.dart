import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guachinches/l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/cubit/account/account_cubit.dart';
import 'package:guachinches/data/cubit/theme/theme_cubit.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/data/cubit/user/user_state.dart';
import 'package:guachinches/data/model/user_info.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/pages/favoritos/favoritos.dart';
import 'package:guachinches/ui/pages/login/login_screen.dart';
import 'package:guachinches/ui/pages/profile/account_management_screen.dart';
import 'package:guachinches/ui/pages/settings/settings_presenter.dart';
import 'package:guachinches/ui/pages/valoraciones/valoraciones.dart';
import 'package:http/http.dart';
import 'package:webview_flutter/webview_flutter.dart';

// ── Constants ────────────────────────────────────────────────────────────────

// TODO(backend): Replace with real URLs from backend config
const _kTermsUrl = 'https://dondecomercanarias.com/terminos';
const _kPrivacyUrl = 'https://dondecomercanarias.com/privacidad';

/// Settings / Profile screen (T-001).
/// Root tab — no back button. Adapts to UserCubit state.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

enum _SessionStatus { checking, notLoggedIn, loading, error }

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin
    implements SettingsView {
  late final SettingsPresenter _presenter;

  // Tracks the local view state independently of UserCubit, so we can
  // distinguish "no userId in storage" from "userId exists but API failed".
  // Without this, a transient network error would render the not-logged-in
  // view even though the user has a valid session in storage.
  _SessionStatus _status = _SessionStatus.checking;

  // Entry animation — fade + translateY
  late final AnimationController _entryCtrl;
  late final Animation<double> _entryFade;
  late final Animation<Offset> _entrySlide;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _entryFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeInOutCubic),
    );
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.02),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeInOutCubic));

    _entryCtrl.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _presenter = SettingsPresenter(
      this,
      HttpRemoteRepository(Client()),
      context.read<UserCubit>(),
    );
    _loadUser();
  }

  void _loadUser() {
    setState(() => _status = _SessionStatus.loading);
    _presenter.loadUser();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  // ── SettingsView callbacks ────────────────────────────────────────────────

  @override
  void onUserNotLoggedIn() {
    if (mounted) setState(() => _status = _SessionStatus.notLoggedIn);
  }

  @override
  void onLoadError() {
    if (mounted) setState(() => _status = _SessionStatus.error);
  }

  @override
  void onLoggedOut() {
    if (!mounted) return;
    GlobalMethods().removePagesAndGoToNewScreen(
      context,
      const LoginScreen(),
    );
  }

  @override
  void onNameUpdated(String name) {
    if (mounted) setState(() {});
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppL10n.of(context).settingsTitle,
      child: FadeTransition(
        opacity: _entryFade,
        child: SlideTransition(
          position: _entrySlide,
          child: BlocBuilder<UserCubit, UserState>(
            builder: (context, state) {
              // A loaded cubit state always wins — even if we previously hit
              // an error, fresh user data means we're good.
              if (state is UserLoaded) {
                return _LoggedInView(
                  user: state.user,
                  onLogout: _showLogoutModal,
                  onDeleteAccount: () => _goToAccountManagement(state.user.id),
                  onEditName: _showEditNameDialog,
                  onReload: _loadUser,
                );
              }
              switch (_status) {
                case _SessionStatus.notLoggedIn:
                  return _NotLoggedInView(onLoginTap: _goToLogin);
                case _SessionStatus.error:
                  return _LoadErrorView(onRetry: _loadUser, onLogout: () => _presenter.logOut());
                case _SessionStatus.checking:
                case _SessionStatus.loading:
                  return const _LoadingView();
              }
            },
          ),
        ),
      ),
    );
  }

  void _goToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _showLogoutModal() {
    HapticFeedback.mediumImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => _DestructiveModal(
        isDark: isDark,
        icon: Icons.logout_rounded,
        iconColor: AppColors.mojo,
        title: '¿Cerrar sesión?',
        body: 'Podrás volver a entrar en cualquier momento con tu cuenta de Google o Apple.',
        confirmLabel: 'Sí, cerrar sesión',
        onConfirm: () {
          Navigator.of(context).pop();
          _presenter.logOut();
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _goToAccountManagement(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => AccountCubit(
            repo: HttpRemoteRepository(Client()),
            userId: userId,
          ),
          child: const AccountManagementScreen(),
        ),
      ),
    );
  }

  void _showDeleteModal() {
    HapticFeedback.mediumImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => _DestructiveModal(
        isDark: isDark,
        icon: Icons.delete_outline_rounded,
        iconColor: AppColors.mojo,
        title: 'Eliminar cuenta',
        titleColor: AppColors.mojo,
        body: 'Esta acción es permanente e irreversible. Se borran tus valoraciones, favoritos y datos de perfil.',
        warningText: '¿Seguro? Esta acción no se puede deshacer.',
        confirmLabel: 'Eliminar mi cuenta definitivamente',
        onConfirm: () {
          Navigator.of(context).pop();
          _presenter.deleteAccount();
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _showEditNameDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? AppColors.elevated : Colors.white,
        title: Text(
          'Editar nombre',
          style: AppTextStyles.ui(
            size: 17,
            weight: FontWeight.w700,
            color: isDark ? AppColors.crema : AppColors.ink,
          ),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          cursorColor: AppColors.atlantico,
          style: AppTextStyles.ui(
            size: 15,
            color: isDark ? AppColors.crema : AppColors.ink,
          ),
          decoration: InputDecoration(
            hintText: 'Tu nombre',
            hintStyle: AppTextStyles.ui(
              size: 15,
              color: isDark
                  ? AppColors.crema.withOpacity(0.38)
                  : AppColors.inkMuted,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text('Cancelar',
                style: AppTextStyles.ui(
                    size: 14, color: AppColors.inkMuted)),
          ),
          TextButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                Navigator.of(dialogCtx).pop();
                _presenter.updateName(name);
              }
            },
            child: Text('Guardar',
                style: AppTextStyles.ui(
                    size: 14,
                    weight: FontWeight.w700,
                    color: AppColors.atlantico)),
          ),
        ],
      ),
    );
  }
}

// ── Logged-in view ────────────────────────────────────────────────────────────

class _LoggedInView extends StatelessWidget {
  final UserInfo user;
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;
  final VoidCallback onEditName;
  final VoidCallback onReload;

  const _LoggedInView({
    required this.user,
    required this.onLogout,
    required this.onDeleteAccount,
    required this.onEditName,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.base : AppColors.crema;
    final surface = isDark ? AppColors.surface : Colors.white;
    final textPrimary = isDark ? AppColors.crema : AppColors.ink;
    final sectionBorder = isDark ? AppColors.borderDark : AppColors.borderCream;
    final cardShadow = isDark
        ? null
        : [
            BoxShadow(
              color: AppColors.ink.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ];

    final initials = _getInitials(user.nombre, user.apellidos);
    final ratingCount = user.valoraciones.length;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [AppColors.surface, AppColors.base]
                        : [AppColors.cremaOscura, AppColors.crema],
                  ),
                ),
                child: Row(
                  children: [
                    // Avatar with edit badge
                    _AvatarWithBadge(
                      initials: initials,
                      isDark: isDark,
                      onTap: onEditName,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${user.nombre} ${user.apellidos}'.trim(),
                            style: AppTextStyles.ui(
                              size: 20,
                              weight: FontWeight.w700,
                              color: textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.email,
                            style: AppTextStyles.ui(
                              size: 13,
                              color: isDark
                                  ? AppColors.crema.withOpacity(0.6)
                                  : AppColors.inkSoft,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Stats pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.07)
                                  : AppColors.ink.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded,
                                    size: 12, color: AppColors.sol),
                                const SizedBox(width: 6),
                                Text(
                                  'Muchacho/a · $ratingCount valoraciones',
                                  style: AppTextStyles.ui(
                                    size: 11,
                                    weight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white.withOpacity(0.6)
                                        : AppColors.ink.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Sections ──────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // CUENTA
                  _SectionLabel(label: 'CUENTA', isDark: isDark),
                  _SettingsCard(
                    isDark: isDark,
                    surface: surface,
                    shadow: cardShadow,
                    border: sectionBorder,
                    children: [
                      _SettingsRow(
                        isDark: isDark,
                        iconBg: AppColors.atlantico.withOpacity(0.15),
                        icon: Icons.person_outline_rounded,
                        iconColor: AppColors.atlantico,
                        title: 'Editar nombre',
                        subtitle: '${user.nombre} ${user.apellidos}'.trim(),
                        onTap: onEditName,
                      ),
                      _SettingsRow(
                        isDark: isDark,
                        iconBg: isDark
                            ? Colors.white.withOpacity(0.05)
                            : AppColors.ink.withOpacity(0.04),
                        icon: Icons.alternate_email_rounded,
                        iconColor: isDark
                            ? AppColors.crema.withOpacity(0.38)
                            : AppColors.ink.withOpacity(0.38),
                        title: 'Email',
                        titleColor: isDark
                            ? AppColors.crema.withOpacity(0.6)
                            : AppColors.inkSoft,
                        subtitle: user.email,
                        subtitleColor: isDark
                            ? AppColors.crema.withOpacity(0.38)
                            : AppColors.inkMuted,
                        trailing: _ReadOnlyBadge(isDark: isDark),
                        onTap: null, // read-only
                      ),
                      Semantics(
                        identifier: 'settings-my-ratings-row',
                        child: _SettingsRow(
                          isDark: isDark,
                          iconBg: AppColors.sol.withOpacity(0.12),
                          icon: Icons.star_outline_rounded,
                          iconColor: AppColors.sol,
                          title: 'Mis valoraciones',
                          subtitle: '$ratingCount valoraciones enviadas',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ValoracionesPage()),
                            );
                          },
                        ),
                      ),
                      Semantics(
                        identifier: 'settings-favorites-row',
                        child: _SettingsRow(
                          isDark: isDark,
                          iconBg: AppColors.mojo.withOpacity(0.12),
                          icon: Icons.favorite_outline_rounded,
                          iconColor: AppColors.mojo,
                          title: 'Favoritos guardados',
                          subtitle: '8 guachinches guardados', // TODO(backend): wire real count from favorites cubit
                          isLast: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const FavoritosPage()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  // PREFERENCIAS
                  _SectionLabel(label: 'PREFERENCIAS', isDark: isDark),
                  _SettingsCard(
                    isDark: isDark,
                    surface: surface,
                    shadow: cardShadow,
                    border: sectionBorder,
                    children: [
                      _SettingsRow(
                        isDark: isDark,
                        iconBg: AppColors.laurisilva.withOpacity(0.12),
                        icon: Icons.language_rounded,
                        iconColor: AppColors.laurisilva,
                        title: 'Idioma',
                        subtitle: 'Español · preparado para v1.1',
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'ES',
                              style: AppTextStyles.ui(
                                size: 13,
                                weight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.crema.withOpacity(0.6)
                                    : AppColors.inkSoft,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: isDark
                                  ? AppColors.crema.withOpacity(0.25)
                                  : AppColors.ink.withOpacity(0.25),
                            ),
                          ],
                        ),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Próximamente más idiomas.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      _ThemeRow(isDark: isDark, isLast: true),
                    ],
                  ),

                  // LEGAL
                  _SectionLabel(label: 'LEGAL', isDark: isDark),
                  _SettingsCard(
                    isDark: isDark,
                    surface: surface,
                    shadow: cardShadow,
                    border: sectionBorder,
                    children: [
                      _SettingsRow(
                        isDark: isDark,
                        iconBg: isDark
                            ? Colors.white.withOpacity(0.05)
                            : AppColors.ink.withOpacity(0.04),
                        icon: Icons.description_outlined,
                        iconColor: isDark
                            ? AppColors.crema.withOpacity(0.38)
                            : AppColors.ink.withOpacity(0.38),
                        title: 'Términos de uso',
                        subtitle: 'Se abre en la app',
                        onTap: () => _openWebView(context, _kTermsUrl,
                            'Términos de uso'),
                      ),
                      _SettingsRow(
                        isDark: isDark,
                        iconBg: isDark
                            ? Colors.white.withOpacity(0.05)
                            : AppColors.ink.withOpacity(0.04),
                        icon: Icons.shield_outlined,
                        iconColor: isDark
                            ? AppColors.crema.withOpacity(0.38)
                            : AppColors.ink.withOpacity(0.38),
                        title: 'Política de privacidad',
                        subtitle: 'Se abre en la app',
                        isLast: true,
                        onTap: () => _openWebView(context, _kPrivacyUrl,
                            'Política de privacidad'),
                      ),
                    ],
                  ),

                  // SESIÓN
                  _SectionLabel(
                    label: 'SESIÓN',
                    isDark: isDark,
                    color: AppColors.mojo.withOpacity(0.6),
                  ),
                  _SettingsCard(
                    isDark: isDark,
                    surface: surface,
                    shadow: cardShadow,
                    border: sectionBorder,
                    children: [
                      _SettingsRow(
                        isDark: isDark,
                        iconBg: AppColors.mojo.withOpacity(0.10),
                        icon: Icons.logout_rounded,
                        iconColor: AppColors.mojo,
                        title: AppL10n.of(context).settingsLogOut,
                        titleColor: AppColors.mojo,
                        titleWeight: FontWeight.w600,
                        showChevron: true,
                        chevronColor: AppColors.mojo.withOpacity(0.4),
                        onTap: onLogout,
                      ),
                      Semantics(
                        identifier: 'settings-account-management-row',
                        child: _SettingsRow(
                          isDark: isDark,
                          iconBg: AppColors.atlantico.withOpacity(0.10),
                          icon: Icons.download_rounded,
                          iconColor: AppColors.atlantico,
                          title: AppL10n.of(context).settingsMyData,
                          showChevron: true,
                          chevronColor: AppColors.atlantico.withOpacity(0.4),
                          onTap: onDeleteAccount,
                        ),
                      ),
                      Semantics(
                        identifier: 'settings-account-management-row',
                        child: _SettingsRow(
                          isDark: isDark,
                          iconBg: AppColors.mojo.withOpacity(0.07),
                          icon: Icons.delete_outline_rounded,
                          iconColor: AppColors.mojo.withOpacity(0.6),
                          title: AppL10n.of(context).settingsDeleteAccount,
                          titleColor: AppColors.mojo.withOpacity(0.7),
                          showChevron: true,
                          chevronColor: AppColors.mojo.withOpacity(0.3),
                          isLast: true,
                          onTap: onDeleteAccount,
                        ),
                      ),
                    ],
                  ),

                  // Version label
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'Dónde Comer Canarias v2.4.0 · Hecho en Canarias',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.ui(
                        size: 11,
                        color: isDark
                            ? AppColors.crema.withOpacity(0.2)
                            : AppColors.ink.withOpacity(0.25),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openWebView(BuildContext context, String url, String title) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _WebViewScreen(url: url, title: title),
    ));
  }

  static String _getInitials(String nombre, String apellidos) {
    final n = nombre.isNotEmpty ? nombre[0].toUpperCase() : '';
    final a = apellidos.isNotEmpty ? apellidos[0].toUpperCase() : '';
    return '$n$a';
  }
}

// ── Loading view ─────────────────────────────────────────────────────────────

class _LoadingView extends StatefulWidget {
  const _LoadingView();

  @override
  State<_LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<_LoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerCtrl;
  late final Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _shimmerAnim = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.base : AppColors.crema;
    final skelBase = isDark
        ? Colors.white.withOpacity(0.07)
        : AppColors.ink.withOpacity(0.07);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AnimatedBuilder(
            animation: _shimmerAnim,
            builder: (context, child) {
              return Column(
                children: [
                  // Avatar skeleton row
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    child: Row(
                      children: [
                        _Skeleton(
                          width: 72,
                          height: 72,
                          borderRadius: 36,
                          baseColor: skelBase,
                          shimmer: _shimmerAnim.value,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Skeleton(
                                width: double.infinity * 0.6,
                                height: 18,
                                baseColor: skelBase,
                                shimmer: _shimmerAnim.value,
                              ),
                              const SizedBox(height: 8),
                              _Skeleton(
                                width: double.infinity,
                                height: 13,
                                baseColor: skelBase,
                                shimmer: _shimmerAnim.value,
                              ),
                              const SizedBox(height: 8),
                              _Skeleton(
                                width: 120,
                                height: 22,
                                borderRadius: 999,
                                baseColor: skelBase,
                                shimmer: _shimmerAnim.value,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _Skeleton(
                    width: 80,
                    height: 12,
                    baseColor: skelBase,
                    shimmer: _shimmerAnim.value,
                  ),
                  const SizedBox(height: 10),
                  _Skeleton(
                    width: double.infinity,
                    height: 160,
                    borderRadius: 16,
                    baseColor: skelBase,
                    shimmer: _shimmerAnim.value,
                  ),
                  const SizedBox(height: 16),
                  _Skeleton(
                    width: 120,
                    height: 12,
                    baseColor: skelBase,
                    shimmer: _shimmerAnim.value,
                  ),
                  const SizedBox(height: 10),
                  _Skeleton(
                    width: double.infinity,
                    height: 120,
                    borderRadius: 16,
                    baseColor: skelBase,
                    shimmer: _shimmerAnim.value,
                  ),
                  const SizedBox(height: 16),
                  _Skeleton(
                    width: 100,
                    height: 12,
                    baseColor: skelBase,
                    shimmer: _shimmerAnim.value,
                  ),
                  const SizedBox(height: 10),
                  _Skeleton(
                    width: double.infinity,
                    height: 90,
                    borderRadius: 16,
                    baseColor: skelBase,
                    shimmer: _shimmerAnim.value,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Not logged in view ────────────────────────────────────────────────────────

class _NotLoggedInView extends StatelessWidget {
  final VoidCallback onLoginTap;
  const _NotLoggedInView({required this.onLoginTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.base : AppColors.crema;
    final surface = isDark ? AppColors.surface : Colors.white;
    final textPrimary = isDark ? AppColors.crema : AppColors.ink;
    final textMuted = isDark
        ? AppColors.crema.withOpacity(0.6)
        : AppColors.inkSoft;
    final textVeryMuted = isDark
        ? AppColors.crema.withOpacity(0.38)
        : AppColors.inkMuted;
    final sectionBorder = isDark ? AppColors.borderDark : AppColors.borderCream;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    // Illustration container
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.atlantico.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        size: 40,
                        color: AppColors.atlantico,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Tu perfil en Dónde Comer Canarias',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.displayHero(
                        size: 24,
                        color: textPrimary,
                      ).copyWith(height: 1.2),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Inicia sesión para guardar favoritos, ver tus valoraciones y personalizar la app.',
                      textAlign: TextAlign.center,
                      style:
                          AppTextStyles.ui(size: 14, color: textMuted)
                              .copyWith(height: 1.6),
                    ),
                    const SizedBox(height: 32),
                    // CTA
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: onLoginTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.atlantico,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Iniciar sesión',
                          style: AppTextStyles.ui(
                            size: 15,
                            weight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '¿Nuevo? Regístrate gratis con Google o Apple',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.ui(size: 12, color: textVeryMuted),
                    ),

                    const SizedBox(height: 48),

                    // Minimal preferences without login
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          'PREFERENCIAS',
                          style: AppTextStyles.ui(
                            size: 10,
                            weight: FontWeight.w700,
                            color: textVeryMuted,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                    _SettingsCard(
                      isDark: isDark,
                      surface: surface,
                      border: sectionBorder,
                      children: [
                        _ThemeRow(isDark: isDark, isLast: true),
                      ],
                    ),

                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Text(
                        'Dónde Comer Canarias v2.4.0 · Hecho en Canarias',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.ui(
                          size: 11,
                          color: isDark
                              ? AppColors.crema.withOpacity(0.2)
                              : AppColors.ink.withOpacity(0.25),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Load error view ───────────────────────────────────────────────────────────
// Shown when storage has a userId but the profile API call failed.
// Keeps the user "logged in" (storage intact) and offers retry, instead of
// kicking them back to the login screen on a transient network error.

class _LoadErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onLogout;
  const _LoadErrorView({required this.onRetry, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.base : AppColors.crema;
    final textPrimary = isDark ? AppColors.crema : AppColors.ink;
    final textMuted =
        isDark ? AppColors.crema.withOpacity(0.6) : AppColors.inkSoft;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.mojo.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  size: 40,
                  color: AppColors.mojo,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No pudimos cargar tu perfil',
                textAlign: TextAlign.center,
                style: AppTextStyles.displayHero(
                  size: 22,
                  color: textPrimary,
                ).copyWith(height: 1.2),
              ),
              const SizedBox(height: 10),
              Text(
                'Comprueba tu conexión e inténtalo de nuevo. Tu sesión sigue activa.',
                textAlign: TextAlign.center,
                style: AppTextStyles.ui(size: 14, color: textMuted)
                    .copyWith(height: 1.6),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.atlantico,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Reintentar',
                    style: AppTextStyles.ui(
                      size: 15,
                      weight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: onLogout,
                child: Text(
                  'Cerrar sesión',
                  style: AppTextStyles.ui(
                    size: 13,
                    weight: FontWeight.w600,
                    color: textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-components ────────────────────────────────────────────────────────────

class _AvatarWithBadge extends StatelessWidget {
  final String initials;
  final bool isDark;
  final VoidCallback onTap;

  const _AvatarWithBadge({
    required this.initials,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.atlantico,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.12)
                    : AppColors.ink.withOpacity(0.08),
                width: 2.5,
              ),
            ),
            child: Center(
              child: Text(
                initials,
                style: AppTextStyles.ui(
                  size: 26,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.atlantico,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.base : AppColors.crema,
                  width: 2,
                ),
              ),
              child: const Icon(Icons.edit_rounded, size: 11, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  final Color? color;

  const _SectionLabel({
    required this.label,
    required this.isDark,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
      child: Text(
        label,
        style: AppTextStyles.ui(
          size: 10,
          weight: FontWeight.w700,
          color: color ??
              (isDark
                  ? AppColors.crema.withOpacity(0.38)
                  : AppColors.ink.withOpacity(0.4)),
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final bool isDark;
  final Color surface;
  final Color border;
  final List<BoxShadow>? shadow;
  final List<Widget> children;

  const _SettingsCard({
    required this.isDark,
    required this.surface,
    required this.border,
    required this.children,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: shadow,
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final bool isDark;
  final Color iconBg;
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color? titleColor;
  final FontWeight? titleWeight;
  final String? subtitle;
  final Color? subtitleColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isLast;
  final bool showChevron;
  final Color? chevronColor;

  const _SettingsRow({
    required this.isDark,
    required this.iconBg,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.titleColor,
    this.titleWeight,
    this.subtitle,
    this.subtitleColor,
    this.trailing,
    this.onTap,
    this.isLast = false,
    this.showChevron = true,
    this.chevronColor,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.crema : AppColors.ink;
    final borderColor =
        isDark ? AppColors.borderDark : AppColors.borderCream;
    final effectiveChevronColor = chevronColor ??
        (isDark
            ? AppColors.crema.withOpacity(0.25)
            : AppColors.ink.withOpacity(0.25));

    return InkWell(
      onTap: onTap,
      splashColor: AppColors.atlantico.withOpacity(0.04),
      highlightColor: AppColors.atlantico.withOpacity(0.04),
      child: Container(
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(color: borderColor, width: 1),
                ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.ui(
                      size: 15,
                      weight: titleWeight ?? FontWeight.w500,
                      color: titleColor ?? textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppTextStyles.ui(
                        size: 12,
                        color: subtitleColor ??
                            (isDark
                                ? AppColors.crema.withOpacity(0.6)
                                : AppColors.inkSoft),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Trailing
            if (trailing != null) trailing!
            else if (onTap != null && showChevron)
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: effectiveChevronColor,
              ),
          ],
        ),
      ),
    );
  }
}

/// Segmented theme control row. Connects to ThemeCubit.
class _ThemeRow extends StatelessWidget {
  final bool isDark;
  final bool isLast;
  const _ThemeRow({required this.isDark, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.crema : AppColors.ink;
    final borderColor =
        isDark ? AppColors.borderDark : AppColors.borderCream;

    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.sol.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.wb_sunny_outlined,
                    size: 18, color: AppColors.sol),
              ),
              const SizedBox(width: 12),
              Text(
                'Tema de la app',
                style: AppTextStyles.ui(
                  size: 15,
                  weight: FontWeight.w500,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ThemeSegmentedControl(isDark: isDark),
        ],
      ),
    );
  }
}

class _ThemeSegmentedControl extends StatelessWidget {
  final bool isDark;
  const _ThemeSegmentedControl({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, mode) {
        return Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.07)
                : AppColors.ink.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              _Segment(
                label: 'Claro',
                active: mode == ThemeMode.light,
                isDark: isDark,
                onTap: () =>
                    context.read<ThemeCubit>().setMode(ThemeMode.light),
              ),
              _Segment(
                label: 'Oscuro',
                active: mode == ThemeMode.dark,
                isDark: isDark,
                onTap: () =>
                    context.read<ThemeCubit>().setMode(ThemeMode.dark),
              ),
              _Segment(
                label: 'Sistema',
                active: mode == ThemeMode.system,
                isDark: isDark,
                onTap: () =>
                    context.read<ThemeCubit>().setMode(ThemeMode.system),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool active;
  final bool isDark;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.active,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeTextColor = isDark ? AppColors.crema : AppColors.ink;
    final inactiveTextColor = isDark
        ? AppColors.crema.withOpacity(0.38)
        : AppColors.ink.withOpacity(0.38);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: const Cubic(0.4, 0, 0.2, 1),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: active
                ? (isDark ? AppColors.elevated : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: active && !isDark
                ? [
                    BoxShadow(
                      color: AppColors.ink.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.ui(
              size: 12,
              weight: active ? FontWeight.w700 : FontWeight.w600,
              color: active ? activeTextColor : inactiveTextColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyBadge extends StatelessWidget {
  final bool isDark;
  const _ReadOnlyBadge({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.07)
            : AppColors.ink.withOpacity(0.06),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Solo lectura',
        style: AppTextStyles.ui(
          size: 10,
          weight: FontWeight.w600,
          color: isDark
              ? AppColors.crema.withOpacity(0.38)
              : AppColors.inkMuted,
        ),
      ),
    );
  }
}

// ── Destructive modal bottom sheet ────────────────────────────────────────────

class _DestructiveModal extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color? titleColor;
  final String body;
  final String? warningText;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _DestructiveModal({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.onConfirm,
    required this.onCancel,
    this.titleColor,
    this.warningText,
  });

  @override
  Widget build(BuildContext context) {
    final sheetBg = isDark ? AppColors.elevated : Colors.white;
    final textPrimary = isDark ? AppColors.crema : AppColors.ink;
    final textMuted = isDark
        ? AppColors.crema.withOpacity(0.6)
        : AppColors.inkSoft;
    final cancelBg = isDark
        ? Colors.white.withOpacity(0.07)
        : AppColors.ink.withOpacity(0.06);

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.2)
                  : AppColors.ink.withOpacity(0.15),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 12),

          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 28, color: iconColor),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.displayHero(
              size: 22,
              color: titleColor ?? textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          // Body
          Text(
            body,
            textAlign: TextAlign.center,
            style: AppTextStyles.ui(size: 14, color: textMuted)
                .copyWith(height: 1.5),
          ),

          // Warning block (for delete account)
          if (warningText != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.mojo.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.mojo.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                warningText!,
                style: AppTextStyles.ui(
                  size: 12,
                  weight: FontWeight.w600,
                  color: AppColors.mojo.withOpacity(0.8),
                ),
              ),
            ),
          ],

          const SizedBox(height: 28),

          // Confirm button (destructive — listed FIRST per design spec)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mojo,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                confirmLabel,
                style: AppTextStyles.ui(
                  size: 15,
                  weight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Cancel button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: onCancel,
              style: ElevatedButton.styleFrom(
                backgroundColor: cancelBg,
                foregroundColor: textPrimary,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Cancelar',
                style: AppTextStyles.ui(
                  size: 15,
                  weight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton shimmer widget ───────────────────────────────────────────────────

class _Skeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Color baseColor;
  final double shimmer; // -1 to 2

  const _Skeleton({
    required this.width,
    required this.height,
    required this.baseColor,
    required this.shimmer,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _ShimmerPainter(
            baseColor: baseColor,
            shimmerPosition: shimmer,
          ),
        ),
      ),
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  final Color baseColor;
  final double shimmerPosition;

  const _ShimmerPainter({
    required this.baseColor,
    required this.shimmerPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = baseColor;
    canvas.drawRect(Offset.zero & size, paint);

    final shimmerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(shimmerPosition - 1, 0),
        end: Alignment(shimmerPosition, 0),
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.18),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, shimmerPaint);
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter oldDelegate) =>
      oldDelegate.shimmerPosition != shimmerPosition;
}

// ── WebView screen ────────────────────────────────────────────────────────────

class _WebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  const _WebViewScreen({required this.url, required this.title});

  @override
  State<_WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<_WebViewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;

    return Scaffold(
      backgroundColor: brand.base,
      appBar: AppBar(
        backgroundColor: brand.base,
        title: Text(
          widget.title,
          style: AppTextStyles.ui(
            size: 16,
            weight: FontWeight.w600,
            color: brand.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: brand.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
