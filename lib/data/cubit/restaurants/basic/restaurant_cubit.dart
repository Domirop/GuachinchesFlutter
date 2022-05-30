import 'package:bloc/bloc.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_state.dart';
import 'package:guachinches/data/model/Review.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/data/model/restaurant_response.dart';

class RestaurantCubit extends Cubit<RestaurantState> {
  final RemoteRepository _remoteRepository;
  Restaurant restaurant;

  RestaurantCubit(this._remoteRepository) : super(RestaurantInitial());

  Future<void> getRestaurants(int number) async {
    RestaurantResponse restaurantResponse = await _remoteRepository.getAllRestaurants(number);

    // for (int i = 0; i < restaurantResponse.restaurants.length; i++) {
    //   String avg = await _calculateAvg(restaurantResponse.restaurants[i].valoraciones);
    //   restaurantResponse.restaurants[i].avg = avg;
    // }
    emit(RestaurantLoaded(restaurantResponse));
  }

  Future<String> _calculateAvg(List<Review> reviews) async {
    double totalReviews = (reviews.length).toDouble();
    double totalratingSum = 0.0;
    for (int i = 0; i < reviews.length; i++) {
      totalratingSum += double.parse(reviews[i].rating);
    }
    return (totalratingSum / totalReviews).toStringAsFixed(2);
  }

  Future<void> getFilterRestaurants(
      RestaurantResponse restaurantResponse, String value) async {
    if (value == null || value.length == 0) {
      emit(RestaurantFilter(restaurantResponse));
    } else {
      List<Restaurant> aux = restaurantResponse.restaurants.where((element) {
        return element.nombre.toLowerCase().contains(value.toLowerCase());
      }).toList();
      restaurantResponse.restaurants = aux;
      emit(RestaurantFilter(restaurantResponse));
    }
  }
}
