import 'dart:async';

import 'package:flutter/material.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';

/// Interpola fotogramas clave estilo CSS: `stops` = [(offset 0..1, valor)].
/// Igual que `animation-timing-function` en CSS, la [curve] se aplica dentro
/// de CADA tramo entre dos fotogramas (no a la animación completa).
double gmKeyframes(double t, List<(double, double)> stops,
    {Curve curve = Curves.easeInOut}) {
  if (t <= stops.first.$1) return stops.first.$2;
  for (var i = 0; i < stops.length - 1; i++) {
    final a = stops[i];
    final b = stops[i + 1];
    if (t <= b.$1) {
      final span = b.$1 - a.$1;
      final local = span <= 0 ? 1.0 : (t - a.$1) / span;
      return a.$2 + (b.$2 - a.$2) * curve.transform(local.clamp(0.0, 1.0));
    }
  }
  return stops.last.$2;
}

/// Cuándo arranca una animación de una sola vez.
enum GmTrigger {
  /// Al montarse (entradas del primer pantallazo).
  mount,

  /// Cuando el widget entra en pantalla (gestos únicos: quesitos, letras,
  /// medalla…). Así el usuario lo ve aunque la sección esté más abajo.
  visible,
}

/// Animación que se reproduce **una vez** (tabla de movimiento del Sistema).
///
/// - Nunca empieza invisible: el `builder` recibe `t` y decide el transform.
/// - Con «reducir movimiento» entrega directamente `t = 1` (estado final).
/// - Con [GmTrigger.visible] espera a que el widget aparezca en el viewport
///   vertical (sin paquetes: escucha el `ScrollPosition` hasta verlo una vez y
///   se desengancha).
class GmOnce extends StatefulWidget {
  final Duration duration;
  final Duration delay;
  final GmTrigger trigger;
  final Widget? child;
  final Widget Function(BuildContext context, double t, Widget? child) builder;

  const GmOnce({
    super.key,
    required this.duration,
    this.delay = Duration.zero,
    this.trigger = GmTrigger.visible,
    required this.builder,
    this.child,
  });

  @override
  State<GmOnce> createState() => _GmOnceState();
}

class _GmOnceState extends State<GmOnce> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);
  Timer? _delayTimer;
  ScrollPosition? _pos;
  bool _armed = false;
  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = GmMotion.reduced(context);
    if (_reduced) {
      _c.value = 1;
      return;
    }
    if (!_armed) {
      _armed = true;
      if (widget.trigger == GmTrigger.mount) {
        _start();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) => _check());
      }
    }
  }

  void _start() {
    _detach();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  void _check() {
    if (!mounted || _c.isAnimating || _c.value > 0 || _delayTimer != null) {
      return;
    }
    final ro = context.findRenderObject();
    if (ro is! RenderBox || !ro.attached || !ro.hasSize) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _check());
      return;
    }
    final top = ro.localToGlobal(Offset.zero).dy;
    final h = ro.size.height;
    final screenH = MediaQuery.sizeOf(context).height;
    // Visible si al menos ~40 px (o 1/3 del widget) asoman en pantalla.
    final margin = h < 120 ? h / 3 : 40.0;
    final visible = top + margin < screenH && top + h - margin > 0;
    if (visible) {
      _start();
      return;
    }
    if (_pos == null) {
      _pos = Scrollable.maybeOf(context, axis: Axis.vertical)?.position;
      _pos?.addListener(_check);
    }
  }

  void _detach() {
    _pos?.removeListener(_check);
    _pos = null;
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _detach();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_reduced) return widget.builder(context, 1, widget.child);
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (ctx, child) => widget.builder(ctx, _c.value, child),
    );
  }
}

/// Entrada «rise»: sube 14 px y se asienta (520 ms, curva asentar,
/// escalonado de 50 ms). Visible desde el primer fotograma (solo transform).
class GmRise extends StatelessWidget {
  final int index;
  final Widget child;
  final GmTrigger trigger;

  const GmRise({
    super.key,
    this.index = 0,
    this.trigger = GmTrigger.visible,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GmOnce(
      duration: GmMotion.rise,
      delay: GmMotion.riseStagger * index,
      trigger: trigger,
      child: child,
      builder: (_, t, c) {
        final dy = GmMotion.riseDistance * (1 - GmMotion.settle.transform(t));
        return Transform.translate(offset: Offset(0, dy), child: c);
      },
    );
  }
}

/// Bucle infinito (solo nubes y punto vivo). Respeta reducir movimiento y
/// TickerMode (se para en pestañas ocultas / rutas tapadas).
class GmLoop extends StatefulWidget {
  final Duration period;
  final bool reverse;
  final Widget? child;
  final Widget Function(BuildContext context, double t, Widget? child) builder;

  const GmLoop({
    super.key,
    required this.period,
    required this.builder,
    this.reverse = false,
    this.child,
  });

  @override
  State<GmLoop> createState() => _GmLoopState();
}

class _GmLoopState extends State<GmLoop> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.period);
  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = GmMotion.reduced(context);
    if (_reduced) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_reduced) return widget.builder(context, 0, widget.child);
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (ctx, child) => widget.builder(
          ctx, widget.reverse ? 1 - _c.value : _c.value, child),
    );
  }
}

/// Feedback de pulsación: la tarjeta se hunde a 0,97 (muelle corto).
class GmPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final String? semanticsIdentifier;
  final String? semanticsLabel;

  const GmPressable({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.97,
    this.semanticsIdentifier,
    this.semanticsLabel,
  });

  @override
  State<GmPressable> createState() => _GmPressableState();
}

class _GmPressableState extends State<GmPressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    Widget w = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => _set(true),
      onTapUp: widget.onTap == null ? null : (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.pressedScale : 1,
        duration: Duration(milliseconds: _down ? 110 : 260),
        curve: _down ? GmMotion.ease : GmMotion.spring,
        child: widget.child,
      ),
    );
    if (widget.semanticsIdentifier != null || widget.semanticsLabel != null) {
      w = Semantics(
        identifier: widget.semanticsIdentifier,
        label: widget.semanticsLabel,
        button: widget.onTap != null,
        child: w,
      );
    }
    return w;
  }
}
