import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/user_cubit.dart';

class LoginPresenter{
  final RemoteRepository _remoteRepository;
  final LoginView _view;
  final storage = new FlutterSecureStorage();
  final UserCubit _userCubit;

  LoginPresenter(this._remoteRepository, this._view, this._userCubit);

  login(String email, String password) async{
    String userId = await _remoteRepository.loginUser(email,password);
    if (userId != null){
      await storage.write(key: "userId", value: userId);
      _userCubit.getUserInfo(userId);
    }
    _view.loginSuccess();
  }
}

abstract class LoginView{
  loginSuccess();
  loginError();
}