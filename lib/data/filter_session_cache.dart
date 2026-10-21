import 'package:flutter/foundation.dart';
import 'package:guachinches/data/model/restaurant.dart';

/// Caché en memoria (de sesión) de las búsquedas de findByFilter sin texto.
///
/// La lista con varias categorías o sin tipo pide la isla entera (≈ 1,5 MB)
/// y filtra en el dispositivo: sin caché se descargaba en cada cambio de
/// filtro. Las entradas caducan a los 10 min; la clave lleva la isla (al
/// cambiar de isla no se reutiliza nada) y el «tira para recargar» de la
/// home la vacía.
class FilterSessionCache {
  FilterSessionCache({DateTime Function()? clock, this.ttl = defaultTtl})
      : _clock = clock ?? DateTime.now;

  static const Duration defaultTtl = Duration(minutes: 10);
  static final FilterSessionCache instance = FilterSessionCache();

  final DateTime Function() _clock;
  final Duration ttl;
  final Map<String, (DateTime, List<Restaurant>)> _entries = {};

  /// Solo las búsquedas sin texto se guardan (las de texto cambian con cada
  /// letra y pesan poco).
  static bool cacheable(String nombre) => nombre.trim().isEmpty;

  static String key({
    required String island,
    required String types,
    required String categories,
    required String municipalities,
  }) =>
      'island=$island|types=$types|cats=$categories|munis=$municipalities';

  List<Restaurant>? get(String key) {
    final e = _entries[key];
    if (e == null) return null;
    if (_clock().difference(e.$1) > ttl) {
      _entries.remove(key);
      return null;
    }
    return e.$2;
  }

  void put(String key, List<Restaurant> value) =>
      _entries[key] = (_clock(), List.unmodifiable(value));

  void clear() => _entries.clear();

  @visibleForTesting
  int get length => _entries.length;
}
