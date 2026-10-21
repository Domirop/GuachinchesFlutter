import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/data/newsletter/newsletter_consent_service.dart';
import 'package:guachinches/ui/pages/login/login_logic.dart';
import 'package:guachinches/ui/pages/login/login_presenter.dart';
import 'package:guachinches/ui/pages/login/widgets/login_widgets.dart';
import 'package:guachinches/ui/pages/newsletter/newsletter_consent_sheet.dart';
import 'package:guachinches/ui/pages/restaurant_detail/reviews_logic.dart'
    show kReviewSupportEmail;
import 'package:guachinches/ui/pages/restaurant_detail/widgets/review_moderation_sheets.dart'
    show showGmToast;
import 'package:guachinches/ui/pages/settings/legal_webview_screen.dart';
import 'package:guachinches/ui/pages/settings/widgets/perfil_widgets.dart'
    show PerfilIcons, PerfilSoftButton;
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';
import 'package:http/http.dart' show Client;
import 'package:url_launcher/url_launcher.dart';

/// Abre el acceso único (Apple · Google · email) y devuelve si el usuario
/// ha entrado. Al entrar: aviso de eliminación pendiente (si toca), sesión
/// guardada, `UserCubit` refrescado, se cierra y vuelve a donde estaba; la
/// primera vez pregunta por la newsletter.
///
/// Se presenta como ruta a pantalla completa que sube desde abajo (no como
/// hoja con asa): la dirección A pinta el lienzo arena → mar con las olas en
/// el borde inferior, que necesita toda la altura, y con teclado el
/// `Scaffold` + scroll se comporta mejor que una hoja arrastrable con campos.
///
/// [startOnEmail] abre directamente el paso «Entrar con email».
Future<bool> showLoginSheet(
  BuildContext context, {
  LoginReason? reason,
  bool startOnEmail = false,
  LoginAuth? auth,
  NewsletterConsentService? newsletter,
}) async {
  final nav = Navigator.of(context, rootNavigator: true);
  final effectiveAuth = auth ??
      LoginPresenter(HttpRemoteRepository(Client()), context.read<UserCubit>());
  final reduced = GmMotion.reduced(context);
  final session = await nav.push<LoginSession>(_LoginRoute(
    reduced: reduced,
    builder: (_) => LoginSheet(
      reason: reason,
      startOnEmail: startOnEmail,
      auth: effectiveAuth,
    ),
  ));
  if (session == null) return false;
  if (nav.mounted) {
    await askNewsletterOnce(nav.context, session.userId, service: newsletter);
  }
  return true;
}

/// Tras entrar fuera de la hoja (botones del Perfil sin sesión o del
/// onboarding): si la cuenta está pendiente de eliminación, pregunta si se
/// conserva. Devuelve `false` si el usuario prefiere cerrar sesión.
Future<bool> completeLogin(
    BuildContext context, LoginAuth auth, LoginSession session) async {
  if (!session.deletionPending) return true;
  final keep = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color(0x57000000),
    builder: (_) => LoginDeletionDialog(at: session.deletionAt),
  );
  if (keep == true) {
    final ok = await auth.keepAccount(session.userId);
    if (!ok && context.mounted) {
      // La sesión ya está abierta: desde Perfil › Mis datos puede reintentar.
      showGmToast(context, 'No se pudo cancelar la eliminación', ok: false);
    }
    return true;
  }
  await auth.signOut();
  return false;
}

/// Consentimiento de newsletter (RGPD) una sola vez tras entrar.
Future<void> askNewsletterOnce(BuildContext context, String userId,
    {NewsletterConsentService? service}) async {
  if (userId.isEmpty) return;
  final consent = service ?? NewsletterConsentService(HttpRemoteRepository(Client()));
  try {
    if (await consent.hasBeenAsked()) return;
  } catch (e) {
    AppLogger.warn('login', 'newsletter: $e');
    return;
  }
  if (!context.mounted) return;
  await showNewsletterConsentSheet(
    context,
    userId: userId,
    service: consent,
    source: 'onboarding',
  );
}

