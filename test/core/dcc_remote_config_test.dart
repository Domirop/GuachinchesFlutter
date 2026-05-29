import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/core/remote_config/dcc_remote_config.dart';

class _FakeRcBridge implements RemoteConfigBridge {
  final bool fetchShouldThrow;
  final Map<String, dynamic> _remoteValues;
  final Map<String, dynamic> _store = {};

  _FakeRcBridge({
    this.fetchShouldThrow = false,
    Map<String, dynamic> remoteValues = const {},
  }) : _remoteValues = remoteValues;

  @override
  Future<void> configure({
    required Duration fetchTimeout,
    required Duration minimumFetchInterval,
  }) async {}

  @override
  Future<void> setDefaults(Map<String, dynamic> defaults) async {
    _store.addAll(defaults);
  }

  @override
  Future<bool> fetchAndActivate() async {
    if (fetchShouldThrow) throw Exception('simulated fetch failure');
    _store.addAll(_remoteValues);
    return true;
  }

  @override
  bool getBool(String key) => _store[key] as bool? ?? false;

  @override
  int getInt(String key) => _store[key] as int? ?? 0;
}

void main() {
  group('DccRemoteConfig', () {
    test('(a) getters return declared defaults when fetchAndActivate fails',
        () async {
      final fake = _FakeRcBridge(fetchShouldThrow: true);
      final dcc = DccRemoteConfig.test(fake);

      await dcc.init();

      expect(dcc.showCuratedLists, isTrue);
      expect(dcc.showWeatherChip, isTrue);
      expect(dcc.minSupportedBuild, equals(1));
      expect(dcc.maintenanceMode, isFalse);
    });

    test('(a) getters return declared defaults when no fetch has happened',
        () async {
      final fake = _FakeRcBridge();
      final dcc = DccRemoteConfig.test(fake);

      // Call init but simulate no-op fetch (no remote values)
      await dcc.init();

      expect(dcc.showCuratedLists, isTrue);
      expect(dcc.showWeatherChip, isTrue);
      expect(dcc.minSupportedBuild, equals(1));
      expect(dcc.maintenanceMode, isFalse);
    });

    test('(b) getters reflect values set via setDefaults / remote override',
        () async {
      final fake = _FakeRcBridge(remoteValues: {
        'show_curated_lists': false,
        'show_weather_chip': false,
        'min_supported_build': 5,
        'maintenance_mode': true,
      });
      final dcc = DccRemoteConfig.test(fake);

      await dcc.init();

      expect(dcc.showCuratedLists, isFalse);
      expect(dcc.showWeatherChip, isFalse);
      expect(dcc.minSupportedBuild, equals(5));
      expect(dcc.maintenanceMode, isTrue);
    });
  });
}
