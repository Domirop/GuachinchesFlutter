import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/pages/discover/discover_screen.dart';
import 'package:guachinches/ui/pages/listas/listas_screen.dart';
import 'package:guachinches/ui/pages/login/login_presenter.dart';
import 'package:guachinches/ui/pages/map/map_search.dart';
import 'package:guachinches/ui/pages/new_home/new_home_screen.dart';
import 'package:guachinches/ui/pages/new_home/new_home_tab_scaffold.dart';
import 'package:guachinches/ui/pages/register/register.dart';
import 'package:guachinches/ui/pages/surveyDetails/surveyDetails.dart';
import 'package:http/http.dart';

class Login extends StatefulWidget {
  final String mainText;
  final bool isModal;

  const Login(this.mainText, {this.isModal = false, Key? key})
      : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> implements LoginView {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  late final RemoteRepository _repo = HttpRemoteRepository(Client());
  late final LoginPresenter _presenter =
      LoginPresenter(_repo, this, context.read<UserCubit>());

  bool _passwordVisible = false;
  bool _loading = false;
  String? _emailError;
  String? _passwordError;
  String? _formError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  bool _validate() {
    final email = _emailCtrl.text.trim();
    final pwd = _passwordCtrl.text;
    String? eErr;
    String? pErr;
    if (email.isEmpty) {
      eErr = 'Introduce tu email';
    } else {
      final re = RegExp(r"^[\w.!#$%&'*+\-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
      if (!re.hasMatch(email)) eErr = 'Email no válido';
    }
    if (pwd.isEmpty) pErr = 'Introduce tu contraseña';
    setState(() {
      _emailError = eErr;
      _passwordError = pErr;
      _formError = null;
    });
    return eErr == null && pErr == null;
  }

  Future<void> _submit() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    if (!_validate()) return;
    setState(() => _loading = true);
    await _presenter.login(_emailCtrl.text.trim(), _passwordCtrl.text);
    if (!mounted) return;
    setState(() => _loading = false);
  }

  void _closeAndContinueAsGuest() {
    GlobalMethods().removePagesAndGoToNewScreen(
      context,
      NewHomeTabScaffold(screens: [
        const NewHomeScreen(),
        const ListasScreen(),
        MapSearch(),
        const DiscoverScreen(),
        Login('Para ver tu perfíl debes iniciar sesión.'),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final canDismiss = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: AppColors.crema,
      // Tap fuera de los textfields → cierra teclado.
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
        children: [
          // Hero image with cream gradient blending into the form area.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.42,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/loginBg.png',
                  fit: BoxFit.cover,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.profundo.withOpacity(0.35),
                        AppColors.profundo.withOpacity(0.15),
                        AppColors.crema,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + bottomInset),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (canDismiss) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _CircleIconButton(
                          icon: Icons.close_rounded,
                          onTap: _closeAndContinueAsGuest,
                          background: Colors.white.withOpacity(0.92),
                          foreground: AppColors.ink,
                        ),
                        GestureDetector(
                          onTap: _closeAndContinueAsGuest,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 10),
                            child: Text(
                              'Saltar',
                              style: AppTextStyles.ui(
                                size: 13,
                                weight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                  ] else
                    const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      'Hola de nuevo',
                      style: AppTextStyles.displayHero(
                        size: 36,
                        color: Colors.white,
                      ).copyWith(height: 1.05),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.mainText.isEmpty
                        ? 'Inicia sesión para guardar tus favoritos y ver tu perfil.'
                        : widget.mainText,
                    style: AppTextStyles.ui(
                      size: 14,
                      color: Colors.white.withOpacity(0.92),
                    ).copyWith(height: 1.35),
                  ),
                  const SizedBox(height: 28),
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_formError != null)
                          _ErrorBanner(message: _formError!),
                        _ModernField(
                          controller: _emailCtrl,
                          focusNode: _emailFocus,
                          label: 'Email',
                          hint: 'tu@email.com',
                          icon: Icons.alternate_email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          errorText: _emailError,
                          onSubmitted: (_) =>
                              FocusScope.of(context).requestFocus(_passwordFocus),
                          onChanged: (_) {
                            if (_emailError != null) {
                              setState(() => _emailError = null);
                            }
                          },
                        ),
                        const SizedBox(height: 14),
                        _ModernField(
                          controller: _passwordCtrl,
                          focusNode: _passwordFocus,
                          label: 'Contraseña',
                          hint: '••••••••',
                          icon: Icons.lock_outline_rounded,
                          obscure: !_passwordVisible,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          errorText: _passwordError,
                          trailing: IconButton(
                            splashRadius: 20,
                            icon: Icon(
                              _passwordVisible
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              size: 20,
                              color: AppColors.inkMuted,
                            ),
                            onPressed: () => setState(
                                () => _passwordVisible = !_passwordVisible),
                          ),
                          onSubmitted: (_) => _submit(),
                          onChanged: (_) {
                            if (_passwordError != null) {
                              setState(() => _passwordError = null);
                            }
                          },
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                content: Text(
                                    'Contacta con soporte para restablecer la contraseña.'),
                                duration: Duration(seconds: 2),
                              ));
                            },
                            child: Text(
                              '¿Has olvidado la contraseña?',
                              style: AppTextStyles.ui(
                                size: 12,
                                weight: FontWeight.w600,
                                color: AppColors.atlantico,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        _PrimaryButton(
                          label: 'Iniciar sesión',
                          loading: _loading,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿Aún no tienes cuenta?',
                        style: AppTextStyles.ui(
                          size: 13,
                          color: AppColors.inkSoft,
                        ),
                      ),
                      const SizedBox(width: 4),
                      TextButton(
                        onPressed: () =>
                            GlobalMethods().pushPage(context, Register()),
                        child: Text(
                          'Crear cuenta',
                          style: AppTextStyles.ui(
                            size: 13,
                            weight: FontWeight.w800,
                            color: AppColors.atlantico,
                          ),
                        ),
                      ),
                    ],
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

  // ── LoginView ──────────────────────────────────────────────────────────
  @override
  loginSuccess(List<Widget> screens, {bool deletionPending = false, String userId = ''}) {
    if (!mounted) return;
    GlobalMethods()
        .removePagesAndGoToNewScreen(context, NewHomeTabScaffold(screens: screens));
    if (widget.isModal) {
      GlobalMethods().pushPage(context, SurveyDetails());
    }
  }

  @override
  loginError() {
    if (!mounted) return;
    setState(() {
      _formError = 'Email o contraseña incorrectos.';
      _loading = false;
    });
  }
}

// ── Reusable widgets ────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderCreamMd),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color background;
  final Color foreground;
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: foreground),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.mojo.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.mojo.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 18, color: AppColors.mojo),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.ui(
                size: 12,
                weight: FontWeight.w600,
                color: AppColors.mojo,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<String>? autofillHints;
  final Widget? trailing;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  const _ModernField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.focusNode,
    this.obscure = false,
    this.errorText,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.trailing,
    this.onSubmitted,
    this.onChanged,
  });

  @override
  State<_ModernField> createState() => _ModernFieldState();
}

