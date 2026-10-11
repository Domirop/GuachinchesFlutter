import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/data/cubit/location/location_cubit.dart';
import 'package:guachinches/data/cubit/location/location_state.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';
import 'package:guachinches/utils/location_prompt_action.dart';

/// Copy según la variante de [LocationDenied].
class _LocCopy {
  final String banner;
  final String cta;
  final String lockedCta;
  const _LocCopy(this.banner, this.cta, this.lockedCta);

  static _LocCopy of(LocationDenied state) {
    if (state is LocationServiceDisabled) {
      return const _LocCopy('Localización apagada', 'Ajustes', 'Abrir Ajustes');
    }
    if (state is LocationPermanentlyDenied) {
      return const _LocCopy('Ubicación bloqueada', 'Ajustes', 'Abrir Ajustes');
    }
    return const _LocCopy(
        'Ubicación desactivada', 'Activar', 'Activar ubicación');
  }
}

/// Aviso de una línea «Ubicación desactivada · Activar» (rediseño iOS 27).
///
/// Comportamiento adaptativo según el sub-tipo de `LocationDenied` (lo
/// resuelve [handleLocationPromptTap]):
///  - [LocationDenied] base: tap → `requestLocation()` (modal nativo).
///  - [LocationPermanentlyDenied] / [LocationServiceDisabled]: tap → guía
///    para Ajustes.
///
/// Se oculta en `LocationLoaded`, `LocationLoading`, `LocationInitial` y
/// `LocationUnavailable`.
class LocationPromptBanner extends StatelessWidget {
  /// Se mantiene por compatibilidad; el aviso ya es siempre de una línea.
  final bool compact;

