import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guachinches/ui/pages/onboarding_flow/onboarding_logic.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

/// Lienzo de un paso del onboarding (día/noche) con la barra de estado
/// acorde y fondo propio (la bienvenida conserva el suyo).
class OnbPage extends StatelessWidget {
  final Widget child;
  const OnbPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final style =
        gm.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: style.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: gm.canvas,
      ),
      child: ColoredBox(color: gm.canvas, child: child),
    );
  }
}

/// Barra superior de los pasos: Volver de cristal (44) · progreso de 4
/// tramos en color de texto (no azul) · «Saltar» opcional.
class OnbTopBar extends StatelessWidget {
  final int step;
  final VoidCallback onBack;
  final VoidCallback? onSkip;
  final String backIdentifier;
  final String skipIdentifier;

  const OnbTopBar({
    super.key,
    required this.step,
    required this.onBack,
    this.onSkip,
    this.backIdentifier = 'onboarding-back',
    this.skipIdentifier = 'onboarding-skip',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, onSkip != null ? 12 : 16, 0),
      child: Row(
        children: [
          GmToolbarButton(
            icon: GmIcons.chevronLeft,
            iconSize: 20,
            light: true,
            onTap: onBack,
            semanticLabel: 'Volver',
            identifier: backIdentifier,
          ),
          const SizedBox(width: 14),
          Expanded(child: OnbProgressBar(step: step)),
          if (onSkip != null)
            OnbTextButton(
              label: 'Saltar',
              muted: true,
              onTap: onSkip,
              identifier: skipIdentifier,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            )
          else
            const SizedBox(width: 44),
        ],
      ),
    );
  }
}

class OnbProgressBar extends StatelessWidget {
  final int step;
  const OnbProgressBar({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      label: onbStepEyebrow(step),
      child: ExcludeSemantics(
        child: Row(
          children: [
            for (var i = 0; i < kOnbTotalSteps; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 320),
                  curve: GmMotion.settle,
                  height: 4,
                  decoration: BoxDecoration(
                    color: i < step ? gm.label : gm.sep,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Botón de texto de 44 («Saltar», «Ahora no», «Explorar sin cuenta»).
class OnbTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool muted;
  final String? identifier;
  final double fontSize;
  final FontWeight weight;
  final EdgeInsetsGeometry padding;

  const OnbTextButton({
    super.key,
    required this.label,
    required this.onTap,
    this.muted = false,
    this.identifier,
    this.fontSize = 15,
    this.weight = FontWeight.w600,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final enabled = onTap != null;
    return Semantics(
      identifier: identifier,
      button: true,
      enabled: enabled,
      child: GmPressable(
        onTap: onTap,
        pressedScale: 0.96,
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
            padding: padding,
            alignment: Alignment.center,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize,
                height: 20 / 15,
                fontWeight: weight,
                letterSpacing: -0.2,
                color: muted ? gm.label2 : gm.label,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón grande de 52 a todo el ancho: primario (degradado Atlántico),
/// secundario (`accentSoft` + `accent`) o deshabilitado (`accentSoft` +
/// `label2`, sin [onTap]).
class OnbBigButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool secondary;
  final String? identifier;

  const OnbBigButton({
    super.key,
    required this.label,
    required this.onTap,
    this.secondary = false,
    this.identifier,
  });

  @override
  Widget build(BuildContext context) {
    final soft = secondary || onTap == null;
    return SizedBox(
      width: double.infinity,
      child: soft
          ? GmSoftCapsuleButton(
              label: label,
              onTap: onTap,
              height: 52,
              fontSize: 17,
              identifier: identifier,
            )
          : GmCapsuleButton(
              label: label,
              onTap: onTap,
              height: 52,
              fontSize: 17,
              identifier: identifier,
            ),
    );
  }
}

/// Cápsula fija abajo sobre un fundido del lienzo (`edgeFade`).
class OnbBottomCta extends StatelessWidget {
  final List<Widget> children;
  const OnbBottomCta({super.key, required this.children});

  static double bottomInset(BuildContext context) {
    final b = MediaQuery.viewPaddingOf(context).bottom;
    return b > 0 ? b + 6 : 16;
  }

  /// Alto que ocupa (para dejar sitio al final del scroll).
  static double heightFor(BuildContext context, {required bool twoButtons}) =>
      24 + 52 + (twoButtons ? 48 : 0) + bottomInset(context);

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [gm.edgeFade0, gm.edgeFade1],
          stops: const [0, 0.22],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 24, 16, bottomInset(context)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 4),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// Esqueleto de los pasos 1–3: barra, «Paso N de 4», título 34/41,
/// subtítulo, contenido con scroll y cápsula fija abajo.
class OnbStepShell extends StatelessWidget {
  final int step;
  final VoidCallback onBack;
  final VoidCallback? onSkip;
  final String skipIdentifier;
  final String title;
  final String subtitle;
  final Widget? eyebrowTrailing;
  final Widget content;
  final List<Widget> cta;

  const OnbStepShell({
    super.key,
    required this.step,
    required this.onBack,
    this.onSkip,
    this.skipIdentifier = 'onboarding-skip',
    required this.title,
    required this.subtitle,
    this.eyebrowTrailing,
    required this.content,
    required this.cta,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final bottom = OnbBottomCta.heightFor(context, twoButtons: cta.length > 1);
    return OnbPage(
      child: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OnbTopBar(
                    step: step,
                    onBack: onBack,
                    onSkip: onSkip,
                    skipIdentifier: skipIdentifier,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(top: 12, bottom: bottom + 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GmRise(
                            trigger: GmTrigger.mount,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(minHeight: 24),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(onbStepEyebrow(step),
                                              style: GmText.eyebrow(
                                                  color: gm.label2)),
                                        ),
                                        if (eyebrowTrailing != null)
                                          eyebrowTrailing!,
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Semantics(
                                    header: true,
                                    child: Text(
                                      title,
                                      style: GmText.largeTitle(color: gm.label)
                                          .copyWith(letterSpacing: -0.8),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(subtitle,
                                      style: GmText.body(color: gm.label2)),
                                ],
                              ),
                            ),
                          ),
                          content,
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
            child: OnbBottomCta(children: cta),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de error con el volcán triste (isla, gustos).
class OnbStateCard extends StatelessWidget {
  final String identifier;
  final String title;
  final String text;
  final Widget action;

  const OnbStateCard({
    super.key,
    required this.identifier,
    required this.title,
    required this.text,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: identifier,
      container: true,
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GmCard(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const GmSadVolcano(width: 96),
                const SizedBox(height: 12),
                Text(title,
                    textAlign: TextAlign.center,
                    style: GmText.poster(color: gm.label)),
                const SizedBox(height: 6),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style:
                      GmText.body(color: gm.label2).copyWith(height: 21 / 15),
                ),
                const SizedBox(height: 16),
                action,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bloque plano de esqueleto (sin barrido).
class OnbSkel extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  const OnbSkel(
      {super.key, this.width, required this.height, this.radius = 10});

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: GmColors.of(context).fill,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}