class _ModernFieldState extends State<_ModernField> {
  late final FocusNode _focus;
  bool _ownsFocus = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _focus = widget.focusNode!;
    } else {
      _focus = FocusNode();
      _ownsFocus = true;
    }
    _focus.addListener(_onFocus);
  }

  void _onFocus() => setState(() {});

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    if (_ownsFocus) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    final focused = _focus.hasFocus;
    final borderColor = hasError
        ? AppColors.mojo
        : focused
            ? AppColors.atlantico
            : AppColors.borderCreamMd;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            widget.label.toUpperCase(),
            style: AppTextStyles.eyebrow(
              size: 10,
              color: hasError
                  ? AppColors.mojo
                  : focused
                      ? AppColors.atlantico
                      : AppColors.inkMuted,
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: AppColors.crema.withOpacity(focused ? 0.55 : 0.35),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: focused || hasError ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(widget.icon, size: 18, color: AppColors.inkMuted),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  obscureText: widget.obscure,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  autofillHints: widget.autofillHints,
                  onSubmitted: widget.onSubmitted,
                  onChanged: widget.onChanged,
                  cursorColor: AppColors.atlantico,
                  style: AppTextStyles.ui(
                    size: 15,
                    color: AppColors.ink,
                    weight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    border: InputBorder.none,
                    hintText: widget.hint,
                    hintStyle: AppTextStyles.ui(
                      size: 15,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ),
              ),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 6),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 13, color: AppColors.mojo),
                const SizedBox(width: 4),
                Text(
                  widget.errorText!,
                  style: AppTextStyles.ui(
                    size: 11,
                    weight: FontWeight.w600,
                    color: AppColors.mojo,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool loading;

  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.atlantico,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.atlantico.withOpacity(0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
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

