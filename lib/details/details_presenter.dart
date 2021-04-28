import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/data/RemoteRepository.dart';

class DetailPresenter{
  RemoteRepository _remoteRepository;
  DetailView _view;
  final storage = new FlutterSecureStorage();

  DetailPresenter(this._remoteRepository, this._view);

  isUserLogged() async {
    String userId = await storage.read(key: "userId");
    if(userId != null){
      _view.goToNewReview();
    }else{
      _view.goToLogin();
    }
  }
}

abstract class DetailView{
  goToLogin();
  goToNewReview();
}