
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/data/RemoteRepository.dart';

class ValoracionesPresenter{
  ValoracionesView _view;
  RemoteRepository _remoteRepository;
  final storage = new FlutterSecureStorage();

  ValoracionesPresenter(this._view, this._remoteRepository);

  isUserLogged() async {
    String userId = await storage.read(key: "userId");
    print(userId);
    if (userId == null){
      _view.goToLogin();
    }
  }
}
abstract class ValoracionesView{
  goToLogin();
}