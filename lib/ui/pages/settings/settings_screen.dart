import 'dart:async';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/account/account_cubit.dart';
import 'package:guachinches/data/cubit/theme/theme_cubit.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/data/cubit/user/user_state.dart';
import 'package:guachinches/data/local/local_repository.dart';
import 'package:guachinches/data/model/user_info.dart';
import 'package:guachinches/data/newsletter/newsletter_consent_service.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/pages/discover/discover_screen.dart';
import 'package:guachinches/ui/pages/favoritos/favoritos.dart';
import 'package:guachinches/ui/pages/listas/listas_screen.dart';
import 'package:guachinches/ui/pages/login/login_logic.dart';
import 'package:guachinches/ui/pages/login/login_presenter.dart';
import 'package:guachinches/ui/pages/login/login_sheet.dart';
import 'package:guachinches/ui/pages/map/map_search.dart';
import 'package:guachinches/ui/pages/new_home/new_home_screen.dart';
import 'package:guachinches/ui/pages/new_home/new_home_tab_scaffold.dart';
import 'package:guachinches/ui/pages/onboarding_flow/onboarding_flow_screen.dart';
import 'package:guachinches/ui/pages/profile/account_deletion_store.dart';
import 'package:guachinches/ui/pages/profile/account_management_screen.dart';
import 'package:guachinches/ui/pages/settings/legal_webview_screen.dart';
import 'package:guachinches/ui/pages/settings/perfil_logic.dart';
import 'package:guachinches/ui/pages/settings/session_profile.dart';
import 'package:guachinches/ui/pages/settings/settings_presenter.dart';
import 'package:guachinches/ui/pages/settings/widgets/perfil_auth_buttons.dart';
import 'package:guachinches/ui/pages/settings/widgets/perfil_widgets.dart';
import 'package:guachinches/ui/pages/valoraciones/valoraciones.dart';
import 'package:guachinches/ui/theme/gm_favorites.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';
import 'package:guachinches/utils/app_version.dart';
import 'package:http/http.dart';

/// Pestaña Perfil (tablero TabPerfil). Raíz de la pestaña 4: sin «Volver».
///
/// Con sesión: identidad (nombre del perfil, email y proveedor guardados al
/// entrar), «Tu actividad», «Preferencias», «Legal» y «Cuenta». Sin sesión:
/// entrar con Apple / Google / email y lo que se puede hacer sin cuenta.
/// Si el perfil no carga, solo falla su fila (la sesión sigue abierta).
class SettingsScreen extends StatefulWidget {
  /// Inyectables para tests; por defecto, los de producción.
  final RemoteRepository? repository;
  final GmFavorites? favorites;
  final LocalRepository? favoritesStore;

  const SettingsScreen(
      {super.key, this.repository, this.favorites, this.favoritesStore});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

/// Las 5 pantallas canónicas de los tabs (EXPLORA · LISTAS · MAPA · VISITAS ·
/// PERFIL). Única fuente: arranque, onboarding y cerrar sesión. Perfil es
/// siempre [SettingsScreen] (con sesión o en modo invitado), nunca un login.
List<Widget> buildMainTabScreens() => [
      const NewHomeScreen(),
      const ListasScreen(),
      MapSearch(),
      const DiscoverScreen(),
      const SettingsScreen(),
    ];

/// Vuelve a la pestaña Explora (CTA «Explorar sitios» de los vacíos).
void perfilGoToExplore(BuildContext context) {
  GlobalMethods().removePagesAndGoToNewScreen(
    context,
    NewHomeTabScaffold(screens: buildMainTabScreens(), initialIndex: 0),
  );
}

enum _Status { checking, guest, loading, error }

class _SettingsScreenState extends State<SettingsScreen>
    implements SettingsView {
  late final RemoteRepository _repo =
      widget.repository ?? HttpRemoteRepository(Client());
  late final GmFavorites _favorites = widget.favorites ?? GmFavorites.instance;
  final _storage = const FlutterSecureStorage();
  final _sessionStore = const SessionProfileStore();
  final _deletionStore = const AccountDeletionStore();

  late final SettingsPresenter _presenter;
  late final LoginPresenter _loginPresenter;
  bool _depsInitialized = false;

  _Status _status = _Status.checking;
  SessionProfile _session = SessionProfile.empty;
  String? _userId;
  DateTime? _deletionAt;
  PerfilAuthKind? _authLoading;
  bool _scrolled = false;

  PerfilToast? _toast;
  Timer? _toastTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Se dispara más de una vez (tema, locale…): se inicializa una sola.
    if (_depsInitialized) return;
    _depsInitialized = true;
    final userCubit = context.read<UserCubit>();
    _presenter = SettingsPresenter(this, userCubit);
    _loginPresenter = LoginPresenter(_repo, userCubit);
    _favorites.ensureLoaded();
    _load();
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    await _readLocal();
    if (!mounted) return;
    if (_userId == null && context.read<UserCubit>().state is! UserLoaded) {
      setState(() => _status = _Status.guest);
      return;
    }
    setState(() => _status = _Status.loading);
    await _presenter.loadUser();
  }

