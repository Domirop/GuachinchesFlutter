import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/core/analytics/analytics.dart';
import 'package:guachinches/core/analytics/analytics_events.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/cubit/new_home/new_home_filters_cubit.dart';
import 'package:guachinches/data/cubit/onboarding/onboarding_cubit.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/data/model/Category.dart';
import 'package:guachinches/data/model/Island.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/data/newsletter/newsletter_consent_service.dart';
import 'package:guachinches/ui/pages/login/login_logic.dart';
import 'package:guachinches/ui/pages/login/login_presenter.dart';
import 'package:guachinches/ui/pages/login/login_sheet.dart';
import 'package:guachinches/ui/pages/new_home/new_home_tab_scaffold.dart';
import 'package:guachinches/ui/pages/onboarding_flow/onboarding_logic.dart';
import 'package:guachinches/ui/pages/onboarding_flow/widgets/onboarding_account_step.dart';
import 'package:guachinches/ui/pages/onboarding_flow/widgets/onboarding_island_step.dart';
import 'package:guachinches/ui/pages/onboarding_flow/widgets/onboarding_location_step.dart';
import 'package:guachinches/ui/pages/onboarding_flow/widgets/onboarding_tastes_step.dart';
import 'package:guachinches/ui/pages/settings/settings_screen.dart'
    show buildMainTabScreens;
import 'package:guachinches/ui/pages/splash_screen/splash_screen.dart';
import 'package:http/http.dart';

/// Onboarding: bienvenida · isla · gustos · ubicación · cuenta.
///
/// La bienvenida conserva su aspecto (se está rediseñando aparte); los pasos
/// 1–4 siguen el tablero `Onboarding` del rediseño iOS 27 (día y noche) y
/// viven en `widgets/`. Persiste las preferencias con [OnboardingCubit] y,
/// si puede, elige la isla en [NewHomeFiltersCubit] para el Inicio.
class OnboardingFlow extends StatefulWidget {
  /// Solo pruebas: sustituyen a las llamadas reales a `/categorias` y a
  /// `/restaurant/pagination` (tarjetas del paso de la cuenta).
  final Future<List<ModelCategory>> Function()? categoriesLoader;
  final Future<List<Restaurant>> Function(String? islandId)? placesLoader;

