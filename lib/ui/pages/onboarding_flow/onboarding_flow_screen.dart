import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/core/analytics/analytics.dart';
import 'package:guachinches/core/analytics/analytics_events.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/location/location_cubit.dart';
import 'package:guachinches/data/cubit/new_home/islands_cubit.dart';
import 'package:guachinches/data/cubit/new_home/new_home_filters_cubit.dart';
import 'package:guachinches/data/cubit/onboarding/onboarding_cubit.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/data/model/Category.dart';
import 'package:guachinches/data/model/Island.dart';
import 'package:guachinches/data/newsletter/newsletter_consent_service.dart';
import 'package:guachinches/ui/pages/newsletter/newsletter_consent_sheet.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/pages/login/login.dart';
import 'package:guachinches/ui/pages/login/login_presenter.dart';
import 'package:guachinches/ui/pages/login/widgets/oauth_button.dart';
import 'package:guachinches/ui/pages/new_home/new_home_tab_scaffold.dart';
import 'package:guachinches/ui/pages/splash_screen/splash_screen.dart';
import 'package:http/http.dart';

/// Onboarding editorial — 6 pantallas:
///   intro · nombre · isla · gustos · ubicación · cuenta
/// Persiste preferencias en flutter_secure_storage y, si es posible,
/// en NewHomeFiltersCubit para personalizar el home al entrar.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _ctrl = PageController();

  // Estado recolectado (el nombre se obtiene del login social, no aquí)
  Island? _island;
  final Set<String> _tastes = {};

  static const _totalSteps = 4; // isla · gustos · ubicación · cuenta

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

  Future<void> _finish() async {
    final cubit = context.read<OnboardingCubit>();
    await cubit.markFinished();
    if (_island != null) {
      await cubit.setIsland(_island!.id);
      try {
        context.read<NewHomeFiltersCubit>().selectIsland(
              id: _island!.id,
              key: _island!.key ?? '',
              label: _island!.name,
            );
      } catch (_) {}
    }
    if (_tastes.isNotEmpty) {
      await cubit.setTastes(_tastes.toList());
    }
    // Person properties para segmentar en PostHog (isla + nº de categorías
    // preferidas). Se mergea con el usuario identificado tras el login social.
    Analytics.I.setPersonProperties({
      AnalyticsEvents.propIslandId: _island?.id,
      AnalyticsEvents.propPreferredCategories: _tastes.length,
    });
  }

  Future<void> _skipAll() async {
    Analytics.I.logEvent(AnalyticsEvents.onboardingFinished, {'method': 'skip'});
    await _finish();
    if (!mounted) return;
    GlobalMethods().pushAndReplacement(context, SplashScreen());
  }

  Future<void> _goToLogin() async {
    Analytics.I
        .logEvent(AnalyticsEvents.onboardingFinished, {'method': 'login_email'});
    await _finish();
    if (!mounted) return;
    // Push (no replace) para que Login pueda volver al onboarding
    // y muestre sus botones de cerrar/saltar (canPop == true).
    GlobalMethods().pushPage(
      context,
      const Login('Inicia sesión para sincronizar tus favoritos.'),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Onboarding siempre en light mode — usamos los tokens de la paleta
    // crema/ink ignorando el ThemeMode global. defaultTextColor controla
    // los estilos que no especifican color explícito.
    AppTextStyles.defaultTextColor = AppColors.ink;
    return Scaffold(
      backgroundColor: AppColors.crema,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: AppColors.crema,
        ),
        child: SafeArea(
          child: PageView(
            controller: _ctrl,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _StepWelcome(
                onStart: () => _go(1),
                onLogin: _goToLogin,
              ),
              // El nombre ya no se pide aquí: viene del login social
              // (Google/Apple) o del registro. Menos fricción.
              _StepIsland(
                step: 1,
                total: _totalSteps,
                userName: '',
                selectedId: _island?.id,
                onBack: () => _go(0),
                onContinue: (island) {
                  setState(() => _island = island);
                  _go(2);
                },
              ),
              _StepTastes(
                step: 2,
                total: _totalSteps,
                selected: _tastes,
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
              _StepLocation(
                step: 3,
                total: _totalSteps,
                onBack: () => _go(2),
                onContinue: () => _go(4),
              ),
              _StepAccount(
                step: 4,
                total: _totalSteps,
                onBack: () => _go(3),
                onPersist: _finish,
                onSkip: _skipAll,
                onLoginEmail: _goToLogin,
              ),
            ],
          ),
        ),
      ),
    );
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
  static const double _swipeStart = 0.62; // primer 62% = reposo; resto = barrido

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
          final raw =
              ((_ctrl.value - _swipeStart) / (1 - _swipeStart)).clamp(0.0, 1.0);
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
            color: AppColors.ink.withOpacity(0.22),
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
// PASO 2 · Isla
// ─────────────────────────────────────────────────────────────────────

