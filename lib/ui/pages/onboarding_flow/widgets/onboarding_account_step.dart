import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart'
    show GmPhoto, gmDisplayName;
import 'package:guachinches/ui/pages/onboarding_flow/onboarding_logic.dart';
import 'package:guachinches/ui/pages/onboarding_flow/widgets/onboarding_icons.dart';
import 'package:guachinches/ui/pages/onboarding_flow/widgets/onboarding_legal_web_view.dart';
import 'package:guachinches/ui/pages/onboarding_flow/widgets/onboarding_step_shell.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

/// Paso 4 · «Guarda tus sitios favoritos» (tablero Onboarding · cuenta).
///
/// Dos tarjetas de sitios reales que se abren en abanico con corazones que
/// laten una vez; Apple primero (solo iOS) y luego Google, con las mismas
/// llamadas de siempre (`LoginPresenter`, cableado en [signIn] por el
/// flujo); «Explorar sin cuenta», «Tengo
/// cuenta con email» y la línea legal con enlaces. Los errores se ven en un
/// aviso dentro de la pantalla (no en un snackbar).
class OnboardingAccountStep extends StatefulWidget {
  final String? islandId;
  final Future<List<Restaurant>> Function(String? islandId) loadPlaces;
  final VoidCallback onBack;

  /// Entra con Apple o Google. Si sale bien, quien llama guarda el
  /// onboarding y navega al Inicio; aquí solo se pinta el resultado.
  final Future<OnbSignInOutcome> Function(OnbAuthProvider provider) signIn;
  final VoidCallback onSkip;
  final VoidCallback onLoginEmail;

  /// Solo pruebas: fuerza la plataforma del botón de Apple.
  final bool? showAppleOverride;

  const OnboardingAccountStep({
    super.key,
    required this.islandId,
    required this.loadPlaces,
    required this.onBack,
    required this.signIn,
    required this.onSkip,
    required this.onLoginEmail,
    this.showAppleOverride,
  });

  @override
  State<OnboardingAccountStep> createState() => OnboardingAccountStepState();
}

@visibleForTesting
class OnboardingAccountStepState extends State<OnboardingAccountStep> {
  OnbAuthProvider? _loading;
  OnbAuthProvider? _error;

  List<Restaurant>? _places;
  bool _placesFailed = false;

  late final TapGestureRecognizer _terms = TapGestureRecognizer()
    ..onTap = () => OnbLegalWebView.open(context,
        url: kOnbTermsUrl, title: 'Términos de uso');
  late final TapGestureRecognizer _privacy = TapGestureRecognizer()
    ..onTap = () => OnbLegalWebView.open(context,
        url: kOnbPrivacyUrl, title: 'Política de privacidad');

  bool get _showApple => widget.showAppleOverride ?? Platform.isIOS;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  @override
  void didUpdateWidget(covariant OnboardingAccountStep old) {
    super.didUpdateWidget(old);
    if (old.islandId != widget.islandId) _loadPlaces();
  }

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  Future<void> _loadPlaces() async {
    setState(() {
      _places = null;
      _placesFailed = false;
    });
    try {
      final rs = await widget.loadPlaces(widget.islandId);
      if (!mounted) return;
      final picked = onbAccountPlaces(rs);
      setState(() {
        _places = picked;
        _placesFailed = picked.length < 2;
      });
    } catch (e) {
      AppLogger.warn('onboarding', 'sitios de la tarjeta: $e');
      if (!mounted) return;
      setState(() => _placesFailed = true);
    }
  }

  Future<void> _login(OnbAuthProvider p) async {
    if (_loading != null) return;
    if (p == OnbAuthProvider.apple && !Platform.isIOS) return;
    HapticFeedback.lightImpact();
    setState(() {
      _loading = p;
      _error = null;
    });
    final outcome = await widget.signIn(p);
    if (!mounted) return;
    switch (outcome) {
      case OnbSignInOutcome.success:
        // El flujo ya navega al Inicio.
        break;
      case OnbSignInOutcome.error:
        HapticFeedback.mediumImpact();
        _showError(p);
      case OnbSignInOutcome.cancelled:
        setState(() => _loading = null);
    }
  }

  void _showError(OnbAuthProvider p) {
    setState(() {
      _loading = null;
      _error = p;
    });
  }

  /// Aviso de error (pruebas).
  @visibleForTesting
  void showErrorForTesting(OnbAuthProvider p) => _showError(p);

