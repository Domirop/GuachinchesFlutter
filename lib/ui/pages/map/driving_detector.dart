import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Umbrales de conducción (m/s).
const double kEnterDriveSpeed = 5.0; // ~18 km/h
const double kExitDriveSpeed = 1.5; // ~5,4 km/h
const int kDriveSampleWindow = 8;
const int kDriveMinSamplesToEnter = 5;

/// Detecta si el usuario va en coche a partir de las posiciones (mediana de
/// la velocidad en una ventana). Al detectarlo NO entra solo en modo coche:
/// levanta [shouldSuggest] para que la pantalla pregunte («¿Vas en
/// coche?»). Sale solo al pararse.
class MapDrivingDetector {
  MapDrivingDetector({DateTime Function()? clock})
      : _now = clock ?? DateTime.now;

  final DateTime Function() _now;
  final List<double> _samples = [];
  final ValueNotifier<bool> isDriving = ValueNotifier<bool>(false);
  final ValueNotifier<bool> shouldSuggest = ValueNotifier<bool>(false);
  Position? _lastPos;
  DateTime? _suppressUntil;

  /// Velocidad mediana actual (m/s).
  double speed = 0;

  void onPosition(Position p) {
    // El simulador de iOS da speed = 0/−1 aunque la posición se mueva: se
    // calcula también con la distancia entre puntos y se usa la mayor.
    double computed = 0;
    final last = _lastPos;
    if (last != null) {
      final dtMs = p.timestamp.difference(last.timestamp).inMilliseconds;
      if (dtMs > 0) {
        final meters = Geolocator.distanceBetween(
            last.latitude, last.longitude, p.latitude, p.longitude);
        computed = meters / (dtMs / 1000.0);
      }
    }
    final raw = p.speed.isFinite && p.speed > 0 ? p.speed : 0.0;
    final v = raw > computed ? raw : computed;
    _lastPos = p;

    _samples.add(v);
    if (_samples.length > kDriveSampleWindow) _samples.removeAt(0);
    speed = median(_samples);

    if (isDriving.value) {
      if (speed < kExitDriveSpeed) isDriving.value = false;
      return;
    }
    if (shouldSuggest.value) return;
    final until = _suppressUntil;
    if (until != null && _now().isBefore(until)) return;
    if (_samples.length >= kDriveMinSamplesToEnter &&
        speed > kEnterDriveSpeed) {
      shouldSuggest.value = true;
    }
  }

  /// «Activar modo coche».
  void confirmDrive() {
    shouldSuggest.value = false;
    isDriving.value = true;
  }

  /// «Ahora no»: no vuelve a preguntar en [cooldown].
  void dismissSuggestion({Duration cooldown = const Duration(minutes: 5)}) {
    shouldSuggest.value = false;
    _suppressUntil = _now().add(cooldown);
  }

  /// «Salir del modo coche».
  void forceExit() {
    _samples.clear();
    _lastPos = null;
    _suppressUntil = _now().add(const Duration(minutes: 5));
    isDriving.value = false;
    shouldSuggest.value = false;
  }

  void onPaused() {
    _samples.clear();
    _lastPos = null;
    speed = 0;
  }

  void dispose() {
    isDriving.dispose();
    shouldSuggest.dispose();
  }

  @visibleForTesting
  static double median(List<double> values) {
    if (values.isEmpty) return 0;
    final sorted = [...values]..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[mid];
    return (sorted[mid - 1] + sorted[mid]) / 2.0;
  }
}
