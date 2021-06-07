import 'package:bloc/bloc.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/model/Review.dart';
import 'package:guachinches/model/restaurant.dart';
import 'package:guachinches/data/cubit/restaurant_state.dart';

class RestaurantCubit extends Cubit<RestaurantState> {
  final RemoteRepository _remoteRepository;
  Restaurant restaurant;

  RestaurantCubit(this._remoteRepository) : super(RestaurantInitial());

  Future<void> getRestaurants() async {
    List<Restaurant> restaurants = await _remoteRepository.getAllRestaurants();

    for (int i = 0; i < restaurants.length; i++) {
      String avg = await _calculateAvg(restaurants[i].valoraciones);
      restaurants[i].avg = avg;
    }
    emit(RestaurantLoaded(restaurants));
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
      List<Restaurant> restaurants, String value) async {
    if (value == null || value.length == 0) {
      emit(RestaurantFilter(restaurants));
    } else {
      List<Restaurant> aux = restaurants.where((element) {
        return element.nombre.toLowerCase().contains(value.toLowerCase());
      }).toList();
      emit(RestaurantFilter(aux));
    }
  }
}
