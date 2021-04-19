import 'package:bloc/bloc.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/model/restaurant.dart';
import 'package:guachinches/data/cubit/restaurant_state.dart';

class RestaurantCubit extends Cubit<RestaurantState> {
  final RemoteRepository _remoteRepository;
  Restaurant cart;

  RestaurantCubit(this._remoteRepository) : super(RestaurantInitial());

  Future<void> getRestaurants() async {
    //TODO: Emit CartLoading
    List<Restaurant> restaurants = await _remoteRepository.getAllRestaurants();

    //TODO: Compare if cart exist return Cart if no exist create and return it.
    emit(RestaurantLoaded(restaurants));
  }

}

