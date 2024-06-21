import 'package:bloc/bloc.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/restaurants/map/restaurant_map_state.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/data/model/restaurant_response.dart';

class RestaurantMapCubit extends Cubit<RestaurantMapState> {
  late final RemoteRepository _remoteRepository;
  late Restaurant restaurant;

  RestaurantMapCubit(this._remoteRepository) : super(RestaurantInitial());

  Future<void> getRestaurants(int number,String islandId) async {
    RestaurantResponse restaurantResponse = await _remoteRepository.getAllRestaurants(number,islandId);
    emit(RestaurantMapLoaded(restaurantResponse));
  }
  Future<void> getAllRestaurants(int number) async {
    RestaurantResponse allRestaurants = await _remoteRepository.getAllRestaurants(0);
    bool condition = true;
    int index= 1;
    while(condition){
      RestaurantResponse restaurantResponse = await _remoteRepository.getAllRestaurants(index*15);
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
     List<Restaurant> restaurants = await _remoteRepository.getFilterRestaurants(categories!.join(";"), municipalities!.join(";"), types!.join(";"), text!,islandId!);
     if (isOpen) {
       restaurants = restaurants.where((element) => element.open).toList();
     }
     emit(RestaurantFilterMap(restaurants));
  }

}