  const LocationPromptBanner({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocationCubit, LocationState>(
      builder: (context, state) {
        if (state is! LocationDenied) return const SizedBox.shrink();
        final gm = GmColors.of(context);
        final copy = _LocCopy.of(state);
        return Semantics(
          identifier: 'home-location-prompt',
          button: true,
          label: '${copy.banner}. ${copy.cta}',
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => handleLocationPromptTap(context),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: gm.card,
                borderRadius: BorderRadius.circular(GmRadius.pill),
                boxShadow: gm.shadow1,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: gm.accentSoft,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: GmIcon(GmIcons.pin, size: 20, color: gm.accent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      copy.banner,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GmText.body(color: gm.label, w: FontWeight.w600)
                          .copyWith(letterSpacing: -0.2),
                    ),
                  ),
                  GmPressable(
                    onTap: () => handleLocationPromptTap(context),
                    pressedScale: 0.94,
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: gm.accentSoft,
                        borderRadius: BorderRadius.circular(GmRadius.pill),
                      ),
                      child: Text(
                        copy.cta,
                        style: GmText.body(
                            color: gm.accent, w: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Estado bloqueado de «Cerca de ti» sin ubicación: ilustración de mapa con
/// chincheta que cae una vez + copy + cápsula «Activar ubicación». Mismo
/// flujo de permiso que [LocationPromptBanner]. Solo se pinta si el estado
/// es [LocationDenied] (o sus variantes).
class LocationLockedCard extends StatelessWidget {
  const LocationLockedCard({super.key});

  static bool shouldRender(LocationState s) => s is LocationDenied;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocationCubit, LocationState>(
      builder: (context, state) {
        if (state is! LocationDenied) return const SizedBox.shrink();
        final gm = GmColors.of(context);
        final copy = _LocCopy.of(state);
        return Semantics(
          identifier: 'home-nearby-locked',
          container: true,
          child: ConstrainedBox(
            // 160 en el tamaño de texto estándar; crece si el sistema lo pide.
            constraints: const BoxConstraints(minHeight: 160),
            child: GmCard(
              child: Stack(
                children: [
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: 190,
                    child: _MapIllustration(gm: gm),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
                    child: SizedBox(
                      width: 198,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Activa la ubicación y te enseñamos lo que tienes a menos de 2 km',
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                            style: GmText.body17(
                                color: gm.label, w: FontWeight.w600),
                          ),
                          const SizedBox(height: 11),
                          GmCapsuleButton(
                            label: copy.lockedCta,
                            fontSize: 15,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 18),
                            identifier: 'home-nearby-locked-cta',
                            onTap: () => handleLocationPromptTap(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Mapa ilustrado (banda crema + calles + radio de 2 km) con la chincheta
/// que cae una vez (estirar y encoger + sombra que la sigue · 1,2 s).
class _MapIllustration extends StatelessWidget {
  final GmColors gm;
  const _MapIllustration({required this.gm});

  @override
  Widget build(BuildContext context) {
    return GmOnce(
      duration: const Duration(milliseconds: 1200),
      delay: const Duration(milliseconds: 500),
      builder: (_, t, __) => CustomPaint(
        painter: _MapPainter(gm: gm, t: t),
        size: const Size(190, 160),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  final GmColors gm;
  final double t;
  _MapPainter({required this.gm, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    // El SVG del tablero es 190×160; escalamos al alto real.
    canvas.save();
    canvas.scale(size.width / 190, size.height / 160);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 190, 160), Paint()..color = gm.band);

    final road = Paint()
      ..color = gm.card
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(-10, 120)
        ..cubicTo(30, 100, 60, 130, 100, 110)
        ..cubicTo(140, 90, 160, 50, 200, 60),
      road..strokeWidth = 10,
    );
    canvas.drawPath(
      Path()
        ..moveTo(60, -10)
        ..cubicTo(66, 40, 86, 80, 74, 190),
      road..strokeWidth = 6,
    );
    canvas.drawPath(
      Path()
        ..moveTo(120, 40)
        ..cubicTo(140, 70, 170, 80, 200, 78),
      road
        ..strokeWidth = 4
        ..color = gm.card.withValues(alpha: 0.8),
    );

    // Radio de 2 km (discontinuo).
    const c = Offset(112, 84);
    canvas.drawCircle(c, 44, Paint()..color = const Color(0x1F0085C4));
    final dash = Paint()
      ..color = const Color(0x590085C4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const n = 30;
    for (var i = 0; i < n; i++) {
      final a0 = i * 2 * 3.14159265 / n;
      canvas.drawArc(Rect.fromCircle(center: c, radius: 44), a0,
          (2 * 3.14159265 / n) * 0.45, false, dash);
    }

    // Sombra de la chincheta (pinshadow).
    final ss = gmKeyframes(t, const [(0, 0.55), (0.4, 1.15), (0.8, 1), (1, 1)],
        curve: const Cubic(0.4, 0, 0.2, 1));
    final so = gmKeyframes(t, const [(0, 0.2), (0.4, 0.6), (0.8, 0.5), (1, 0.5)]);
    canvas.save();
    canvas.translate(112, 88);
    canvas.scale(ss, ss);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 16, height: 5.2),
      Paint()..color = Color.fromRGBO(0, 60, 90, 0.35 * so / 0.5),
    );
    canvas.restore();

    // Chincheta: cae 8 px, se aplasta y se asienta (origen: la punta).
    const ease = Cubic(0.4, 0, 0.2, 1);
    final dy = gmKeyframes(t, const [(0, -8), (0.4, 0), (0.62, -2), (0.8, 0), (1, 0)],
        curve: ease);
    final sx = gmKeyframes(t, const [(0, 0.94), (0.4, 1.14), (0.62, 0.97), (0.8, 1), (1, 1)],
        curve: ease);
    final sy = gmKeyframes(t, const [(0, 1.08), (0.4, 0.84), (0.62, 1.04), (0.8, 1), (1, 1)],
        curve: ease);
    canvas.save();
    canvas.translate(112, 88 + dy);
    canvas.scale(sx, sy);
    canvas.translate(-112, -88);
    final pin = Path()
      ..moveTo(112, 88)
      ..cubicTo(112, 88, 100, 76.5, 100, 67.5)
      ..arcToPoint(const Offset(124, 67.5), radius: const Radius.circular(12))
      ..cubicTo(124, 76.5, 112, 88, 112, 88)
      ..close();
    canvas.drawPath(pin, Paint()..color = GmColors.atlantico);
    canvas.drawCircle(const Offset(112, 67.5), 4.4, Paint()..color = Colors.white);
    canvas.restore();

    // Fundido hacia la tarjeta por la izquierda.
    final fade = Paint()
      ..shader = LinearGradient(
        colors: [gm.card, gm.card.withValues(alpha: 0)],
        stops: const [0, 0.35],
      ).createShader(const Rect.fromLTWH(0, 0, 190, 160));
    canvas.drawRect(const Rect.fromLTWH(0, 0, 190, 160), fade);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) => old.t != t || old.gm != gm;
}
