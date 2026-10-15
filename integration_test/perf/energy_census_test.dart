// Censo de energía: recorre la app real y, en cada pantalla, mide lo que
// cuesta tenerla abierta.
//
// Por escenario:
// - fotogramas por segundo (en reposo debería ser ~0: cada fotograma es
//   CPU + GPU de pantalla completa, a 120 Hz en ProMotion);
// - tiempos de build (UI) y raster de cada fotograma (solo valen en profile);
// - tickers activos y sin silenciar (los que piden fotogramas), por widget;
// - capas caras del último fotograma: BackdropFilter, Opacity, vistas de
//   plataforma (mapa) y texturas (vídeo).
//
// Ejecutar en dispositivo real (profile):
//   flutter drive --profile -d <udid> \
//     --driver=test_driver/perf_driver.dart \
//     --target=integration_test/perf/energy_census_test.dart
// Resultado en build/perf/energy_census.json.
//
// En simulador (debug) los recuentos de fotogramas, tickers y capas valen;
// los milisegundos no.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/cubit/new_home/new_home_filters_cubit.dart';
import 'package:guachinches/data/cubit/new_home/visits_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_state.dart';
import 'package:guachinches/data/model/Types.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/main.dart' as app;
import 'package:guachinches/ui/pages/advance_search/advanced_search.dart';
import 'package:guachinches/ui/pages/new_home/new_home_screen.dart';
import 'package:guachinches/ui/pages/premios/premios_entry_page.dart';
import 'package:guachinches/ui/pages/premios/premios_ranking_page.dart';
import 'package:guachinches/ui/pages/restaurant_detail/restaurant_detail_screen.dart';
import 'package:guachinches/ui/pages/visit/visit_screen.dart';
import 'package:guachinches/utils/open_state.dart';
import 'package:guachinches/utils/contextual_pool.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

const _idle = Duration(seconds: 10);

/// Solo los escenarios cuyo nombre empieza por alguno de estos prefijos
/// (`--dart-define=PERF_ONLY=ficha,visita`). Vacío: todos.
const _only = String.fromEnvironment('PERF_ONLY');
final _prefixes = _only.split(',').where((p) => p.isNotEmpty).toList();

/// El Inicio, aunque haya otra pantalla encima (entonces está «offstage»).
final _home = find.byType(NewHomeScreen, skipOffstage: false);

final List<FrameTiming> _timings = [];

/// Cuenta los fotogramas que PIDE la app (tickers, setState, repintados).
///
/// En un test «vivo» el binding encadena un fotograma tras otro aunque nadie
/// los pida, así que contar fotogramas dibujados daría siempre el máximo.
/// Aquí solo cuenta un fotograma si desde el anterior alguien llamó a
/// [scheduleFrame], que es exactamente lo que, fuera del test, despierta al
/// motor.
class _EnergyBinding extends IntegrationTestWidgetsFlutterBinding {
  int appFrames = 0;
  bool _requested = false;

  @override
  void scheduleFrame() {
    _requested = true;
    super.scheduleFrame();
  }

  @override
  void handleBeginFrame(Duration? rawTimeStamp) {
    if (_requested) appFrames++;
    _requested = false;
    super.handleBeginFrame(rawTimeStamp);
  }
}

late final _EnergyBinding _binding;

