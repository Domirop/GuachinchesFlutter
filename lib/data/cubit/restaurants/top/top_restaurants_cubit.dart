import 'package:bloc/bloc.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/restaurants/top/top_restaurant_state.dart';
import 'package:guachinches/data/model/TopRestaurants.dart';

class TopRestaurantCubit extends Cubit<TopRestaurantState> {
  final RemoteRepository _remoteRepository;

  TopRestaurantCubit(this._remoteRepository) : super(TopRestaurantInitial());

  Future<void> getTopRestaurants() async {
    List<TopRestaurants> restaurants = await _remoteRepository.getTopRestaurants();
    print(restaurants);
    emit(TopRestaurantLoaded(restaurants));
  }

}