  const OnboardingFlow({super.key, this.categoriesLoader, this.placesLoader});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

/// Lo elegido en el onboarding (se guarda solo al terminarlo).
class _OnbChoices {
  final Island? island;
  final List<String> tastes;
  const _OnbChoices(this.island, this.tastes);
}

Future<void> _persistOnboarding(
  OnboardingCubit cubit,
  NewHomeFiltersCubit? filters,
  _OnbChoices c,
) async {
  await cubit.markFinished();
  final island = c.island;
  if (island != null) {
    await cubit.setIsland(island.id);
    filters?.selectIsland(
      id: island.id,
      key: island.key ?? '',
      label: island.name,
    );
  }
  if (c.tastes.isNotEmpty) await cubit.setTastes(c.tastes);
  // Person properties para segmentar en PostHog (isla + nº de categorías
  // preferidas). Se mergea con el usuario identificado tras el login.
  Analytics.I.setPersonProperties({
    AnalyticsEvents.propIslandId: island?.id,
    AnalyticsEvents.propPreferredCategories: c.tastes.length,
  });
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _ctrl = PageController();

  Island? _island;
  final Set<String> _tastes = {};

  late final _repo = HttpRemoteRepository(Client());

  @override
  void initState() {
    super.initState();
    Analytics.I.logEvent(AnalyticsEvents.onboardingStarted);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _go(int next) {
    Analytics.I.logEvent(AnalyticsEvents.onboardingStep, {'step': next});
    _ctrl.animateToPage(
      next,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
    HapticFeedback.selectionClick();
  }

  NewHomeFiltersCubit? _filters() {
    try {
      return context.read<NewHomeFiltersCubit>();
    } on ProviderNotFoundException {
      return null;
    }
  }

  _OnbChoices get _choices => _OnbChoices(_island, _tastes.toList());

  Future<void> _finish() =>
      _persistOnboarding(context.read<OnboardingCubit>(), _filters(), _choices);

  Future<void> _skipAll() async {
    Analytics.I
        .logEvent(AnalyticsEvents.onboardingFinished, {'method': 'skip'});
    await _finish();
    if (!mounted) return;
    GlobalMethods().pushAndReplacement(context, SplashScreen());
  }

  /// «Ya tengo cuenta» / «Tengo cuenta con email»: abre el acceso único
  /// **sin** dar el onboarding por terminado. Solo se marca terminado si se
  /// entra; si cierra el acceso, el onboarding sigue donde estaba.
  Future<void> _goToLogin({bool email = false}) async {
    final ok = await showLoginSheet(
      context,
      reason: LoginReason.onboarding,
      startOnEmail: email,
      newsletter: NewsletterConsentService(_repo),
    );
    if (!ok || !mounted) return;
    Analytics.I.logEvent(AnalyticsEvents.onboardingFinished,
        {'method': email ? 'login_email' : 'login'});
    await _finish();
    if (!mounted) return;
    _enterApp();
  }

  /// Apple / Google en línea (paso de la cuenta) con el `LoginPresenter` del
  /// acceso único. Si sale bien: eliminación pendiente (si toca), guarda el
  /// onboarding, pregunta una vez por la newsletter (RGPD) y entra al Inicio.
  Future<OnbSignInOutcome> _signIn(OnbAuthProvider provider) async {
    final presenter = LoginPresenter(_repo, context.read<UserCubit>());
    final method = provider == OnbAuthProvider.google
        ? LoginMethod.google
        : LoginMethod.apple;
    final outcome = await presenter.signIn(method);
    final session = outcome.session;
    if (session == null) {
      return outcome.failure == LoginFailure.cancelled
          ? OnbSignInOutcome.cancelled
          : OnbSignInOutcome.error;
    }
    if (!mounted) return OnbSignInOutcome.success;
    if (!await completeLogin(context, presenter, session)) {
      // Prefirió cerrar sesión: sigue en el onboarding.
      return OnbSignInOutcome.cancelled;
    }
    Analytics.I.logEvent(AnalyticsEvents.onboardingFinished, {
      'method': provider == OnbAuthProvider.google ? 'google' : 'apple',
    });
    await _finish();
    if (!mounted) return OnbSignInOutcome.success;
    await askNewsletterOnce(context, session.userId,
        service: NewsletterConsentService(_repo));
    if (!mounted) return OnbSignInOutcome.success;
    _enterApp();
    return OnbSignInOutcome.success;
  }

  /// Entra a las pestañas (Perfil = SettingsScreen, ya con sesión).
  void _enterApp() {
    GlobalMethods().removePagesAndGoToNewScreen(
      context,
      NewHomeTabScaffold(screens: buildMainTabScreens()),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // La bienvenida conserva su aspecto claro de siempre; los pasos 1–4
    // pintan su propio lienzo día/noche (OnbPage).
    AppTextStyles.defaultTextColor = AppColors.ink;
    return Scaffold(
      backgroundColor: AppColors.crema,
      body: PageView(
        controller: _ctrl,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: AppColors.crema,
            ),
            child: ColoredBox(
              color: AppColors.crema,
              child: SafeArea(
                child: _StepWelcome(
                  onStart: () => _go(1),
                  onLogin: _goToLogin,
                ),
              ),
            ),
          ),
          OnboardingIslandStep(
            selectedId: _island?.id,
            onBack: () => _go(0),
            onContinue: (island) {
              setState(() => _island = island);
              _go(2);
            },
          ),
          OnboardingTastesStep(
            selected: _tastes,
            loadCategories:
                widget.categoriesLoader ?? () => _repo.getAllCategories(),
            onBack: () => _go(1),
            onContinue: (set) {
              setState(() {
                _tastes
                  ..clear()
                  ..addAll(set);
              });
              _go(3);
            },
          ),
          OnboardingLocationStep(
            islandName: _island?.name,
            onBack: () => _go(2),
            onContinue: () => _go(4),
          ),
          OnboardingAccountStep(
            islandId: _island?.id,
            loadPlaces: widget.placesLoader ?? _loadPlaces,
            onBack: () => _go(3),
            signIn: _signIn,
            onSkip: _skipAll,
            onLoginEmail: () => _goToLogin(email: true),
          ),
        ],
      ),
    );
  }

  Future<List<Restaurant>> _loadPlaces(String? islandId) async {
    final res = islandId == null
        ? await _repo.getAllRestaurants(0)
        : await _repo.getAllRestaurants(0, islandId);
    return res.restaurants;
  }
}

// ─────────────────────────────────────────────────────────────────────
// PASO 0 · Welcome
// ─────────────────────────────────────────────────────────────────────

class _StepWelcome extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onLogin;

