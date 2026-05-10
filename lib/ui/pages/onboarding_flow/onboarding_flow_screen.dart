import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/cubit/location/location_cubit.dart';
import 'package:guachinches/data/cubit/new_home/islands_cubit.dart';
import 'package:guachinches/data/cubit/new_home/new_home_filters_cubit.dart';
import 'package:guachinches/data/model/Island.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/pages/login/login.dart';
import 'package:guachinches/ui/pages/register/register.dart';
import 'package:guachinches/ui/pages/splash_screen/splash_screen.dart';

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
  static const _storage = FlutterSecureStorage();
  final _ctrl = PageController();

  // Estado recolectado
  String _name = '';
  Island? _island;
  final Set<String> _tastes = {};

  static const _totalSteps = 4; // nombre · isla · gustos · ubicación

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _go(int next) {
    _ctrl.animateToPage(
      next,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
    HapticFeedback.selectionClick();
  }

  Future<void> _finish() async {
    await _storage.write(key: 'onBoardingFinished', value: 'true');
    if (_name.isNotEmpty) {
      await _storage.write(key: 'onb_name', value: _name);
    }
    if (_island != null) {
      await _storage.write(key: 'prefIslandId', value: _island!.id);
      try {
        context.read<NewHomeFiltersCubit>().selectIsland(
              id: _island!.id,
              key: _island!.key ?? '',
              label: _island!.name,
            );
      } catch (_) {}
    }
    if (_tastes.isNotEmpty) {
      await _storage.write(key: 'prefTastes', value: _tastes.join(','));
    }
  }

  Future<void> _skipAll() async {
    await _finish();
    if (!mounted) return;
    GlobalMethods().pushAndReplacement(context, SplashScreen());
  }

  Future<void> _goToLogin() async {
    await _finish();
    if (!mounted) return;
    // Push (no replace) para que Login pueda volver al onboarding
    // y muestre sus botones de cerrar/saltar (canPop == true).
    GlobalMethods().pushPage(
      context,
      const Login('Inicia sesión para sincronizar tus favoritos.'),
    );
  }

  Future<void> _goToRegister() async {
    await _finish();
    if (!mounted) return;
    GlobalMethods().pushPage(context, Register());
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
              _StepName(
                step: 1,
                total: _totalSteps,
                initial: _name,
                onBack: () => _go(0),
                onContinue: (v) {
                  setState(() => _name = v.trim());
                  _go(2);
                },
              ),
              _StepIsland(
                step: 2,
                total: _totalSteps,
                userName: _name,
                selectedId: _island?.id,
                onBack: () => _go(1),
                onContinue: (island) {
                  setState(() => _island = island);
                  _go(3);
                },
              ),
              _StepTastes(
                step: 3,
                total: _totalSteps,
                selected: _tastes,
                onBack: () => _go(2),
                onContinue: (set) {
                  setState(() {
                    _tastes
                      ..clear()
                      ..addAll(set);
                  });
                  _go(4);
                },
              ),
              _StepLocation(
                step: 4,
                total: _totalSteps,
                onBack: () => _go(3),
                onContinue: () => _go(5),
              ),
              _StepAccount(
                onCreateAccount: _goToRegister,
                onLogin: _goToLogin,
                onSkip: _skipAll,
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
          const _SunsetIllustration(),
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
          _PrimaryButton(label: 'EMPEZAR', onTap: onStart),
          const SizedBox(height: 12),
          GestureDetector(
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
        ],
      ),
    );
  }
}

class _SunsetIllustration extends StatelessWidget {
  const _SunsetIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Halo del sol
          Align(
            alignment: const Alignment(0, -0.35),
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.sol.withOpacity(0.30),
                    AppColors.sol.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Sol
          Align(
            alignment: const Alignment(0, -0.45),
            child: Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.sol,
              ),
            ),
          ),
          // Montañas
          Positioned.fill(
            child: CustomPaint(painter: _MountainsPainter()),
          ),
        ],
      ),
    );
  }
}

class _MountainsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.tierra.withOpacity(0.55);
    final w = size.width;
    final h = size.height;
    final p = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.65)
      ..lineTo(w * 0.18, h * 0.50)
      ..lineTo(w * 0.32, h * 0.62)
      ..lineTo(w * 0.50, h * 0.30)
      ..lineTo(w * 0.66, h * 0.55)
      ..lineTo(w * 0.82, h * 0.45)
      ..lineTo(w, h * 0.65)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(p, paint);

    final paint2 = Paint()..color = AppColors.tierra;
    final p2 = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.78)
      ..lineTo(w * 0.25, h * 0.68)
      ..lineTo(w * 0.45, h * 0.80)
      ..lineTo(w * 0.70, h * 0.65)
      ..lineTo(w, h * 0.80)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(p2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────
// PASO 1 · Nombre
// ─────────────────────────────────────────────────────────────────────

class _StepName extends StatefulWidget {
  final int step;
  final int total;
  final String initial;
  final VoidCallback onBack;
  final ValueChanged<String> onContinue;

  const _StepName({
    required this.step,
    required this.total,
    required this.initial,
    required this.onBack,
    required this.onContinue,
  });

  @override
  State<_StepName> createState() => _StepNameState();
}

class _StepNameState extends State<_StepName> {
  late final TextEditingController _ctrl;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial);
    _ctrl.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = _ctrl.text.trim();
    return _StepShell(
      step: widget.step,
      total: widget.total,
      onBack: widget.onBack,
      eyebrow: 'PASO ${widget.step} DE ${widget.total}',
      title: '¿CÓMO TE\nLLAMAS?',
      subtitle: 'Solo lo usamos para saludarte. Nada más.',
      cta: 'CONTINUAR',
      ctaEnabled: value.length >= 2,
      onCta: () => widget.onContinue(_ctrl.text),
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: TextField(
          controller: _ctrl,
          focusNode: _focus,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.words,
          autofocus: true,
          cursorColor: AppColors.atlantico,
          style: AppTextStyles.displayHero(size: 22, color: AppColors.ink),
          onSubmitted: (_) {
            if (value.length >= 2) widget.onContinue(_ctrl.text);
          },
          decoration: InputDecoration(
            hintText: 'Tu nombre',
            hintStyle: AppTextStyles.ui(
              size: 18,
              color: AppColors.inkMuted,
            ),
            filled: true,
            fillColor: AppColors.cremaSoft,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.borderCreamMd),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.borderCreamMd),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppColors.atlantico, width: 1.6),
            ),
          ),
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
  final String key;
  final String emoji;
  final String label;
  final Color accent;
  const _Taste(this.key, this.emoji, this.label, this.accent);
}

