import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/data/cubit/new_home/islands_cubit.dart';
import 'package:guachinches/data/model/Island.dart';
import 'package:guachinches/ui/pages/onboarding_flow/onboarding_logic.dart';
import 'package:guachinches/ui/pages/onboarding_flow/widgets/onboarding_icons.dart';
import 'package:guachinches/ui/pages/onboarding_flow/widgets/onboarding_step_shell.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

/// Paso 1 · «¿En qué isla estás?» (tablero Onboarding · isla).
///
/// Lista agrupada de `/islands` con la clave en una insignia («TF») y un
/// radio; sin iconos de silueta (rechazados) y sin saludo por nombre.
/// Sin recuento de sitios: `/islands` no lo trae y pedirlo isla a isla no
/// compensa en el arranque.
class OnboardingIslandStep extends StatefulWidget {
  final String? selectedId;
  final VoidCallback onBack;

  /// Isla elegida (o `null` si se salta / se elige más tarde).
  final ValueChanged<Island?> onContinue;

  const OnboardingIslandStep({
    super.key,
    required this.selectedId,
    required this.onBack,
    required this.onContinue,
  });

  @override
  State<OnboardingIslandStep> createState() => _OnboardingIslandStepState();
}

class _OnboardingIslandStepState extends State<OnboardingIslandStep> {
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedId;
    final cubit = context.read<IslandsCubit>();
    if (cubit.state is IslandsInitial) cubit.load();
  }

  void _pick(Island i) {
    HapticFeedback.selectionClick();
    setState(() => _selectedId = i.id);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IslandsCubit, IslandsState>(
      builder: (context, state) {
        final islands = state is IslandsLoaded
            ? onbSortedIslands(state.islands)
            : const <Island>[];
        final failed = state is IslandsFailure ||
            (state is IslandsLoaded && islands.isEmpty);
        final loading = !failed && islands.isEmpty;
        Island? selected;
        for (final i in islands) {
          if (i.id == _selectedId) selected = i;
        }
        final label = onbIslandCta(
            loading: loading, failed: failed, selected: selected != null);

        final Widget content;
        if (failed) {
          content = OnbStateCard(
            identifier: 'onboarding-island-error',
            title: 'No pudimos cargar las islas',
            text: 'Puedes seguir y elegirla después en el Inicio, o volver a '
                'intentarlo.',
            action: GmSoftCapsuleButton(
              label: 'Reintentar',
              fontSize: 15,
              identifier: 'onboarding-island-retry',
              onTap: () => context.read<IslandsCubit>().load(),
            ),
          );
        } else if (loading) {
          content = const _IslandSkeleton();
        } else {
          content = _IslandList(
            islands: islands,
            selectedId: _selectedId,
            onPick: _pick,
          );
        }

        return OnbStepShell(
          step: 1,
          onBack: widget.onBack,
          onSkip: () => widget.onContinue(null),
          skipIdentifier: 'onboarding-island-skip',
          title: '¿En qué isla estás?',
          subtitle:
              'Te enseñamos primero lo de aquí. Puedes cambiarla cuando quieras.',
          content: Padding(
            padding: const EdgeInsets.only(top: 18),
            child: GmRise(index: 1, trigger: GmTrigger.mount, child: content),
          ),
          cta: [
            OnbBigButton(
              label: label,
              secondary: failed,
              identifier: 'onboarding-continue',
              onTap: failed
                  ? () => widget.onContinue(null)
                  : (selected == null
                      ? null
                      : () => widget.onContinue(selected)),
            ),
          ],
        );
      },
    );
  }
}

class _IslandList extends StatelessWidget {
  final List<Island> islands;
  final String? selectedId;
  final ValueChanged<Island> onPick;

  const _IslandList({
    required this.islands,
    required this.selectedId,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: 'onboarding-island-list',
      container: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GmCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < islands.length; i++) ...[
                if (i > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 64),
                    child: Container(height: 1, color: gm.sep),
                  ),
                _IslandRow(
                  island: islands[i],
                  selected: islands[i].id == selectedId,
                  onTap: () => onPick(islands[i]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _IslandRow extends StatelessWidget {
  final Island island;
  final bool selected;
  final VoidCallback onTap;

  const _IslandRow({
    required this.island,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final badge = onbIslandBadge(island);
    return Semantics(
      identifier: 'onboarding-island-${(island.key ?? badge).toLowerCase()}',
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: island.name,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 58),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 16, 8),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? gm.accentSoft : gm.fill,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 13,
                      height: 16 / 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      color: selected ? gm.accent : gm.label2,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    island.name,
                    style: TextStyle(
                      fontSize: 17,
                      height: 22 / 17,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.3,
                      color: gm.label,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _Radio(on: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  final bool on;
  const _Radio({required this.on});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: on ? GmColors.accentFill : null,
        border: on ? null : Border.all(color: gm.sep, width: 2),
      ),
      child: on ? GmIcon(OnbIcons.check, size: 14, color: Colors.white) : null,
    );
  }
}

class _IslandSkeleton extends StatelessWidget {
  const _IslandSkeleton();

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    const widths = [96.0, 128.0, 104.0, 132.0, 90.0, 112.0, 92.0];
    return Semantics(
      identifier: 'onboarding-island-loading',
      label: 'Cargando islas',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GmCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < widths.length; i++) ...[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 64),
                      child: Container(height: 1, color: gm.sep),
                    ),
                  SizedBox(
                    height: 58,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 16, 8),
                      child: Row(
                        children: [
                          const OnbSkel(width: 36, height: 36, radius: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: OnbSkel(
                                  width: widths[i], height: 14, radius: 6),
                            ),
                          ),
                          const OnbSkel(width: 24, height: 24, radius: 12),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
