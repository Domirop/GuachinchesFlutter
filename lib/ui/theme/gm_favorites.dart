import 'package:flutter/foundation.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/data/local/sql_lite_local_repository.dart';

/// Estado compartido de «Guardados» para los corazones del rediseño.
///
/// Usa la MISMA fuente que la ficha y la pantalla de Favoritos: la tabla
/// local `fav` de SQLite (`SqlLiteLocalRepository`). Sin lógica nueva: solo
/// cachea los ids en memoria para que los corazones de la home pinten sin
/// una consulta por tarjeta.
class GmFavorites extends ValueNotifier<Set<String>> {
  GmFavorites._() : super(const <String>{});
  static final GmFavorites instance = GmFavorites._();

  final _repo = SqlLiteLocalRepository();
  bool _loaded = false;

  /// Carga perezosa (una vez). Llamar también tras cambiar favoritos en
  /// otra pantalla para resincronizar.
  Future<void> ensureLoaded({bool force = false}) async {
    if (_loaded && !force) return;
    _loaded = true;
    try {
      final rows = await _repo.getRestaurants();
      value = rows.map((r) => r.restaurantId).toSet();
    } catch (e) {
      AppLogger.warn('gm-favorites', 'no se pudo leer fav: $e');
    }
  }

  bool isSaved(String id) => value.contains(id);

  /// Alterna guardado. Optimista: pinta al instante y persiste detrás.
  Future<bool> toggle(String id) async {
    final wasSaved = value.contains(id);
    final next = {...value};
    wasSaved ? next.remove(id) : next.add(id);
    value = next;
    final ok = wasSaved
        ? await _repo.removeRestaurant(id)
        : await _repo.insertRestaurant(id);
    if (!ok) {
      // Rollback si la BD falla.
      final back = {...value};
      wasSaved ? back.add(id) : back.remove(id);
      value = back;
    }
    return value.contains(id);
  }
}
