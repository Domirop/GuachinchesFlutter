
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/services/app_storage.dart';

class ValoracionesPresenter{
  ValoracionesView _view;
  RemoteRepository _remoteRepository;
  UserCubit _userCubit;
  final storage = AppStorage.instance;

  ValoracionesPresenter(this._view, this._remoteRepository, this._userCubit);

  isUserLogged() async {
    String? userId = await storage.read(key: "userId");
    if (userId == null){
      _view.goToLogin();
    }else{
      // if (_userCubit.state is UserInitial) {
      await _userCubit.getUserInfo(userId);
      //}
    }
  }
}
abstract class ValoracionesView{
  goToLogin();
}