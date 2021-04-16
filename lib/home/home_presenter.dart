import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/model/Category.dart';
import 'package:guachinches/model/Review.dart';
import 'package:guachinches/model/restaurant.dart';

class HomePresenter{
  final RemoteRepository _remoteRepository;
  final HomeView _view;

  HomePresenter(this._remoteRepository, this._view);

  getAllRestaurants() async {
    List<Restaurant> restaurants= await _remoteRepository.getAllRestaurants();
    for(int i = 0; i<restaurants.length; i++){
      String avg = await _calculateAvg(restaurants[i].valoraciones);
      restaurants[i].avg = avg;
      print(restaurants[i].avg);
    }

    _view.setAllRestaurants(restaurants);
  }
  Future<String> _calculateAvg(List<Review> reviews) async {
    double totalReviews = (reviews.length).toDouble();
    double totalratingSum = 0.0;
    for(int i = 0; i<reviews.length; i++){
      totalratingSum += double.parse(reviews[i].rating);
    }
    return (totalratingSum/ totalReviews).toString();
  }

  getAllCategories() async {
    List<Category> categories = await _remoteRepository.getAllCategories();
    _view.setAllCategories(categories);
  }
}
abstract class HomeView{
  setAllRestaurants(List<Restaurant> restaurants);
  setAllCategories(List<Category> categories);

}