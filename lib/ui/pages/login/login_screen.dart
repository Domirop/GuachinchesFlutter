import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:guachinches/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/pages/login/login_presenter.dart';
import 'package:guachinches/ui/pages/login/widgets/oauth_button.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/ui/pages/new_home/new_home_tab_scaffold.dart';
import 'package:http/http.dart';

/// Pantalla de login reimplementada según mockup T-002.
/// Estructura: hero foto + form area (OAuth-first, email legacy secundario).
/// Estados internos: default, loading, emailForm, error.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum _LoginState { defaultView, loading, emailForm, error }

enum _OAuthProvider { google, apple }

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin
    implements LoginView {
  _LoginState _state = _LoginState.defaultView;
  _OAuthProvider? _activeProvider;
  String? _errorMessage;

  // Email form controllers
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _passwordVisible = false;
  bool _emailLoading = false;
  String? _emailError;

  // Shake animation for error banner
  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;

  // Entry animation (fade + slide)
  late final AnimationController _entryCtrl;
  late final Animation<double> _entryFade;
  late final Animation<Offset> _entrySlide;

  // Inicialización inline lazy: `late final` solo se evalúa en el primer
  // acceso, así no se reasigna nunca aunque didChangeDependencies se dispare
  // múltiples veces (p.ej. al aparecer el teclado). El viejo login.dart usa
  // el mismo patrón.
  late final RemoteRepository _repo = HttpRemoteRepository(Client());
  late final LoginPresenter _presenter =
      LoginPresenter(_repo, this, context.read<UserCubit>());

  @override
  void initState() {
    super.initState();

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -6), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -6, end: 6), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 6, end: -4), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -4, end: 4), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 4, end: 0), weight: 20),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _entryFade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _entryCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _onGoogleTap() async {
    if (_state == _LoginState.loading) return;
    HapticFeedback.lightImpact();
    setState(() {
      _state = _LoginState.loading;
      _activeProvider = _OAuthProvider.google;
      _errorMessage = null;
    });
    await _presenter.loginWithGoogle();
    if (mounted && _state == _LoginState.loading) {
      setState(() {
        _state = _LoginState.defaultView;
        _activeProvider = null;
      });
    }
  }

  void _onAppleTap() async {
    if (_state == _LoginState.loading) return;
    HapticFeedback.lightImpact();
    if (!Platform.isIOS) return;
    setState(() {
      _state = _LoginState.loading;
      _activeProvider = _OAuthProvider.apple;
      _errorMessage = null;
    });
    await _presenter.loginWithApple();
    if (mounted && _state == _LoginState.loading) {
      setState(() {
        _state = _LoginState.defaultView;
        _activeProvider = null;
      });
    }
  }

  void _triggerError(String message) {
    HapticFeedback.mediumImpact();
    setState(() {
      _state = _LoginState.error;
      _errorMessage = message;
      _activeProvider = null;
    });
    _shakeCtrl.forward(from: 0);
  }

  void _showEmailForm() {
    setState(() {
      _state = _LoginState.emailForm;
      _errorMessage = null;
    });
  }

  void _backToDefault() {
    setState(() {
      _state = _LoginState.defaultView;
      _errorMessage = null;
      _emailCtrl.clear();
      _passwordCtrl.clear();
      _emailError = null;
    });
  }

  Future<void> _submitEmail() async {
    if (_emailLoading) return;
    FocusScope.of(context).unfocus();
    final email = _emailCtrl.text.trim();
    final pwd = _passwordCtrl.text;
    if (email.isEmpty || pwd.isEmpty) {
      setState(() => _emailError = 'Introduce tu email y contraseña.');
      return;
    }
    setState(() {
      _emailLoading = true;
      _emailError = null;
    });
    await _presenter.login(email, pwd);
    if (!mounted) return;
    setState(() => _emailLoading = false);
  }

  // ── LoginView callbacks ───────────────────────────────────────────────────

  @override
  loginSuccess(List<Widget> screens, {bool deletionPending = false, String userId = ''}) {
    if (!mounted) return;
    if (deletionPending && userId.isNotEmpty) {
      _showDeletionPendingDialog(screens, userId);
      return;
    }
    GlobalMethods().removePagesAndGoToNewScreen(
      context,
      NewHomeTabScaffold(screens: screens),
    );
  }

  void _showDeletionPendingDialog(List<Widget> screens, String userId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.elevated,
        title: Text(
          'Cuenta pendiente de eliminación',
          style: AppTextStyles.ui(
            size: 17,
            weight: FontWeight.w700,
            color: AppColors.crema,
          ),
        ),
        content: Text(
          'Tu cuenta está programada para eliminarse. ¿Deseas cancelar la eliminación o cerrar sesión?',
          style: AppTextStyles.ui(size: 14, color: AppColors.crema.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await const FlutterSecureStorage().deleteAll();
            },
            child: Text(
              'Salir',
              style: AppTextStyles.ui(
                size: 14,
                color: AppColors.crema.withOpacity(0.6),
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await _repo.cancelAccountDeletion(userId);
              } catch (_) {}
              if (!mounted) return;
              GlobalMethods().removePagesAndGoToNewScreen(
                context,
                NewHomeTabScaffold(screens: screens),
              );
            },
            child: Text(
              'Cancelar eliminación',
              style: AppTextStyles.ui(
                size: 14,
                weight: FontWeight.w700,
                color: AppColors.atlantico,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  loginError() {
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    // If the user came from the email form, keep them there with an inline
    // error so they can edit their credentials. Falling back to _triggerError
    // would yank them back to the OAuth-first view, hiding their input.
    if (_state == _LoginState.emailForm) {
      setState(() {
        _emailLoading = false;
        _emailError =
            'Email o contraseña incorrectos. Revisa tus datos e inténtalo de nuevo.';
      });
      return;
    }
    setState(() => _emailLoading = false);
    _triggerError('Email o contraseña incorrectos. Inténtalo de nuevo.');
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.base : AppColors.crema;
    final isLoading = _state == _LoginState.loading;
    final showBack = _state != _LoginState.emailForm;

    return Scaffold(
      backgroundColor: bg,
      body: FadeTransition(
        opacity: _entryFade,
        child: SlideTransition(
          position: _entrySlide,
          child: Stack(
            children: [
              Column(
                children: [
                  // Hero — fixed, does not scroll
                  _HeroArea(isDark: isDark),
                  // Form area — scrollable
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                      ),
                      physics: const BouncingScrollPhysics(),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.06),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: animation,
                                curve: const Cubic(0.4, 0, 0.2, 1),
                              )),
                              child: child,
                            ),
                          );
                        },
                        child: _buildFormContent(isDark),
                      ),
                    ),
                  ),
                ],
              ),
              if (showBack)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 12,
                  child: _LoginBackButton(
                    onTap: isLoading
                        ? null
                        : () => Navigator.maybePop(context),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent(bool isDark) {
    switch (_state) {
      case _LoginState.emailForm:
        return _EmailFormArea(
          key: const ValueKey('email'),
          isDark: isDark,
          emailCtrl: _emailCtrl,
          passwordCtrl: _passwordCtrl,
          passwordVisible: _passwordVisible,
          onTogglePassword: () =>
              setState(() => _passwordVisible = !_passwordVisible),
          loading: _emailLoading,
          errorText: _emailError,
          onBack: _backToDefault,
          onSubmit: _submitEmail,
        );
      default:
        return _DefaultFormArea(
          key: ValueKey(_state),
          isDark: isDark,
          state: _state,
          activeProvider: _activeProvider,
          errorMessage: _errorMessage,
          shakeAnim: _shakeAnim,
          onGoogleTap: _onGoogleTap,
          onAppleTap: _onAppleTap,
          onEmailTap: _showEmailForm,
        );
    }
  }
}

