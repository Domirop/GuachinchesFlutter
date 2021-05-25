import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/user_cubit.dart';
import 'package:guachinches/home/home.dart';
import 'package:guachinches/profile.dart';
import 'package:guachinches/valoraciones/valoraciones.dart';

class LoginPresenter{
  final RemoteRepository _remoteRepository;
  final LoginView _view;
  final storage = new FlutterSecureStorage();
  final UserCubit _userCubit;

  LoginPresenter(this._remoteRepository, this._view, this._userCubit);

  login(String email, String password) async{
    String userId = await _remoteRepository.loginUser(email,password);
    List<Widget> screens = [Home(), Valoraciones(), Profile()];
    if (userId != null){
      await storage.write(key: "userId", value: userId);
      _userCubit.getUserInfo(userId);
    }
    _view.loginSuccess(screens);
  }
}

abstract class LoginView{
  loginSuccess(List<Widget> screens);
  loginError();
}