class _StepIsland extends StatefulWidget {
  final int step;
  final int total;
  final String userName;
  final String? selectedId;
  final VoidCallback onBack;
  final ValueChanged<Island> onContinue;

  const _StepIsland({
    required this.step,
    required this.total,
    required this.userName,
    required this.selectedId,
    required this.onBack,
    required this.onContinue,
  });

  @override
  State<_StepIsland> createState() => _StepIslandState();
}

class _StepIslandState extends State<_StepIsland> {
  String? _selectedId;
  Island? _selected;

  static const _islandEmoji = {
    'tenerife': '🏔',
    'gran canaria': '🌅',
    'lanzarote': '🌋',
    'fuerteventura': '🏝',
    'la palma': '🌿',
    'la gomera': '🌲',
    'el hierro': '🌊',
  };

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedId;
  }

  String _iconFor(String name) {
    final n = name.toLowerCase().trim();
    return _islandEmoji[n] ?? '🏝';
  }

  String _greeting() {
    final n = widget.userName.trim();
    if (n.isEmpty) return '¿EN QUÉ\nISLA ESTÁS?';
    final cap = '${n[0].toUpperCase()}${n.substring(1).toLowerCase()}';
    return '$cap,\n¿EN QUÉ ISLA\nESTÁS?';
  }

  @override
  Widget build(BuildContext context) {
    return _StepShell(
      step: widget.step,
      total: widget.total,
      onBack: widget.onBack,
      eyebrow: 'PASO ${widget.step} DE ${widget.total}',
      title: _greeting(),
      subtitle:
          'Te enseñamos primero lo de aquí. Puedes cambiar siempre que quieras.',
      cta: 'CONTINUAR',
      ctaEnabled: _selected != null,
      onCta: () => widget.onContinue(_selected!),
      child: BlocBuilder<IslandsCubit, IslandsState>(
        builder: (context, state) {
          if (state is IslandsLoaded && state.islands.isNotEmpty) {
            final list = [...state.islands]
              ..sort((a, b) => a.position.compareTo(b.position));
            return _IslandsGrid(
              islands: list,
              selectedId: _selectedId,
              iconFor: _iconFor,
              onTap: (i) => setState(() {
                _selectedId = i.id;
                _selected = i;
              }),
            );
          }
          if (state is IslandsFailure) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No pudimos cargar las islas. Puedes seguir y elegirla más tarde.',
                textAlign: TextAlign.center,
                style: AppTextStyles.ui(
                  size: 13,
                  color: AppColors.inkMuted,
                ),
              ),
            );
          }
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}

class _IslandsGrid extends StatelessWidget {
  final List<Island> islands;
  final String? selectedId;
  final String Function(String name) iconFor;
  final ValueChanged<Island> onTap;

  const _IslandsGrid({
    required this.islands,
    required this.selectedId,
    required this.iconFor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.55,
      ),
      itemCount: islands.length,
      itemBuilder: (_, i) {
        final island = islands[i];
        final selected = island.id == selectedId;
        return _IslandCard(
          name: island.name,
          icon: iconFor(island.name),
          selected: selected,
          onTap: () => onTap(island),
        );
      },
    );
  }
}

