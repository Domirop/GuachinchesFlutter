import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/pages/login/login.dart';
import 'package:guachinches/ui/pages/register/register_presenter.dart';
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher.dart';

class Register extends StatefulWidget {
  const Register({Key? key}) : super(key: key);

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> implements RegisterView {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _apellidos = TextEditingController();
  final _telefono = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();

  late final RemoteRepository _repo = HttpRemoteRepository(Client());
  late final RegisterPresenter _presenter = RegisterPresenter(_repo, this);

  bool _passwordVisible = false;
  bool _passwordConfirmVisible = false;
  bool _termsAccepted = false;
  bool _termsError = false;
  bool _loading = false;
  String _errorText = '';

  // Same regex used by the legacy form so backend validation is preserved.
  static final RegExp _phoneRe = RegExp(r'^[6,7]{1}[0-9]{8}$');
  static final RegExp _emailRe =
      RegExp(r"^[\w.!#$%&'*+\-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");

  @override
  void dispose() {
    _nombre.dispose();
    _apellidos.dispose();
    _telefono.dispose();
    _email.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    final formValid = _formKey.currentState?.validate() == true;
    setState(() => _termsError = !_termsAccepted);
    if (!formValid || !_termsAccepted) return;

    final data = <String, String>{
      'nombre': _nombre.text.trim(),
      'apellidos': _apellidos.text.trim(),
      'email': _email.text.trim().toLowerCase(),
      'telefono': _telefono.text.trim(),
      'password': _password.text,
    };

    setState(() {
      _loading = true;
      _errorText = '';
    });
    await _presenter.register(data);
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: AppColors.crema,
      // Tap fuera de los textfields → cierra teclado.
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.32,
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
                        AppColors.profundo.withOpacity(0.45),
                        AppColors.profundo.withOpacity(0.18),
                        AppColors.crema,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 32 + bottomInset),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      _CircleIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.of(context).pop(),
                        background: Colors.white.withOpacity(0.92),
                        foreground: AppColors.ink,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Crear cuenta',
                    style: AppTextStyles.displayHero(
                      size: 34,
                      color: Colors.white,
                    ).copyWith(height: 1.05),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'En menos de un minuto formarás parte de la comunidad guachinche.',
                    style: AppTextStyles.ui(
                      size: 13,
                      color: Colors.white.withOpacity(0.92),
                    ).copyWith(height: 1.35),
                  ),
                  const SizedBox(height: 24),
                  _Card(
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_errorText.isNotEmpty)
                            _ErrorBanner(message: _errorText),
                          _SectionLabel(
                            text: 'Datos personales',
                            icon: Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 12),
                          _ModernField(
                            controller: _nombre,
                            label: 'Nombre',
                            hint: 'Nombre',
                            icon: Icons.badge_outlined,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.givenName],
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Campo obligatorio'
                                    : null,
                          ),
                          const SizedBox(height: 14),
                          _ModernField(
                            controller: _apellidos,
                            label: 'Apellidos',
                            hint: 'Apellidos',
                            icon: Icons.badge_outlined,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.familyName],
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Campo obligatorio'
                                    : null,
                          ),
                          const SizedBox(height: 22),
                          _SectionLabel(
                            text: 'Contacto',
                            icon: Icons.alternate_email_rounded,
                          ),
                          const SizedBox(height: 12),
                          _ModernField(
                            controller: _email,
                            label: 'Email',
                            hint: 'tu@email.com',
                            icon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            validator: (v) {
                              final value = v?.trim() ?? '';
                              if (value.isEmpty) return 'Campo obligatorio';
                              if (!_emailRe.hasMatch(value)) {
                                return 'Email no válido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _ModernField(
                            controller: _telefono,
                            label: 'Teléfono',
                            hint: '6XXXXXXXX',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [
                              AutofillHints.telephoneNumber
                            ],
                            formatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(9),
                            ],
                            validator: (v) {
                              final value = v?.trim() ?? '';
                              if (value.isEmpty) return 'Campo obligatorio';
                              if (!_phoneRe.hasMatch(value)) {
                                return 'Móvil inválido (9 dígitos)';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 22),
                          _SectionLabel(
                            text: 'Seguridad',
                            icon: Icons.lock_outline_rounded,
                          ),
                          const SizedBox(height: 12),
                          _ModernField(
                            controller: _password,
                            label: 'Contraseña',
                            hint: 'Mínimo 8 caracteres',
                            icon: Icons.lock_outline_rounded,
                            obscure: !_passwordVisible,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.newPassword],
                            trailing: IconButton(
                              splashRadius: 20,
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                size: 20,
                                color: AppColors.inkMuted,
                              ),
                              onPressed: () => setState(() =>
                                  _passwordVisible = !_passwordVisible),
                            ),
                            validator: (v) {
                              if (v == null || v.length < 8) {
                                return 'Debe tener al menos 8 caracteres';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _ModernField(
                            controller: _passwordConfirm,
                            label: 'Repetir contraseña',
                            hint: 'Confirmación',
                            icon: Icons.lock_outline_rounded,
                            obscure: !_passwordConfirmVisible,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.newPassword],
                            trailing: IconButton(
                              splashRadius: 20,
                              icon: Icon(
                                _passwordConfirmVisible
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                size: 20,
                                color: AppColors.inkMuted,
                              ),
                              onPressed: () => setState(() =>
                                  _passwordConfirmVisible =
                                      !_passwordConfirmVisible),
                            ),
                            onFieldSubmitted: (_) => _submit(),
                            validator: (v) {
                              if (v == null || v.length < 8) {
                                return 'Debe tener al menos 8 caracteres';
                              }
                              if (v != _password.text) {
                                return 'Las contraseñas no coinciden';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          _TermsRow(
                            value: _termsAccepted,
                            error: _termsError,
                            onChanged: (v) => setState(() {
                              _termsAccepted = v;
                              if (v) _termsError = false;
                            }),
                            onOpenPrivacy: () => _openUrl(
                                'https://www.guachinchesmodernos.com/data/dataPolicy/'),
                            onOpenTerms: () => _openUrl(
                                'https://www.guachinchesmodernos.com/data/terms/'),
                          ),
                          if (_termsError)
                            Padding(
                              padding: const EdgeInsets.only(top: 6, left: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded,
                                      size: 13, color: AppColors.mojo),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Debes aceptar los términos para continuar.',
                                    style: AppTextStyles.ui(
                                      size: 11,
                                      weight: FontWeight.w600,
                                      color: AppColors.mojo,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 18),
                          _PrimaryButton(
                            label: 'Crear cuenta',
                            loading: _loading,
                            onPressed: _submit,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿Ya tienes cuenta?',
                        style: AppTextStyles.ui(
                          size: 13,
                          color: AppColors.inkSoft,
                        ),
                      ),
                      const SizedBox(width: 4),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Inicia sesión',
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

  // ── RegisterView ──────────────────────────────────────────────────────
  @override
  correctInsert() {
    if (!mounted) return;
    GlobalMethods().pushAndReplacement(
      context,
      const Login('Registro con éxito, inicia sesión'),
    );
  }

  @override
  errorInsert(String error) {
    if (!mounted) return;
    setState(() {
      _errorText = error.isEmpty ? 'No hemos podido completar el registro.' : error;
      _loading = false;
    });
  }
}

// ── Reusable widgets (mismo estilo que Login) ──────────────────────────────
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
        child: Icon(icon, size: 18, color: foreground),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final IconData icon;
  const _SectionLabel({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.atlantico),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: AppTextStyles.eyebrow(
            size: 11,
            color: AppColors.atlantico,
          ),
        ),
      ],
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
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<String>? autofillHints;
  final List<TextInputFormatter>? formatters;
  final Widget? trailing;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldValidator<String>? validator;

  const _ModernField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.formatters,
    this.trailing,
    this.onFieldSubmitted,
    this.validator,
  });

  @override
  State<_ModernField> createState() => _ModernFieldState();
}

class _ModernFieldState extends State<_ModernField> {
  final FocusNode _focus = FocusNode();
  String? _error;

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
    final hasError = _error != null;
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
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: _focus,
                  obscureText: widget.obscure,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  autofillHints: widget.autofillHints,
                  inputFormatters: widget.formatters,
                  validator: (v) {
                    final result = widget.validator?.call(v);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      if (_error != result) setState(() => _error = result);
                    });
                    return result;
                  },
                  onFieldSubmitted: widget.onFieldSubmitted,
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
                    errorStyle: const TextStyle(height: 0, fontSize: 0),
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
                Flexible(
                  child: Text(
                    _error!,
                    style: AppTextStyles.ui(
                      size: 11,
                      weight: FontWeight.w600,
                      color: AppColors.mojo,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TermsRow extends StatelessWidget {
  final bool value;
  final bool error;
  final ValueChanged<bool> onChanged;
  final VoidCallback onOpenPrivacy;
  final VoidCallback onOpenTerms;

  const _TermsRow({
    required this.value,
    required this.error,
    required this.onChanged,
    required this.onOpenPrivacy,
    required this.onOpenTerms,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => onChanged(!value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            margin: const EdgeInsets.only(top: 2),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: value
                  ? AppColors.atlantico
                  : Colors.white,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: error
                    ? AppColors.mojo
                    : value
                        ? AppColors.atlantico
                        : AppColors.borderCreamMd,
                width: 1.4,
              ),
            ),
            child: value
                ? const Icon(Icons.check_rounded,
                    size: 16, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.ui(
                  size: 12,
                  color: AppColors.inkSoft,
                ).copyWith(height: 1.4),
                children: [
                  const TextSpan(text: 'He leído y acepto la '),
                  TextSpan(
                    text: 'protección de datos',
                    style: AppTextStyles.ui(
                      size: 12,
                      weight: FontWeight.w700,
                      color: AppColors.atlantico,
                    ).copyWith(decoration: TextDecoration.underline),
                    recognizer: TapGestureRecognizer()..onTap = onOpenPrivacy,
                  ),
                  const TextSpan(text: ' y los '),
                  TextSpan(
                    text: 'términos de uso',
                    style: AppTextStyles.ui(
                      size: 12,
                      weight: FontWeight.w700,
                      color: AppColors.atlantico,
                    ).copyWith(decoration: TextDecoration.underline),
                    recognizer: TapGestureRecognizer()..onTap = onOpenTerms,
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
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