/// Ruta a pantalla completa que sube desde abajo (fundido con «reducir
/// movimiento»).
class _LoginRoute extends PageRouteBuilder<LoginSession> {
  _LoginRoute({required WidgetBuilder builder, required bool reduced})
      : super(
          fullscreenDialog: true,
          transitionDuration: Duration(milliseconds: reduced ? 0 : 420),
          reverseTransitionDuration: Duration(milliseconds: reduced ? 0 : 300),
          pageBuilder: (ctx, _, __) => builder(ctx),
          transitionsBuilder: (ctx, animation, _, child) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: GmMotion.settle,
              reverseCurve: Curves.easeInCubic,
            )),
            child: child,
          ),
        );
}

class _LoginError {
  final LoginMethod method;
  final LoginFailure failure;
  final LoginStep step;
  const _LoginError(this.method, this.failure, this.step);
}

/// Pantalla del acceso. Pasos: inicio (proveedores) · email · recuperar.
/// Estados: conectando (botón con indicador), error por proveedor, error de
/// email en línea. Cierra con la [LoginSession] al entrar.
class LoginSheet extends StatefulWidget {
  final LoginReason? reason;
  final bool startOnEmail;
  final LoginAuth auth;

  const LoginSheet({
    super.key,
    required this.auth,
    this.reason,
    this.startOnEmail = false,
  });

  @override
  State<LoginSheet> createState() => _LoginSheetState();
}

class _LoginSheetState extends State<LoginSheet> {
  late LoginStep _step = widget.startOnEmail ? LoginStep.email : LoginStep.main;
  LoginMethod? _busy;
  _LoginError? _error;
  bool _obscure = true;

  final _email = TextEditingController();
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool get _apple => widget.auth.appleAvailable;

