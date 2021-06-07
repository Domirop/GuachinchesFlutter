import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/data/cubit/user_cubit.dart';

class ProfilePresenter{
  final ProfileView _view;
  final storage = new FlutterSecureStorage();
  UserCubit _userCubit;
  ProfilePresenter(this._view, this._userCubit);

  getUserInfo() async {
    String userId = await storage.read(key: "userId");
    await _userCubit.getUserInfo(userId);
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
}
