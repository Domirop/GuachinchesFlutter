import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:guachinches/core/analytics/analytics.dart';

/// Adaptador de [AnalyticsService] sobre PostHog (analítica de producto:
/// funnels, retención, feature flags, session replay).
///
/// Se configura por env (`POSTHOG_API_KEY` / `POSTHOG_HOST`). Mientras no haya
/// API key, este adaptador NO se añade al multiplexor (ver `main.dart`), así que
/// la app no envía nada a PostHog hasta que tú lo actives.
class PostHogAnalyticsService implements AnalyticsService {
  final String apiKey;
  final String host;

  PostHogAnalyticsService({
    required this.apiKey,
    this.host = 'https://eu.i.posthog.com',
  });

  @override
  Future<void> init() async {
    final config = PostHogConfig(apiKey)
      ..host = host
      ..debug = kDebugMode // logs de captura en consola solo en debug
      ..captureApplicationLifecycleEvents = true
      // Session replay con masking total (maskAllTexts/maskAllImages = true por
      // defecto) → privacy-safe / GDPR. Se puede desenmascarar selectivamente
      // más adelante con PostHogMaskWidget si se quiere ver alguna pantalla.
      ..sessionReplay = true;
    await Posthog().setup(config);
  }

  @override
  Future<void> logEvent(String name, [Map<String, Object?>? params]) {
    return Posthog().capture(
      eventName: name,
      properties: sanitizeParams(params),
    );
  }

  @override
  Future<void> identify(String userId) => Posthog().identify(userId: userId);

  @override
  Future<void> reset() => Posthog().reset();
}
