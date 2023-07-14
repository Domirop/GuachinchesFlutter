import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/local/restaurant_sql_lite.dart';
import 'package:guachinches/data/local/sql_lite_local_repository.dart';
import 'package:guachinches/data/model/Review.dart';
import 'package:guachinches/data/model/block_user.dart';
import 'package:guachinches/data/model/report_review.dart';
import 'package:guachinches/data/model/restaurant.dart';

class DetailPresenter {
  RemoteRepository _remoteRepository;
  DetailView _view;
  final storage = new FlutterSecureStorage();
  SqlLiteLocalRepository sqlLiteLocalRepository = SqlLiteLocalRepository();

  DetailPresenter(this._remoteRepository, this._view);

  isUserLogged() async {
    String userId = await storage.read(key: "userId");
    if (userId != null) {
      _view.setUserId(userId);
    }
    return userId;
  }

  getRestaurantById(String id) async {
    Restaurant restaurant = await _remoteRepository.getRestaurantById(id);
    FirebaseAnalytics.instance.logEvent(
        name: 'detalles_restaurantes',
        parameters: <String, dynamic>{
          'id': '${restaurant.id}',
          'name': '${restaurant.nombre}'
        });
    await getIsFav(id);
    String userId = await isUserLogged();
    if (userId != null) {
      List<BlockUser> userBlocked =
          await _remoteRepository.getBlockUser(userId);
      List<ReportReview> reportReview =
          await _remoteRepository.getReviewReported(userId);
      List<Review> valoracionesBlocked = [];
      for (var i = 0; i < restaurant.valoraciones.length; i++) {
        var condition = true;
        for (var y = 0; y < userBlocked.length; y++) {
          if (userBlocked[y].userBlockedId ==
              restaurant.valoraciones[i].usuario.id) {
            condition = false;
          }

        }
        for (var y = 0; y < reportReview.length; y++) {
          if (reportReview[y].valoracionesId ==
              restaurant.valoraciones[i].id) {
            condition = false;
          }
        }
        if (condition) {
          valoracionesBlocked.add(restaurant.valoraciones[i]);
        }
      }
      restaurant.valoraciones = valoracionesBlocked;
    }
    _view.setRestaurant(restaurant);
  }

  blockUser(String userId, String userIdToBlock) async {
    await _remoteRepository.blockUser(userId, userIdToBlock);
    _view.refreshScreen();
  }
  reportReview(String userId, String reviewId) async{
    await _remoteRepository.reportReview(userId, reviewId);
    _view.refreshScreen();

  }

  getIsFav(String restaurantId) async {
    RestaurantSQLLite restaurantSQLLite =
        await sqlLiteLocalRepository.getRestaurant(restaurantId);
    bool correct = false;
    if (restaurantSQLLite != null) {
      correct = true;
    } else {
      correct = false;
    }
    _view.setFav(correct);
  }

  saveFavRestaurant(String restaurantId) async {
    bool correct = false;
    RestaurantSQLLite restaurantSQLLite =
        await sqlLiteLocalRepository.getRestaurant(restaurantId);
    if (restaurantSQLLite != null) {
      correct = await sqlLiteLocalRepository.removeRestaurant(restaurantId);
    } else {
      correct = await sqlLiteLocalRepository.insertRestaurant(restaurantId);
    }
    sqlLiteLocalRepository.getRestaurants();
    _view.setFav(correct);
  }
}

abstract class DetailView {
  goToLogin();

  setFav(bool correct);

  refreshScreen();

  setUserId(String id);

  setRestaurant(Restaurant restaurant);
}
