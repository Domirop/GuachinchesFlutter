import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:guachinches/ui/pages/login/login_logic.dart';
import 'package:guachinches/ui/pages/settings/widgets/perfil_widgets.dart'
    show PerfilIcons, PerfilLogo, PerfilSpinner;
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';

/// Piezas del acceso único (tablero AltLogin · A «Arena y logo» y estados
/// del tablero Login). Colores propios de la dirección en [LoginPalette].

// ── Colores ─────────────────────────────────────────────────────────────────

/// Tokens de la dirección A y de los botones de proveedor (día / noche),
/// tal cual `XV` de `tools/gen_alternativas.py`.
class LoginPalette {
  final Color sea;
  final Color sun;
  final Color wave;
  final Color wave2;
  final Color errSoft;
  final Color appleBg;
  final Color appleInk;
  final Color googleBg;
  final Color googleInk;
  final Color googleEdge;

  const LoginPalette._({
    required this.sea,
    required this.sun,
    required this.wave,
    required this.wave2,
    required this.errSoft,
    required this.appleBg,
    required this.appleInk,
    required this.googleBg,
    required this.googleInk,
    required this.googleEdge,
  });

  static const day = LoginPalette._(
    sea: Color(0xFFE3F1F8),
    sun: Color(0x42F2B84B), // rgba(242,184,75,0.26)
    wave: Color(0x4D0085C4), // 0.30
    wave2: Color(0x290085C4), // 0.16
    errSoft: Color(0x17C0352B), // rgba(192,53,43,0.09)
    appleBg: Color(0xFF000000),
    appleInk: Color(0xFFFFFFFF),
    googleBg: Color(0xFFFFFFFF),
    googleInk: Color(0xFF1F1F1F),
    googleEdge: Color(0x381F1A14), // rgba(31,26,20,0.22)
  );

  static const night = LoginPalette._(
    sea: Color(0xFF0C2230),
    sun: Color(0x1A4DAEDB), // 0.10
    wave: Color(0x574DAEDB), // 0.34
    wave2: Color(0x294DAEDB), // 0.16
    errSoft: Color(0x24FF6B5E), // rgba(255,107,94,0.14)
    appleBg: Color(0xFFFFFFFF),
    appleInk: Color(0xFF000000),
    googleBg: Color(0xFF131314),
    googleInk: Color(0xFFE3E3E3),
    googleEdge: Color(0xFF8E918F),
  );

  static LoginPalette of(BuildContext context) =>
      GmColors.of(context).isDark ? night : day;
}

/// Glifos propios del acceso (rejilla 24, trazo `currentColor`).
class LoginIcons {
  LoginIcons._();

  static String _stroke(String inner, {double width = 2}) =>
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
      'stroke="currentColor" stroke-width="$width" stroke-linecap="round" '
      'stroke-linejoin="round">$inner</svg>';

  static final eye = _stroke(
      '<path d="M2.5 12S6 5.5 12 5.5 21.5 12 21.5 12 18 18.5 12 18.5 2.5 12 2.5 12z"/>'
      '<circle cx="12" cy="12" r="3"/>');
  static final eyeOff = _stroke(
      '<path d="M4 4l16 16"/><path d="M9.9 5.8A9.6 9.6 0 0112 5.5c6 0 9.5 6.5 9.5 6.5a16 16 0 01-2.6 3.4"/>'
      '<path d="M6.3 7.4C3.9 9.1 2.5 12 2.5 12S6 18.5 12 18.5c1.6 0 3-.4 4.2-1"/>'
      '<path d="M9.9 9.9a3 3 0 004.2 4.2"/>');
  static final alert =
      _stroke('<circle cx="12" cy="12" r="9"/><path d="M12 7.5v5.5M12 16.4v.1"/>');
  static final flag = _stroke(
      '<path d="M5 21V4.5"/><path d="M5 4.5h11l-2 4 2 4H5"/>',
      width: 2.4);
  static final heart = _stroke(
      '<path d="M12 20s-7.5-4.6-7.5-10.1A4.4 4.4 0 0112 7.3a4.4 4.4 0 017.5 2.6C19.5 15.4 12 20 12 20z"/>',
      width: 2.4);
}

// ── Fondo «Arena y logo» ────────────────────────────────────────────────────

