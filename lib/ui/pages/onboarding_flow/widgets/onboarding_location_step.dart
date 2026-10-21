import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/data/cubit/location/location_cubit.dart';
import 'package:guachinches/data/cubit/onboarding/onboarding_cubit.dart';
import 'package:guachinches/ui/pages/onboarding_flow/onboarding_logic.dart';
import 'package:guachinches/ui/pages/onboarding_flow/widgets/onboarding_icons.dart';
import 'package:guachinches/ui/pages/onboarding_flow/widgets/onboarding_map_card.dart';
import 'package:guachinches/ui/pages/onboarding_flow/widgets/onboarding_step_shell.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';

/// Paso 3 · «Lo bueno, cerca de ti» (tablero Onboarding · ubicación).
///
/// Mapa claro estilizado con chinchetas de tema que caen una vez (sustituye
/// al pulso infinito). «Activar ubicación» pide el permiso del sistema; si
/// no se concede, pasa a «Sin ubicación, de momento» con «Continuar».
class OnboardingLocationStep extends StatefulWidget {
  final String? islandName;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  const OnboardingLocationStep({
    super.key,
    required this.islandName,
    required this.onBack,
    required this.onContinue,
  });

  @override
  State<OnboardingLocationStep> createState() => _OnboardingLocationStepState();
}

class _OnboardingLocationStepState extends State<OnboardingLocationStep> {
  bool _requesting = false;
  bool _declined = false;

  Future<void> _activate() async {
    if (_requesting) return;
    setState(() => _requesting = true);
    final location = context.read<LocationCubit>();
    final onboarding = context.read<OnboardingCubit>();
    var granted = false;
    try {
      // Solo esperamos la respuesta al diálogo del sistema; el fix GPS va en
      // segundo plano (si no, el paso se quedaba en «Activando…»).
      await location.requestPermissionOnly();
      granted = onbLocationGranted(location.state);
      await onboarding.markLocationAsked();
    } catch (e) {
      AppLogger.warn('onboarding', 'permiso de ubicación: $e');
    }
    if (!mounted) return;
    setState(() {
      _requesting = false;
      _declined = !granted;
    });
    if (granted) widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final declined = _declined;
    final note = declined
        ? Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: gm.fill,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child:
                      GmIcon(OnbIcons.pinOutline, size: 18, color: gm.label2),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(
                        text: 'Sin ubicación también funciona. ',
                        style: GmText.body(color: gm.label, w: FontWeight.w600),
                      ),
                      TextSpan(
                        text: 'Elige zona en el Inicio y ordenamos por '
                            'valoración. Puedes activarla cuando quieras.',
                        style: GmText.body(color: gm.label),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          )
        : Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                GmIcon(OnbIcons.lock, size: 16, color: gm.label2),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Solo mientras usas la app.',
                      style: GmText.sub(color: gm.label2)),
                ),
              ],
            ),
          );

    return Semantics(
      identifier: declined
          ? 'onboarding-location-declined'
          : 'onboarding-location-step',
      container: true,
      child: OnbStepShell(
        step: 3,
        onBack: widget.onBack,
        title: onbLocationTitle(declined: declined),
        subtitle: onbLocationSubtitle(
            declined: declined, islandName: widget.islandName),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GmRise(
              index: 2,
              trigger: GmTrigger.mount,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: OnbMapCard(off: declined),
              ),
            ),
            GmRise(index: 3, trigger: GmTrigger.mount, child: note),
          ],
        ),
        cta: declined
            ? [
                OnbBigButton(
                  label: 'Continuar',
                  identifier: 'onboarding-continue',
                  onTap: widget.onContinue,
                ),
              ]
            : [
                OnbBigButton(
                  label: _requesting ? 'Activando…' : 'Activar ubicación',
                  identifier: 'onboarding-continue',
                  onTap: _requesting ? null : _activate,
                ),
                OnbTextButton(
                  label: 'Ahora no',
                  muted: true,
                  identifier: 'onboarding-location-skip',
                  onTap: _requesting ? null : widget.onContinue,
                ),
              ],
      ),
    );
  }
}
