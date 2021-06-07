import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/restaurant_cubit.dart';
import 'package:guachinches/model/restaurant.dart';

class NewReviewPresenter{
  RemoteRepository _remoteRepository;
  NewReviewView _view;
  RestaurantCubit _restaurantCubit;

  NewReviewPresenter(this._remoteRepository, this._view, this._restaurantCubit);

  saveReview(String userId, Restaurant restaurant ,String title, String review, String rating) async {
    bool isAdded = await _remoteRepository.saveReview( userId,  restaurant , title,  review,  rating);
    if(isAdded == true){
      await _restaurantCubit.getRestaurants();
      _view.reviewSaved();
    }else{
      _view.reviewNotSaved();
    }
  }
}
abstract class NewReviewView{
  reviewSaved();
  reviewNotSaved();
}