  /// Sesión guardada en el móvil: id, email/proveedor y fecha de borrado.
  Future<void> _readLocal() async {
    String? id;
    try {
      id = await _storage.read(key: 'userId');
    } catch (e) {
      AppLogger.warn('perfil', 'no se pudo leer la sesión: $e');
    }
    final session = await _sessionStore.read();
    final deletion =
        (id == null || id.isEmpty) ? null : await _deletionStore.read(id);
    if (!mounted) return;
    setState(() {
      _userId = (id == null || id.isEmpty) ? null : id;
      _session = session;
      _deletionAt = deletion;
    });
  }

  // ── SettingsView ───────────────────────────────────────────────────────

  @override
  void onUserNotLoggedIn() {
    if (mounted) setState(() => _status = _Status.guest);
  }

  @override
  void onLoadError() {
    if (mounted) setState(() => _status = _Status.error);
  }

  @override
  void onLoggedOut() {
    if (!mounted) return;
    // Cerrar sesión NO expulsa de la app: vuelve al Perfil sin sesión.
    GlobalMethods().removePagesAndGoToNewScreen(
      context,
      NewHomeTabScaffold(screens: buildMainTabScreens(), initialIndex: 4),
    );
  }

  // ── Entrar desde el Perfil sin sesión ─────────────────────────────────

  /// Apple / Google en línea (mismo presenter y mismos pasos que el acceso
  /// único). Al entrar el Perfil se recarga en su sitio: no se reconstruyen
  /// las pestañas.
  Future<void> _signIn(PerfilAuthKind kind) async {
    if (_authLoading != null) return;
    HapticFeedback.lightImpact();
    setState(() => _authLoading = kind);
    final method =
        kind == PerfilAuthKind.apple ? LoginMethod.apple : LoginMethod.google;
    final outcome = await _loginPresenter.signIn(method);
    if (!mounted) return;
    final session = outcome.session;
    if (session == null) {
      setState(() => _authLoading = null);
      final copy =
          loginErrorCopy(method, outcome.failure ?? LoginFailure.unknown);
      if (copy != null) {
        HapticFeedback.mediumImpact();
        _showToast(PerfilToast(
          identifier: 'perfil-login-error',
          message: copy.$1,
        ));
      }
      return;
    }
    final stay = await completeLogin(context, _loginPresenter, session);
    if (!mounted) return;
    setState(() => _authLoading = null);
    if (stay) {
      await askNewsletterOnce(context, session.userId,
          service: NewsletterConsentService(_repo));
    }
    if (mounted) await _load();
  }

  /// «Entrar con email y contraseña»: el acceso único en su paso de email.
  Future<void> _openEmailLogin() async {
    final ok = await showLoginSheet(
      context,
      reason: LoginReason.profile,
      startOnEmail: true,
      auth: _loginPresenter,
      newsletter: NewsletterConsentService(_repo),
    );
    if (ok && mounted) await _load();
  }

  Future<void> _confirmLogout() async {
    HapticFeedback.mediumImpact();
    final apple = defaultTargetPlatform == TargetPlatform.iOS;
    final ok = await showPerfilSheet<bool>(
      context,
      builder: (ctx) {
        final gm = GmColors.of(ctx);
        return PerfilConfirmSheet(
          identifier: 'perfil-logout-sheet',
          icon: PerfilIcons.logout,
          iconBackground: gm.fill,
          iconColor: gm.label,
          title: '¿Cerrar sesión?',
          text: perfilLogoutText(apple: apple),
          actions: [
            PerfilWideButton(
              label: 'Cerrar sesión',
              identifier: 'perfil-logout-confirm-button',
              onTap: () => Navigator.of(ctx).pop(true),
            ),
            PerfilWideButton(
              label: 'Cancelar',
              secondary: true,
              identifier: 'perfil-logout-cancel-button',
              onTap: () => Navigator.of(ctx).pop(false),
            ),
          ],
        );
      },
    );
    if (ok == true && mounted) await _presenter.logOut();
  }

