import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/user_cubit.dart';

class SplashScreenPresenter{
  final SplashScreenView _view ;
  final RemoteRepository _remoteRepository ;
  final UserCubit _userCubit;


  SplashScreenPresenter(this._view, this._remoteRepository, this._userCubit);

  getUserInfo() async {
    String userId = "08444ae3-0f82-4c51-9d67-50ef92458aac";
    print("Prueba");
    await _userCubit.getUserInfo(userId);
    _view.goToMenu();
  }
}
abstract class SplashScreenView{
  goToMenu();
}