// ── Hero Area ────────────────────────────────────────────────────────────────

class _HeroArea extends StatelessWidget {
  final bool isDark;
  const _HeroArea({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.base : AppColors.crema;
    final headlineColor = isDark ? Colors.white : AppColors.ink;
    final subtitleColor = isDark
        ? Colors.white.withOpacity(0.75)
        : AppColors.ink.withOpacity(0.6);

    return SizedBox(
      height: 280,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background photo
          Image.asset(
            'assets/images/loginBg.png',
            fit: BoxFit.cover,
          ),
          // Base contrast gradient
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        const Color(0x33000000),
                        Colors.transparent,
                        const Color(0x80000000),
                      ]
                    : [
                        AppColors.crema.withOpacity(0.15),
                        Colors.transparent,
                        AppColors.crema.withOpacity(0.4),
                      ],
                stops: const [0.0, 0.4, 0.75],
              ),
            ),
          ),
          // Top fade — blends with status bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 80,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    bg,
                    bg.withOpacity(0.7),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 1.0],
                ),
              ),
            ),
          ),
          // Bottom fade — blends into form area
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 120,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, bg.withOpacity(0.6), bg],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          // Logo
          Positioned(
            top: 20 + MediaQuery.of(context).padding.top,
            left: 24,
            child: Image.asset(
              'assets/images/logoGrande.png',
              height: 48,
              fit: BoxFit.fitHeight,
            ),
          ),
          // Headline
          Positioned(
            bottom: 28,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Dónde comer\nen Canarias',
                  style: AppTextStyles.displayHero(
                    size: 32,
                    color: headlineColor,
                  ).copyWith(height: 1.1),
                ),
                const SizedBox(height: 6),
                Text(
                  'Guachinches, tacos de pescado, mojo picón.\nTodo en un lugar.',
                  style: AppTextStyles.ui(
                    size: 13,
                    color: subtitleColor,
                  ).copyWith(height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Default / Loading / Error form area ─────────────────────────────────────

class _DefaultFormArea extends StatelessWidget {
  final bool isDark;
  final _LoginState state;
  final _OAuthProvider? activeProvider;
  final String? errorMessage;
  final Animation<double> shakeAnim;
  final VoidCallback onGoogleTap;
  final VoidCallback onAppleTap;
  final VoidCallback onEmailTap;

  const _DefaultFormArea({
    super.key,
    required this.isDark,
    required this.state,
    required this.activeProvider,
    required this.errorMessage,
    required this.shakeAnim,
    required this.onGoogleTap,
    required this.onAppleTap,
    required this.onEmailTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.base : AppColors.crema;
    final isLoading = state == _LoginState.loading;
    final textMuted = isDark
        ? AppColors.crema.withOpacity(0.6)
        : AppColors.ink.withOpacity(0.6);
    final dividerColor = isDark
        ? AppColors.borderDark
        : AppColors.borderCream;
    final textVeryMuted = isDark
        ? AppColors.crema.withOpacity(0.38)
        : AppColors.ink.withOpacity(0.38);

    return Container(
      color: bg,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Error banner (only in error state)
          if (state == _LoginState.error && errorMessage != null) ...[
            AnimatedBuilder(
              animation: shakeAnim,
              builder: (context, child) => Transform.translate(
                offset: Offset(shakeAnim.value, 0),
                child: child,
              ),
              child: _ErrorBanner(
                message: errorMessage!,
                isDark: isDark,
              ),
            ),
            const SizedBox(height: 4),
          ],

          // Label
          Text(
            state == _LoginState.error
                ? 'INTENTA OTRA VEZ'
                : 'CONTINÚA CON TU CUENTA',
            textAlign: TextAlign.center,
            style: AppTextStyles.ui(
              size: 11,
              weight: FontWeight.w600,
              color: textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),

          // Google button
          OAuthButton(
            isDark: isDark,
            isGoogleButton: true,
            loading: isLoading && activeProvider == _OAuthProvider.google,
            disabled: isLoading && activeProvider != _OAuthProvider.google,
            onTap: isLoading ? null : onGoogleTap,
            label: isLoading && activeProvider == _OAuthProvider.google
                ? 'Conectando con Google…'
                : AppL10n.of(context).loginWithGoogle,
          ),
          const SizedBox(height: 12),

          // Apple button
          OAuthButton(
            isDark: isDark,
            isGoogleButton: false,
            loading: isLoading && activeProvider == _OAuthProvider.apple,
            disabled: isLoading && activeProvider != _OAuthProvider.apple,
            onTap: isLoading ? null : onAppleTap,
            label: AppL10n.of(context).loginWithApple,
          ),
          const SizedBox(height: 24),

          // Divider
          Row(
            children: [
              Expanded(child: Divider(color: dividerColor, thickness: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'o',
                  style: AppTextStyles.ui(size: 12, color: textVeryMuted),
                ),
              ),
              Expanded(child: Divider(color: dividerColor, thickness: 1)),
            ],
          ),
          const SizedBox(height: 20),

          // Email legacy link
          GestureDetector(
            onTap: isLoading ? null : onEmailTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Entrar con email y contraseña',
                textAlign: TextAlign.center,
                style: AppTextStyles.ui(
                  size: 13,
                  weight: FontWeight.w600,
                  color: isLoading ? textVeryMuted : textMuted,
                ).copyWith(
                  decoration: isLoading
                      ? TextDecoration.none
                      : TextDecoration.underline,
                  decorationColor: textMuted,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Legal footer
          _LegalFooter(isDark: isDark),
        ],
      ),
    );
  }
}

// ── Email form area ──────────────────────────────────────────────────────────

class _EmailFormArea extends StatelessWidget {
  final bool isDark;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool passwordVisible;
  final bool loading;
  final String? errorText;
  final VoidCallback onBack;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  const _EmailFormArea({
    super.key,
    required this.isDark,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.passwordVisible,
    required this.loading,
    required this.onBack,
    required this.onTogglePassword,
    required this.onSubmit,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.base : AppColors.crema;
    final textPrimary = isDark ? AppColors.crema : AppColors.ink;
    final textMuted = isDark
        ? AppColors.crema.withOpacity(0.6)
        : AppColors.ink.withOpacity(0.6);
    final textVeryMuted = isDark
        ? AppColors.crema.withOpacity(0.38)
        : AppColors.ink.withOpacity(0.38);

    return Container(
      color: bg,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Back button
          GestureDetector(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_rounded, size: 16, color: textMuted),
                  const SizedBox(width: 6),
                  Text(
                    'Otras formas de entrar',
                    style: AppTextStyles.ui(
                      size: 13,
                      weight: FontWeight.w600,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Text(
            'Entrar con email',
            style: AppTextStyles.displayHero(size: 22, color: textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Para usuarios registrados antes de mayo 2026.',
            style: AppTextStyles.ui(size: 13, color: textMuted),
          ),
          const SizedBox(height: 24),

          // Error banner
          if (errorText != null) ...[
            _ErrorBanner(message: errorText!, isDark: isDark),
            const SizedBox(height: 4),
          ],

          // Email field
          _LoginField(
            isDark: isDark,
            label: 'EMAIL',
            controller: emailCtrl,
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),

          // Password field
          _LoginField(
            isDark: isDark,
            label: 'CONTRASEÑA',
            controller: passwordCtrl,
            icon: Icons.lock_outline_rounded,
            obscureText: !passwordVisible,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSubmit(),
            trailing: GestureDetector(
              onTap: onTogglePassword,
              child: Icon(
                passwordVisible
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                size: 18,
                color: textVeryMuted,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Forgot password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // TODO(auth): forgot password flow
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Contacta con soporte para restablecer tu contraseña.'),
                  duration: Duration(seconds: 2),
                ));
              },
              child: Text(
                '¿Olvidaste tu contraseña?',
                style: AppTextStyles.ui(
                  size: 12,
                  weight: FontWeight.w600,
                  color: AppColors.atlantico,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Submit button
          _PrimaryButton(
            label: 'Iniciar sesión',
            loading: loading,
            onTap: onSubmit,
          ),

          const SizedBox(height: 24),
          Text(
            '¿Nuevo en Dónde Comer Canarias? Usa Google o Apple para registrarte.',
            textAlign: TextAlign.center,
            style: AppTextStyles.ui(size: 11, color: textVeryMuted)
                .copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}


class _LoginField extends StatefulWidget {
  final bool isDark;
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? trailing;
  final ValueChanged<String>? onSubmitted;

  const _LoginField({
    required this.isDark,
    required this.label,
    required this.controller,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.trailing,
    this.onSubmitted,
  });

  @override
  State<_LoginField> createState() => _LoginFieldState();
}

class _LoginFieldState extends State<_LoginField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    final isDark = widget.isDark;
    final labelColor = isDark
        ? AppColors.crema.withOpacity(0.38)
        : AppColors.ink.withOpacity(0.38);
    final fieldBg = isDark
        ? Colors.white.withOpacity(0.06)
        : AppColors.ink.withOpacity(0.04);
    final borderColor = focused ? AppColors.atlantico : Colors.transparent;
    final textColor = isDark ? AppColors.crema : AppColors.ink;
    final iconColor = isDark
        ? AppColors.crema.withOpacity(0.38)
        : AppColors.ink.withOpacity(0.38);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            widget.label,
            style: AppTextStyles.ui(
              size: 10,
              weight: FontWeight.w700,
              color: labelColor,
              letterSpacing: 0.8,
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 52,
          decoration: BoxDecoration(
            color: fieldBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(widget.icon, size: 16, color: iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  obscureText: widget.obscureText,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  onSubmitted: widget.onSubmitted,
                  cursorColor: AppColors.atlantico,
                  style: AppTextStyles.ui(
                    size: 15,
                    color: textColor,
                    weight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintStyle: AppTextStyles.ui(
                      size: 15,
                      color: iconColor,
                    ),
                  ),
                ),
              ),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.atlantico,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.atlantico.withOpacity(0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: AppTextStyles.ui(
                  size: 15,
                  weight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final bool isDark;

  const _ErrorBanner({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.mojo.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.mojo.withOpacity(0.35),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.error_outline_rounded,
                size: 18, color: AppColors.mojo),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No hemos podido verificar tu cuenta',
                  style: AppTextStyles.ui(
                    size: 13,
                    weight: FontWeight.w700,
                    color: AppColors.mojo,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: AppTextStyles.ui(
                    size: 12,
                    color: AppColors.mojo.withOpacity(0.75),
                  ).copyWith(height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginBackButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _LoginBackButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.4 : 1.0,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.glassDark,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegalFooter extends StatelessWidget {
  final bool isDark;
  const _LegalFooter({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = isDark
        ? AppColors.crema.withOpacity(0.38)
        : AppColors.ink.withOpacity(0.35);

    return Text(
      AppL10n.of(context).loginPrivacyNotice,
      textAlign: TextAlign.center,
      style: AppTextStyles.ui(size: 11, color: color).copyWith(height: 1.5),
    );
  }
}
