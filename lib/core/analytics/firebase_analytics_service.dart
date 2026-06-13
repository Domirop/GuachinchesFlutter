import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:guachinches/core/analytics/analytics.dart';

/// Adaptador de [AnalyticsService] sobre Firebase Analytics (GA4).
/// `Firebase.initializeApp()` ya se llama en `main()`, así que [init] es no-op.
class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalytics get _fa => FirebaseAnalytics.instance;

  @override
  Future<void> init() async {}

  @override
  Future<void> logEvent(String name, [Map<String, Object?>? params]) {
    return _fa.logEvent(name: name, parameters: sanitizeParams(params));
  }

  @override
  Future<void> identify(String userId) => _fa.setUserId(id: userId);

  @override
  Future<void> setPersonProperties(Map<String, Object?> properties) async {
    // Firebase solo admite propiedades de usuario string. Coercemos.
    for (final e in properties.entries) {
      if (e.value == null) continue;
      await _fa.setUserProperty(name: e.key, value: e.value.toString());
    }
  }

  @override
  Future<void> reset() => _fa.setUserId(id: null);
}
