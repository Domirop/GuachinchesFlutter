import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:guachinches/core/logging/app_logger.dart';

/// Abstraction over FirebaseRemoteConfig, exposed so tests can inject a fake.
abstract class RemoteConfigBridge {
  Future<void> configure({
    required Duration fetchTimeout,
    required Duration minimumFetchInterval,
  });
  Future<void> setDefaults(Map<String, dynamic> defaults);
  Future<bool> fetchAndActivate();
  bool getBool(String key);
  int getInt(String key);
  String getString(String key);
}

class _FirebaseRcBridge implements RemoteConfigBridge {
  final FirebaseRemoteConfig _rc;
  _FirebaseRcBridge(this._rc);

  @override
  Future<void> configure({
    required Duration fetchTimeout,
    required Duration minimumFetchInterval,
  }) =>
      _rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: fetchTimeout,
        minimumFetchInterval: minimumFetchInterval,
      ));

  @override
  Future<void> setDefaults(Map<String, dynamic> defaults) =>
      _rc.setDefaults(defaults);

  @override
  Future<bool> fetchAndActivate() => _rc.fetchAndActivate();

  @override
  bool getBool(String key) => _rc.getBool(key);

  @override
  int getInt(String key) => _rc.getInt(key);

  @override
  String getString(String key) => _rc.getString(key);
}

class DccRemoteConfig {
  /// Set before the first widget build in tests to avoid Firebase initialization.
  @visibleForTesting
  static DccRemoteConfig? testOverride;

  static DccRemoteConfig get instance => testOverride ?? _productionInstance;

  static final DccRemoteConfig _productionInstance = DccRemoteConfig._internal(
    _FirebaseRcBridge(FirebaseRemoteConfig.instance),
  );

  DccRemoteConfig._internal(this._bridge);

  factory DccRemoteConfig.test(RemoteConfigBridge bridge) =>
      DccRemoteConfig._internal(bridge);

  final RemoteConfigBridge _bridge;

  /// Valores por defecto locales: la app arranca con ellos y no espera a la
  /// red.
  static const Map<String, dynamic> defaults = {
    'show_curated_lists': true,
    'show_weather_chip': true,
    'min_supported_build': 1,
    'maintenance_mode': false,
  };

  /// Tope real para la descarga: `fetchTimeout` solo cubre la petición, no
  /// el token de Firebase Installations del primer arranque (que llegó a
  /// tardar más de un minuto en iOS).
  static const fetchDeadline = Duration(seconds: 10);

  /// Ajustes y valores por defecto (locales, rápidos). La descarga va aparte
  /// ([fetchInBackground]) y nunca retiene el primer frame.
  Future<void> init({Duration localDeadline = const Duration(seconds: 3)}) async {
    try {
      await _bridge
          .configure(
            fetchTimeout: const Duration(seconds: 10),
            minimumFetchInterval: const Duration(hours: 1),
          )
          .timeout(localDeadline);
      await _bridge.setDefaults(defaults).timeout(localDeadline);
    } catch (e) {
      AppLogger.warn('remote-config', 'init: ${e.runtimeType}');
    }
  }

  /// Descarga y activa sin bloquear: lo nuevo vale desde que llega (o en el
  /// siguiente arranque). Si pasa de [fetchDeadline], se deja.
  Future<void> fetchInBackground({Duration deadline = fetchDeadline}) async {
    try {
      await _bridge.fetchAndActivate().timeout(deadline);
    } catch (e) {
      AppLogger.warn('remote-config', 'fetchAndActivate: ${e.runtimeType}');
    }
  }

  bool get showCuratedLists => _bridge.getBool('show_curated_lists');
  bool get showWeatherChip => _bridge.getBool('show_weather_chip');
  int get minSupportedBuild => _bridge.getInt('min_supported_build');
  bool get maintenanceMode => _bridge.getBool('maintenance_mode');
}
