import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/data/cubit/restaurant_cubit.dart';
import 'package:guachinches/data/cubit/user_cubit.dart';
import 'package:guachinches/data/local/restaurant_sql_lite.dart';
import 'package:guachinches/data/local/sql_lite_local_repository.dart';

class ProfilePresenter{
  final ProfileView _view;
  final storage = new FlutterSecureStorage();
  UserCubit _userCubit;
  SqlLiteLocalRepository sqlLiteLocalRepository = SqlLiteLocalRepository();
  RestaurantCubit _restaurantCubit;
  ProfilePresenter(this._view, this._userCubit, this._restaurantCubit);


  getUserInfo() async {
    String userId = await storage.read(key: "userId");
    await _userCubit.getUserInfo(userId);
  }

  getRestaurantsFavs() async {
    List<RestaurantSQLLite> restaurants = await sqlLiteLocalRepository.getRestaurants();
    _view.updateListSql(restaurants);
  }

  getAllRestaurants() async {
    await _restaurantCubit.getRestaurants();
  }

  logOut() async {

    await storage.delete(key: "userId");
    await storage.delete(key: "accessToken");
    await storage.delete(key: "refreshToken");

    _view.goSplashScreen();
  }
}

abstract class ProfileView{
  goSplashScreen();
  updateListSql(List<RestaurantSQLLite> restaurants);
}