/// Lienzo arena que se funde con un mar claro, sol suave y dos olas
/// dibujadas abajo. Estático (sin bucles).
class LoginArenaBackground extends StatelessWidget {
  const LoginArenaBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final p = LoginPalette.of(context);
    return RepaintBoundary(
      child: CustomPaint(
        painter: _ArenaPainter(canvas: gm.canvas, palette: p),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ArenaPainter extends CustomPainter {
  final Color canvas;
  final LoginPalette palette;

  _ArenaPainter({required this.canvas, required this.palette});

  @override
  void paint(Canvas c, Size size) {
    final rect = Offset.zero & size;
    c.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [canvas, canvas, palette.sea],
          stops: const [0, 0.48, 1],
        ).createShader(rect),
    );
    // Sol: 522 de diámetro centrado, a 150 del borde superior del tablero.
    final sunCenter = Offset(size.width / 2, size.height * (411 / 874));
    const radius = 261.0;
    c.drawCircle(
      sunCenter,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [palette.sun, palette.sun.withValues(alpha: 0)],
          stops: const [0, 0.66],
        ).createShader(Rect.fromCircle(center: sunCenter, radius: radius)),
    );
    // Olas: periodo 140, amplitud 14 / 12, a 64 y 34 del borde inferior.
    _wave(c, size, y: size.height - 64, amp: 14, phase: -20,
        color: palette.wave);
    _wave(c, size, y: size.height - 34, amp: 12, phase: -50,
        color: palette.wave2);
  }

  void _wave(Canvas c, Size size,
      {required double y,
      required double amp,
      required double phase,
      required Color color}) {
    final path = Path()..moveTo(phase, y);
    var x = phase;
    var up = true;
    while (x < size.width + 70) {
      final dy = up ? -amp : amp;
      path.cubicTo(x + 30, y, x + 40, y + dy, x + 70, y + dy);
      x += 70;
      y += dy;
      up = !up;
    }
    c.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ArenaPainter old) =>
      old.canvas != canvas || old.palette != palette;
}

// ── Logo y chip ─────────────────────────────────────────────────────────────

/// Logo oficial (día: transparente; noche: azules aclarados).
class LoginLogo extends StatelessWidget {
  final double width;
  const LoginLogo({super.key, this.width = 176});

  @override
  Widget build(BuildContext context) {
    final dark = GmColors.of(context).isDark;
    return Image.asset(
      dark ? 'assets/images/logo_dcc_noche.png' : 'assets/images/logo_dcc_dia.png',
      width: width,
      height: width * 412 / 474,
      fit: BoxFit.contain,
      semanticLabel: 'Dónde Comer Canarias',
      excludeFromSemantics: false,
    );
  }
}

