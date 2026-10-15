import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:guachinches/data/cubit/location/location_cubit.dart';
import 'package:guachinches/data/cubit/location/location_state.dart';
import 'package:guachinches/ui/pages/location_denied/location_denied_logic.dart';
import 'package:guachinches/ui/pages/onboarding_flow/widgets/onboarding_icons.dart';
import 'package:guachinches/ui/pages/onboarding_flow/widgets/onboarding_map_card.dart';
import 'package:guachinches/ui/pages/onboarding_flow/widgets/onboarding_step_shell.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

/// «Ubicación denegada» (tablero `UbicacionDenegada`): modal a pantalla
/// completa cuando el diálogo del sistema ya no puede salir
/// (`LocationPermanentlyDenied`) o la localización está apagada en todo el
/// dispositivo (`LocationServiceDisabled`).
///
/// Mapa con la flecha tachada, título, explicación y los pasos como lista
/// agrupada estilo Ajustes; «Abrir Ajustes» / «Ahora no». Textos según la
/// plataforma (en Android nunca «iPhone»). Al volver de Ajustes con permiso,
/// el `checkLocationSilently` del cubit emite `LocationLoaded` y la pantalla
/// se cierra sola.
class LocationDeniedScreen extends StatelessWidget {
  /// Solo pruebas: fuerza la plataforma de los textos.
  final bool? isIOSOverride;

  const LocationDeniedScreen({super.key, this.isIOSOverride});

  /// Ruta de modal a pantalla completa (sube desde abajo en iOS).
  static Route<void> route() => MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const LocationDeniedScreen(),
      );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocationCubit, LocationState>(
      builder: (context, state) {
        // Si volvemos aquí con el permiso ya concedido, cerrar.
        if (state is LocationLoaded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            final nav = Navigator.of(context);
            if (nav.canPop()) nav.pop();
          });
        }
        final variant = locationDeniedVariantFor(state);
        final isIOS = isIOSOverride ?? Platform.isIOS;
        final copy = locationDeniedCopy(variant, isIOS: isIOS);
        return Scaffold(
          backgroundColor: GmColors.of(context).canvas,
          body: Semantics(
            identifier: 'location-denied-screen',
            container: true,
            child: _Body(copy: copy, variant: variant, isIOS: isIOS),
          ),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  final LocationDeniedCopy copy;
  final LocationDeniedVariant variant;
  final bool isIOS;

  const _Body({required this.copy, required this.variant, required this.isIOS});

  Future<void> _open() async {
    HapticFeedback.lightImpact();
    // En iOS ambos llevan a Ajustes; en Android `openLocationSettings` abre
    // directo el interruptor del sistema.
    if (!isIOS && variant == LocationDeniedVariant.service) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final close = () => Navigator.of(context).maybePop();
    final bottom = OnbBottomCta.heightFor(context, twoButtons: true);
    return OnbPage(
      child: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: GmToolbarButton(
                        icon: GmIcons.close,
                        light: true,
                        onTap: close,
                        semanticLabel: 'Cerrar',
                        identifier: 'location-denied-close',
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(top: 12, bottom: bottom + 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const GmRise(
                            trigger: GmTrigger.mount,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: OnbMapCard(
                                refHeight: 130,
                                off: true,
                                pins: false,
                                offCenter: Offset(184, 66),
                              ),
                            ),
                          ),
                          GmRise(
                            index: 1,
                            trigger: GmTrigger.mount,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      GmIcon(OnbIcons.pinOutline,
                                          size: 14, color: gm.label2),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(copy.eyebrow,
                                            style: GmText.eyebrow(
                                                color: gm.label2)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Semantics(
                                    header: true,
                                    child: Text(
                                      copy.title,
                                      style: GmText.largeTitle(color: gm.label)
                                          .copyWith(letterSpacing: -0.8),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(copy.text,
                                      style: GmText.body(color: gm.label2)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          GmRise(
                            index: 2,
                            trigger: GmTrigger.mount,
                            child: _StepsGroup(steps: copy.steps),
                          ),
                          if (copy.footnote != null)
                            GmRise(
                              index: 3,
                              trigger: GmTrigger.mount,
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 14, 20, 0),
                                child: Text(copy.footnote!,
                                    style: GmText.sub(color: gm.label2)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: OnbBottomCta(children: [
              OnbBigButton(
                label: 'Abrir Ajustes',
                identifier: 'location-denied-open-settings',
                onTap: _open,
              ),
              OnbTextButton(
                label: 'Ahora no',
                muted: true,
                identifier: 'location-denied-later',
                onTap: close,
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _StepsGroup extends StatelessWidget {
  final List<DeniedStep> steps;
  const _StepsGroup({required this.steps});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: 'location-denied-steps',
      container: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GmCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                if (i > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 56),
                    child: Container(height: 1, color: gm.sep),
                  ),
                _StepRow(n: i + 1, step: steps[i]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final int n;
  final DeniedStep step;
  const _StepRow({required this.n, required this.step});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final (Color bg, Color ink) = switch (step.tint) {
      DeniedStepTint.neutral => (gm.fill, gm.label2),
      DeniedStepTint.accent => (gm.accentSoft, gm.accent),
      DeniedStepTint.ok => (gm.okSoft, gm.greenText),
      DeniedStepTint.warn => (gm.warnSoft, gm.warnText),
    };
    final icon = switch (step.icon) {
      DeniedStepIcon.gear => OnbIcons.gear,
      DeniedStepIcon.hand => OnbIcons.mano,
      DeniedStepIcon.locate => OnbIcons.locate,
      DeniedStepIcon.check => OnbIcons.check,
      DeniedStepIcon.target => OnbIcons.diana,
    };
    return Semantics(
      label: 'Paso $n: ${step.label}',
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 58),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 16, 8),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: GmIcon(icon, size: 18, color: ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  step.label,
                  style: TextStyle(
                    fontSize: 17,
                    height: 22 / 17,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.3,
                    color: gm.label,
                  ),
                ),
              ),
              if (step.toggle) ...[
                const SizedBox(width: 8),
                const _SwitchOn(),
              ],
              const SizedBox(width: 10),
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration:
                    BoxDecoration(color: gm.fill, shape: BoxShape.circle),
                child: Text(
                  '$n',
                  style: TextStyle(
                    fontSize: 13,
                    height: 16 / 13,
                    fontWeight: FontWeight.w700,
                    color: gm.label2,
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

/// Interruptor encendido de muestra (lo que hay que activar en Ajustes).
class _SwitchOn extends StatelessWidget {
  const _SwitchOn();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 25,
      padding: const EdgeInsets.all(2),
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        color: const Color(0xFF34C759),
        borderRadius: BorderRadius.circular(GmRadius.pill),
      ),
      child: Container(
        width: 21,
        height: 21,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Color(0x33000000), blurRadius: 5, offset: Offset(0, 2)),
          ],
        ),
      ),
    );
  }
}