  // ── Aviso flotante ─────────────────────────────────────────────────────

  void _showToast(PerfilToast toast, {bool sticky = false}) {
    _toastTimer?.cancel();
    setState(() => _toast = toast);
    if (!sticky) {
      _toastTimer = Timer(const Duration(seconds: 4), _hideToast);
    }
  }

  void _hideToast() {
    _toastTimer?.cancel();
    if (mounted && _toast != null) setState(() => _toast = null);
  }

  // ── Navegación ─────────────────────────────────────────────────────────

  Future<void> _push(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  Future<void> _openAccount(String userId) async {
    await _push(BlocProvider(
      create: (_) => AccountCubit(repo: _repo, userId: userId),
      child: const AccountManagementScreen(),
    ));
    final at = await _deletionStore.read(userId);
    if (mounted) setState(() => _deletionAt = at);
  }

  void _openLegal(String url, String title) =>
      _push(LegalWebViewScreen(url: url, title: title));

  void _openSaved() => _push(FavoritosPage(
        favorites: widget.favorites,
        localRepository: widget.favoritesStore,
        repository: widget.repository,
      ));

  void _openReviews() => _push(ValoracionesPage(repository: widget.repository));

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return BlocConsumer<UserCubit, UserState>(
      listener: (context, state) {
        if (state is UserLoaded) {
          _sessionStore.saveName(state.user.nombre);
          if (_userId == null && state.user.id.isNotEmpty) {
            setState(() => _userId = state.user.id);
          }
        }
      },
      builder: (context, state) {
        final user = state is UserLoaded ? state.user : null;
        final Widget content;
        if (user != null) {
          content = _loggedIn(context, user: user, status: null);
        } else {
          switch (_status) {
            case _Status.checking:
              content = _scroll(context, [const PerfilLargeTitle('Perfil')]);
            case _Status.guest:
              content = _guest(context);
            case _Status.loading:
            case _Status.error:
              content = _loggedIn(context, user: null, status: _status);
          }
        }
        return Scaffold(
          backgroundColor: gm.canvas,
          body: Stack(
            children: [
              Positioned.fill(child: content),
              GmTopScrim(visible: _scrolled),
              Positioned(
                left: GmSpace.gutter,
                right: GmSpace.gutter,
                bottom: MediaQuery.paddingOf(context).bottom + 96,
                child: PerfilToastSlot(toast: _toast),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _scroll(BuildContext context, List<Widget> children) {
    final media = MediaQuery.of(context);
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
          top: media.padding.top + 10,
          // Hueco para la barra de pestañas flotante.
          bottom: media.padding.bottom + 120,
        ),
        children: children,
      ),
    );
  }

  // ── Con sesión ─────────────────────────────────────────────────────────

  /// [status] null = perfil cargado; loading / error = parcial.
  Widget _loggedIn(BuildContext context,
      {required UserInfo? user, required _Status? status}) {
    final gm = GmColors.of(context);
    final name = perfilDisplayName(user?.nombre ?? '', _session.name);
    final email = _session.email;
    final userId = user?.id.isNotEmpty == true ? user!.id : _userId;
    final knowsIdentity = name.isNotEmpty || (email?.isNotEmpty ?? false);
    final deletionActive = perfilDeletionActive(_deletionAt, DateTime.now());

    return _scroll(context, [
      const GmRise(trigger: GmTrigger.mount, child: PerfilLargeTitle('Perfil')),
      const SizedBox(height: 14),
      GmRise(
        index: 1,
        trigger: GmTrigger.mount,
        child: status == _Status.loading && !knowsIdentity
            ? const _IdentitySkeleton()
            : _IdentityCard(
                name: name,
                email: email,
                provider: _session.provider,
              ),
      ),
      const SizedBox(height: 8),
      _activityGroup(context, user: user, status: status),
      PerfilGroup(
        caption: 'Preferencias',
        riseIndex: 3,
        rows: [
          if (userId != null)
            _NewsletterRow(key: ValueKey(userId), userId: userId, repo: _repo),
          const _ThemeRow(),
        ],
      ),
      _legalGroup(4),
      PerfilGroup(
        caption: 'Cuenta',
        riseIndex: 5,
        rows: [
          PerfilRow(
            identifier: 'settings-account-management-row',
            title: 'Mis datos',
            subtitle: deletionActive
                ? 'Tu cuenta se eliminará el ${perfilDateShort(_deletionAt!)}'
                : 'Descargar tus datos o eliminar la cuenta',
            leading:
                PerfilIconTile(icon: PerfilIcons.person, background: gm.fill),
            onTap: userId == null ? null : () => _openAccount(userId),
          ),
          PerfilRow(
            identifier: 'settings-logout-row',
            title: 'Cerrar sesión',
            chevron: false,
            leading:
                PerfilIconTile(icon: PerfilIcons.logout, background: gm.fill),
            onTap: _confirmLogout,
          ),
        ],
      ),
      if (kDebugMode) _devGroup(context),
      PerfilFooter(versionLabel: perfilVersionLabel(currentAppVersion())),
    ]);
  }

  Widget _activityGroup(BuildContext context,
      {required UserInfo? user, required _Status? status}) {
    final gm = GmColors.of(context);
    final List<Widget> rows;
    if (status == _Status.loading) {
      rows = const [_SkeletonRow(0.38, 0.52), _SkeletonRow(0.32, 0.58)];
    } else {
      rows = [
        if (status == _Status.error)
          _ProfileErrorRow(onRetry: () {
            setState(() => _status = _Status.loading);
            _presenter.loadUser();
          })
        else
          PerfilRow(
            identifier: 'settings-my-ratings-row',
            title: 'Mis reseñas',
            subtitle: perfilReviewsSummary(
              user?.valoraciones.length ?? 0,
              perfilAverage((user?.valoraciones ?? const <Valoraciones>[])
                  .map((v) => v.rating)),
            ),
            leading: PerfilIconTile(
              background: gm.warnSoft,
              child: GmIcon(GmIcons.star, size: 18, color: GmColors.star),
            ),
            onTap: _openReviews,
          ),
        _savedRow(context),
      ];
    }
    return Semantics(
      identifier: status == _Status.loading ? 'perfil-activity-loading' : null,
      label: status == _Status.loading ? 'Cargando tu actividad' : null,
      child: PerfilGroup(caption: 'Tu actividad', riseIndex: 2, rows: rows),
    );
  }

  Widget _savedRow(BuildContext context) {
    final gm = GmColors.of(context);
    return ValueListenableBuilder<Set<String>>(
      valueListenable: _favorites,
      builder: (_, ids, __) => PerfilRow(
        identifier: 'settings-favorites-row',
        title: 'Guardados',
        subtitle: perfilSavedSummary(ids.length),
        leading: PerfilIconTile(
          background: gm.fill,
          child: GmIcon(GmIcons.heart, size: 18, color: GmColors.heart),
        ),
        onTap: _openSaved,
      ),
    );
  }

  Widget _legalGroup(int rise) {
    final gm = GmColors.of(context);
    return PerfilGroup(
      caption: 'Legal',
      riseIndex: rise,
      rows: [
        PerfilRow(
          identifier: 'settings-terms-row',
          title: 'Términos de uso',
          leading: PerfilIconTile(icon: PerfilIcons.doc, background: gm.fill),
          onTap: () => _openLegal(kPerfilTermsUrl, 'Términos de uso'),
        ),
        PerfilRow(
          identifier: 'settings-privacy-row',
          title: 'Política de privacidad',
          leading: PerfilIconTile(icon: PerfilIcons.lock, background: gm.fill),
          onTap: () => _openLegal(kPerfilPrivacyUrl, 'Política de privacidad'),
        ),
      ],
    );
  }

  /// Solo en debug: no aparece en release/TestFlight/App Store.
  Widget _devGroup(BuildContext context) {
    final gm = GmColors.of(context);
    return PerfilGroup(
      caption: 'Desarrollo',
      riseIndex: 6,
      rows: [
        PerfilRow(
          identifier: 'settings-dev-onboarding-row',
          title: 'Lanzar onboarding',
          subtitle: 'Solo en desarrollo',
          leading:
              PerfilIconTile(icon: PerfilIcons.restart, background: gm.fill),
          onTap: () => _push(const OnboardingFlow()),
        ),
      ],
    );
  }

  // ── Sin sesión ─────────────────────────────────────────────────────────

  Widget _guest(BuildContext context) {
    final gm = GmColors.of(context);
    final ios = defaultTargetPlatform == TargetPlatform.iOS;
    final busy = _authLoading != null;
    return _scroll(context, [
      const GmRise(trigger: GmTrigger.mount, child: PerfilLargeTitle('Perfil')),
      const SizedBox(height: 14),
      GmRise(
        index: 1,
        trigger: GmTrigger.mount,
        child: Semantics(
          identifier: 'perfil-guest-card',
          container: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: GmSpace.gutter),
            child: GmCard(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
              child: Column(
                children: [
                  ExcludeSemantics(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration:
                          BoxDecoration(color: gm.fill, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: GmIcon(PerfilIcons.person,
                          size: 30, color: gm.label2),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Semantics(
                    header: true,
                    child: Text('Tu perfil en Dónde Comer Canarias',
                        textAlign: TextAlign.center,
                        style: GmText.title2(color: gm.label)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Entra para escribir reseñas y tenerlas todas aquí. '
                    'Para guardar sitios no hace falta cuenta.',
                    textAlign: TextAlign.center,
                    style:
                        GmText.body(color: gm.label2).copyWith(height: 21 / 15),
                  ),
                  const SizedBox(height: 16),
                  if (ios) ...[
                    PerfilAuthButton(
                      kind: PerfilAuthKind.apple,
                      identifier: 'perfil-login-apple',
                      loading: _authLoading == PerfilAuthKind.apple,
                      onTap: busy ? null : () => _signIn(PerfilAuthKind.apple),
                    ),
                    const SizedBox(height: 10),
                  ],
                  PerfilAuthButton(
                    kind: PerfilAuthKind.google,
                    identifier: 'perfil-login-google',
                    loading: _authLoading == PerfilAuthKind.google,
                    onTap: busy ? null : () => _signIn(PerfilAuthKind.google),
                  ),
                  const SizedBox(height: 10),
                  PerfilWideButton(
                    label: 'Entrar con email y contraseña',
                    secondary: true,
                    identifier: 'perfil-login-email',
                    onTap: busy ? null : _openEmailLogin,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      PerfilGroup(
        caption: 'Sin cuenta también puedes',
        riseIndex: 2,
        rows: [_savedRow(context)],
      ),
      const PerfilGroup(
        caption: 'Preferencias',
        riseIndex: 3,
        rows: [_ThemeRow()],
      ),
      _legalGroup(4),
      PerfilFooter(versionLabel: perfilVersionLabel(currentAppVersion())),
    ]);
  }
}

// ── Identidad ───────────────────────────────────────────────────────────────

class _IdentityCard extends StatelessWidget {
  final String name;
  final String? email;
  final PerfilProvider? provider;

  const _IdentityCard({required this.name, this.email, this.provider});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final initial = perfilInitial(name, email);
    final hasEmail = email != null && email!.trim().isNotEmpty;
    return Semantics(
      identifier: 'perfil-identity-card',
      container: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: GmSpace.gutter),
        child: GmCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    ExcludeSemantics(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                            color: gm.avAbg, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: initial.isEmpty
                            ? GmIcon(PerfilIcons.person,
                                size: 28, color: gm.avAink)
                            : Text(
                                initial,
                                style: TextStyle(
                                  fontSize: 26,
                                  height: 30 / 26,
                                  fontWeight: FontWeight.w800,
                                  color: gm.avAink,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isEmpty ? 'Tu cuenta' : name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GmText.title2(color: gm.label),
                          ),
                          if (hasEmail)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                email!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GmText.body(color: gm.label2),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (provider != null) ...[
                Container(height: 1, color: gm.sep),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Row(
                    children: [
                      _providerIcon(gm, provider!),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(perfilProviderLine(provider!),
                            style: GmText.meta(color: gm.label2)),
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

  static Widget _providerIcon(GmColors gm, PerfilProvider p) => switch (p) {
        PerfilProvider.google =>
          const PerfilLogo(PerfilIcons.google, width: 15, height: 15),
        PerfilProvider.apple => PerfilLogo(PerfilIcons.apple,
            width: 13, height: 15, color: gm.label2),
        PerfilProvider.email =>
          GmIcon(PerfilIcons.mail, size: 15, color: gm.label2),
      };
}

class _IdentitySkeleton extends StatelessWidget {
  const _IdentitySkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'perfil-identity-loading',
      label: 'Cargando tu perfil',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: GmSpace.gutter),
          child: GmCard(
            padding: const EdgeInsets.all(14),
            child: LayoutBuilder(
              builder: (_, c) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const PerfilSkeleton(width: 60, height: 60, radius: 30),
                      const SizedBox(width: 14),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (_, cc) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PerfilSkeleton(
                                  width: cc.maxWidth * 0.6, height: 20),
                              const SizedBox(height: 9),
                              PerfilSkeleton(
                                  width: cc.maxWidth * 0.9, height: 14),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  PerfilSkeleton(width: c.maxWidth * 0.84, height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Filas especiales ────────────────────────────────────────────────────────

class _SkeletonRow extends StatelessWidget {
  final double w1;
  final double w2;
  const _SkeletonRow(this.w1, this.w2);

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 58),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 16, 8),
            child: Row(
              children: [
                const PerfilSkeleton(width: 30, height: 30, radius: 9),
                const SizedBox(width: 12),
                Expanded(
                  child: LayoutBuilder(
                    builder: (_, c) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PerfilSkeleton(width: c.maxWidth * w1, height: 15),
                        const SizedBox(height: 7),
                        PerfilSkeleton(width: c.maxWidth * w2, height: 11),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

/// Error parcial: solo la fila del perfil, en ámbar suave, con «Reintentar».
class _ProfileErrorRow extends StatelessWidget {
  final VoidCallback onRetry;
  const _ProfileErrorRow({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: 'perfil-profile-error',
      container: true,
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PerfilIconTile(
                icon: PerfilIcons.help,
                background: gm.warnSoft,
                color: gm.warnText),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No pudimos cargar tu perfil',
                    style: GmText.body17(color: gm.label, w: FontWeight.w600)
                        .copyWith(height: 22 / 17),
                  ),
                  Text('Revisa tu conexión. Tu sesión sigue abierta.',
                      style: GmText.meta(color: gm.label2)),
                  const SizedBox(height: 8),
                  PerfilSoftButton(
                    label: 'Reintentar',
                    identifier: 'perfil-retry-button',
                    height: 36,
                    fontSize: 14,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    onTap: onRetry,
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

/// Newsletter (RGPD). El interruptor cambia al instante; `submit`
/// sincroniza con el backend. Darse de baja es tan fácil como suscribirse.
class _NewsletterRow extends StatefulWidget {
  final String userId;
  final RemoteRepository repo;

  const _NewsletterRow({super.key, required this.userId, required this.repo});

  @override
  State<_NewsletterRow> createState() => _NewsletterRowState();
}

class _NewsletterRowState extends State<_NewsletterRow> {
  late final NewsletterConsentService _consent =
      NewsletterConsentService(widget.repo);
  bool _granted = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Estado real del servidor (con el local de respaldo si no hay red).
    _consent.syncedGranted(widget.userId).then((v) {
      if (mounted) setState(() => _granted = v);
    });
  }

  Future<void> _set(bool value) async {
    if (_busy) return;
    HapticFeedback.selectionClick();
    setState(() {
      _busy = true;
      _granted = value;
    });
    await _consent.submit(
      userId: widget.userId,
      granted: value,
      source: 'settings',
    );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: 'settings-newsletter-row',
      toggled: _granted,
      child: PerfilRow(
        title: 'Newsletter',
        subtitle: _granted
            ? 'Recibes aperturas y rutas por email'
            : 'Recibe aperturas y rutas por email',
        chevron: false,
        leading: PerfilIconTile(
            icon: PerfilIcons.mail,
            background: gm.accentSoft,
            color: gm.accent),
        trailing: ExcludeSemantics(
          child: PerfilSwitch(
            value: _granted,
            onChanged: _busy ? null : _set,
          ),
        ),
        onTap: _busy ? null : () => _set(!_granted),
      ),
    );
  }
}

/// Tema: Claro · Oscuro · Sistema (ThemeCubit).
class _ThemeRow extends StatelessWidget {
  const _ThemeRow();

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: 'settings-theme-row',
      container: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                PerfilIconTile(icon: PerfilIcons.moon, background: gm.fill),
                const SizedBox(width: 12),
                Text(
                  'Tema',
                  style: GmText.body17(color: gm.label, w: FontWeight.w500)
                      .copyWith(height: 22 / 17, letterSpacing: -0.3),
                ),
              ],
            ),
            const SizedBox(height: 10),
            BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (context, mode) => PerfilSegmented<ThemeMode>(
                identifierPrefix: 'settings-theme',
                options: const [
                  (ThemeMode.light, 'Claro'),
                  (ThemeMode.dark, 'Oscuro'),
                  (ThemeMode.system, 'Sistema'),
                ],
                value: mode,
                onChanged: (m) {
                  HapticFeedback.selectionClick();
                  context.read<ThemeCubit>().setMode(m);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
