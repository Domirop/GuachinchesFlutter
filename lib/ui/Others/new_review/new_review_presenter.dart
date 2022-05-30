import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_cubit.dart';
import 'package:guachinches/data/model/restaurant.dart';

class NewReviewPresenter{
  RemoteRepository _remoteRepository;
  NewReviewView _view;
  RestaurantCubit _restaurantCubit;

  NewReviewPresenter(this._remoteRepository, this._view, this._restaurantCubit);

  saveReview(String userId, Restaurant restaurant ,String title, String review, String rating) async {
    if(title == null || title.length == 0){
      title = "";
    }
    if(review == null || review.length == 0){
      review = "Sin descripción";
    }
    bool isAdded = await _remoteRepository.saveReview( userId,  restaurant , title,  review,  rating);
    if(isAdded == true){
      // await _restaurantCubit.getRestaurants();
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