void main() {
  final binding = _binding = _EnergyBinding();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('censo de energía por pantalla', (tester) async {
    final report = <String, Object?>{};
    SchedulerBinding.instance.addTimingsCallback(_timings.addAll);

    await _skipOnboarding();
    // main() pone su propio FlutterError.onError (Crashlytics); el binding
    // de test necesita el suyo de vuelta para informar de los fallos.
    final testOnError = FlutterError.onError;
    app.main();
    // En el simulador Firebase + Remote Config tardan en arrancar.
    await _waitFor(
        tester, find.byType(NewHomeScreen), const Duration(minutes: 4));
    FlutterError.onError = testOnError;
    _log('arranque', {'ok': true});

    await _dismissPremiosSheet(tester);
    // Arranque: datos, imágenes y entradas «una vez».
    await _wait(const Duration(seconds: 12));

    // Se eligen ya el restaurante y la visita (cuando hayan llegado): luego
    // la lista temática usa el mismo RestaurantCubit para filtrar y el
    // estado deja de ser el pool.
    final homeCtx = tester.element(_home);
    var pool = const <Restaurant>[];
    String? visitId;
    for (var i = 0; i < 40 && (pool.isEmpty || visitId == null); i++) {
      final rState = homeCtx.read<RestaurantCubit>().state;
      if (rState is AllRestaurantLoaded) {
        pool = rState.restaurantResponse.restaurants;
      }
      final vState = homeCtx.read<VisitsCubit>().state;
      if (vState is VisitsLoaded && vState.visits.isNotEmpty) {
        visitId = vState.visits.first.id;
      }
      if (pool.isEmpty || visitId == null) {
        await _wait(const Duration(milliseconds: 500));
      }
    }
    final now = DateTime.now();
    final openId = pool.isEmpty
        ? null
        : pool
            .firstWhere((r) => isRestaurantOpenNow(r, now),
                orElse: () => pool.first)
            .id;

    Future<void> scenario(String name, Future<void> Function() body) async {
      if (_prefixes.isNotEmpty && !_prefixes.any(name.startsWith)) return;
      try {
        await body();
      } catch (e) {
        report[name] = {'error': '$e'};
      }
      _log(name, report[name]);
    }

    Future<void> idle(String name) async {
      report[name] = await _measure(tester, _idle);
    }

    await scenario('inicio_reposo_arriba', () => idle('inicio_reposo_arriba'));

    await scenario('inicio_scroll', () async {
      report['inicio_scroll'] = await _measure(tester, Duration.zero,
          during: () async {
        final s = _mainScroll(tester);
        for (var i = 0; i < 4; i++) {
          await tester.fling(s, const Offset(0, -500), 1500);
          await _wait(const Duration(milliseconds: 1200));
        }
      });
    });

    await scenario('inicio_reposo_scrolleado',
        () => idle('inicio_reposo_scrolleado'));

    for (final (id, name) in const [
      ('tab-listas', 'tab_listas_reposo'),
      ('tab-mapa', 'tab_mapa_reposo'),
      ('tab-visitas', 'tab_visitas_reposo'),
      ('tab-perfil', 'tab_perfil_reposo'),
    ]) {
      await scenario(name, () async {
        await _tapId(tester, id);
        await _wait(const Duration(seconds: 4));
        await idle(name);
      });
    }

    await scenario('tab_explora_vuelta', () async {
      await _tapId(tester, 'tab-explora');
      await _wait(const Duration(seconds: 2));
    });

    // Lista temática con cabecera animada (mesa con brindis).
    await scenario('lista_tradicional_reposo', () async {
      final ctx = tester.element(_home);
      final islandId = ctx.read<NewHomeFiltersCubit>().state.islandId;
      final tipo = Types(
          id: RestaurantTypeIds.guachinchesTradicionales,
          nombre: 'Guachinches tradicionales',
          iconUrl: '');
      Navigator.of(ctx).push(MaterialPageRoute(
        builder: (_) => AdvancedSearch(
          categories: const [],
          municipalities: const [],
          types: [tipo],
          preSelectedTypes: [tipo],
          islandId: islandId,
        ),
      ));
      await _wait(const Duration(seconds: 5));
      await idle('lista_tradicional_reposo');
    });
    await scenario('lista_tradicional_scroll', () async {
      report['lista_tradicional_scroll'] =
          await _measure(tester, Duration.zero, during: () async {
        final s = _mainScroll(tester);
        for (var i = 0; i < 3; i++) {
          await tester.fling(s, const Offset(0, -500), 1500);
          await _wait(const Duration(milliseconds: 1200));
        }
      });
    });
    await scenario('lista_tradicional_reposo_scrolleado',
        () => idle('lista_tradicional_reposo_scrolleado'));
    await _popToHome(tester);

    // Ficha de un restaurante abierto ahora (cabecera con el punto vivo),
    // como al tocarlo desde el Inicio.
    await scenario('ficha_reposo', () async {
      if (openId == null) throw StateError('sin restaurantes');
      final ctx = tester.element(_home);
      Navigator.of(ctx).push(MaterialPageRoute(
          builder: (_) => RestaurantDetailScreen(id: openId)));
      await _wait(const Duration(seconds: 6));
      await idle('ficha_reposo');
    });
    await scenario('ficha_scroll', () async {
      report['ficha_scroll'] =
          await _measure(tester, Duration.zero, during: () async {
        final s = _mainScroll(tester);
        for (var i = 0; i < 3; i++) {
          await tester.fling(s, const Offset(0, -500), 1500);
          await _wait(const Duration(milliseconds: 1200));
        }
      });
    });
    await _popToHome(tester);

    // Encuesta: Entrada (papeleta y barrica) y Ranking (brillos).
    for (final (name, page) in [
      ('encuesta_entrada_reposo', const PremiosEntryPage()),
      ('encuesta_ranking_reposo', const PremiosRankingPage()),
    ]) {
      await scenario(name, () async {
        final ctx = tester.element(_home);
        Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => page));
        await _wait(const Duration(seconds: 5));
        await idle(name);
      });
      await _popToHome(tester);
    }

    // Reels: la primera visita, como al tocarla en el Inicio o en Visitas.
    await scenario('visita_reels', () async {
      final id = visitId;
      if (id == null) throw StateError('sin visitas');
      final ctx = tester.element(_home);
      Navigator.of(ctx).push(MaterialPageRoute(
          builder: (_) => VisitDetailPage(visitId: id)));
      await _wait(const Duration(seconds: 6));
      await idle('visita_reels');
    });
    await _popToHome(tester);

    binding.reportData = report;
  }, timeout: const Timeout(Duration(minutes: 15)));
}

