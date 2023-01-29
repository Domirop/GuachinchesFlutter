
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/data/cubit/user/user_state.dart';

class ValoracionesPresenter{
  ValoracionesView _view;
  RemoteRepository _remoteRepository;
  UserCubit _userCubit;
  final storage = new FlutterSecureStorage();

  ValoracionesPresenter(this._view, this._remoteRepository, this._userCubit);

  isUserLogged() async {
    String userId = await storage.read(key: "userId");
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