class _IslandCard extends StatelessWidget {
  final String name;
  final String icon;
  final bool selected;
  final VoidCallback onTap;

  const _IslandCard({
    required this.name,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: AppColors.cremaSoft,
            border: Border.all(
              color: selected
                  ? AppColors.atlantico
                  : AppColors.borderCreamMd,
              width: selected ? 1.6 : 1.0,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(icon, style: const TextStyle(fontSize: 26)),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.displayHero(
                        size: 14,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
              if (selected)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.atlantico,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        size: 14, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// PASO 3 · Gustos
// ─────────────────────────────────────────────────────────────────────

class _Taste {
  final String key; // id real de la categoría (backend)
  final String emoji;
  final String label;
  final Color accent;
  const _Taste(this.key, this.emoji, this.label, this.accent);
}

/// Categorías reales (`/categorias`) que son **servicios/amenities** y no
/// cocina. Idealmente el backend las marcaría con un campo `kind`; mientras
/// tanto las clasificamos por nombre normalizado (ver migration backend
/// `028-categories-kind-and-user-preferences`).
const Set<String> _kServiceCategoryNames = {
  'terraza',
  'datafono',
  'permite mascotas',
  'animales',
  'acceso pmr',
  'zona infantil',
  'con vistas',
  'cosecha propia',
  'mercado',
  'experiencia',
};

/// Emoji por nombre de categoría normalizado. Si no hay match, cae a un
/// genérico según el grupo (🍽️ cocina / 🛎️ servicio).
const Map<String, String> _kCategoryEmoji = {
  // cocina
  'carne cabra': '🐐',
  'cochino negro': '🐖',
  'papas, pinas y costillas': '🥔',
  'pescado o marisco': '🐟',
  'puchero': '🍲',
  'sin gluten': '🌾',
  // servicios
  'terraza': '⛱️',
  'datafono': '💳',
  'permite mascotas': '🐾',
  'animales': '🐕',
  'acceso pmr': '♿',
  'zona infantil': '🧒',
  'con vistas': '🏞️',
  'cosecha propia': '🌿',
  'mercado': '🧺',
  'experiencia': '✨',
};

String _normalizeCat(String s) {
  const from = 'áàäâãéèëêíìïîóòöôõúùüûñç';
  const to = 'aaaaaeeeeiiiiooooouuuunc';
  final buf = StringBuffer();
  for (final rune in s.toLowerCase().trim().runes) {
    final ch = String.fromCharCode(rune);
    final idx = from.indexOf(ch);
    buf.write(idx >= 0 ? to[idx] : ch);
  }
  return buf.toString();
}

bool _isServiceCategory(String name) =>
    _kServiceCategoryNames.contains(_normalizeCat(name));

class _StepTastes extends StatefulWidget {
  final int step;
  final int total;
  final Set<String> selected;
  final VoidCallback onBack;
  final ValueChanged<Set<String>> onContinue;

  const _StepTastes({
    required this.step,
    required this.total,
    required this.selected,
    required this.onBack,
    required this.onContinue,
  });

  @override
  State<_StepTastes> createState() => _StepTastesState();
}

class _StepTastesState extends State<_StepTastes> {
  late Set<String> _set;
  late final RemoteRepository _repo = HttpRemoteRepository(Client());

  List<_Taste> _gustos = const [];
  List<_Taste> _servicios = const [];
  bool _loading = true;
  bool _error = false;

  // Paletas por grupo (se ciclan por índice para variedad visual).
  static const _cuisineAccents = [
    AppColors.mojo,
    AppColors.sol,
    AppColors.tierra,
    AppColors.atlantico,
    AppColors.laurisilva,
  ];
  static const _serviceAccents = [
    AppColors.atlantico,
    AppColors.laurisilva,
    AppColors.atlanticoClaro,
    AppColors.tierra,
  ];

  @override
  void initState() {
    super.initState();
    _set = {...widget.selected};
    _load();
  }

  _Taste _toTaste(ModelCategory c, {required bool isService, required Color accent}) {
    final emoji = _kCategoryEmoji[_normalizeCat(c.nombre)] ??
        (isService ? '🛎️' : '🍽️');
    return _Taste(c.id, emoji, c.nombre.toUpperCase(), accent);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final cats = await _repo.getAllCategories();
      final gustos = <_Taste>[];
      final servicios = <_Taste>[];
      for (final c in cats) {
        if (_isServiceCategory(c.nombre)) {
          servicios.add(_toTaste(c,
              isService: true,
              accent: _serviceAccents[servicios.length % _serviceAccents.length]));
        } else {
          gustos.add(_toTaste(c,
              isService: false,
              accent: _cuisineAccents[gustos.length % _cuisineAccents.length]));
        }
      }
      if (!mounted) return;
      setState(() {
        _gustos = gustos;
        _servicios = servicios;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  void _toggle(String key) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_set.contains(key)) {
        _set.remove(key);
      } else {
        _set.add(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final reachedMin = _set.length >= 3;
    final total = _gustos.length + _servicios.length;
    return _StepShell(
      step: widget.step,
      total: widget.total,
      onBack: widget.onBack,
      eyebrow: 'PASO ${widget.step} DE ${widget.total}',
      title: '¿QUÉ TE\nTIRA MÁS?',
      subtitle:
          'Elige lo que te gusta y te lo enseñamos primero. Mínimo 3.',
      cta: reachedMin ? 'CONTINUAR' : 'ELIGE ${3 - _set.length} MÁS',
      ctaEnabled: reachedMin,
      onCta: () => widget.onContinue(_set),
      titleTrailing: (_loading || total == 0)
          ? null
          : _SelectionCounter(count: _set.length, total: total),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(AppColors.atlantico),
          ),
        ),
      );
    }
    if (_error) {
      return Padding(
        padding: const EdgeInsets.only(top: 32),
        child: Column(
          children: [
            Text(
              'No hemos podido cargar las categorías.',
              textAlign: TextAlign.center,
              style: AppTextStyles.ui(size: 14, color: AppColors.inkSoft),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _load,
              child: Text(
                'Reintentar',
                style: AppTextStyles.displaySection(size: 12)
                    .copyWith(color: AppColors.atlantico),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_gustos.isNotEmpty) ...[
          _GroupLabel('ME GUSTA COMER'),
          const SizedBox(height: 12),
          _wrap(_gustos),
        ],
        if (_servicios.isNotEmpty) ...[
          const SizedBox(height: 24),
          _GroupLabel('SERVICIOS QUE VALORO'),
          const SizedBox(height: 12),
          _wrap(_servicios),
        ],
      ],
    );
  }

  Widget _wrap(List<_Taste> items) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((t) {
        return _TasteChip(
          taste: t,
          selected: _set.contains(t.key),
          onTap: () => _toggle(t.key),
        );
      }).toList(),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String text;
  const _GroupLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.eyebrow(size: 11, color: AppColors.inkMuted)
          .copyWith(letterSpacing: 1.4),
    );
  }
}

class _SelectionCounter extends StatelessWidget {
  final int count;
  final int total;
  const _SelectionCounter({required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    final filled = count > 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: filled ? AppColors.atlantico : AppColors.cremaSoft,
        border: Border.all(
          color: filled ? AppColors.atlantico : AppColors.borderCreamMd,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count / $total',
        style: AppTextStyles.displaySection(size: 11).copyWith(
          color: filled ? Colors.white : AppColors.inkSoft,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _TasteChip extends StatelessWidget {
  final _Taste taste;
  final bool selected;
  final VoidCallback onTap;

  const _TasteChip({
    required this.taste,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? taste.accent : AppColors.cremaSoft;
    final fg = selected ? Colors.white : AppColors.ink;
    final border = selected ? taste.accent : AppColors.borderCreamMd;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.fromLTRB(12, 10, selected ? 14 : 14, 10),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border, width: selected ? 0 : 1.0),
            borderRadius: BorderRadius.circular(999),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: taste.accent.withOpacity(0.30),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withOpacity(0.20)
                      : taste.accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  taste.emoji,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                taste.label,
                style: AppTextStyles.displaySection(size: 11)
                    .copyWith(color: fg, letterSpacing: 0.7),
              ),
              if (selected) ...[
                const SizedBox(width: 6),
                Container(
                  width: 16,
                  height: 16,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 12,
                    color: taste.accent,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// PASO 4 · Ubicación
// ─────────────────────────────────────────────────────────────────────

class _StepLocation extends StatefulWidget {
  final int step;
  final int total;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  const _StepLocation({
    required this.step,
    required this.total,
    required this.onBack,
    required this.onContinue,
  });

  @override
  State<_StepLocation> createState() => _StepLocationState();
}

class _StepLocationState extends State<_StepLocation> {
  bool _requesting = false;

  Future<void> _activate() async {
    if (_requesting) return;
    setState(() => _requesting = true);
    try {
      // Esperamos SOLO a que el usuario responda al diálogo de permiso; el fix
      // GPS se obtiene en segundo plano. Antes se esperaba el fix entero
      // (getCurrentPosition 15s + stream 20s) y el onboarding se quedaba pillado
      // en "ACTIVANDO…" cuando el fix tardaba o no llegaba.
      await context.read<LocationCubit>().requestPermissionOnly();
      await context.read<OnboardingCubit>().markLocationAsked();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _requesting = false);
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    return _StepShell(
      step: widget.step,
      total: widget.total,
      onBack: widget.onBack,
      eyebrow: 'PASO ${widget.step} DE ${widget.total}',
      title: 'LO BUENO,\nCERCA DE TI',
      subtitle:
          'Activa tu ubicación y te enseñamos los sitios abiertos a tu alrededor. Sin ubicación también funciona.',
      cta: _requesting ? 'ACTIVANDO…' : 'ACTIVAR UBICACIÓN',
      ctaEnabled: !_requesting,
      onCta: _activate,
      footer: Semantics(
        identifier: 'onboarding-location-skip',
        button: true,
        child: TextButton(
          onPressed: widget.onContinue,
          child: Text(
            'Ahora no',
            style: AppTextStyles.ui(
              size: 13,
              weight: FontWeight.w600,
              color: AppColors.inkMuted,
            ),
          ),
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: _LocationPulse()),
      ),
    );
  }
}

class _LocationPulse extends StatefulWidget {
  const _LocationPulse();

  @override
  State<_LocationPulse> createState() => _LocationPulseState();
}

class _LocationPulseState extends State<_LocationPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Stack(
          alignment: Alignment.center,
          children: [
            for (int i = 0; i < 3; i++) _ring(i),
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.atlantico.withOpacity(0.18),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.atlantico,
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.my_location_rounded,
                color: AppColors.atlanticoClaro,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ring(int i) {
    final t = (_ctrl.value + i / 3) % 1.0;
    final size = 80 + 120 * t;
    final opacity = (1.0 - t).clamp(0.0, 1.0) * 0.45;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.atlantico.withOpacity(opacity),
          width: 1.2,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// PASO 5 · Cuenta (easy login Google/Apple + email legacy + saltar)
// ─────────────────────────────────────────────────────────────────────

class _StepAccount extends StatefulWidget {
  final int step;
  final int total;

  /// Vuelve al paso anterior (ubicación).
  final VoidCallback onBack;

  /// Persiste el onboarding (markFinished + nombre/isla/gustos) antes de
  /// navegar al home tras un login exitoso. Es el `_finish` del flujo.
  final Future<void> Function() onPersist;
  final VoidCallback onSkip;
  final VoidCallback onLoginEmail;

  const _StepAccount({
    required this.step,
    required this.total,
    required this.onBack,
    required this.onPersist,
    required this.onSkip,
    required this.onLoginEmail,
  });

  @override
  State<_StepAccount> createState() => _StepAccountState();
}

class _StepAccountState extends State<_StepAccount> implements LoginView {
  late final RemoteRepository _repo = HttpRemoteRepository(Client());
  late final LoginPresenter _presenter =
      LoginPresenter(_repo, this, context.read<UserCubit>());

  bool _loading = false;
  bool _google = false; // proveedor activo (true=google, false=apple)

  Future<void> _onGoogle() async {
    if (_loading) return;
    HapticFeedback.lightImpact();
    setState(() {
      _loading = true;
      _google = true;
    });
    await _presenter.loginWithGoogle();
    if (mounted && _loading) {
      setState(() => _loading = false);
    }
  }

  Future<void> _onApple() async {
    if (_loading || !Platform.isIOS) return;
    HapticFeedback.lightImpact();
    setState(() {
      _loading = true;
      _google = false;
    });
    await _presenter.loginWithApple();
    if (mounted && _loading) {
      setState(() => _loading = false);
    }
  }

  @override
  loginSuccess(List<Widget> screens,
      {bool deletionPending = false, String userId = ''}) async {
    if (!mounted) return;
    Analytics.I.logEvent(AnalyticsEvents.onboardingFinished, {
      'method': _google ? 'google' : 'apple',
    });
    // Cierra el onboarding como completado y guarda las preferencias antes de
    // entrar al home.
    await widget.onPersist();
    if (!mounted) return;
    // Consentimiento de newsletter (RGPD): se pregunta UNA vez, tras el
    // registro, desvinculado del alta. Opt-in = pulsar "Sí, suscribirme".
    final consent = NewsletterConsentService(_repo);
    if (userId.isNotEmpty && !await consent.hasBeenAsked()) {
      await showNewsletterConsentSheet(
        context,
        userId: userId,
        service: consent,
        source: 'onboarding',
      );
      if (!mounted) return;
    }
    GlobalMethods().removePagesAndGoToNewScreen(
      context,
      NewHomeTabScaffold(screens: screens),
    );
  }

  @override
  loginError() {
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No hemos podido iniciar sesión. Inténtalo de nuevo.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final googleLoading = _loading && _google;
    final appleLoading = _loading && !_google;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header consistente con el resto: volver + barra de progreso.
          Row(
            children: [
              Semantics(
                identifier: 'onboarding-account-back',
                button: true,
                child: GestureDetector(
                  onTap: widget.onBack,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.inkSoft,
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ProgressBar(step: widget.step, total: widget.total),
              ),
              const SizedBox(width: 36),
            ],
          ),
          const Spacer(flex: 1),
          Center(
            child: Container(
              width: 88,
              height: 88,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.atlantico.withOpacity(0.35),
                    AppColors.atlantico.withOpacity(0.10),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.atlantico, width: 1.4),
              ),
              child: const Icon(
                Icons.bookmark_rounded,
                color: AppColors.atlanticoClaro,
                size: 38,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Center(
            child: Text(
              'ÚLTIMO PASO',
              style: AppTextStyles.eyebrow(
                size: 11,
                color: AppColors.inkMuted,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'GUARDA TUS\nSITIOS FAVORITOS',
            textAlign: TextAlign.center,
            style: AppTextStyles.displayHero(size: 32, color: AppColors.ink),
          ),
          const SizedBox(height: 12),
          Text(
            'Sincroniza guardados, listas y reseñas en todos tus dispositivos. Tarda dos segundos.',
            textAlign: TextAlign.center,
            style: AppTextStyles.editorial(
              size: 13,
              color: AppColors.inkSoft,
            ),
          ),
          const Spacer(flex: 2),
          // Google (easy login)
          Semantics(
            identifier: 'onboarding-account-google',
            button: true,
            child: OAuthButton(
              isDark: false,
              isGoogleButton: true,
              loading: googleLoading,
              disabled: _loading && !_google,
              onTap: _loading ? null : _onGoogle,
              label: googleLoading
                  ? 'Conectando con Google…'
                  : 'Continuar con Google',
            ),
          ),
          if (Platform.isIOS) ...[
            const SizedBox(height: 12),
            Semantics(
              identifier: 'onboarding-account-apple',
              button: true,
              child: OAuthButton(
                isDark: false,
                isGoogleButton: false,
                loading: appleLoading,
                disabled: _loading && _google,
                onTap: _loading ? null : _onApple,
                label: 'Continuar con Apple',
              ),
            ),
          ],
          const SizedBox(height: 14),
          Semantics(
            identifier: 'onboarding-account-skip',
            button: true,
            child: TextButton(
              onPressed: _loading ? null : widget.onSkip,
              child: Text(
                'Saltar y explorar sin cuenta',
                style: AppTextStyles.ui(
                  size: 13,
                  weight: FontWeight.w600,
                  color: AppColors.inkMuted,
                ),
              ),
            ),
          ),
          // Acceso legacy con email/contraseña (usuarios registrados antes de
          // mayo 2026). Subtle, debajo de Saltar.
          Semantics(
            identifier: 'onboarding-account-email',
            button: true,
            child: GestureDetector(
              onTap: _loading ? null : widget.onLoginEmail,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Entrar con email',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.ui(
                    size: 12,
                    color: AppColors.inkMuted.withOpacity(0.8),
                  ).copyWith(decoration: TextDecoration.underline),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              text: 'Al continuar aceptas los ',
              style: AppTextStyles.ui(
                size: 11,
                color: AppColors.inkMuted,
              ),
              children: [
                TextSpan(
                  text: 'Términos',
                  style: AppTextStyles.ui(
                    size: 11,
                    weight: FontWeight.w700,
                    color: AppColors.inkSoft,
                  ),
                ),
                const TextSpan(text: ' y la '),
                TextSpan(
                  text: 'Privacidad',
                  style: AppTextStyles.ui(
                    size: 11,
                    weight: FontWeight.w700,
                    color: AppColors.inkSoft,
                  ),
                ),
                const TextSpan(text: '. Sin spam, te lo prometemos.'),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Shell común para los pasos 1-4
// ─────────────────────────────────────────────────────────────────────

class _StepShell extends StatelessWidget {
  final int step;
  final int total;
  final VoidCallback onBack;
  final String eyebrow;
  final String title;
  final String subtitle;
  final String cta;
  final bool ctaEnabled;
  final VoidCallback onCta;
  final Widget child;
  final Widget? footer;
  final Widget? titleTrailing;

  const _StepShell({
    required this.step,
    required this.total,
    required this.onBack,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.ctaEnabled,
    required this.onCta,
    required this.child,
    this.footer,
    this.titleTrailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Semantics(
                identifier: 'onboarding-back',
                button: true,
                child: GestureDetector(
                  onTap: onBack,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.inkSoft,
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: _ProgressBar(step: step, total: total)),
              const SizedBox(width: 36),
            ],
          ),
          const SizedBox(height: 22),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow,
                    style: AppTextStyles.eyebrow(
                      size: 11,
                      color: AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: AppTextStyles.displayHero(
                            size: 38,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      if (titleTrailing != null) ...[
                        const SizedBox(width: 12),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: titleTrailing!,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    style: AppTextStyles.editorial(
                      size: 13,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 20),
                  child,
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          _PrimaryButton(
            label: cta,
            onTap: onCta,
            enabled: ctaEnabled,
            identifier: 'onboarding-continue',
          ),
          if (footer != null) Center(child: footer!),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int step;
  final int total;
  const _ProgressBar({required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final filled = i < step;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 4,
              decoration: BoxDecoration(
                color: filled
                    ? AppColors.atlantico
                    : AppColors.borderCreamMd,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final String? identifier;

  const _PrimaryButton({
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.identifier,
  });

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
