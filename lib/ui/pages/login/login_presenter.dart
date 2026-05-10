import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/ui/pages/discover/discover_screen.dart';
import 'package:guachinches/ui/pages/listas/listas_screen.dart';
import 'package:guachinches/ui/pages/map/map_search.dart';
import 'package:guachinches/ui/pages/new_home/new_home_screen.dart';
import 'package:guachinches/ui/pages/profile/profile_v2.dart';

class LoginPresenter{
  final RemoteRepository _remoteRepository;
  final LoginView _view;
  final storage = new FlutterSecureStorage();
  final UserCubit _userCubit;

  LoginPresenter(this._remoteRepository, this._view, this._userCubit);

  login(String email, String password) async{
    try{
    var userId = await _remoteRepository.loginUser(email,password);
    List<Widget> screens = [
      const NewHomeScreen(),
      const ListasScreen(),
      MapSearch(),
      const DiscoverScreen(),
      Profilev2(),
    ];

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

