import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/restaurants/map/restaurant_map_cubit.dart';
import 'package:guachinches/data/model/Types.dart';

/// Datos de la pestaña Mapa: tipos de local (chips) y todos los sitios de la
/// isla (vía [RestaurantMapCubit], compartido con «Cerca de ti»).
class MapSearchPresenter {
  final MapSearchView _view;
  final RemoteRepository repository;
  final RestaurantMapCubit _restaurantCubit;

  MapSearchPresenter(this._view, this.repository, this._restaurantCubit);

  /// Tipos del servidor para los chips. Si fallan, el mapa sigue con
  /// «Abierto ahora» solo.
  Future<void> getAllTypes() async {
    try {
      final List<Types> types = await repository.getAllTypes();
      _view.setTypes(types);
    } catch (e) {
      AppLogger.warn('mapa', 'no se pudieron cargar los tipos: $e');
    }
  }

  /// Carga todos los sitios de la isla. El resultado llega por el cubit;
  /// el error se propaga para que la pantalla pinte «No pudimos cargar los
  /// sitios».
  Future<void> getAllRestaurants(String islandId) =>
      _restaurantCubit.getAllRestaurants(0, islandId);

  /// «Reintentar»: vuelve a pedir los sitios saltándose la caché.
  Future<void> reloadRestaurants(String islandId) async {
    try {
      await repository.invalidateCache('restaurants:');
    } catch (e) {
      AppLogger.warn('mapa', 'no se pudo invalidar la caché: $e');
    }
    await _restaurantCubit.getAllRestaurants(0, islandId);
  }
}

abstract class MapSearchView {
  void setTypes(List<Types> types);
}
