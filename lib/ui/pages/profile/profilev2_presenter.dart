import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/data/local/restaurant_sql_lite.dart';
import 'package:guachinches/data/local/sql_lite_local_repository.dart';
import 'package:guachinches/data/model/Cupones.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/data/model/user_info.dart';

class Profilev2Presenter{
  final Profilev2View _view;
  final storage = new FlutterSecureStorage();
  UserCubit _userCubit;
  RemoteRepository _remoteRepository;
  SqlLiteLocalRepository sqlLiteLocalRepository = SqlLiteLocalRepository();
  Profilev2Presenter(this._view, this._userCubit, this._remoteRepository);


  getUserInfo() async {
    String? userId = await storage.read(key: "userId");
    if (userId != null) {
      UserInfo userInfo = await _remoteRepository.getUserInfo(userId).timeout(const Duration(seconds: 5));
      _view.setUserInfo(userInfo);
    }

  }
}

abstract class Profilev2View{
  setUserInfo(UserInfo userInfo);
}