/// En una instalación nueva la app abre el onboarding: se marca como hecho
/// (sin tocar nada si ya lo estaba) para medir directamente el Inicio.
Future<void> _skipOnboarding() async {
  final dir = await getApplicationSupportDirectory();
  await dir.create(recursive: true);
  final marker = File('${dir.path}/.dcc_installed_v1');
  if (!await marker.exists()) await marker.create();
  const storage = FlutterSecureStorage();
  for (final k in const [
    'onBoardingFinished',
    'prefLocationAsked',
    'surveyOnboarding2026Shown',
  ]) {
    if (await storage.read(key: k) != 'true') {
      await storage.write(key: k, value: 'true');
    }
  }
}

/// La campaña de Premios puede abrir una hoja al entrar: se cierra.
Future<void> _dismissPremiosSheet(WidgetTester tester) async {
  await _wait(const Duration(seconds: 6));
  final handle = tester.ensureSemantics();
  final notNow = find.bySemanticsIdentifier('home-premios-sheet-not-now');
  if (notNow.evaluate().isNotEmpty) {
    await tester.tap(notNow.first, warnIfMissed: false);
    await _wait(const Duration(seconds: 2));
  }
  handle.dispose();
}

Future<void> _wait(Duration d) => Future<void>.delayed(d);

Future<void> _waitFor(WidgetTester tester, Finder f, Duration max) async {
  final start = DateTime.now();
  final end = start.add(max);
  var lastLog = start;
  while (f.evaluate().isEmpty) {
    if (DateTime.now().difference(lastLog).inSeconds >= 15) {
      lastLog = DateTime.now();
      _log('esperando', {
        'buscando': '$f',
        'segundos': DateTime.now().difference(start).inSeconds,
      });
    }
    if (DateTime.now().isAfter(end)) {
      throw TestFailure('No apareció $f en $max');
    }
    await _wait(const Duration(milliseconds: 250));
  }
}

Future<void> _tapId(WidgetTester tester, String id) async {
  final handle = tester.ensureSemantics();
  await tester.tap(find.bySemanticsIdentifier(id), warnIfMissed: false);
  handle.dispose();
}

/// El scroll vertical más grande de la pantalla de arriba (no las filas
/// horizontales de chips ni los carruseles).
Finder _mainScroll(WidgetTester tester) {
  final vertical = find.byWidgetPredicate((w) =>
      w is Scrollable &&
      (w.axisDirection == AxisDirection.down ||
          w.axisDirection == AxisDirection.up));
  final candidates = vertical.evaluate().toList()
    ..sort((a, b) {
      final sa = a.size ?? Size.zero;
      final sb = b.size ?? Size.zero;
      return (sb.width * sb.height).compareTo(sa.width * sa.height);
    });
  if (candidates.isEmpty) throw StateError('sin scroll vertical');
  return find.byElementPredicate((e) => e == candidates.first);
}

