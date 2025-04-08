import 'package:bloc/bloc.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_state.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/data/model/restaurant_response.dart';

class RestaurantCubit extends Cubit<RestaurantState> {
  late final RemoteRepository _remoteRepository;
  late Restaurant restaurant;

  RestaurantCubit(this._remoteRepository) : super(RestaurantInitial());

  Future<void> getRestaurants(int number,String islandId) async {
    RestaurantResponse restaurantResponse = await _remoteRepository.getAllRestaurants(number,islandId);

    emit(RestaurantLoaded(restaurantResponse));
  }

  Future<void> getAllRestaurants(int number,String islandId) async {
    emit(RestaurantLoading());
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
      print('EMITTING RESTAURANT 0');
      print(restaurantResponse.restaurants.length);
      index++;
    }

    emit(AllRestaurantLoaded(allRestaurants));

  }
  Future<void> getFilterRestaurants({List<String>? categories, List<String>? municipalities, List<String>? types, String? text,String? islandId,bool isOpen=false}) async {
     List<Restaurant> restaurants = await _remoteRepository.getFilterRestaurants(categories!.join(";"), municipalities!.join(";"), types!.join(";"), text!,islandId!);
     if (isOpen) {
       restaurants = restaurants.where((element) => element.open).toList();
     }
     print('EMITTING RESTAURANT 2');
     print('EMITTING RESTAURANT 2');
     emit(RestaurantFilter(restaurants));
  }
  Future<void> getFilterRestaurantsAdvance({List<String>? categories, List<String>? municipalities, List<String>? types, String? text,String? islandId,bool isOpen=false}) async {
    emit(RestaurantLoading());
    List<Restaurant> restaurants = await _remoteRepository.getFilterRestaurants(categories!.join(";"), municipalities!.join(";"), types!.join(";"), text!,islandId!);
    if (isOpen) {
      restaurants = restaurants.where((element) => element.open).toList();
    }
    print('EMITTING RESTAURANT 2');
    print('EMITTING RESTAURANT 2');
    print('EMITTING RESTAURANT 2');
    emit(RestaurantFilterAdvanced(restaurants));
  }
}
