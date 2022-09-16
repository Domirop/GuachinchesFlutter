import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/data/local/restaurant_sql_lite.dart';
import 'package:guachinches/data/local/sql_lite_local_repository.dart';
import 'package:guachinches/data/model/Cupones.dart';
import 'package:guachinches/data/model/restaurant.dart';

class ProfilePresenter{
  final ProfileView _view;
  final storage = new FlutterSecureStorage();
  UserCubit _userCubit;
  RemoteRepository _remoteRepository;
  SqlLiteLocalRepository sqlLiteLocalRepository = SqlLiteLocalRepository();
  ProfilePresenter(this._view, this._userCubit, this._remoteRepository);


  getUserInfo() async {
    String userId = await storage.read(key: "userId");
    await _userCubit.getUserInfo(userId);
    List<Cupones> cupones = await _remoteRepository.getCuponesUsuario(userId);
    _view.updateCupones(cupones);
  }

  removeCupon(String id) async {
    await _remoteRepository.removeCupon(id);
    String userId = await storage.read(key: "userId");
    List<Cupones> cupones = await _remoteRepository.getCuponesUsuario(userId);
    _view.updateCupones(cupones);
  }

  getRestaurantsFavs() async {
    List<RestaurantSQLLite> restaurantsSql = await sqlLiteLocalRepository.getRestaurants();
    List<Restaurant> restaurants = [];
    for(var i = 0; i < restaurantsSql.length; i++) {
      Restaurant restaurant = await _remoteRepository.getRestaurantById(restaurantsSql[i].restaurantId);
      restaurant.id = restaurantsSql[i].restaurantId;
      restaurants.add(restaurant);
    }
    _view.updateListSql(restaurants);
  }

  logOut() async {

    await storage.delete(key: "userId");
    await storage.delete(key: "accessToken");
    await storage.delete(key: "refreshToken");

    _view.goSplashScreen();
  }

  deleteAccount() async {
    await storage.delete(key: "userId");
    await storage.delete(key: "accessToken");
    await storage.delete(key: "refreshToken");

    _view.goSplashScreen();
    String userId = await storage.read(key: "userId");
    await _remoteRepository.deleteUser(userId);
  }
}

abstract class ProfileView{
  goSplashScreen();
  updateListSql(List<Restaurant> restaurants);
  updateCupones(List<Cupones> cupones);
}