const List<_Taste> _kTastes = [
  _Taste('guachinches', '🍷', 'GUACHINCHES TRADICIONALES', AppColors.tierra),
  _Taste('mariscos', '🦐', 'MARISCOS', AppColors.atlantico),
  _Taste('carnes', '🥩', 'CARNES', AppColors.mojo),
  _Taste('quesos', '🧀', 'QUESOS', AppColors.sol),
  _Taste('vegano', '🌱', 'VEGANO', AppColors.laurisilva),
  _Taste('cafes', '☕️', 'CAFÉS', AppColors.tierra),
  _Taste('tapas', '🍤', 'TAPAS', AppColors.atlantico),
  _Taste('mojo_picon', '🌶', 'MOJO PICÓN', AppColors.mojo),
  _Taste('vino_local', '🍇', 'VINO LOCAL', AppColors.tierra),
  _Taste('postres', '🍰', 'POSTRES', AppColors.atlanticoClaro),
  _Taste('pizzas', '🍕', 'PIZZAS', AppColors.mojo),
  _Taste('cocina_canaria', '🍌', 'COCINA CANARIA', AppColors.sol),
  _Taste('tradicional', '🏠', 'TRADICIONAL', AppColors.tierra),
  _Taste('moderno', '✨', 'MODERNO', AppColors.atlantico),
];

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

  @override
  void initState() {
    super.initState();
    _set = {...widget.selected};
  }

  @override
  Widget build(BuildContext context) {
    final reachedMin = _set.length >= 3;
    final selectedCount = _set.length;
    return _StepShell(
      step: widget.step,
      total: widget.total,
      onBack: widget.onBack,
      eyebrow: 'PASO ${widget.step} DE ${widget.total}',
      title: '¿QUÉ TE\nTIRA MÁS?',
      subtitle:
          'Elige lo que te gusta y te lo enseñamos primero. Mínimo 3.',
      cta: reachedMin
          ? 'CONTINUAR'
          : 'ELIGE ${3 - _set.length} MÁS',
      ctaEnabled: reachedMin,
      onCta: () => widget.onContinue(_set),
      titleTrailing: _SelectionCounter(count: selectedCount, total: _kTastes.length),
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _kTastes.map((t) {
            final selected = _set.contains(t.key);
            return _TasteChip(
              taste: t,
              selected: selected,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (selected) {
                    _set.remove(t.key);
                  } else {
                    _set.add(t.key);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
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
      await context.read<LocationCubit>().requestLocation();
      await const FlutterSecureStorage()
          .write(key: 'prefLocationAsked', value: 'true');
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
      eyebrow: 'PASO ${widget.step} DE ${widget.total} · ÚLTIMO',
      title: 'LO BUENO,\nCERCA DE TI',
      subtitle:
          'Activa tu ubicación y te enseñamos los sitios abiertos a tu alrededor. Sin ubicación también funciona.',
      cta: _requesting ? 'ACTIVANDO…' : 'ACTIVAR UBICACIÓN',
      ctaEnabled: !_requesting,
      onCta: _activate,
      footer: TextButton(
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
// PASO 5 · Cuenta (sin Google/Apple — only email + skip)
// ─────────────────────────────────────────────────────────────────────

class _StepAccount extends StatelessWidget {
  final VoidCallback onCreateAccount;
  final VoidCallback onLogin;
  final VoidCallback onSkip;

  const _StepAccount({
    required this.onCreateAccount,
    required this.onLogin,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: onSkip,
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.cremaSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderCreamMd),
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: AppColors.ink,
                  size: 18,
                ),
              ),
            ),
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
              'ANTES DE EMPEZAR',
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
          _PrimaryButton(label: 'CREAR CUENTA', onTap: onCreateAccount),
          const SizedBox(height: 10),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.borderCreamMd),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: onLogin,
            child: Text(
              'YA TENGO CUENTA',
              style: AppTextStyles.displaySection(size: 12).copyWith(
                color: AppColors.ink,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onSkip,
            child: Text(
              'Saltar y explorar sin cuenta',
              style: AppTextStyles.ui(
                size: 13,
                weight: FontWeight.w600,
                color: AppColors.inkMuted,
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
              GestureDetector(
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
          _PrimaryButton(label: cta, onTap: onCta, enabled: ctaEnabled),
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

  const _PrimaryButton({
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
  }
}