  @override
  void initState() {
    super.initState();
    if (widget.startOnEmail) _focusEmailSoon();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ── Navegación entre pasos ──────────────────────────────────────────────

  void _goTo(LoginStep step) {
    if (_busy != null) return;
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();
    setState(() {
      _step = step;
      _error = null;
    });
    if (step == LoginStep.email) _focusEmailSoon();
  }

  void _focusEmailSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _step != LoginStep.email) return;
      (_email.text.isEmpty ? _emailFocus : _passwordFocus).requestFocus();
    });
  }

  void _close() {
    HapticFeedback.lightImpact();
    Navigator.of(context).maybePop();
  }

  void _back() => _goTo(
      _step == LoginStep.recover ? LoginStep.email : LoginStep.main);

  // ── Entrar ──────────────────────────────────────────────────────────────

  Future<void> _social(LoginMethod method) async {
    if (_busy != null) return;
    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = method;
      _error = null;
    });
    final outcome = await widget.auth.signIn(method);
    if (!mounted) return;
    await _handle(method, outcome);
  }

  Future<void> _submitEmail() async {
    if (_busy != null || !loginCanSubmit(_email.text, _password.text)) return;
    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = LoginMethod.email;
      _error = null;
    });
    final outcome = await widget.auth.signIn(
      LoginMethod.email,
      email: _email.text.trim(),
      password: _password.text,
    );
    if (!mounted) return;
    if (outcome.ok) TextInput.finishAutofillContext();
    await _handle(LoginMethod.email, outcome);
  }

  Future<void> _handle(LoginMethod method, LoginOutcome outcome) async {
    final session = outcome.session;
    if (session != null) {
      final stay = await completeLogin(context, widget.auth, session);
      if (!mounted) return;
      if (stay) {
        Navigator.of(context).pop(session);
      } else {
        setState(() => _busy = null);
      }
      return;
    }
    final failure = outcome.failure ?? LoginFailure.unknown;
    if (failure != LoginFailure.cancelled) HapticFeedback.mediumImpact();
    setState(() {
      _busy = null;
      _error = failure == LoginFailure.cancelled
          ? null
          : _LoginError(method, failure, _step);
    });
  }

  void _clearEmailError() {
    if (_error?.method == LoginMethod.email) {
      setState(() => _error = null);
    } else {
      setState(() {}); // recalcula «Iniciar sesión»
    }
  }

  // ── Enlaces ─────────────────────────────────────────────────────────────

  void _openLegal(String url, String title) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => LegalWebViewScreen(url: url, title: title),
    ));
  }

  Future<void> _writeSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: kReviewSupportEmail,
      query: 'subject=${Uri.encodeComponent(kLoginSupportSubject)}',
    );
    try {
      final ok = await launchUrl(uri);
      if (!ok && mounted) {
        showGmToast(context, 'Escríbenos a $kReviewSupportEmail', ok: false);
      }
    } catch (e, st) {
      AppLogger.error('login', e, st);
      if (mounted) {
        showGmToast(context, 'Escríbenos a $kReviewSupportEmail', ok: false);
      }
    }
  }

  // ── Construcción ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final reduced = GmMotion.reduced(context);
    return PopScope(
      canPop: _step == LoginStep.main,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: gm.isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: Semantics(
          identifier: 'login-sheet',
          container: true,
          explicitChildNodes: true,
          child: Scaffold(
            backgroundColor: gm.canvas,
            // El teclado se compensa en el scroll: así el fondo (y las olas)
            // no se recolocan al abrirlo.
            resizeToAvoidBottomInset: false,
            body: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusScope.of(context).unfocus(),
              child: Stack(
                children: [
                  const Positioned.fill(child: LoginArenaBackground()),
                  SafeArea(
                    bottom: false,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: AnimatedSwitcher(
                            duration:
                                Duration(milliseconds: reduced ? 0 : 280),
                            switchInCurve: GmMotion.settle,
                            switchOutCurve: Curves.easeOut,
                            layoutBuilder: (current, previous) => Stack(
                              fit: StackFit.expand,
                              children: [...previous, if (current != null) current],
                            ),
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.03),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            ),
                            child: KeyedSubtree(
                              key: ValueKey(_step),
                              child: _scroll(context, _stepBody(context)),
                            ),
                          ),
                        ),
                        _topBar(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _scroll(BuildContext context, Widget child) {
    final media = MediaQuery.of(context);
    final main = _step == LoginStep.main;
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.only(
        top: main ? 49 : 64,
        // Hueco para las olas (inicio) o para el teclado.
        bottom: media.viewInsets.bottom + media.padding.bottom + (main ? 110 : 32),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: child,
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    final gm = GmColors.of(context);
    final main = _step == LoginStep.main;
    final title = switch (_step) {
      LoginStep.main => null,
      LoginStep.email => kLoginEmailTitle,
      LoginStep.recover => kLoginRecoverTitle,
    };
    return Positioned(
      top: 9,
      left: 16,
      right: 16,
      child: SizedBox(
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 52),
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GmText.guideTitle(color: gm.label),
                  ),
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: main
                  ? GmToolbarButton(
                      icon: GmIcons.close,
                      light: true,
                      iconSize: 18,
                      identifier: 'login-close-button',
                      semanticLabel: 'Cerrar',
                      onTap: _close,
                    )
                  : GmToolbarButton(
                      icon: GmIcons.chevronLeft,
                      light: true,
                      iconSize: 20,
                      identifier: 'login-back-button',
                      semanticLabel: 'Volver',
                      onTap: _back,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepBody(BuildContext context) => switch (_step) {
        LoginStep.main => _mainStep(context),
        LoginStep.email => _emailStep(context),
        LoginStep.recover => _recoverStep(context),
      };

  (String, String)? _errorFor(LoginStep step) {
    final e = _error;
    if (e == null || e.step != step) return null;
    return loginErrorCopy(e.method, e.failure);
  }

  Widget _providerButtons() {
    final busy = _busy != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_apple) ...[
          LoginProviderButton(
            method: LoginMethod.apple,
            identifier: 'login-apple-button',
            loading: _busy == LoginMethod.apple,
            onTap: busy ? null : () => _social(LoginMethod.apple),
          ),
          const SizedBox(height: 12),
        ],
        LoginProviderButton(
          method: LoginMethod.google,
          identifier: 'login-google-button',
          loading: _busy == LoginMethod.google,
          onTap: busy ? null : () => _social(LoginMethod.google),
        ),
      ],
    );
  }

  // ── Inicio ──────────────────────────────────────────────────────────────

  Widget _mainStep(BuildContext context) {
    final gm = GmColors.of(context);
    final chip = loginReasonChip(widget.reason);
    final error = _errorFor(LoginStep.main);
    final busy = _busy != null;
    return Semantics(
      identifier: 'login-main-step',
      container: true,
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const GmRise(
                    trigger: GmTrigger.mount, child: LoginLogo(width: 176)),
                if (chip != null) ...[
                  const SizedBox(height: 18),
                  GmRise(
                    index: 1,
                    trigger: GmTrigger.mount,
                    child: LoginReasonChip(chip: chip),
                  ),
                  const SizedBox(height: 10),
                ] else
                  const SizedBox(height: 18),
                GmRise(
                  index: 1,
                  trigger: GmTrigger.mount,
                  child: Semantics(
                    header: true,
                    child: Text(
                      kLoginTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        height: 34 / 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        color: gm.label,
                      ),
                    ),
                  ),
                ),
                if (error == null) ...[
                  const SizedBox(height: 6),
                  GmRise(
                    index: 2,
                    trigger: GmTrigger.mount,
                    child: Text(
                      kLoginSubtitle,
                      textAlign: TextAlign.center,
                      style: GmText.body(color: gm.label2),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: LoginErrorBanner(title: error.$1, text: error.$2),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
            child: GmRise(
              index: 2,
              trigger: GmTrigger.mount,
              child: _providerButtons(),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(34, 14, 34, 4),
            child: LoginOrDivider(),
          ),
          Center(
            child: LoginTextButton(
              label: kLoginEmailEntry,
              icon: PerfilIcons.mail,
              identifier: 'login-email-entry',
              onTap: busy ? null : () => _goTo(LoginStep.email),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              kLoginEmailNote,
              textAlign: TextAlign.center,
              style: GmText.meta(color: gm.label2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
            child: LoginLegalLine(
              onTerms: () => _openLegal(kPerfilTermsUrl, 'Términos de uso'),
              onPrivacy: () =>
                  _openLegal(kPerfilPrivacyUrl, 'Política de privacidad'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Email ───────────────────────────────────────────────────────────────

  Widget _emailStep(BuildContext context) {
    final gm = GmColors.of(context);
    final error = _errorFor(LoginStep.email);
    final loading = _busy == LoginMethod.email;
    final credentials = _error?.step == LoginStep.email &&
        _error?.failure == LoginFailure.credentials;
    final canSubmit = loginCanSubmit(_email.text, _password.text);
    return Semantics(
      identifier: 'login-email-step',
      container: true,
      explicitChildNodes: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  kLoginEmailNote,
                  textAlign: TextAlign.center,
                  style: GmText.body(color: gm.label2),
                ),
              ),
              const SizedBox(height: 14),
              if (error != null) ...[
                LoginErrorBanner(title: error.$1, text: error.$2),
                const SizedBox(height: 14),
              ],
              LoginField(
                label: 'Email',
                hint: 'tu@email.com',
                controller: _email,
                focusNode: _emailFocus,
                identifier: 'login-email-field',
                enabled: !loading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email, AutofillHints.username],
                onChanged: (_) => _clearEmailError(),
                onSubmitted: (_) => _passwordFocus.requestFocus(),
              ),
              const SizedBox(height: 14),
              LoginField(
                label: 'Contraseña',
                hint: 'Tu contraseña',
                controller: _password,
                focusNode: _passwordFocus,
                identifier: 'login-password-field',
                enabled: !loading,
                error: credentials,
                obscure: _obscure,
                onToggleObscure: () => setState(() => _obscure = !_obscure),
                keyboardType: TextInputType.visiblePassword,
                textInputAction: TextInputAction.go,
                autofillHints: const [AutofillHints.password],
                onChanged: (_) => _clearEmailError(),
                onSubmitted: (_) => _submitEmail(),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: LoginTextButton(
                  label: kLoginForgot,
                  identifier: 'login-forgot-button',
                  onTap: loading ? null : () => _goTo(LoginStep.recover),
                ),
              ),
              const SizedBox(height: 8),
              LoginSubmitButton(
                label: kLoginSubmit,
                enabled: canSubmit,
                loading: loading,
                onTap: _submitEmail,
              ),
              const SizedBox(height: 14),
              _noAccountLine(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _noAccountLine(BuildContext context) {
    final gm = GmColors.of(context);
    final base = GmText.meta(color: gm.label2);
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: loginNoAccountLead(appleAvailable: _apple)),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Semantics(
              identifier: 'login-back-to-social',
              button: true,
              label: 'Volver a Apple y Google',
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _goTo(LoginStep.main),
                child: Text(
                  'volver',
                  style: base.copyWith(
                    color: gm.label,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: gm.label,
                  ),
                ),
              ),
            ),
          ),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  // ── Recuperar ───────────────────────────────────────────────────────────

  Widget _recoverStep(BuildContext context) {
    final gm = GmColors.of(context);
    final error = _errorFor(LoginStep.recover);
    final (before, bold, after) = loginRecoverLead(appleAvailable: _apple);
    final (q, rest) = loginRecoverSupport(appleAvailable: _apple);
    return Semantics(
      identifier: 'login-recover-step',
      container: true,
      explicitChildNodes: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 6),
            const Center(child: LoginVolcano(width: 72)),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text.rich(
                TextSpan(
                  style: GmText.body17(color: gm.label),
                  children: [
                    TextSpan(text: before),
                    TextSpan(
                        text: bold,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    TextSpan(text: after),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            if (error != null) ...[
              LoginErrorBanner(title: error.$1, text: error.$2),
              const SizedBox(height: 12),
            ],
            _providerButtons(),
            const SizedBox(height: 22),
            GmCard(
              radius: 22,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      style: GmText.body(color: gm.label),
                      children: [
                        TextSpan(
                            text: q,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        const TextSpan(text: ' '),
                        TextSpan(
                            text: rest, style: TextStyle(color: gm.label2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Cápsula secundaria que parte en dos líneas con letra grande.
                  PerfilSoftButton(
                    label: kLoginSupport,
                    identifier: 'login-support-button',
                    leading:
                        GmIcon(PerfilIcons.mail, size: 16, color: gm.accent),
                    onTap: _writeSupport,
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

/// Aviso de eliminación pendiente (tablero Login · eliminación): tarjeta
/// r30 centrada con papelera en `warnSoft`, título con la fecha y dos
/// acciones apiladas. Devuelve `true` = conservar.
class LoginDeletionDialog extends StatelessWidget {
  final DateTime? at;
  const LoginDeletionDialog({super.key, this.at});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final (title, text) = loginDeletionCopy(at, DateTime.now());
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Semantics(
            identifier: 'login-deletion-dialog',
            container: true,
            scopesRoute: true,
            namesRoute: true,
            explicitChildNodes: true,
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 16),
                decoration: BoxDecoration(
                  color: gm.card,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x61000000),
                        blurRadius: 60,
                        offset: Offset(0, 24)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                            color: gm.warnSoft, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: GmIcon(PerfilIcons.trash,
                            size: 22, color: gm.warnText),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Semantics(
                      header: true,
                      child: Text(title,
                          textAlign: TextAlign.center,
                          style: GmText.poster(color: gm.label)),
                    ),
                    const SizedBox(height: 8),
                    Text(text,
                        textAlign: TextAlign.center,
                        style: GmText.body(color: gm.label2)),
                    const SizedBox(height: 18),
                    GmCapsuleButton(
                      label: kLoginKeepAccount,
                      height: 52,
                      fontSize: 17,
                      identifier: 'login-deletion-keep',
                      onTap: () => Navigator.of(context).pop(true),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      identifier: 'login-deletion-logout',
                      button: true,
                      label: kLoginSignOut,
                      excludeSemantics: true,
                      child: GmPressable(
                        onTap: () => Navigator.of(context).pop(false),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 48),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: gm.fill,
                            borderRadius:
                                BorderRadius.circular(GmRadius.pill),
                          ),
                          child: Text(
                            kLoginSignOut,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: gm.label,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
