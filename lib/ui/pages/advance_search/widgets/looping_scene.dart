import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:guachinches/core/app_route_observer.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';

/// Base de las cabeceras animadas de las listas temáticas («Mesa con
/// brindis», «El barraquito»…). Un único Ticker que:
/// - solo corre en los tramos con movimiento ([quietRemaining] dice cuánto
///   reposo queda); en el reposo se para y un Timer lo despierta;
/// - no arranca hasta que acaba la transición de entrada de la pantalla;
/// - se para fuera de pantalla ([LoopingScene.active] = false), con otra
///   ruta encima, con la app en segundo plano o con TickerMode apagado;
/// - con «reducir movimiento» no corre: [buildLayers] recibe `time: null`
///   y pinta el fotograma final quieto.
abstract class LoopingScene extends StatefulWidget {
  /// Está a la vista (la pantalla lo apaga al hacer scroll).
  final bool active;

  const LoopingScene({super.key, this.active = true});
}

abstract class LoopingSceneState<T extends LoopingScene> extends State<T>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  late final Ticker _ticker = createTicker(_onTick);

  /// Segundos de animación transcurridos (sin contar las pausas).
  final ValueNotifier<double> _time = ValueNotifier(0);
  double _base = 0;
  Timer? _wake;
  bool _reduced = false;
  bool _appActive = true;
  bool _covered = false;
  bool _tickerMode = true;
  bool _routeReady = true;
  Animation<double>? _routeAnim;

  /// Segundos de reposo que quedan desde [t] (0 si hay movimiento).
  double quietRemaining(double t);

  /// Ancho y alto de referencia (tablero de 402).
  double get designWidth => 402;
  double get designHeight;

  /// Las capas de la escena. [time] es `null` con movimiento reducido.
  Widget buildLayers(
      BuildContext context, double scale, double? time, bool dark);

  /// Para los tests: ¿está corriendo el ticker?
  @visibleForTesting
  bool get isTicking => _ticker.isActive;

  /// Para los tests: ¿pinta el fotograma final quieto?
  @visibleForTesting
  bool get isStatic => _reduced;

  bool get _shouldRun =>
      !_reduced &&
      widget.active &&
      _appActive &&
      !_covered &&
      _tickerMode &&
      _routeReady;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = GmMotion.reduced(context);
    _tickerMode = TickerMode.valuesOf(context).enabled;
    final route = ModalRoute.of(context);
    if (route is PageRoute) appRouteObserver.subscribe(this, route);
    final anim = route?.animation;
    if (anim != _routeAnim) {
      _routeAnim?.removeStatusListener(_onRouteStatus);
      _routeAnim = anim;
      _routeReady = anim == null || anim.status == AnimationStatus.completed;
      anim?.addStatusListener(_onRouteStatus);
    }
    _sync();
  }

  void _onRouteStatus(AnimationStatus status) {
    final ready = status == AnimationStatus.completed;
    if (ready != _routeReady) {
      _routeReady = ready;
      _sync();
    }
  }

  @override
  void didUpdateWidget(T old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
    _sync();
  }

  @override
  void didPushNext() {
    _covered = true;
    _sync();
  }

  @override
  void didPopNext() {
    _covered = false;
    _sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    appRouteObserver.unsubscribe(this);
    _routeAnim?.removeStatusListener(_onRouteStatus);
    _wake?.cancel();
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  /// Arranca o para el reloj según la visibilidad.
  void _sync() {
    if (_shouldRun) {
      if (!_ticker.isActive && _wake == null) _resume();
    } else {
      _pause();
    }
  }

  void _sleep(double t, double quietFor) {
    _wake = Timer(Duration(milliseconds: (quietFor * 1000).ceil()), () {
      _wake = null;
      _time.value = t + quietFor;
      _base = _time.value;
      if (_shouldRun) _ticker.start();
    });
  }

  void _resume() {
    final t = _time.value;
    final quietFor = quietRemaining(t);
    if (quietFor > 0) {
      // En reposo: nada que pintar hasta el siguiente tiempo.
      _sleep(t, quietFor);
      return;
    }
    _base = t;
    _ticker.start();
  }

  void _pause() {
    _wake?.cancel();
    _wake = null;
    if (_ticker.isActive) {
      _ticker.stop();
      _base = _time.value;
    }
  }

  void _onTick(Duration elapsed) {
    final t = _base + elapsed.inMicroseconds / 1e6;
    final quietFor = quietRemaining(t);
    _time.value = t;
    if (quietFor > 0) {
      // Fotograma de reposo pintado: se duerme hasta el siguiente tiempo.
      _ticker.stop();
      _base = t;
      if (_shouldRun) _sleep(t, quietFor);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = GmColors.of(context).isDark;
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final s = w / designWidth;
      // Ilustración decorativa: VoiceOver/TalkBack la saltan.
      return ExcludeSemantics(
        child: SizedBox(
          width: w,
          height: designHeight * s,
          child: ValueListenableBuilder<double>(
            valueListenable: _time,
            builder: (context, t, _) =>
                buildLayers(context, s, _reduced ? null : t, dark),
          ),
        ),
      );
    });
  }
}

/// Reposo restante en un bucle de [loop] s con tramos activos [active]
/// (segundos dentro del bucle) y una entrada inicial hasta [entranceEnd].
double loopQuietRemaining(
  double t, {
  required double loop,
  required List<(double, double)> active,
  double entranceEnd = 0,
}) {
  if (t < entranceEnd + 0.05) return 0;
  // Al despertar justo en el inicio de un tramo, el resto de la división
  // puede quedar una millonésima por debajo: eso ya cuenta como tramo
  // activo (si no, el reloj se volvería a dormir 1 ms una y otra vez).
  const eps = 0.002;
  final lt = t % loop;
  for (final (a, b) in active) {
    if (lt >= a - eps && lt < b) return 0;
  }
  for (final (a, _) in active) {
    if (lt < a) return a - lt;
  }
  final rest = loop - lt + active.first.$1;
  return rest < eps ? 0 : rest;
}
