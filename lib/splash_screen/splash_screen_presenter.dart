import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/user_cubit.dart';

class SplashScreenPresenter{
  final SplashScreenView _view ;
  final RemoteRepository _remoteRepository ;
  final UserCubit _userCubit;
  final storage = new FlutterSecureStorage();


  SplashScreenPresenter(this._view, this._remoteRepository, this._userCubit);

  getUserInfo() async {
    // String userId = await storage.read(key: "userId");

    userId = "7f88bd16-db4b-4ac6-85fb-47910b15ee74";
    if(userId != null){
      await _userCubit.getUserInfo(userId);

    }
    _view.goToMenu();
  }
}
abstract class SplashScreenView{
  goToMenu();
}