import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ProfilePresenter{
  final ProfileView _view;
  final storage = new FlutterSecureStorage();

  ProfilePresenter(this._view);

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
