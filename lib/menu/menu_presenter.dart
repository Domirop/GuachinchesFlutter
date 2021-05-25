import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/user_cubit.dart';

class MenuPresenter {
  final MenuView _view;
  final storage = new FlutterSecureStorage();
  final UserCubit _userCubit;

  MenuPresenter(this._view, this._userCubit);

  getUserInfo() async {
    String userId = await storage.read(key: "userId");
    if (userId != null) {
      await _userCubit.getUserInfo(userId);
      _view.loginSuccess();
    }else{
      _view.loginSuccess();
    }
  }
}

abstract class MenuView {
  loginSuccess();

  loginError();
}