  /// Estado «Conectando con …» (pruebas).
  @visibleForTesting
  void showLoadingForTesting(OnbAuthProvider p) {
    setState(() {
      _loading = p;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final busy = _loading != null;
    final linkStyle = TextStyle(
      color: gm.label,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: gm.label,
    );
    return OnbPage(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OnbTopBar(
              step: 4,
              onBack: widget.onBack,
              backIdentifier: 'onboarding-account-back',
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 18),
                    _FanCards(places: _places, failed: _placesFailed),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GmRise(
                            trigger: GmTrigger.mount,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Último paso',
                                    style: GmText.eyebrow(color: gm.label2)),
                                const SizedBox(height: 2),
                                Semantics(
                                  header: true,
                                  child: Text(
                                    'Guarda tus sitios favoritos',
                                    style: GmText.largeTitle(color: gm.label)
                                        .copyWith(letterSpacing: -0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 10),
                            _ErrorBanner(provider: _error!),
                          ] else ...[
                            const SizedBox(height: 6),
                            Text(
                              'Tus guardados, listas y reseñas, en todos tus '
                              'dispositivos. Tarda dos segundos.',
                              style: GmText.body(color: gm.label2),
                            ),
                          ],
                          const SizedBox(height: 20),
                          GmRise(
                            index: 2,
                            trigger: GmTrigger.mount,
                            child: Column(
                              children: [
                                if (_showApple) ...[
                                  _OAuthCapsule(
                                    provider: OnbAuthProvider.apple,
                                    loading: _loading == OnbAuthProvider.apple,
                                    disabled: busy &&
                                        _loading != OnbAuthProvider.apple,
                                    onTap: () => _login(OnbAuthProvider.apple),
                                    identifier: 'onboarding-account-apple',
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                _OAuthCapsule(
                                  provider: OnbAuthProvider.google,
                                  loading: _loading == OnbAuthProvider.google,
                                  disabled: busy &&
                                      _loading != OnbAuthProvider.google,
                                  onTap: () => _login(OnbAuthProvider.google),
                                  identifier: 'onboarding-account-google',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          OnbTextButton(
                            label: 'Explorar sin cuenta',
                            identifier: 'onboarding-account-skip',
                            onTap: busy ? null : widget.onSkip,
                          ),
                          OnbTextButton(
                            label: 'Tengo cuenta con email',
                            muted: true,
                            fontSize: 14,
                            weight: FontWeight.w500,
                            identifier: 'onboarding-account-email',
                            onTap: busy ? null : widget.onLoginEmail,
                          ),
                          const SizedBox(height: 6),
                          Semantics(
                            identifier: 'onboarding-account-legal',
                            container: true,
                            child: Text.rich(
                              TextSpan(
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 18 / 13,
                                  color: gm.label2,
                                ),
                                children: [
                                  const TextSpan(
                                      text: 'Al continuar aceptas los '),
                                  TextSpan(
                                    text: 'Términos',
                                    style: linkStyle,
                                    recognizer: _terms,
                                  ),
                                  const TextSpan(text: ' y la '),
                                  TextSpan(
                                    text: 'Política de privacidad',
                                    style: linkStyle,
                                    recognizer: _privacy,
                                  ),
                                  const TextSpan(text: '.'),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
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

/// Aviso de error dentro de la pantalla (sustituye al snackbar).
class _ErrorBanner extends StatelessWidget {
  final OnbAuthProvider provider;
  const _ErrorBanner({required this.provider});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: 'onboarding-account-error',
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: gm.closedText.withValues(alpha: gm.isDark ? 0.14 : 0.09),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: GmIcon(OnbIcons.alert, size: 20, color: gm.closedText),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    onbAuthErrorTitle(provider),
                    style:
                        GmText.body(color: gm.closedText, w: FontWeight.w700),
                  ),
                  Text(kOnbAuthErrorText, style: GmText.sub(color: gm.label)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón de Apple / Google en cápsula de 52 (colores de marca por tema).
class _OAuthCapsule extends StatelessWidget {
  final OnbAuthProvider provider;
  final bool loading;
  final bool disabled;
  final VoidCallback onTap;
  final String identifier;

  const _OAuthCapsule({
    required this.provider,
    required this.loading,
    required this.disabled,
    required this.onTap,
    required this.identifier,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final night = gm.isDark;
    final apple = provider == OnbAuthProvider.apple;
    final Color bg;
    final Color ink;
    final Color? edge;
    if (apple) {
      bg = night ? Colors.white : Colors.black;
      ink = night ? Colors.black : Colors.white;
      edge = null;
    } else {
      bg = night ? const Color(0xFF131314) : Colors.white;
      ink = night ? const Color(0xFFE3E3E3) : const Color(0xFF1F1F1F);
      edge = night ? const Color(0xFF8E918F) : const Color(0x381F1A14);
    }
    final label = loading
        ? onbAuthLoadingLabel(provider)
        : 'Continuar con ${onbProviderName(provider)}';
    final Widget leading = loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CupertinoActivityIndicator(
              radius: 9,
              color: ink,
              animating: !GmMotion.reduced(context),
            ),
          )
        : (apple
            ? GmIcon(OnbIcons.apple, size: 20, color: ink)
            : GmIcon(OnbIcons.google, size: 20, color: ink));
    final enabled = !disabled && !loading;
    return Semantics(
      identifier: identifier,
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: GmPressable(
        onTap: enabled ? onTap : null,
        pressedScale: 0.97,
        child: Opacity(
          opacity: disabled ? 0.45 : 1,
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(GmRadius.pill),
              border: edge == null ? null : Border.all(color: edge, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                leading,
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      height: 22 / 17,
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

/// Dos tarjetas de sitios reales que se abren en abanico (900 ms, asentar)
/// con corazones que laten una vez (squash, 1,1 s). Mientras cargan, foto
/// en relleno; si no hay sitios, glifo de marca sin nombre (nunca uno
/// inventado).
class _FanCards extends StatelessWidget {
  final List<Restaurant>? places;
  final bool failed;

  const _FanCards({required this.places, required this.failed});

  @override
  Widget build(BuildContext context) {
    final ps = places;
    Restaurant? at(int i) =>
        (!failed && ps != null && ps.length > i) ? ps[i] : null;
    final loading = ps == null && !failed;
    return ExcludeSemantics(
      child: SizedBox(
        height: 200,
        child: Center(
          child: SizedBox(
            width: 278,
            height: 200,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  top: 14,
                  child: _Fan(
                    fromDx: 30,
                    toDeg: -6,
                    delay: const Duration(milliseconds: 200),
                    child: _MiniPlace(
                        place: at(0),
                        loading: loading,
                        glyph: GmGlyphKind.cabra),
                  ),
                ),
                Positioned(
                  left: 128,
                  top: 0,
                  child: _Fan(
                    fromDx: -30,
                    toDeg: 5,
                    delay: const Duration(milliseconds: 300),
                    child: _MiniPlace(
                        place: at(1),
                        loading: loading,
                        glyph: GmGlyphKind.copa),
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

class _Fan extends StatelessWidget {
  final double fromDx;
  final double toDeg;
  final Duration delay;
  final Widget child;

  const _Fan({
    required this.fromDx,
    required this.toDeg,
    required this.delay,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GmOnce(
      duration: const Duration(milliseconds: 900),
      delay: delay,
      trigger: GmTrigger.mount,
      child: child,
      builder: (_, t, c) {
        final e = GmMotion.settle.transform(t);
        return Transform.translate(
          offset: Offset(fromDx * (1 - e), 0),
          child: Transform.rotate(angle: toDeg * e * 3.1415926 / 180, child: c),
        );
      },
    );
  }
}

class _MiniPlace extends StatelessWidget {
  final Restaurant? place;
  final bool loading;
  final GmGlyphKind glyph;

  const _MiniPlace({
    required this.place,
    required this.loading,
    required this.glyph,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final p = place;
    final Widget photo;
    if (p != null) {
      photo = GmPhoto(p.mainFoto, decodeWidth: 420);
    } else if (loading) {
      photo = const GmFill();
    } else {
      photo = ColoredBox(
        color: gm.fill,
        child: Center(child: GmGlyph(glyph, size: 44)),
      );
    }
    return Container(
      width: 150,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: gm.card,
        borderRadius: BorderRadius.circular(GmRadius.card),
        boxShadow: gm.shadow2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 112,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(GmRadius.photo),
                  child: photo,
                ),
                const Positioned(right: 6, top: 6, child: _PoppingHeart()),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
            child: SizedBox(
              height: 20,
              child: p != null
                  ? Text(
                      gmDisplayName(p.nombre),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        height: 20 / 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                        color: gm.label,
                      ),
                    )
                  : (loading
                      ? const Align(
                          alignment: Alignment.centerLeft,
                          child: OnbSkel(width: 90, height: 12, radius: 6))
                      : null),
            ),
          ),
        ],
      ),
    );
  }
}

/// Corazón activo en cristal sobre la foto; late una vez (squash 760 ms).
class _PoppingHeart extends StatelessWidget {
  const _PoppingHeart();

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return GmOnce(
      duration: const Duration(milliseconds: 760),
      delay: const Duration(milliseconds: 1100),
      trigger: GmTrigger.mount,
      builder: (_, t, child) {
        // Fotogramas `squash` del Sistema (como en el tablero, espera al
        // 80 % durante el retardo: visible desde el principio).
        const stops = [
          (0.0, 0.8),
          (0.3, 1.18),
          (0.52, 0.94),
          (0.72, 1.03),
          (1.0, 1.0)
        ];
        const stopsY = [
          (0.0, 0.8),
          (0.3, 0.84),
          (0.52, 1.06),
          (0.72, 0.98),
          (1.0, 1.0)
        ];
        final sx = gmKeyframes(t, stops, curve: GmMotion.spring);
        final sy = gmKeyframes(t, stopsY, curve: GmMotion.spring);
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(sx, sy, 1),
          child: child,
        );
      },
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: gm.photoGlass,
          shape: BoxShape.circle,
          border: Border.all(color: gm.photoEdge, width: 0.5),
        ),
        child: GmIcon(GmIcons.heartFilled, size: 17, color: GmColors.heart),
      ),
    );
  }
}
