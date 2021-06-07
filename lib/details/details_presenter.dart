import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/local/restaurant_sql_lite.dart';
import 'package:guachinches/data/local/sql_lite_local_repository.dart';

class DetailPresenter {
  RemoteRepository _remoteRepository;
  DetailView _view;
  final storage = new FlutterSecureStorage();
  SqlLiteLocalRepository sqlLiteLocalRepository = SqlLiteLocalRepository();

  DetailPresenter(this._remoteRepository, this._view);

  isUserLogged() async {
    String userId = await storage.read(key: "userId");
    if (userId == null) {
      _view.goToLogin();
    }else{
      _view.setUserId(userId);
    }
  }

  getIsFav(String restaurantId) async {
    RestaurantSQLLite restaurantSQLLite = await sqlLiteLocalRepository.getRestaurant(restaurantId);
    bool correct = false;
    if(restaurantSQLLite != null) {
      correct = true;
    }else{
      correct = false;
    }
    _view.setFav(correct);
  }

  saveFavRestaurant(String restaurantId) async {
    bool correct = false;
    RestaurantSQLLite restaurantSQLLite = await sqlLiteLocalRepository.getRestaurant(restaurantId);
    if(restaurantSQLLite != null){
      correct = await sqlLiteLocalRepository.removeRestaurant(restaurantId);
    }else{
      correct = await sqlLiteLocalRepository.insertRestaurant(restaurantId);
    }
    sqlLiteLocalRepository.getRestaurants();
    _view.setFav(correct);
  }
}

abstract class DetailView {
  goToLogin();
  setFav(bool correct);
  setUserId(String id);
}
