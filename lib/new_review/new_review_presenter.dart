import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/model/restaurant.dart';

class NewReviewPresenter{
  RemoteRepository _remoteRepository;
  NewReviewView _view;

  NewReviewPresenter(this._remoteRepository, this._view);

  saveReview(String userId, Restaurant restaurant ,String title, String review, String rating){
    _remoteRepository.saveReview( userId,  restaurant , title,  review,  rating);
  }
}
abstract class NewReviewView{
  reviewSaved();
}