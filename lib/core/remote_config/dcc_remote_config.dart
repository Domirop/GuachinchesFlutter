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

  Future<void> init() async {
    await _bridge.configure(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(hours: 1),
    );
    await _bridge.setDefaults({
      'show_curated_lists': true,
      'show_weather_chip': true,
      'min_supported_build': 1,
      'maintenance_mode': false,
    });
    try {
      await _bridge.fetchAndActivate();
    } catch (e) {
      AppLogger.warn('remote-config', 'fetchAndActivate failed: $e');
    }
  }

  bool get showCuratedLists => _bridge.getBool('show_curated_lists');
  bool get showWeatherChip => _bridge.getBool('show_weather_chip');
  int get minSupportedBuild => _bridge.getInt('min_supported_build');
  bool get maintenanceMode => _bridge.getBool('maintenance_mode');
}