Future<void> _popToHome(WidgetTester tester) async {
  final ctx = tester.element(_home);
  Navigator.of(ctx).popUntil((r) => r.isFirst);
  await _wait(const Duration(seconds: 2));
}

/// Mide una ventana: en reposo ([window]) o mientras corre [during].
Future<Map<String, Object?>> _measure(WidgetTester tester, Duration window,
    {Future<void> Function()? during}) async {
  final f0 = _binding.appFrames;
  final t0 = _timings.length;
  final sw = Stopwatch()..start();
  if (during != null) {
    await during();
  } else {
    await _wait(window);
  }
  sw.stop();
  // Los FrameTiming llegan en lotes: se da tiempo a que lleguen.
  await _wait(const Duration(milliseconds: 1200));
  final secs = sw.elapsedMilliseconds / 1000;
  final frames = _binding.appFrames - f0;
  final timings = _timings.sublist(t0);
  return {
    'segundos': double.parse(secs.toStringAsFixed(1)),
    'fotogramas': frames,
    'fps': double.parse((frames / secs).toStringAsFixed(1)),
    'build_ms': _stats(timings.map((t) => t.buildDuration)),
    'raster_ms': _stats(timings.map((t) => t.rasterDuration)),
    'tickers_activos': _activeTickers(),
    'capas': _layerCensus(),
  };
}

Map<String, num> _stats(Iterable<Duration> ds) {
  final l = ds.map((d) => d.inMicroseconds / 1000).toList()..sort();
  if (l.isEmpty) return {'n': 0};
  double p(double q) => l[((l.length - 1) * q).round()];
  double r(double v) => double.parse(v.toStringAsFixed(2));
  return {
    'n': l.length,
    'media': r(l.reduce((a, b) => a + b) / l.length),
    'p90': r(p(0.9)),
    'p99': r(p(0.99)),
    'max': r(l.last),
  };
}

/// Widgets cuyo State tiene un Ticker activo y sin silenciar (= pide un
/// fotograma en cada vsync). Agrupados por tipo de widget.
Map<String, int> _activeTickers() {
  final out = <String, int>{};
  void visit(Element e) {
    if (e is StatefulElement && e.state is TickerProvider) {
      for (final p in e.state.toDiagnosticsNode().getProperties()) {
        final v = p.value;
        final tickers = v is Ticker
            ? [v]
            : v is Set<Ticker>
                ? v.toList()
                : const <Ticker>[];
        final n = tickers.where((t) => t.isActive && !t.muted).length;
        if (n > 0) {
          final k = e.widget.runtimeType.toString();
          out[k] = (out[k] ?? 0) + n;
        }
      }
    }
    e.visitChildren(visit);
  }

  WidgetsBinding.instance.rootElement?.visitChildren(visit);
  return out;
}

/// Capas caras del último fotograma pintado.
Map<String, int> _layerCensus() {
  final out = <String, int>{};
  void add(String k) => out[k] = (out[k] ?? 0) + 1;
  void visit(Layer l) {
    if (l is BackdropFilterLayer) add('BackdropFilter');
    if (l is OpacityLayer && (l.alpha ?? 255) < 255) add('Opacity');
    if (l is ImageFilterLayer) add('ImageFilter');
    if (l is ShaderMaskLayer) add('ShaderMask');
    if (l is ColorFilterLayer) add('ColorFilter');
    if (l is PlatformViewLayer) add('PlatformView');
    if (l is TextureLayer) add('Texture');
    if (l is ClipRRectLayer &&
        l.clipBehavior == Clip.antiAliasWithSaveLayer) {
      add('ClipSaveLayer');
    }
    if (l is PictureLayer) add('Picture');
    if (l is ContainerLayer) {
      var c = l.firstChild;
      while (c != null) {
        visit(c);
        c = c.nextSibling;
      }
    }
  }

  for (final v in RendererBinding.instance.renderViews) {
    // ignore: invalid_use_of_protected_member
    final root = v.layer;
    if (root != null) visit(root);
  }
  return out;
}

void _log(String name, Object? data) {
  // Una línea por escenario para poder sacarla del log del simulador.
  // ignore: avoid_print
  print('PERF_JSON ${jsonEncode({'escenario': name, ...?data as Map?})}');
}
