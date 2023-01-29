import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/ui/pages/home/home.dart';
import 'package:guachinches/ui/pages/profile/profile.dart';
import 'package:guachinches/ui/pages/search_page/search_page.dart';
import 'package:guachinches/ui/pages/valoraciones/valoraciones.dart';

class LoginPresenter{
  final RemoteRepository _remoteRepository;
  final LoginView _view;
  final storage = new FlutterSecureStorage();
  final UserCubit _userCubit;

  LoginPresenter(this._remoteRepository, this._view, this._userCubit);

  login(String email, String password) async{
    try{
    var userId = await _remoteRepository.loginUser(email,password);
    List<Widget> screens = [Home(), SearchPage(), Valoraciones(), Profile()];

    if (userId != null){
      await storage.write(key: "userId", value: userId["id"]);
      await storage.write(key: "accessToken", value: userId["accessToken"]);
      await storage.write(key: "refreshToken", value: userId["refreshToken"]);
      _userCubit.getUserInfo(userId["id"]);
    }
    _view.loginSuccess(screens);
  }catch(e){
      _view.loginError();
    }
  }
}

abstract class LoginView{
  loginSuccess(List<Widget> screens);
  loginError();
}
