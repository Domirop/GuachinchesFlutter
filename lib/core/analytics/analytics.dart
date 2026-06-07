/// Capa de analítica desacoplada. Las pantallas llaman a `Analytics.I.logEvent`
/// y no conocen el backend concreto (Firebase, PostHog…). Permite:
///  - cambiar de proveedor sin tocar las pantallas,
///  - enviar a varios a la vez durante una transición (MultiplexAnalyticsService),
///  - apagar todo en tests (NoopAnalyticsService).
abstract class AnalyticsService {
  Future<void> init();

  /// Evento de producto. Los valores null de [params] se descartan.
  Future<void> logEvent(String name, [Map<String, Object?>? params]);

  /// Asocia los eventos siguientes a un usuario (login).
  Future<void> identify(String userId);

  /// Desasocia el usuario (logout).
  Future<void> reset();
}

/// Limpia parámetros: descarta nulls y devuelve null si queda vacío.
Map<String, Object>? sanitizeParams(Map<String, Object?>? params) {
  if (params == null) return null;
  final out = <String, Object>{};
  params.forEach((k, v) {
    if (v != null) out[k] = v;
  });
  return out.isEmpty ? null : out;
}

/// No hace nada. Default seguro (tests, o antes de configurar).
class NoopAnalyticsService implements AnalyticsService {
  const NoopAnalyticsService();

  @override
  Future<void> init() async {}

  @override
  Future<void> logEvent(String name, [Map<String, Object?>? params]) async {}

  @override
  Future<void> identify(String userId) async {}

  @override
  Future<void> reset() async {}
}

/// Envía a varios backends a la vez. Un fallo en uno no impide a los demás.
class MultiplexAnalyticsService implements AnalyticsService {
  final List<AnalyticsService> services;

  MultiplexAnalyticsService(this.services);

  Future<void> _each(Future<void> Function(AnalyticsService s) op) async {
    for (final s in services) {
      try {
        await op(s);
      } catch (_) {
        // Un backend caído no debe romper el resto ni la app.
      }
    }
  }

  @override
  Future<void> init() => _each((s) => s.init());

  @override
  Future<void> logEvent(String name, [Map<String, Object?>? params]) =>
      _each((s) => s.logEvent(name, params));

  @override
  Future<void> identify(String userId) => _each((s) => s.identify(userId));

  @override
  Future<void> reset() => _each((s) => s.reset());
}

/// Punto de acceso global. Configurado una vez en `main()`.
class Analytics {
  Analytics._();

  static AnalyticsService _instance = const NoopAnalyticsService();

  static AnalyticsService get I => _instance;

  /// True si PostHog está activo (hay POSTHOG_API_KEY). Lo usa el MaterialApp
  /// para enganchar el PostHogObserver (screen-tracking automático) solo cuando
  /// PostHog está configurado.
  static bool posthogEnabled = false;

  static void configure(AnalyticsService service) => _instance = service;
}
