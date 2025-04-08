import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/model/Video.dart';
import 'package:guachinches/data/model/restaurant.dart';

class VideoPresenter{
    final VideoPresenterView _view;
    final RemoteRepository _repository;

    VideoPresenter(this._view, this._repository);

    getAllVideos() async {
      List<Video> videos = await _repository.getAllVideos();
      _view.setVideos(videos);
    }
    getRestaurantDetails(String restaurantId) async {
      Restaurant restaurant = await _repository.getRestaurantById(restaurantId);
      _view.setRestaurant(restaurant);
    }

}

abstract class VideoPresenterView {
  setVideos(List<Video> videos);
  setRestaurant(Restaurant restaurant);
}
