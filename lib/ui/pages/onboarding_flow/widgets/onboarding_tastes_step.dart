import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/data/model/Category.dart';
import 'package:guachinches/ui/pages/onboarding_flow/onboarding_logic.dart';
import 'package:guachinches/ui/pages/onboarding_flow/widgets/onboarding_icons.dart';
import 'package:guachinches/ui/pages/onboarding_flow/widgets/onboarding_step_shell.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

/// Paso 2 · «¿Qué te tira más?» (tablero Onboarding · gustos).
///
/// Las 17 categorías reales (`/categorias`) como chips con glifo propio,
/// reagrupadas en «Me gusta comer», «Planes que me tiran» y «Servicios que
/// valoro», con los nombres limpios. Mínimo 3.
class OnboardingTastesStep extends StatefulWidget {
  final Set<String> selected;
  final Future<List<ModelCategory>> Function() loadCategories;
  final VoidCallback onBack;

  /// Ids de categoría elegidos (vacío si se salta).
  final ValueChanged<Set<String>> onContinue;

  const OnboardingTastesStep({
    super.key,
    required this.selected,
    required this.loadCategories,
    required this.onBack,
    required this.onContinue,
  });

  @override
  State<OnboardingTastesStep> createState() => _OnboardingTastesStepState();
}

class _OnboardingTastesStepState extends State<OnboardingTastesStep> {
  late final Set<String> _set = {...widget.selected};
  Map<OnbTasteGroup, List<OnbTaste>> _groups = const {};
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final cats = await widget.loadCategories();
      if (!mounted) return;
      final groups = onbGroupTastes(cats);
      setState(() {
        _groups = groups;
        _loading = false;
        _error = groups.isEmpty;
      });
    } catch (e) {
      AppLogger.warn('onboarding', 'categorías: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  void _toggle(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_set.remove(id)) _set.add(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final n = _set.length;
    final counter = onbTastesCounter(n);
    final Widget content;
    final OnbBigButton cta;
    if (_error) {
      content = Padding(
        padding: const EdgeInsets.only(top: 24),
        child: OnbStateCard(
          identifier: 'onboarding-tastes-error',
          title: 'No hemos podido cargar los gustos',
          text: 'Revisa tu conexión. También puedes saltar este paso y '
              'elegirlos más tarde en Perfil.',
          action: GmCapsuleButton(
            label: 'Reintentar',
            fontSize: 15,
            identifier: 'onboarding-tastes-retry',
            onTap: _load,
          ),
        ),
      );
      cta = OnbBigButton(
        label: 'Saltar este paso',
        secondary: true,
        identifier: 'onboarding-continue',
        onTap: () => widget.onContinue(<String>{}),
      );
    } else if (_loading) {
      content = const _TastesSkeleton();
      cta = const OnbBigButton(
          label: 'Continuar', onTap: null, identifier: 'onboarding-continue');
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final e in _groups.entries) ...[
            _Caption(e.key.title),
            GmRise(
              index: 2,
              trigger: GmTrigger.mount,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 2,
                  children: [
                    for (final t in e.value)
                      _TasteChip(
                        taste: t,
                        selected: _set.contains(t.id),
                        onTap: () => _toggle(t.id),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      );
      cta = OnbBigButton(
        label: onbTastesCta(n),
        identifier: 'onboarding-continue',
        onTap: n >= kOnbMinTastes ? () => widget.onContinue({..._set}) : null,
      );
    }

    return OnbStepShell(
      step: 2,
      onBack: widget.onBack,
      onSkip: () => widget.onContinue(<String>{}),
      skipIdentifier: 'onboarding-tastes-skip',
      title: '¿Qué te tira más?',
      subtitle: 'Elige al menos 3 y te lo enseñamos primero.',
      eyebrowTrailing: counter.isEmpty ? null : _Counter(counter),
      content: content,
      cta: [cta],
    );
  }
}

class _Caption extends StatelessWidget {
  final String text;
  const _Caption(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Semantics(
        header: true,
        child: Text(text,
            style: GmText.eyebrow(color: GmColors.of(context).label2)),
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  final String text;
  const _Counter(this.text);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'onboarding-tastes-counter',
      liveRegion: true,
      child: Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: GmColors.accentFill,
          borderRadius: BorderRadius.circular(GmRadius.pill),
        ),
        child: Text(
          text,
          style: GmText.eyebrow(color: Colors.white),
        ),
      ),
    );
  }
}

/// Chip de gusto: 38 visibles (44 de toque), tarjeta + sombra e1; elegido
/// en `accentSoft` con filo y texto `accent` y una marca de verificación.
class _TasteChip extends StatelessWidget {
  final OnbTaste taste;
  final bool selected;
  final VoidCallback onTap;

  const _TasteChip({
    required this.taste,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final fg = selected ? gm.accent : gm.label;
    return Semantics(
      identifier: 'onboarding-taste-${taste.id}',
      button: true,
      toggled: selected,
      label: taste.label,
      excludeSemantics: true,
      child: GmPressable(
        onTap: onTap,
        pressedScale: 0.95,
        child: Padding(
          // 38 visibles + 3 arriba y abajo = 44 de toque.
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            // Mínimo 38; crece si el texto del sistema es grande.
            constraints: const BoxConstraints(minHeight: 38),
            padding: const EdgeInsets.fromLTRB(11, 8, 14, 8),
            decoration: BoxDecoration(
              color: selected ? gm.accentSoft : gm.card,
              borderRadius: BorderRadius.circular(GmRadius.pill),
              border: Border.all(
                color: selected ? gm.accent : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: selected ? null : gm.shadow1,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OnbTasteIcon(taste.glyph, color: fg, size: 18),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    taste.label,
                    style: TextStyle(
                      fontSize: 15,
                      height: 20 / 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      color: fg,
                    ),
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 6),
                  GmIcon(OnbIcons.check, size: 14, color: gm.accent),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TastesSkeleton extends StatelessWidget {
  const _TastesSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget row(List<double> ws) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Wrap(spacing: 8, children: [
            for (final w in ws) OnbSkel(width: w, height: 38, radius: 19),
          ]),
        );
    Widget cap(double w) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
          child: Align(
              alignment: Alignment.centerLeft,
              child: OnbSkel(width: w, height: 13, radius: 6)),
        );
    return Semantics(
      identifier: 'onboarding-tastes-loading',
      label: 'Cargando categorías',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            cap(110),
            row([150, 140]),
            row([170, 104]),
            row([120, 96, 112]),
            cap(140),
            row([104, 128]),
            row([110, 126]),
            cap(132),
            row([112, 116]),
            row([140, 130]),
          ],
        ),
      ),
    );
  }
}
