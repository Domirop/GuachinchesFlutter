import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/core/analytics/analytics.dart';
import 'package:guachinches/core/analytics/analytics_events.dart';
import 'package:guachinches/data/RemoteRepository.dart';

/// Versión del texto de consentimiento mostrado al usuario. DEBE coincidir con
/// el `consentTextVersion` que se envía al backend (prueba RGPD, migration 029).
/// Si se cambia el copy del consentimiento, hay que subir esta versión.
const String kNewsletterConsentTextVersion = '2026-06-11.v1';

/// Gestiona el consentimiento de newsletter:
/// - Estado **local** (secure storage) para reflejar el toggle sin round-trip.
/// - Sincronización **defensiva** al backend (fuente de verdad legal).
///
/// El fallo de red NO debe romper el flujo de registro: el estado local queda
/// guardado y se puede reintentar desde Ajustes.
class NewsletterConsentService {
  static const _kAsked = 'nl_consent_asked';
  static const _kGranted = 'nl_consent_granted';

  final RemoteRepository _repo;
  final FlutterSecureStorage _storage;

  NewsletterConsentService(
    this._repo, {
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  /// True si ya se le preguntó al usuario (para no repetir el prompt).
  Future<bool> hasBeenAsked() async =>
      (await _storage.read(key: _kAsked)) == 'true';

  /// Estado local del consentimiento (para el toggle de Ajustes).
  Future<bool> isGranted() async =>
      (await _storage.read(key: _kGranted)) == 'true';

  /// Estado real del servidor (fuente de verdad legal). Cae al estado local si
  /// la red falla. Útil para reflejar el toggle con precisión al abrir Ajustes.
  Future<bool> syncedGranted(String userId) async {
    if (userId.isEmpty) return isGranted();
    try {
      final server = await _repo.getNewsletterConsent(userId);
      await _storage.write(key: _kGranted, value: server ? 'true' : 'false');
      return server;
    } catch (_) {
      return isGranted();
    }
  }

  /// Guarda la decisión localmente y la sincroniza al backend.
  Future<void> submit({
    required String userId,
    required bool granted,
    required String source,
  }) async {
    await _storage.write(key: _kAsked, value: 'true');
    await _storage.write(key: _kGranted, value: granted ? 'true' : 'false');
    // Analítica: evento + propiedad de persona para segmentar en PostHog.
    Analytics.I.logEvent(AnalyticsEvents.newsletterConsent, {
      'granted': granted,
      'source': source,
    });
    Analytics.I.setPersonProperties({
      AnalyticsEvents.propNewsletter: granted,
    });
    if (userId.isEmpty) return;
    try {
      await _repo.setNewsletterConsent(
        userId,
        granted: granted,
        consentTextVersion: kNewsletterConsentTextVersion,
        source: source,
      );
    } catch (_) {
      // Backend aún no desplegado o sin red: el estado local queda guardado y
      // el usuario puede reintentar desde el toggle de Ajustes.
    }
  }
}