/// Chip de contexto («Para guardar Casa Ángela»): relleno `fill`, 30 alto.
class LoginReasonChip extends StatelessWidget {
  final ({LoginChipIcon icon, String text}) chip;
  const LoginReasonChip({super.key, required this.chip});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final svg = switch (chip.icon) {
      LoginChipIcon.heart => LoginIcons.heart,
      LoginChipIcon.pencil => PerfilIcons.pencil,
      LoginChipIcon.flag => LoginIcons.flag,
      LoginChipIcon.medal => GmIcons.medal,
    };
    return Semantics(
      identifier: 'login-reason-chip',
      container: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 30),
        padding: const EdgeInsets.fromLTRB(10, 5, 12, 5),
        decoration: BoxDecoration(
          color: gm.fill,
          borderRadius: BorderRadius.circular(GmRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GmIcon(svg, size: 14, color: gm.label2),
            const SizedBox(width: 6),
            Flexible(
              child: Text(chip.text,
                  textAlign: TextAlign.center,
                  style: GmText.eyebrow(color: gm.label2)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Botones ─────────────────────────────────────────────────────────────────

/// «Continuar con Apple» (negro de día, blanco de noche, como pide Apple) o
/// «Continuar con Google» (blanco con filo de día, gris Google de noche).
/// 52 de alto, cápsula a todo lo ancho. Cargando: indicador + «Conectando…».
class LoginProviderButton extends StatelessWidget {
  final LoginMethod method;
  final bool loading;
  final VoidCallback? onTap;
  final String identifier;

  const LoginProviderButton({
    super.key,
    required this.method,
    required this.identifier,
    this.loading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = LoginPalette.of(context);
    final apple = method == LoginMethod.apple;
    final bg = apple ? p.appleBg : p.googleBg;
    final ink = apple ? p.appleInk : p.googleInk;
    final label = loginProviderLabel(method, loading: loading);
    final enabled = onTap != null;
    final Widget logo = loading
        ? PerfilSpinner(color: ink, size: 18)
        : apple
            ? PerfilLogo(PerfilIcons.apple, width: 15, height: 18, color: ink)
            : SvgPicture.asset('assets/images/google_g_logo.svg',
                width: 20, height: 20, excludeFromSemantics: true);
    return Semantics(
      identifier: identifier,
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: GmPressable(
        onTap: onTap,
        pressedScale: 0.97,
        child: AnimatedOpacity(
          opacity: enabled || loading ? 1 : 0.5,
          duration: Duration(milliseconds: GmMotion.reduced(context) ? 0 : 160),
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(GmRadius.pill),
              border: apple ? null : Border.all(color: p.googleEdge),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                logo,
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                      color: ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón de texto (44 de alto) con glifo opcional: «Entrar con email y
/// contraseña», «¿Has olvidado la contraseña?».
class LoginTextButton extends StatelessWidget {
  final String label;
  final String? icon;
  final VoidCallback? onTap;
  final String identifier;
  final Color? color;

  const LoginTextButton({
    super.key,
    required this.label,
    required this.identifier,
    this.icon,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final ink = onTap == null ? gm.label2 : (color ?? gm.label);
    return Semantics(
      identifier: identifier,
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: GmPressable(
        onTap: onTap,
        pressedScale: 0.96,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                GmIcon(icon!, size: 18, color: ink),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 20 / 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: ink,
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

/// «Iniciar sesión»: cápsula de acento de 52. Deshabilitada (relleno
/// `accentSoft`, texto `label2`) hasta que el formulario es válido; cargando
/// con indicador y «Entrando…».
class LoginSubmitButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool loading;
  final VoidCallback onTap;

  const LoginSubmitButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final active = enabled || loading;
    final text = loading ? loginLoadingLabel(LoginMethod.email) : label;
    return Semantics(
      identifier: 'login-submit-button',
      button: true,
      enabled: enabled && !loading,
      label: text,
      excludeSemantics: true,
      child: GmPressable(
        onTap: enabled && !loading ? onTap : null,
        pressedScale: 0.97,
        child: AnimatedContainer(
          duration: Duration(milliseconds: GmMotion.reduced(context) ? 0 : 200),
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          decoration: BoxDecoration(
            gradient: active ? GmColors.accentFill : null,
            color: active ? null : gm.accentSoft,
            borderRadius: BorderRadius.circular(GmRadius.pill),
            boxShadow: active ? const [
              BoxShadow(
                color: Color(0x8C005A8C),
                offset: Offset(0, 8),
                blurRadius: 18,
                spreadRadius: -6,
              ),
            ] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading) ...[
                const PerfilSpinner(color: Colors.white, size: 18),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                    color: active ? Colors.white : gm.label2,
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

/// Raya «o» entre los proveedores y el email.
class LoginOrDivider extends StatelessWidget {
  const LoginOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return ExcludeSemantics(
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: gm.sep)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('o', style: GmText.meta(color: gm.label2)),
          ),
          Expanded(child: Container(height: 1, color: gm.sep)),
        ],
      ),
    );
  }
}

// ── Aviso de error ──────────────────────────────────────────────────────────

/// Aviso en línea (r18, `errSoft`): título rojo 15/20 · 700 y texto 14/19.
class LoginErrorBanner extends StatelessWidget {
  final String title;
  final String text;
  const LoginErrorBanner({super.key, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final p = LoginPalette.of(context);
    return Semantics(
      identifier: 'login-error-banner',
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: p.errSoft,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: GmIcon(LoginIcons.alert, size: 20, color: gm.closedText),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontSize: 15,
                        height: 20 / 15,
                        fontWeight: FontWeight.w700,
                        color: gm.closedText,
                      )),
                  Text(text, style: GmText.sub(color: gm.label)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Campo ───────────────────────────────────────────────────────────────────

/// Campo del rediseño: etiqueta 13/18 en caja normal, tarjeta r16 con
/// sombra e1, anillo de acento al enfocar y rojo con error. 52 de alto.
class LoginField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String identifier;
  final bool error;
  final bool enabled;
  final bool obscure;

  /// Solo contraseña: alterna mostrar / ocultar.
  final VoidCallback? onToggleObscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const LoginField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.focusNode,
    required this.identifier,
    this.error = false,
    this.enabled = true,
    this.obscure = false,
    this.onToggleObscure,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<LoginField> createState() => _LoginFieldState();
}

class _LoginFieldState extends State<LoginField> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(covariant LoginField old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      old.focusNode.removeListener(_onFocus);
      widget.focusNode.addListener(_onFocus);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocus);
    super.dispose();
  }

  void _onFocus() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final focused = widget.focusNode.hasFocus;
    final ring = widget.error
        ? gm.closedText
        : focused
            ? gm.accent
            : Colors.transparent;
    final reduced = GmMotion.reduced(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(widget.label, style: GmText.eyebrow(color: gm.label2)),
        ),
        Semantics(
          identifier: widget.identifier,
          textField: true,
          child: AnimatedContainer(
            duration: Duration(milliseconds: reduced ? 0 : 160),
            constraints: const BoxConstraints(minHeight: 52),
            padding: EdgeInsets.only(
                left: 16, right: widget.onToggleObscure != null ? 4 : 16),
            decoration: BoxDecoration(
              color: gm.card,
              borderRadius: BorderRadius.circular(16),
              boxShadow: gm.shadow1,
              border: Border.all(color: ring, width: 1.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    enabled: widget.enabled,
                    obscureText: widget.obscure,
                    autocorrect: false,
                    enableSuggestions: !widget.obscure &&
                        widget.keyboardType != TextInputType.emailAddress,
                    keyboardType: widget.keyboardType,
                    textInputAction: widget.textInputAction,
                    autofillHints: widget.autofillHints,
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
                    cursorColor: gm.accent,
                    style: TextStyle(
                        fontSize: 17, height: 22 / 17, color: gm.label),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      filled: false,
                      hintText: widget.hint,
                      hintStyle: TextStyle(fontSize: 17, color: gm.label2),
                    ),
                  ),
                ),
                if (widget.onToggleObscure != null)
                  Semantics(
                    identifier: 'login-password-toggle',
                    button: true,
                    label: widget.obscure
                        ? 'Mostrar contraseña'
                        : 'Ocultar contraseña',
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        widget.onToggleObscure!();
                      },
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child: GmIcon(
                            widget.obscure ? LoginIcons.eye : LoginIcons.eyeOff,
                            size: 20,
                            color: gm.label2,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Legal ───────────────────────────────────────────────────────────────────

/// «Al continuar aceptas los Términos y la Política de privacidad.» con los
/// dos enlaces pulsables (subrayados, `label`, 600). Los enlaces son
/// `WidgetSpan` para llevar su propio `Semantics.identifier`.
class LoginLegalLine extends StatelessWidget {
  final VoidCallback onTerms;
  final VoidCallback onPrivacy;
  const LoginLegalLine(
      {super.key, required this.onTerms, required this.onPrivacy});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final base = GmText.meta(color: gm.label2);
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          const TextSpan(text: 'Al continuar aceptas los '),
          _link(gm, base, 'Términos', 'login-terms-link', onTerms),
          const TextSpan(text: ' y la '),
          _link(gm, base, 'Política de privacidad', 'login-privacy-link',
              onPrivacy),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  InlineSpan _link(GmColors gm, TextStyle base, String text, String id,
          VoidCallback onTap) =>
      WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: Semantics(
          identifier: id,
          link: true,
          button: true,
          label: text,
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Text(
              text,
              style: base.copyWith(
                color: gm.label,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: gm.label,
              ),
            ),
          ),
        ),
      );
}

// ── Mascota ─────────────────────────────────────────────────────────────────

/// Volcán mascota contento (100 × 70): cráter de lava, mofletes y sonrisa.
class LoginVolcano extends StatelessWidget {
  final double width;
  const LoginVolcano({super.key, this.width = 72});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: CustomPaint(
          size: Size(width, width * 0.7),
          painter: _HappyVolcanoPainter(GmColors.of(context)),
        ),
      );
}

class _HappyVolcanoPainter extends CustomPainter {
  final GmColors gm;
  _HappyVolcanoPainter(this.gm);

  static const _lava = Color(0xFFE0603A);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 70);
    final body = Path()
      ..moveTo(6, 68)
      ..lineTo(34, 34)
      ..cubicTo(37, 30.6, 40, 29.9, 42.6, 31.8)
      ..lineTo(46.9, 34.8)
      ..cubicTo(50.1, 37, 53.5, 37, 56.7, 34.8)
      ..lineTo(61, 31.8)
      ..cubicTo(63.6, 29.9, 66.6, 30.6, 69.6, 34)
      ..lineTo(94, 68)
      ..close();
    canvas.drawPath(body, Paint()..color = gm.volcFill);
    canvas.drawPath(
        body,
        Paint()
          ..color = gm.sep
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(38.5, 33.5)
        ..lineTo(44.1, 37.5)
        ..cubicTo(48.1, 40.3, 53.3, 40.3, 57.3, 37.5)
        ..lineTo(62.9, 33.5),
      stroke
        ..color = _lava
        ..strokeWidth = 3.4,
    );
    final ink = Paint()..color = gm.volcInk;
    canvas.drawCircle(const Offset(42.5, 50), 2.8, ink);
    canvas.drawCircle(const Offset(57.5, 50), 2.8, ink);
    canvas.drawPath(
      Path()
        ..moveTo(45, 56)
        ..quadraticBezierTo(50, 59.8, 55, 56),
      Paint()
        ..color = gm.volcInk
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
    final cheek = Paint()..color = _lava.withValues(alpha: 0.3);
    canvas.drawCircle(const Offset(37, 56), 3, cheek);
    canvas.drawCircle(const Offset(63, 56), 3, cheek);
  }

  @override
  bool shouldRepaint(covariant _HappyVolcanoPainter old) => old.gm != gm;
}
