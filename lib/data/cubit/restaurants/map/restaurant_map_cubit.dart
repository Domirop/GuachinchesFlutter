import 'package:bloc/bloc.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/restaurants/map/restaurant_map_state.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/data/model/restaurant_response.dart';

class RestaurantMapCubit extends Cubit<RestaurantMapState> {
  late final RemoteRepository _remoteRepository;
  late Restaurant restaurant;

  // Last-query params used by refresh()
  String? _lastIslandId;
  List<String> _lastCategories = const [];
  List<String> _lastMunicipalities = const [];
  List<String> _lastTypes = const [];
  String _lastText = '';
  bool _lastIsOpen = false;
  bool _hasFilterQuery = false;

  RestaurantMapCubit(this._remoteRepository) : super(RestaurantInitial());

  Future<void> getRestaurants(int number,String islandId) async {
    _lastIslandId = islandId;
    RestaurantResponse restaurantResponse = await _remoteRepository.getAllRestaurants(number,islandId);
    emit(RestaurantMapLoaded(restaurantResponse));
  }
  Future<void> getAllRestaurants(int number,String islandId) async {
    _lastIslandId = islandId;
    _hasFilterQuery = false;
    RestaurantResponse allRestaurants = await _remoteRepository.getAllRestaurants(0,islandId);
    bool condition = true;
    int index= 1;
    while(condition){
      RestaurantResponse restaurantResponse = await _remoteRepository.getAllRestaurants(index*15,islandId);
      if(restaurantResponse.restaurants.length>0){
        restaurantResponse.restaurants.forEach((element) {
          allRestaurants.restaurants.add(element);
        });
      }
      else{
        condition = false;
      }
      index++;
    }

    emit(AllRestaurantMapLoaded(allRestaurants));

  }
  Future<void> getFilterMapRestaurants({List<String>? categories, List<String>? municipalities, List<String>? types, String? text,String? islandId,bool isOpen=false}) async {
     _lastIslandId = islandId;
     _lastCategories = categories ?? const [];
     _lastMunicipalities = municipalities ?? const [];
     _lastTypes = types ?? const [];
     _lastText = text ?? '';
     _lastIsOpen = isOpen;
     _hasFilterQuery = true;
     List<Restaurant> restaurants = await _remoteRepository.getFilterRestaurants(categories!.join(";"), municipalities!.join(";"), types!.join(";"), text!,islandId!);
     if (isOpen) {
       restaurants = restaurants.where((element) => element.open).toList();
     }
     emit(RestaurantFilterMap(restaurants));
  }

  /// Re-invokes the last query (filter or all-restaurants) without emitting
  /// an intermediate Loading state. No-op if no query has been made yet.
  Future<void> refresh() async {
    final id = _lastIslandId;
    if (id == null) return;
    if (_hasFilterQuery) {
      await getFilterMapRestaurants(
        categories: _lastCategories,
        municipalities: _lastMunicipalities,
        types: _lastTypes,
        text: _lastText,
        isOpen: _lastIsOpen,
        islandId: id,
      );
    } else {
      await getAllRestaurants(0, id);
    }
  }

}