  const _StepWelcome({required this.onStart, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        children: [
          const Spacer(flex: 1),
          const _PostcardStack(),
          const Spacer(flex: 1),
          Text(
            'VISITADO POR\nGUACHINCHESMODERNOS',
            textAlign: TextAlign.center,
            style: AppTextStyles.eyebrow(
              size: 11,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '¿DÓNDE\nCOMEMOS\nHOY?',
            textAlign: TextAlign.center,
            style: AppTextStyles.displayHero(size: 56, color: AppColors.ink),
          ),
          const SizedBox(height: 18),
          Text(
            '"La guía gastronómica de Canarias por la gente que de verdad come en Canarias."',
            textAlign: TextAlign.center,
            style: AppTextStyles.editorial(
              size: 14,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '— Jonay y Joana',
            textAlign: TextAlign.center,
            style: AppTextStyles.ui(
              size: 11,
              weight: FontWeight.w600,
              color: AppColors.inkMuted,
            ),
          ),
          const Spacer(flex: 2),
          _PrimaryButton(
            label: 'EMPEZAR',
            onTap: onStart,
            identifier: 'onboarding-welcome-start',
          ),
          const SizedBox(height: 12),
          Semantics(
            identifier: 'onboarding-welcome-login',
            button: true,
            child: GestureDetector(
              onTap: onLogin,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Ya tengo cuenta · Iniciar sesión',
                  style: AppTextStyles.ui(
                    size: 13,
                    weight: FontWeight.w600,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Postal: foto real + etiqueta del sitio.
class _Postcard {
  final String asset;
  final String label;
  const _Postcard(this.asset, this.label);
}

const List<_Postcard> _kPostcards = [
  _Postcard(
      'assets/images/backgrounds/ddc_island_bg/tenerife_dcc.jpg', 'TENERIFE'),
  _Postcard('assets/images/backgrounds/ddc_island_bg/las_palmas_dcc.jpg',
      'GRAN CANARIA'),
  _Postcard(
      'assets/images/backgrounds/ddc_island_bg/lanzarote_dcc.jpg', 'LANZAROTE'),
  _Postcard('assets/images/backgrounds/ddc_island_bg/fuerteventura_dcc.jpg',
      'FUERTEVENTURA'),
  _Postcard(
      'assets/images/backgrounds/ddc_island_bg/la_gomera_dcc.jpg', 'LA GOMERA'),
  _Postcard(
      'assets/images/backgrounds/ddc_island_bg/el_hierro_dcc.jpg', 'EL HIERRO'),
];

/// Pila de postales (fotos reales) que se barajan sola: la de arriba se desliza
/// hacia un lado girando y desvaneciéndose, y la siguiente avanza al frente.
class _PostcardStack extends StatefulWidget {
  const _PostcardStack();

  @override
  State<_PostcardStack> createState() => _PostcardStackState();
}

class _PostcardStackState extends State<_PostcardStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  int _index = 0;

  static const double _cardW = 172;
  static const double _cardH = 212;
  static const int _visible = 3;
  static const double _swipeStart =
      0.62; // primer 62% = reposo; resto = barrido

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          setState(() => _index = (_index + 1) % _kPostcards.length);
          _ctrl.forward(from: 0);
        }
      })
      ..forward();
  }

  /// Tap sobre la pila: salta el reposo y baraja la postal de arriba ya.
  void _advanceNow() {
    if (_ctrl.value < _swipeStart) {
      HapticFeedback.selectionClick();
      _ctrl.forward(from: _swipeStart);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precarga para que la primera postal no aparezca en blanco.
    for (final pc in _kPostcards) {
      precacheImage(AssetImage(pc.asset), context);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _advanceNow,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: _cardW + 70,
        height: _cardH + 40,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final raw = ((_ctrl.value - _swipeStart) / (1 - _swipeStart))
                .clamp(0.0, 1.0);
            final p = Curves.easeInCubic.transform(raw);
            // Pintar de atrás hacia delante (j alto = más al fondo).
            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                for (int j = _visible - 1; j >= 0; j--)
                  _card(_kPostcards[(_index + j) % _kPostcards.length], j, p),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _card(_Postcard pc, int j, double p) {
    double dx, dy, rot, scale, opacity;
    if (j == 0) {
      // Carta de arriba: se desliza a la derecha, gira y se desvanece.
      dx = p * _cardW * 1.05;
      dy = -p * 12;
      rot = p * 0.20;
      scale = 1.0 - p * 0.04;
      opacity = (1 - p * 1.55).clamp(0.0, 1.0);
    } else {
      // Cartas del fondo: avanzan hacia el frente conforme p crece.
      final eff = j - p;
      scale = 1 - 0.06 * eff;
      dy = 18.0 * eff;
      dx = 0;
      rot = (j.isEven ? 1 : -1) * 0.04 * eff; // ligero tilt de "apiladas"
      opacity = (1 - 0.16 * eff).clamp(0.0, 1.0);
    }
    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(dx, dy),
        child: Transform.rotate(
          angle: rot,
          child: Transform.scale(
            scale: scale,
            child: _PostcardCard(postcard: pc, width: _cardW, height: _cardH),
          ),
        ),
      ),
    );
  }
}

class _PostcardCard extends StatelessWidget {
  final _Postcard postcard;
  final double width;
  final double height;

  const _PostcardCard({
    required this.postcard,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(7), // marco blanco tipo postal
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              postcard.asset,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              // La postal mide ~172pt; decodificar a ~520px (≈3x) en vez de a
              // resolución completa del JPG corta el pico de RAM de la pila.
              cacheWidth: 520,
            ),
            // Degradado + etiqueta del sitio (sello de postal).
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0x99000000)],
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.place_rounded,
                        size: 12, color: Colors.white70),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        postcard.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.eyebrow(
                          size: 11,
                          color: Colors.white,
                        ).copyWith(letterSpacing: 1.0),
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

// ─────────────────────────────────────────────────────────────────────

/// Botón principal de la bienvenida (aspecto de siempre; ya solo lo usa
/// ella, siempre habilitado).
class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final String? identifier;

  const _PrimaryButton({
    required this.label,
    required this.onTap,
    this.identifier,
  });

  bool get enabled => true;

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.atlantico,
          disabledBackgroundColor: AppColors.cremaOscura,
          disabledForegroundColor: AppColors.inkMuted,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        onPressed: enabled ? onTap : null,
        child: Text(
          label,
          style: AppTextStyles.displaySection(size: 12).copyWith(
            color: enabled ? Colors.white : AppColors.inkMuted,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
    if (identifier == null) return button;
    return Semantics(identifier: identifier, button: true, child: button);
  }
}
